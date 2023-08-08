--------------------------------------------
-- VIEWS --
--------------------------------------------


-- accounts that are ready for deletion --
DROP VIEW IF EXISTS acc_deletion_rdy_view;
CREATE VIEW acc_deletion_rdy_view AS
	SELECT acc.account_id AS account_id
	FROM accounts acc
	WHERE
		acc.del_process_started = TRUE
		AND DATE_PART('day', CURRENT_TIMESTAMP - acc.date_last_login) >= 30;


-- current teams and their rosters --
DROP VIEW IF EXISTS tea_rosters_view;
CREATE VIEW tea_rosters_view AS
	SELECT DISTINCT ON (tph.team_id, tph.player_id)
		tph.history_timestamp AS history_timestamp,
		tph.team_id AS team_id,
		tph.player_id AS player_id,
		tph.team_role AS team_role,
		tph.is_active AS is_active
	FROM teams t
		INNER JOIN team_player_histories tph USING(team_id)
	WHERE
		t.date_disbanded IS NULL
		AND tph.team_role != 'UNK'
	ORDER BY tph.team_id, tph.player_id, tph.history_timestamp DESC;


-- teams that are ready for disbandment --
DROP VIEW IF EXISTS tea_disband_rdy_view;
CREATE VIEW tea_disband_rdy_view AS
	SELECT t.team_id AS team_id
	FROM teams t
	WHERE
		t.date_disbanded IS NULL
		AND DATE_PART('day', CURRENT_TIMESTAMP - t.date_db_process_started) >= 30;


-- unfinished matches --
DROP VIEW IF EXISTS mat_unfinished_view;
CREATE VIEW mat_unfinished_view AS
	SELECT m.match_id AS match_id
	FROM matches m
	WHERE
		m.match_result IS NULL;


-- season and point combination --
DROP VIEW IF EXISTS leagseas_seasonpoints_view;
CREATE VIEW leagseas_seasonpoints_view AS
	SELECT
		ls.season_id AS season_id,
		l.league_id AS league_id,
		l.cutoff_points AS cutoff_points
	FROM league_seasons ls
		INNER JOIN leagues l USING(league_id);

DROP VIEW IF EXISTS leagseas_seasonpoints_cur_view;
CREATE VIEW leagseas_seasonpoints_cur_view AS
	SELECT *
	FROM leagseas_seasonpoints_view
	WHERE
		season_id IN (
			SELECT season_id
			FROM seasons
			WHERE is_current = TRUE );


--------------------------------------------
-- TRIGGER FUNCTIONS --
--------------------------------------------


CREATE OR REPLACE FUNCTION prank_creation_fk()
RETURNS TRIGGER AS
$$
DECLARE
    _league_id integer;
BEGIN
	-- set it to lowest league --
	SELECT league_id
	FROM leagseas_seasonpoints_cur_view
	INTO _league_id
	ORDER BY cutoff_points ASC
	LIMIT 1;

    INSERT INTO player_rankings(
		player_id, league_id )
	VALUES( 
		NEW.player_id, _league_id );

	RETURN NEW;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION trank_creation_fk()
RETURNS TRIGGER AS
$$
DECLARE
    _league_id integer;
BEGIN
	-- set it to lowest league --
	SELECT league_id
	FROM leagseas_seasonpoints_cur_view
	INTO _league_id
	ORDER BY cutoff_points ASC
	LIMIT 1;

    INSERT INTO team_rankings(
		team_id, league_id )
	VALUES( 
		NEW.team_id, _league_id );

	RETURN NEW;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION ptrank_seasonreset_fk()
RETURNS TRIGGER AS
$$
BEGIN
	UPDATE player_rankings
	SET
		ranking = 0,
		season_start_state = 99
	WHERE
		player_id IN(
			SELECT player_id
			FROM players
			WHERE account_id IS NOT NULL );

	UPDATE team_rankings
	SET
		ranking = 0,
		season_start_state = 99
	WHERE
		team_id IN(
			SELECT team_id
			FROM teams
			WHERE date_disbanded IS NULL);

	RETURN NEW;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION ptrank_chgranking_fk()
RETURNS TRIGGER AS
$$
DECLARE
    _new_league_id integer;
