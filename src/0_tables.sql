--------------------------------------------
-- CREATE TABLE + PRIMARY KEY + COMMENTS --
--------------------------------------------



-- Accounts --
-- CREATE TABLE --

CREATE TABLE accounts (
    account_id                uuid NOT NULL,
    player_id                 BIGINT,
    user_name                 VARCHAR(25) NOT NULL,
    email                     VARCHAR(320) NOT NULL,
    password                  CHAR(64) NOT NULL,
    first_name                VARCHAR(25) NOT NULL,
    last_name                 VARCHAR(25) NOT NULL,
    date_last_login           TIMESTAMP NOT NULL,
    del_process_started       BOOLEAN NOT NULL,
    phone_number              VARCHAR(15)
);

-- PRIMARY KEY --

ALTER TABLE accounts ADD CONSTRAINT accounts_pk PRIMARY KEY ( account_id );

-- COMMENTS --

COMMENT ON TABLE accounts IS
    'Accounts table that contains all the relevant data which is needed to identify users. The most important one is an ID which is unique globally, meaning across different servers. This is necessary so we can actually transfer accounts between regions, e.g. in the case of someone moving to a different country. It contains the login information in the form of a username which is NOT displayed ingame, as well as a hashed password. The user can start an account deletion process which will result in a permanent deletion after a certain time passed since the last login. It also contains additional data like first and last name, phone number, the latter one is optional and can be used for additional account security measures, if so desired.';

COMMENT ON COLUMN accounts.account_id IS
    'Unique ID generated for each account on creation, has to be globally unique for account transfers to other regions.';

COMMENT ON COLUMN accounts.user_name IS
    'Arbitrary user name, which is used for login on website, launcher etc.';

COMMENT ON COLUMN accounts.email IS
    'Email name, which is used for password reset etc.';

COMMENT ON COLUMN accounts.password IS
    'Hashed SHA-256 password, which is used for login on website, launcher etc.';

COMMENT ON COLUMN accounts.first_name IS
    'First name of the account owner.';

COMMENT ON COLUMN accounts.last_name IS
    'Last name of the account owner.';

COMMENT ON COLUMN accounts.date_last_login IS
    'Date and time of the last login, used for account deletion process.';

COMMENT ON COLUMN accounts.del_process_started IS
    'Flag that indicates that the account deletion process was started.';

COMMENT ON COLUMN accounts.phone_number IS
    'Phone Number used for account recovery, additional security etc.';



-- League_Seasons --
-- CREATE TABLE --

CREATE TABLE league_seasons (
    season_id  INTEGER NOT NULL,
    league_id  INTEGER NOT NULL
);

-- PRIMARY KEY --

ALTER TABLE league_seasons ADD CONSTRAINT league_seasons_pk PRIMARY KEY ( season_id,
                                                                          league_id );

-- COMMENTS --

COMMENT ON TABLE league_seasons IS
    'League_Seasons table that contains the Season and League ID''s. In other words which leagues are/were available in a specific season. References with the Leagues and Seasons table via primary foreign keys.';



-- Leagues --
-- CREATE TABLE --

CREATE TABLE leagues (
    league_id      SERIAL NOT NULL,
    league_name    VARCHAR(25) NOT NULL,
    cutoff_points  NUMERIC(4) NOT NULL
);

-- PRIMARY KEY --

ALTER TABLE leagues ADD CONSTRAINT leagues_pk PRIMARY KEY ( league_id );

-- COMMENTS --

COMMENT ON TABLE leagues IS
    'Seasons table that contains a specific season name, as well as the timeframe. Used together with the ranking information of a player/team and the Seasons table to determine the specific league the player/team is in. References with the Seasons table via foreign keys.';

COMMENT ON COLUMN leagues.league_id IS
    'Unique ID generated for each league on creation. Unique to the specific region.';

COMMENT ON COLUMN leagues.league_name IS
    'League name, which is displayed ingame.';

COMMENT ON COLUMN leagues.cutoff_points IS
    'Cutoff values in the form of a numeric value between 0 and 9999 (0, 1200, 1400, ..., 2600).';



-- Match_Modes --
-- CREATE TABLE --

CREATE TABLE match_modes (
    match_mode_id  SERIAL NOT NULL,
    match_type     CHAR(4) NOT NULL,
    is_ranked      BOOLEAN NOT NULL,
    rounds         NUMERIC(1) NOT NULL
);

