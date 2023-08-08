
-- 1. CREATE Seasons --
-- seas_creation_pd( _season_name varchar, _date_begin date, _date_end date ) --
call seas_creation_pd( 'season_1', '2000-01-01', '2001-01-01' );
call seas_creation_pd( 'test', CURRENT_DATE, CURRENT_DATE );
-- seas_chginfo_pd( _seasons_id integer, _season_name varchar, _date_begin date, _date_end date ) --
call seas_chginfo_pd( 2, 'season_2', CURRENT_DATE, CURRENT_DATE + 365 );
SELECT * FROM seas_chkinfo_fk();

-- 2. CREATE Leagues --
-- leag_creation_pd( _league_name varchar, _cutoff_points numeric ) --
call leag_creation_pd( 'Unranked', 0 );
call leag_creation_pd( 'League_1', 200 );
SELECT * FROM leag_chkinfo_fk();

-- 3. CREATE League_Seasons --
-- leagseas_creation_pd( _season_id integer, _league_id integer ) --
-- there's only unranked in season 1
call leagseas_creation_pd( 1, 1 );
-- there's unranked and league_1 in season 2
call leagseas_creation_pd( 2, 1 );
call leagseas_creation_pd( 2, 2 );
SELECT * FROM leagseas_chkinfo_fk();

-- 4. Start current Season --
call seas_chgcurrent_pd();
-- seas_deletion_pd( _seasons_id integer ) --
-- should do nothing to current season --
call seas_deletion_pd( 2 );
SELECT * FROM seasons;
SELECT * FROM leagues;

-- 5. CREATE Accounts --
-- acc_creation_pd( _account_id uuid, _user_name varchar, _email varchar, _password char, _first_name varchar, _last_name varchar, _phone_number varchar DEFAULT NULL) --
call acc_creation_pd( '123e4567-e89b-12d3-a456-426614174000', 'acc0', 'foo@bar0.com', 'foo0', 'foo0', 'bar0' );
call acc_creation_pd( '123e4567-e89b-12d3-a456-426614174001', 'acc1', 'foo@bar1.com', 'foo1', 'foo1', 'bar1' );
call acc_creation_pd( '123e4567-e89b-12d3-a456-426614174002', 'acc2', 'foo@bar2.com', 'foo2', 'foo2', 'bar2' );
-- acc_chklogin_fk( _user_name varchar,_password char ) --
SELECT * FROM acc_chklogin_fk( 'foobar1','foo1' );
SELECT * FROM accounts;

-- 6. CREATE Players --
-- play_chklogin_fk( _account_id uuid ) --
SELECT * FROM play_chklogin_fk( '123e4567-e89b-12d3-a456-426614174000' );
-- acc_startdel_pd( _account_id uuid ) --
call acc_startdel_pd( '123e4567-e89b-12d3-a456-426614174000' );
-- acc_onlogin_pd( _account_id uuid ) --
call acc_onlogin_pd( '123e4567-e89b-12d3-a456-426614174000' );
-- play_creation_pd( _account_id uuid, _player_name varchar ) --
call play_creation_pd( '123e4567-e89b-12d3-a456-426614174000', 'player0' );
call play_creation_pd( '123e4567-e89b-12d3-a456-426614174001', 'player1' );
call play_creation_pd( '123e4567-e89b-12d3-a456-426614174002', 'player2' );
SELECT * FROM players;

-- 7. CREATE Teams (add, remove players and change their role) --
-- tea_creation_pd( _player_id bigint, _team_name varchar ) --
call tea_creation_pd( 1, 'testteam0' );
call tea_creation_pd( 3, 'testteam1' );
-- play_jointeam_pd( _player_id bigint, _team_id bigint ) --
call play_jointeam_pd( 2, 1 );
-- play_chgrole_pd( _player_id bigint, _team_id bigint, _team_role char ) --
call play_chgrole_pd( 1, 1, 'CPT' );
call play_chgrole_pd( 2, 1, 'VIC' );
call play_chgrole_pd( 3, 2, 'CPT' );
-- play_chgactive_pd( _player_id bigint, _team_id bigint, _is_active boolean ) --
call play_chgactive_pd( 1, 2, TRUE );
call play_chgactive_pd( 1, 2, FALSE );
-- play_leaveteam_pd( _player_id bigint, _team_id bigint ) --
call play_leaveteam_pd( 2, 1 );
call play_jointeam_pd( 2, 1 );
SELECT * FROM teams;

-- 8. CREATE Matchmodes --
-- mamo_creation_pd( _match_type char, _is_ranked boolean, _rounds numeric ) --
call mamo_creation_pd( 'SOLO', 'TRUE', 1 );
call mamo_creation_pd( 'SOLO', 'FALSE', 1 );
call mamo_creation_pd( 'TEAM', 'TRUE', 1 );
SELECT * FROM  mamo_chkinfo_fk();

-- 9. CREATE Matches (after third game league of player should change) --
-- mat_creation_pd( _match_mode_id integer, _participant_id_1 bigint, _participant_id_2 bigint, INOUT _match_id bigint ) --
call mat_creation_pd( 1, 1, 2, 1 );
call mat_creation_pd( 1, 1, 3, 2 );
call mat_creation_pd( 1, 1, 2, 3 );
-- mat_chgresult_pd( _match_id bigint, _match_result bigint ) --
call mat_chgresult_pd( 1, 1 );
call mat_chgresult_pd( 2, 1 );
call mat_chgresult_pd( 3, 1 );
SELECT * FROM matches;

-- 10. CREATE Ranking_History Entries --
call rankhist_creation_pd();
call rankhist_creation_pd();
SELECT * FROM  team_rankings;
SELECT * FROM  player_rankings;