BEGIN
	IF NEW.season_start_state = 99
	THEN
		NEW.season_start_state := 0;
	ELSIF OLD.season_start_state < 10
	THEN
		-- if still season_start
		IF NEW.ranking > OLD.ranking
		THEN
			-- flat bonus at season start --
			NEW.ranking := OLD.ranking + 100;
		ELSE
			-- don't punish losses --
			NEW.ranking := OLD.ranking;
		END IF;

		NEW.season_start_state := OLD.season_start_state + 1;

	END IF;

	-- set new league_id if ranking changed
	SELECT league_id
	FROM leagseas_seasonpoints_cur_view
	INTO _new_league_id
	WHERE
		NEW.ranking >= cutoff_points
	ORDER BY cutoff_points DESC
	LIMIT 1;

	IF OLD.league_id != _new_league_id
	THEN
		NEW.league_id := _new_league_id;
	END IF;

	RETURN NEW;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION tphist_creation_fk()
RETURNS TRIGGER AS
$$
DECLARE
    _player_id bigint;
BEGIN
	SELECT player_id
	FROM tea_rosters_view
	INTO _player_id
	WHERE
		team_id = NEW.team_id
		AND team_role = 'CPT';

	IF _player_id IS NULL
	THEN
		INSERT INTO team_player_histories(
			team_id, player_id, team_role )
		VALUES( 
			NEW.team_id, NEW.player_id, 'CPT' );
	ELSE
		INSERT INTO team_player_histories(
			team_id, player_id )
		VALUES( 
			NEW.team_id, NEW.player_id );
	END IF;

	RETURN NEW;
END;
$$ LANGUAGE plpgsql;


--------------------------------------------
-- TRIGGER --
--------------------------------------------


DROP TRIGGER IF EXISTS play_creation_tr
    ON players;
CREATE TRIGGER play_creation_tr
    AFTER INSERT
    ON players
    FOR EACH ROW
    EXECUTE FUNCTION prank_creation_fk();


DROP TRIGGER IF EXISTS tea_creation_tr
    ON teams;
CREATE TRIGGER tea_creation_tr
    AFTER INSERT
    ON teams
    FOR EACH ROW
    EXECUTE FUNCTION trank_creation_fk();


DROP TRIGGER IF EXISTS prank_chgranking_tr
    ON player_rankings;
CREATE TRIGGER prank_chgranking_tr
    BEFORE UPDATE
    OF ranking
    ON player_rankings
    FOR EACH ROW
    EXECUTE FUNCTION ptrank_chgranking_fk();


DROP TRIGGER IF EXISTS trank_chgranking_tr
    ON team_rankings;
CREATE TRIGGER trank_chgranking_tr
    BEFORE UPDATE
    OF ranking
    ON team_rankings
    FOR EACH ROW
    EXECUTE FUNCTION ptrank_chgranking_fk();


DROP TRIGGER IF EXISTS seasons_chgcurrent_tr
    ON seasons;
CREATE TRIGGER seasons_chgcurrent_tr
    BEFORE UPDATE
    OF is_current
    ON seasons
    FOR EACH STATEMENT
    EXECUTE FUNCTION ptrank_seasonreset_fk();


DROP TRIGGER IF EXISTS teamplay_creation_tr
    ON team_players;
CREATE TRIGGER teamplay_creation_tr
    AFTER INSERT
    ON team_players
    FOR EACH ROW
    EXECUTE FUNCTION tphist_creation_fk();


--------------------------------------------
-- STORED PROCEDURES + FUNCTIONS --
--------------------------------------------


-- create account, data from website etc. --
CREATE OR REPLACE PROCEDURE acc_creation_pd(
	_account_id uuid, _user_name varchar, _email varchar, _password char, _first_name varchar, _last_name varchar, _phone_number varchar DEFAULT NULL)
AS $$
BEGIN
	INSERT INTO accounts(
		account_id, user_name, email, password, first_name, last_name, phone_number)
	VALUES(
		_account_id, _user_name, _email, _password, _first_name, _last_name, _phone_number);
END;
$$ LANGUAGE plpgsql;