-- PRIMARY KEY --

ALTER TABLE match_modes ADD CONSTRAINT match_modes_pk PRIMARY KEY ( match_mode_id );

-- COMMENTS --

COMMENT ON TABLE match_modes IS
    'Match_Modes table that contains information for a specific type of match like wether it''s a match between players or teams or if its necessary to update the ranking afterwards.';

COMMENT ON COLUMN match_modes.match_mode_id IS
    'Unique ID generated for each match mode on creation. Unique to the specific region.';

COMMENT ON COLUMN match_modes.match_type IS
    'Type of match, can be one of two: between individual players (solo) or between group players/teams (team).';

COMMENT ON COLUMN match_modes.is_ranked IS
    'Flag that determines wether it''s ranked or not.';

COMMENT ON COLUMN match_modes.rounds IS
    'Number of rounds per match for something like a tournament, in the form of a numeric value (1, 3, 5).';



-- Matches --
-- CREATE TABLE --

CREATE TABLE matches (
    match_id         BIGSERIAL NOT NULL,
    match_mode_id    INTEGER NOT NULL,
    match_timestamp  TIMESTAMP NOT NULL,
    match_result     BIGINT
);

-- PRIMARY KEY --

ALTER TABLE matches ADD CONSTRAINT matches_pk PRIMARY KEY ( match_id,
                                                            match_mode_id );

-- COMMENTS --

COMMENT ON TABLE matches IS
    'Matches table that contains the match specific data, like participants, as well as when the match was player and the final result. References with the Match_Modes, Players and Team table via foreign keys. Arc to differentiate between Solo and Team Matches.';

COMMENT ON COLUMN matches.match_id IS
    'Unique ID generated for each match on creation. Unique to the specific region.';

COMMENT ON COLUMN matches.match_mode_id IS
    'match_mode of this match';

COMMENT ON COLUMN matches.match_timestamp IS
    'Date and time of the match creation/start.';

COMMENT ON COLUMN matches.match_result IS
    'Result of the match, can be one of three: win for either participant (id), draw (0) and unknown (NULL) if the match is still ongoing.';



-- Player_Rankings --
-- CREATE TABLE --

CREATE TABLE player_rankings (
    player_id           BIGINT NOT NULL,
    league_id           INTEGER NOT NULL,
    ranking             NUMERIC(4) NOT NULL,
    season_start_state  NUMERIC(2) NOT NULL
);

-- PRIMARY KEY --

ALTER TABLE player_rankings ADD CONSTRAINT player_rankings_pk PRIMARY KEY ( player_id );

-- COMMENTS --

COMMENT ON TABLE player_rankings IS
    'Player_Rankings table that contains the current ranking information of the player. In other words the ranking in the form of points (a numeric value), which can be used together with the Leagues and Seasons tables to determine what League the player is in. There''s also information if the player already played his games at the start of the season after the ranking reset.';

COMMENT ON COLUMN player_rankings.player_id IS
    'Unique ID generated for each player on creation. Unique to the specific region.';

COMMENT ON COLUMN player_rankings.league_id IS
    'league that player belongs to, based on ranking';

COMMENT ON COLUMN player_rankings.ranking IS
    'Ranking in the form of a numeric value between 0 and 9999 (should never go beyond 4000).';

COMMENT ON COLUMN player_rankings.season_start_state IS
    'State of initial promos at season start, after ranking reset in the form of a numeric value between 0 and 10 (0 = no games played, +1 per game played, 10 = done).';



-- Players --
-- CREATE TABLE --

CREATE TABLE players (
    player_id    BIGSERIAL NOT NULL,
    account_id   uuid,
    player_name  VARCHAR(25) NOT NULL
);

-- PRIMARY KEY --

ALTER TABLE players ADD CONSTRAINT players_pk PRIMARY KEY ( player_id );

-- COMMENTS --

COMMENT ON TABLE players IS
    'Players table that contains user data which is unique to the game. This distinction is generally useful if there is the possibility of adding additional games. player_name only gets used ingame as a kind of visual cue for the user to easier differentiate between players. Reference with the Accounts table via foreign key. Supertype of the Player_Rankings table.';