-- check accounts for deletion --
-- should frequently be run, e.g. cronjob --
-- better control than with trigger --
CREATE OR REPLACE PROCEDURE acc_deletion_pd()
AS $$
BEGIN
	DELETE FROM accounts
	WHERE account_id IN (
		SELECT account_id
		FROM acc_deletion_rdy_view);
END;
$$ LANGUAGE plpgsql;


-- return account_id --
CREATE OR REPLACE FUNCTION acc_chklogin_fk( _user_name varchar,_password char )
RETURNS TABLE (acc_id uuid)
AS $$
BEGIN
    RETURN QUERY SELECT account_id
    FROM accounts
    WHERE
        user_name = _user_name
        AND password = _password;
END;
$$ LANGUAGE plpgsql;


-- should be called when user successfully logs in --
CREATE OR REPLACE PROCEDURE acc_onlogin_pd( _account_id uuid )
AS $$
BEGIN
	UPDATE accounts
	SET
		date_last_login = CURRENT_TIMESTAMP,
		del_process_started = FALSE
	WHERE
		account_id = _account_id;
END;
$$ LANGUAGE plpgsql;


-- if none, player must be created first
CREATE OR REPLACE FUNCTION play_chklogin_fk( _account_id uuid )
RETURNS TABLE (play_id bigint)
AS $$
BEGIN
--    RETURN QUERY SELECT player_id
--    FROM players
--    WHERE
--        account_id = _account_id;
	RETURN QUERY SELECT player_id
	FROM accounts
	WHERE
		account_id = _account_id
		AND player_id IS NOT NULL;
END;
$$ LANGUAGE plpgsql;


-- start deletion process --
CREATE OR REPLACE PROCEDURE acc_startdel_pd( _account_id uuid )
AS $$
BEGIN
	UPDATE accounts
	SET
		del_process_started = TRUE
	WHERE
		account_id = _account_id;
END;
$$ LANGUAGE plpgsql;


-- update account information --
-- old values should be sent if no changes --
CREATE OR REPLACE PROCEDURE acc_chginfo_pd(
	_account_id uuid, _email varchar, _password char, _first_name varchar, _last_name varchar,
	_phone_number varchar DEFAULT NULL)
AS $$
BEGIN
	UPDATE accounts
	SET
		email = _email,
		password = _password,
		first_name = _first_name,
		last_name = _last_name,
		phone_number = _phone_number
	WHERE
		account_id = _account_id;
END;
$$ LANGUAGE plpgsql;


-- create player entry, if none yet --
CREATE OR REPLACE PROCEDURE play_creation_pd( _account_id uuid, _player_name varchar )
AS $$
DECLARE
	_player_id bigint;
BEGIN
	INSERT INTO players(
		account_id, player_name )
	VALUES( 
		_account_id, _player_name )
	RETURNING player_id INTO _player_id;

	UPDATE accounts
	SET
		player_id = _player_id
	WHERE
		account_id = _account_id;
END;
$$ LANGUAGE plpgsql;


-- namechange --
CREATE OR REPLACE PROCEDURE play_chgname_pd( _player_id bigint, _player_name varchar )
AS $$
BEGIN
	UPDATE players
	SET
		player_name = _player_name
	WHERE
		player_id = _player_id;
END;
$$ LANGUAGE plpgsql;


-- check if player can change role of others --
-- check if player can invite or set active role true --
CREATE OR REPLACE FUNCTION play_chkrole_fk( _player_id bigint,_team_id bigint )
RETURNS TABLE (team_role char)
AS $$
BEGIN
    RETURN QUERY SELECT team_role
    FROM tea_rosters_view
    WHERE
        player_id = _player_id
        AND team_id = _team_id;
END;
$$ LANGUAGE plpgsql;


-- check if player can join team --
CREATE OR REPLACE PROCEDURE play_jointeam_pd( _player_id bigint, _team_id bigint )
AS $$
DECLARE
	team_count integer;
	mem_count integer;
	_old_team bigint;