COMMENT ON COLUMN players.player_id IS
    'Unique ID generated for each player on creation. Unique to the specific region.';

COMMENT ON COLUMN players.account_id IS
    'account that this player belongs to';

COMMENT ON COLUMN players.player_name IS
    'Arbitrary player name, which is displayed ingame.';



-- Ranking_Histories --
-- CREATE TABLE --

CREATE TABLE ranking_histories (
    history_id          BIGSERIAL NOT NULL,
    history_timestamp   TIMESTAMP NOT NULL,
    player_id           BIGINT,
    team_id             BIGINT,
    league_id           INTEGER NOT NULL,
    ranking             NUMERIC(4) NOT NULL,
    season_start_state  NUMERIC(2) NOT NULL
);

-- PRIMARY KEY + ARC --

ALTER TABLE ranking_histories ADD CONSTRAINT ranking_histories_pk PRIMARY KEY ( history_id );

ALTER TABLE ranking_histories
    ADD CONSTRAINT arc_2 CHECK ( ( ( team_id IS NOT NULL )
                                   AND ( player_id IS NULL ) )
                                 OR ( ( player_id IS NOT NULL )
                                      AND ( team_id IS NULL ) ) );

-- COMMENTS --

COMMENT ON TABLE ranking_histories IS
    'Ranking_Histories table that contains past ranking information of players/teams. New entry should be created in intervalls, like on a weekly basis. Its possible to calculate ranking information inbetween with the data from the Matches table and a history entry. Reference with the Players/Teams table via foreign key.';

COMMENT ON COLUMN ranking_histories.history_id IS
    'Unique ID generated for each history entry.';
    
COMMENT ON COLUMN ranking_histories.history_timestamp IS
    'Date and time of the history event.';

COMMENT ON COLUMN ranking_histories.player_id IS
    'player that this history entry belongs to';

COMMENT ON COLUMN ranking_histories.team_id IS
    'team that this history entry belongs to';

COMMENT ON COLUMN ranking_histories.league_id IS
    'league that player/team belongs to, based on ranking';

COMMENT ON COLUMN ranking_histories.ranking IS
    'Ranking in the form of a numeric value between 0 and 9999 (should never go beyond 4000).';

COMMENT ON COLUMN ranking_histories.season_start_state IS
    'State of initial promos at season start, after ranking reset in the form of a numeric value between 0 and 10 (0 = no games played, +1 per game played, 10 = done).';



-- Seasons --
-- CREATE TABLE --

CREATE TABLE seasons (
    season_id    SERIAL NOT NULL,
    season_name  VARCHAR(25) NOT NULL,
    date_begin   DATE NOT NULL,
    date_end     DATE NOT NULL,
    is_current    BOOLEAN NOT NULL
);

-- PRIMARY KEY --

ALTER TABLE seasons ADD CONSTRAINT seasons_pk PRIMARY KEY ( season_id );

-- COMMENTS --

COMMENT ON TABLE seasons IS
    'Seasons table that contains a specific season name, as well as the timeframe. Used together with the ranking information of a player/team and the Leagues table to determine the specific rank. Mostly used by external scripts to determine when a specific season ends and reset player/team ranking data. References with the Leagues table via foreign keys.';

COMMENT ON COLUMN seasons.season_id IS
    'Unique ID generated for each season on creation. Unique to the specific region.';

COMMENT ON COLUMN seasons.season_name IS
    'Season name, which is displayed ingame.';

COMMENT ON COLUMN seasons.date_begin IS
    'Date when the season begins.';

COMMENT ON COLUMN seasons.date_end IS
    'Date when the season ends. Important to avoid overlapping seasons.';

COMMENT ON COLUMN seasons.is_current IS
    'Current season. There can only ever be one. Check daily.';



-- Solo_Matches --
-- CREATE TABLE --

CREATE TABLE solo_matches (
    player_id      BIGINT NOT NULL,
    match_id       BIGINT NOT NULL,
    match_mode_id  INTEGER NOT NULL
);

-- PRIMARY KEY --

ALTER TABLE solo_matches
    ADD CONSTRAINT solo_matches_pk PRIMARY KEY ( player_id,
                                                 match_id,
                                                 match_mode_id );

-- COMMENTS --

COMMENT ON TABLE solo_matches IS
    'Solo_Matches table that contains the matches between single players. References with the Match_Modes and Players table via primary foreign keys.';



-- Team_Matches --
-- CREATE TABLE --

CREATE TABLE team_matches (
    team_id        BIGINT NOT NULL,
    match_id       BIGINT NOT NULL,
    match_mode_id  INTEGER NOT NULL
);

-- PRIMARY KEY --

ALTER TABLE team_matches
    ADD CONSTRAINT team_matches_pk PRIMARY KEY ( team_id,
                                                 match_id,
                                                 match_mode_id );

-- COMMENTS --

COMMENT ON TABLE team_matches IS
    'Team_Matches table that contains the matches between groups of players (teams). References with the Match_Modes and Teamss table via primary foreign keys.';



-- Team_Player_Histories --
-- CREATE TABLE --

CREATE TABLE team_player_histories (
    history_timestamp  TIMESTAMP NOT NULL,
    team_id            BIGINT NOT NULL,
    player_id          BIGINT NOT NULL,
    team_role          CHAR(3) NOT NULL,
    is_active          BOOLEAN NOT NULL
);

-- PRIMARY KEY --

ALTER TABLE team_player_histories
    ADD CONSTRAINT team_player_histories_pk PRIMARY KEY ( history_timestamp,
                                                          team_id,
                                                          player_id );

-- COMMENTS --

COMMENT ON TABLE team_player_histories IS
    'Team_Player_Histories table that contains past present members of teams, as well as their role and activity. New entry should be created everytime the role or activity changes, also everytime a player joins or leaves the team. References with the Players and the Teams table via primary foreign keys.';

COMMENT ON COLUMN team_player_histories.history_timestamp IS
    'Date and time of the history event.';

COMMENT ON COLUMN team_player_histories.team_id IS
    'team this player belongs to';

COMMENT ON COLUMN team_player_histories.player_id IS
    'player that this history entry belongs to';

COMMENT ON COLUMN team_player_histories.team_role IS
    'Role that the player performs in the team, can be one of three: captain, vize-captain or member (CPT, VIC, MEM, UNK).';

COMMENT ON COLUMN team_player_histories.is_active IS
    'Flag that determines wether a player is part of the team roster or bench.';



-- Team_Players --
-- CREATE TABLE --

CREATE TABLE team_players (
    team_id    BIGINT NOT NULL,
    player_id  BIGINT NOT NULL
);

-- PRIMARY KEY --

ALTER TABLE team_players ADD CONSTRAINT team_players_pk PRIMARY KEY ( team_id,
                                                                      player_id );

-- COMMENTS --

COMMENT ON TABLE team_players IS
    'Team_Players table that contains information which player is/was related to which team. References with the Players and the Teams table via primary foreign keys.';

COMMENT ON COLUMN team_players.team_id IS
    'team this player belongs to';

COMMENT ON COLUMN team_players.player_id IS
    'player that belongs to this team';



-- Team_Rankings --
-- CREATE TABLE --

CREATE TABLE team_rankings (
    team_id             BIGINT NOT NULL,
    league_id           INTEGER NOT NULL,
    ranking             NUMERIC(4) NOT NULL,
    season_start_state  NUMERIC(2) NOT NULL
);

-- PRIMARY KEY --

ALTER TABLE team_rankings ADD CONSTRAINT team_rankings_pk PRIMARY KEY ( team_id );

-- COMMENTS --

COMMENT ON TABLE team_rankings IS
    'Team_Rankings table that contains the current ranking information of the team. In other words the ranking in the form of points (a numeric value), which can be used together with the Leagues and Seasons tables to determine what League the team is in. There''s also information if the team already played their games at the start of the season after the ranking reset. Subtype of the Teams table.';

COMMENT ON COLUMN team_rankings.team_id IS
    'Unique ID generated for each team on creation. Unique to the specific region.';

COMMENT ON COLUMN team_rankings.league_id IS
    'league that team belongs to, based on ranking';

COMMENT ON COLUMN team_rankings.ranking IS
    'Ranking in the form of a numeric value between 0 and 9999 (should never go beyond 4000).';

COMMENT ON COLUMN team_rankings.season_start_state IS
    'State of initial promos at season start, after ranking reset in the form of a numeric value between 0 and 10 (0 = no games played, +1 per game played, 10 = done).';



-- Teams --
-- CREATE TABLE --