BEGIN
	SELECT COUNT(*)
	FROM tea_rosters_view
	INTO team_count
	WHERE
		player_id = _player_id;
	SELECT COUNT(player_id)
	FROM tea_rosters_view
	INTO mem_count
	WHERE
		team_id = _team_id;
	SELECT team_id
	FROM team_player_histories
	INTO _old_team
	WHERE
		player_id = _player_id
		AND team_id = _team_id;

	IF team_count < 3 AND mem_count < 20
	THEN
		IF _old_team IS NULL
		THEN
			INSERT INTO team_players(
				team_id, player_id )
			VALUES( 
				_team_id, _player_id );
		ELSE			
			INSERT INTO team_player_histories(
				team_id, player_id )
			VALUES( 
				_team_id, _player_id );
		END IF;
	END IF;
END;
$$ LANGUAGE plpgsql;


-- change team_role of player --
CREATE OR REPLACE PROCEDURE play_chgrole_pd( _player_id bigint, _team_id bigint, _team_role char )
AS $$
BEGIN
	-- use leave function for that --
	IF _team_role != 'UNK'
	THEN
		-- unset old cpt or vic --
		IF _team_role = 'VIC' OR _team_role = 'CPT'
		THEN
			UPDATE team_player_histories
			SET
				team_role = DEFAULT
			WHERE
				player_id IN(
					SELECT player_id
					FROM tea_rosters_view
					WHERE
						team_id = _team_id
						AND team_role = _team_role);
		END IF;

		UPDATE team_player_histories
		SET
			team_role = _team_role
		WHERE
			player_id = _player_id
			AND team_id = _team_id;
	END IF;
END;
$$ LANGUAGE plpgsql;


-- change is_active of player --
CREATE OR REPLACE PROCEDURE play_chgactive_pd( _player_id bigint, _team_id bigint, _is_active boolean )
AS $$
DECLARE
	mem_active_count integer;
BEGIN
	IF _is_active = TRUE
	THEN
		SELECT COUNT(player_id)
		FROM tea_rosters_view
		INTO mem_active_count
		WHERE
			team_id = _team_id
			AND is_active = TRUE;
	END IF;

	IF mem_active_count IS NULL OR mem_active_count < 5
	THEN
		UPDATE team_player_histories
		SET
			is_active = _is_active
		WHERE
			player_id = _player_id
			AND team_id = _team_id;
	END IF;
END;
$$ LANGUAGE plpgsql;


-- checks if team has enough members (should be called by matchmaking service) --
CREATE OR REPLACE FUNCTION tea_chkmem_fk( _team_id bigint )
RETURNS TABLE (mem_active_count integer)
AS $$
BEGIN
    RETURN QUERY SELECT COUNT(player_id)
	FROM tea_rosters_view
	WHERE
		team_id = _team_id
		AND is_active = TRUE;
END;
$$ LANGUAGE plpgsql;


-- create team entry, if not exists --
CREATE OR REPLACE PROCEDURE tea_creation_pd( _player_id bigint, _team_name varchar )
AS $$
DECLARE
	team_count integer;
	_team_id bigint;
BEGIN
	SELECT COUNT(*)
	FROM tea_rosters_view
	INTO team_count
	WHERE
		player_id = _player_id;

	IF team_count < 3
	THEN
		INSERT INTO teams(
			player_id, team_name )
		VALUES( 
			_player_id, _team_name )
		RETURNING team_id INTO _team_id;

		INSERT INTO team_players(
			player_id, team_id )
		VALUES( 
			_player_id, _team_id );
	END IF;
END;
$$ LANGUAGE plpgsql;


-- start/stop db_process of team --
CREATE OR REPLACE PROCEDURE tea_chgdb_process_pd( _team_id bigint )
AS $$
BEGIN
	UPDATE teams
		SET date_db_process_started = (CASE WHEN date_db_process_started IS NULL THEN CURRENT_TIMESTAMP
											ELSE NULL
										END)
		WHERE
			team_id = _team_id;
END;
$$ LANGUAGE plpgsql;

-- check for disband team --
-- should be run by cronjob --
-- also possible to set name to '', to free up names --
CREATE OR REPLACE PROCEDURE tea_disband_pd()
AS $$
BEGIN
	-- remove all players that are still part of team --
	UPDATE team_player_histories
	SET team_role = 'UNK'
	WHERE
        team_role != 'UNK'
		AND team_id IN (
			SELECT team_id
			FROM tea_disband_rdy_view);

	-- disband current teams with 0 players in roster --
	UPDATE teams
	SET date_disbanded = CURRENT_DATE
	WHERE
		date_disbanded IS NULL 
		AND team_id NOT IN(
			SELECT team_id
			FROM tea_rosters_view);