CREATE TABLE teams (
    team_id                  BIGSERIAL NOT NULL,
    player_id                BIGINT NOT NULL,
    team_name                VARCHAR(25) NOT NULL,
    date_created             DATE NOT NULL,
    date_db_process_started  TIMESTAMP,
    date_disbanded           DATE
);

-- PRIMARY KEY --

ALTER TABLE teams ADD CONSTRAINT teams_pk PRIMARY KEY ( team_id );

-- COMMENTS --

COMMENT ON TABLE teams IS
    'Teams table that contains the specific name of a team, as well as information of its creation and possible disbandment. The disbandment process can only be started and stopped by the team captain. Reference with the Players table via foreign key. Supertype of the Team_Rankings table.';

COMMENT ON COLUMN teams.team_id IS
    'Unique ID generated for each team on creation. Unique to the specific region.';

COMMENT ON COLUMN teams.player_id IS
    'player that created this team';

COMMENT ON COLUMN teams.team_name IS
    'Arbitrary team name, which is displayed ingame.';

COMMENT ON COLUMN teams.date_created IS
    'Date of the team creation.';

COMMENT ON COLUMN teams.date_db_process_started IS
    'Date and time when the team disbandment process was started.';

COMMENT ON COLUMN teams.date_disbanded IS
    'Date of the team disbandment.';

-------------------------------
-- REFERENCES + FOREIGN KEYS --
-------------------------------

ALTER TABLE accounts
    ADD CONSTRAINT acc_play_fk FOREIGN KEY ( player_id )
        REFERENCES players ( player_id )
            ON DELETE SET NULL;


ALTER TABLE league_seasons
    ADD CONSTRAINT league_seasons_leag_fk FOREIGN KEY ( league_id )
        REFERENCES leagues ( league_id )
            ON DELETE CASCADE;


ALTER TABLE league_seasons
    ADD CONSTRAINT league_seasons_seas_fk FOREIGN KEY ( season_id )
        REFERENCES seasons ( season_id )
            ON DELETE CASCADE;


ALTER TABLE matches
    ADD CONSTRAINT mat_mamo_fk FOREIGN KEY ( match_mode_id )
        REFERENCES match_modes ( match_mode_id );


ALTER TABLE players
    ADD CONSTRAINT play_acc_fk FOREIGN KEY ( account_id )
        REFERENCES accounts ( account_id )
            ON DELETE SET NULL;


ALTER TABLE player_rankings
    ADD CONSTRAINT prank_leag_fk FOREIGN KEY ( league_id )
        REFERENCES leagues ( league_id );


ALTER TABLE player_rankings
    ADD CONSTRAINT prank_play_fk FOREIGN KEY ( player_id )
        REFERENCES players ( player_id );


ALTER TABLE ranking_histories
    ADD CONSTRAINT rankhist_leag_fk FOREIGN KEY ( league_id )
        REFERENCES leagues ( league_id );


ALTER TABLE ranking_histories
    ADD CONSTRAINT rankhist_prank_fk FOREIGN KEY ( player_id )
        REFERENCES player_rankings ( player_id );


ALTER TABLE ranking_histories
    ADD CONSTRAINT rankhist_trank_fk FOREIGN KEY ( team_id )
        REFERENCES team_rankings ( team_id );


ALTER TABLE solo_matches
    ADD CONSTRAINT solo_matches_mat_fk FOREIGN KEY ( match_id,
                                                     match_mode_id )
        REFERENCES matches ( match_id,
                             match_mode_id );


ALTER TABLE solo_matches
    ADD CONSTRAINT solo_matches_play_fk FOREIGN KEY ( player_id )
        REFERENCES players ( player_id );


ALTER TABLE teams
    ADD CONSTRAINT tea_play_fk FOREIGN KEY ( player_id )
        REFERENCES players ( player_id );


ALTER TABLE team_matches
    ADD CONSTRAINT team_matches_mat_fk FOREIGN KEY ( match_id,
                                                     match_mode_id )
        REFERENCES matches ( match_id,
                             match_mode_id );


ALTER TABLE team_matches
    ADD CONSTRAINT team_matches_tea_fk FOREIGN KEY ( team_id )
        REFERENCES teams ( team_id );


ALTER TABLE team_players
    ADD CONSTRAINT teamplay_play_fk FOREIGN KEY ( player_id )
        REFERENCES players ( player_id );


ALTER TABLE team_players
    ADD CONSTRAINT teamplay_tea_fk FOREIGN KEY ( team_id )
        REFERENCES teams ( team_id );


ALTER TABLE team_player_histories
    ADD CONSTRAINT tphist_teamplay_fk FOREIGN KEY ( team_id,
                                                    player_id )
        REFERENCES team_players ( team_id,
                                  player_id );


ALTER TABLE team_rankings
    ADD CONSTRAINT trank_leag_fk FOREIGN KEY ( league_id )
        REFERENCES leagues ( league_id );


ALTER TABLE team_rankings
    ADD CONSTRAINT trank_tea_fk FOREIGN KEY ( team_id )
        REFERENCES teams ( team_id );

---------------------
-- CREATE TRIGGERS --
---------------------

-- TRIGGER FUNCTIONS --

CREATE OR REPLACE FUNCTION raise_excp_fk()
    RETURNS TRIGGER AS
$$
DECLARE
    arg TEXT;
BEGIN
    RAISE EXCEPTION 'Non Transferable FK constraint on table % is violated', arg;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION raise_excp_hist_arc()
    RETURNS TRIGGER AS
$$
BEGIN
    IF OLD.player_id IS NOT NULL THEN
        RAISE EXCEPTION 'Non Transferable FK constraint RankHist_PRank_FK on table Ranking_Histories is violated';
    END IF;

    IF OLD.team_id IS NOT NULL THEN
        RAISE EXCEPTION 'Non Transferable FK constraint RankHist_TRank_FK on table Ranking_Histories is violated';
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION raise_excp_players_fk()
    RETURNS TRIGGER AS
$$
BEGIN
    IF OLD.account_id IS NOT NULL THEN
        RAISE EXCEPTION 'Non Transferable FK constraint Play_Acc_FK on table Players is violated';
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;



-- CREATE TRIGGERS --

DROP TRIGGER IF EXISTS fkntm_matches
    ON matches;
CREATE TRIGGER fkntm_matches
    BEFORE UPDATE
    OF match_mode_id
    ON matches
    EXECUTE FUNCTION raise_excp_fk('Matches');


DROP TRIGGER IF EXISTS fknto_players
    ON players;
CREATE TRIGGER fknto_players
    BEFORE UPDATE
    OF account_id
    ON players
    FOR EACH ROW
    EXECUTE FUNCTION raise_excp_players_fk();


DROP TRIGGER IF EXISTS fkntm_solo_matches
    ON solo_matches;
CREATE TRIGGER fkntm_solo_matches
    BEFORE UPDATE
    OF match_id, match_mode_id
    ON solo_matches
    EXECUTE FUNCTION raise_excp_fk('Solo_Matches');


DROP TRIGGER IF EXISTS fkntm_team_matches
    ON team_matches;
CREATE TRIGGER fkntm_team_matches
    BEFORE UPDATE
    OF match_id, match_mode_id
    ON team_matches
    EXECUTE FUNCTION raise_excp_fk('Team_Matches');


DROP TRIGGER IF EXISTS fkntm_team_player_histories
    ON team_player_histories;
CREATE TRIGGER fkntm_team_player_histories
    BEFORE UPDATE
    OF team_id, player_id
    ON team_player_histories
    EXECUTE FUNCTION raise_excp_fk('Team_Player_Histories');


DROP TRIGGER IF EXISTS fkntm_team_players
    ON team_players;
CREATE TRIGGER fkntm_team_players
    BEFORE UPDATE
    OF player_id, team_id
    ON team_players
    EXECUTE FUNCTION raise_excp_fk('Team_Players');


DROP TRIGGER IF EXISTS fkntm_teams
    ON teams;
CREATE TRIGGER fkntm_teams
    BEFORE UPDATE
    OF player_id
    ON teams
    EXECUTE FUNCTION raise_excp_fk('Teams');


DROP TRIGGER IF EXISTS fknto_ranking_histories
    ON ranking_histories;
CREATE TRIGGER fknto_ranking_histories
    BEFORE UPDATE
    OF player_id, team_id
    ON ranking_histories
    FOR EACH ROW
    EXECUTE FUNCTION raise_excp_hist_arc();