END;
$$ LANGUAGE plpgsql;


-- player leaves team --
CREATE OR REPLACE PROCEDURE play_leaveteam_pd( _player_id bigint, _team_id bigint )
AS $$
DECLARE
	_team_role varchar;
BEGIN
	-- old role --
	SELECT team_role
	FROM tea_rosters_view
	INTO _team_role
	WHERE
		team_id = _team_id
		AND player_id = _player_id;

	-- remove player from team --
	UPDATE team_player_histories
	SET team_role = 'UNK'
	WHERE
		team_id = _team_id
		AND player_id = _player_id;

	-- set new captain, if captain left --
	IF _team_role = 'CPT'
	THEN
		UPDATE team_player_histories
		SET team_role = 'CPT'
		WHERE
			team_id = _team_id
			AND (team_role = 'VIC'
				OR player_id IN (
					SELECT player_id
					FROM tea_rosters_view
					ORDER BY history_timestamp ASC));
	END IF;
END;
$$ LANGUAGE plpgsql;


-- create match_mode entry, if not exists --
CREATE OR REPLACE PROCEDURE mamo_creation_pd( _match_type char, _is_ranked boolean, _rounds numeric )
AS $$
BEGIN
	INSERT INTO match_modes(
		match_type, is_ranked, rounds )
	VALUES( 
		_match_type, _is_ranked, _rounds );
END;
$$ LANGUAGE plpgsql;


-- change match_mode information --
CREATE OR REPLACE PROCEDURE mamo_chginfo_pd( _match_mode_id integer, _match_type char, _is_ranked boolean, _rounds numeric )
AS $$
BEGIN
	UPDATE match_modes
	SET 
		match_type = _match_type,
		is_ranked = _is_ranked,
		rounds = _rounds
	WHERE
		match_mode_id = _match_mode_id;
END;
$$ LANGUAGE plpgsql;


-- gives list of match_modes and their info --
-- to present the user a list of possible modes to choose from --
CREATE OR REPLACE FUNCTION mamo_chkinfo_fk()
RETURNS TABLE ( _match_mode_id integer, _match_type char, _is_ranked boolean, _rounds numeric )
AS $$
BEGIN
    RETURN QUERY SELECT *
	FROM match_modes;
END;
$$ LANGUAGE plpgsql;


-- create match entry, if not exists --
-- assumption that it is always 2 players or 2 teams --
-- returns the match_id to change result later --
CREATE OR REPLACE PROCEDURE mat_creation_pd( _match_mode_id integer, _participant_id_1 bigint, _participant_id_2 bigint, INOUT _match_id bigint )
AS $$
DECLARE
	_match_type varchar;
BEGIN
	-- get the match_type to determine wether participant_id is a player_id or team_id --
	SELECT match_type
	FROM match_modes
	INTO _match_type
	WHERE
		match_mode_id = _match_mode_id;

	-- create the match --
	INSERT INTO matches(
		match_mode_id )
	VALUES( 
		_match_mode_id )
	RETURNING match_id INTO _match_id;

	-- add the participants to the match --
	IF _match_type = 'SOLO'
	THEN
		INSERT INTO solo_matches(
			 player_id, match_id, match_mode_id )
		VALUES 
			( _participant_id_1, _match_id, _match_mode_id ),
			( _participant_id_2, _match_id, _match_mode_id );
	ELSIF _match_type = 'TEAM'
	THEN
		INSERT INTO team_matches(
			 team_id, match_id, match_mode_id )
		VALUES 
			( _participant_id_1, _match_id, _match_mode_id ),
			( _participant_id_2, _match_id, _match_mode_id );
	END IF;
END;
$$ LANGUAGE plpgsql;


-- deletes all unfinished matches, should only be used if something like a system failure happened --
CREATE OR REPLACE PROCEDURE mat_deletion_pd()
AS $$
BEGIN
	DELETE FROM solo_matches
	WHERE match_id IN (
		SELECT match_id
		FROM mat_unfinished_view);

	DELETE FROM team_matches
	WHERE match_id IN (
		SELECT match_id
		FROM mat_unfinished_view);

	DELETE FROM matches
	WHERE match_result IS NULL;
END;
$$ LANGUAGE plpgsql;


-- update match_result after game finished --
-- should be id of winner or 0 if draw --
CREATE OR REPLACE PROCEDURE mat_chgresult_pd( _match_id bigint, _match_result bigint )
AS $$
DECLARE
	_match_mode_id integer;
	_match_type varchar;
	_is_ranked boolean;
	_loser_id integer;
BEGIN
	UPDATE matches
	SET 
		match_result = _match_result
	WHERE
		match_id = _match_id
	RETURNING match_mode_id INTO _match_mode_id;

	SELECT match_type, is_ranked
	FROM match_modes
	INTO _match_type, _is_ranked
	WHERE 
		match_mode_id = _match_mode_id;

	-- update ranking, if ranked and no draw --
	IF _is_ranked = TRUE AND _match_result != 0
	THEN
		IF _match_type = 'SOLO'
		THEN
			-- get other id --
			SELECT player_id
			FROM solo_matches
			INTO _loser_id
			WHERE
				match_id = _match_id
				AND player_id != _match_result;

			UPDATE player_rankings
			SET 
				ranking = ranking + 10
			WHERE
				player_id = _match_result;

			UPDATE player_rankings
			SET 
				ranking = ranking - 10
			WHERE
				player_id = _loser_id;
		ELSIF _match_type = 'TEAM'
		THEN
			-- get other id --
			SELECT team_id
			FROM solo_matches
			INTO _loser_id
			WHERE
				match_id = _match_id
				AND team_id != _match_result;

			UPDATE team_rankings
			SET 
				ranking = ranking + 10
			WHERE
				team_id = _match_result;

			UPDATE team_rankings
			SET 
				ranking = ranking - 10
			WHERE
				team_id = _loser_id;
		END IF;
	END IF;
END;
$$ LANGUAGE plpgsql;


-- create season entry, if none yet -- 
CREATE OR REPLACE PROCEDURE seas_creation_pd( _season_name varchar, _date_begin date, _date_end date )
AS $$
BEGIN
	INSERT INTO seasons(
		season_name, date_begin, date_end )
	VALUES( 
		_season_name, _date_begin, _date_end );
END;
$$ LANGUAGE plpgsql;


-- changes current season should be run daily at specific time --
-- also make sure that new_season has a league --
CREATE OR REPLACE PROCEDURE seas_chgcurrent_pd()
AS $$
DECLARE
	_new_season_id integer;
BEGIN
	SELECT season_id
	FROM seasons
	INTO _new_season_id
	WHERE
		is_current != TRUE
		AND ( CURRENT_DATE BETWEEN date_begin AND date_end )
		AND season_id IN (
			SELECT season_id
			FROM league_seasons );

	-- new season started or is ongoing --
	IF _new_season_id IS NOT NULL
	THEN
		-- unset old season (partial index!) --
		UPDATE seasons
		SET 
			is_current = FALSE
		WHERE
			is_current = TRUE;

		UPDATE seasons
		SET 
			is_current = TRUE
		WHERE
			season_id = _new_season_id;
	END IF;
END;
$$ LANGUAGE plpgsql;


-- changes season info --
-- should be used carefully --
-- restrict to not current seasons --
CREATE OR REPLACE PROCEDURE seas_chginfo_pd( _season_id integer, _season_name varchar, _date_begin date, _date_end date )
AS $$
BEGIN
	UPDATE seasons
	SET 
		season_name = _season_name,
		date_begin = _date_begin,
		date_end = _date_end
	WHERE
		season_id = _season_id
		AND is_current = FALSE;
END;
$$ LANGUAGE plpgsql;


-- deletes season, should only be used if really needed --
-- also deletes respective league_seasons entries --
-- restrict to not current seasons --
CREATE OR REPLACE PROCEDURE seas_deletion_pd( _season_id integer )
AS $$
BEGIN
	DELETE FROM seasons
	WHERE
		season_id = _season_id
		AND is_current = FALSE;
END;
$$ LANGUAGE plpgsql;


-- gives list of seasons and their info, for change procedure --
CREATE OR REPLACE FUNCTION seas_chkinfo_fk()
RETURNS TABLE ( _season_id integer, _season_name varchar, _date_begin date, _date_end date, _is_current boolean )
AS $$
BEGIN
    RETURN QUERY SELECT *
	FROM seasons;
END;
$$ LANGUAGE plpgsql;


-- create league entry, if none yet -- 
CREATE OR REPLACE PROCEDURE leag_creation_pd( _league_name varchar, _cutoff_points numeric )
AS $$
BEGIN
	INSERT INTO leagues(
		league_name, cutoff_points )
	VALUES( 
		_league_name, _cutoff_points );
END;
$$ LANGUAGE plpgsql;


-- changes league info --
-- since it also affects history entries, no changes to points allowed --
CREATE OR REPLACE PROCEDURE leag_chginfo_pd( _league_id integer, _league_name varchar )
AS $$
BEGIN
	UPDATE leagues
	SET 
		league_name = _league_name
	WHERE
		league_id = _league_id;
END;
$$ LANGUAGE plpgsql;


-- deletes league, can only be used if no reference to ranking_histories --
CREATE OR REPLACE PROCEDURE leag_deletion_pd( _league_id integer )
AS $$
BEGIN
	DELETE FROM leagues
	WHERE league_id = _league_id;
END;
$$ LANGUAGE plpgsql;


-- gives list of leagues and their info, for change procedure --
CREATE OR REPLACE FUNCTION leag_chkinfo_fk()
RETURNS TABLE ( _league_id integer, _league_name varchar, _cutoff_points numeric )
AS $$
BEGIN
    RETURN QUERY SELECT *
	FROM leagues;
END;
$$ LANGUAGE plpgsql;


-- create league_seasons entry, if none yet -- 
CREATE OR REPLACE PROCEDURE leagseas_creation_pd( _season_id integer, _league_id integer )
AS $$
DECLARE
	_seasonpoints numeric;
BEGIN
	SELECT l.cutoff_points
	FROM leagues l
	INNER JOIN leagseas_seasonpoints_view lsv ON l.cutoff_points = lsv.cutoff_points
	INTO _seasonpoints
	WHERE
		l.league_id = _league_id
		AND lsv.season_id =_season_id;

	-- check wether this season-point combination already exists --
	IF _seasonpoints IS NULL
	THEN
		INSERT INTO league_seasons(
			season_id, league_id )
		VALUES( 
			_season_id, _league_id );
	END IF;
END;
$$ LANGUAGE plpgsql;


-- gives list of league_seasons --
CREATE OR REPLACE FUNCTION leagseas_chkinfo_fk()
RETURNS TABLE ( _season_id integer, _league_id integer )
AS $$
BEGIN
    RETURN QUERY SELECT *
	FROM league_seasons;
END;
$$ LANGUAGE plpgsql;


-- deletes league_season --
CREATE OR REPLACE PROCEDURE leagseas_deletion_pd( _season_id integer, _league_id integer )
AS $$
BEGIN
	DELETE FROM league_seasons
	WHERE
		season_id = _season_id
		AND league_id = _league_id;
END;
$$ LANGUAGE plpgsql;


-- create ranking_histories entry --
-- should be called by cronjob for rank update -- 
CREATE OR REPLACE PROCEDURE rankhist_creation_pd()
AS $$
BEGIN
    -- players --
	INSERT INTO ranking_histories (player_id, league_id, ranking, season_start_state)
	SELECT player_id, league_id, ranking, season_start_state
	FROM player_rankings
	WHERE player_id IN (
		SELECT player_id
		FROM players
		WHERE account_id IS NOT NULL);

	-- teams --
	INSERT INTO ranking_histories (team_id, league_id, ranking, season_start_state)
	SELECT team_id, league_id, ranking, season_start_state
	FROM team_rankings
	WHERE team_id IN (
		SELECT team_id
		FROM teams
		WHERE date_disbanded IS NOT NULL);
END;
$$ LANGUAGE plpgsql;

