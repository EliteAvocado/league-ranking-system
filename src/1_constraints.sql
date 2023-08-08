--------------------------------------------
-- CONSTRAINTS --
--------------------------------------------



-- Accounts --

ALTER TABLE accounts
	ADD CONSTRAINT acc_user_name_un UNIQUE ( user_name ),
	ADD CONSTRAINT acc_player_id_un UNIQUE ( player_id ),
	ALTER COLUMN date_last_login SET DEFAULT CURRENT_TIMESTAMP,
	ALTER COLUMN del_process_started SET DEFAULT FALSE;

---

-- Players --

ALTER TABLE players
	ADD CONSTRAINT play_account_id_un UNIQUE ( account_id ),
	ADD CONSTRAINT play_player_name_un UNIQUE ( player_name );

---



-- Teams --

ALTER TABLE teams
	ADD CONSTRAINT tea_player_id_chk CHECK (player_id > 0),
	ADD CONSTRAINT tea_team_name_un UNIQUE ( team_name ),
	ALTER COLUMN date_created SET DEFAULT CURRENT_DATE;

---

-- Team_Players --

ALTER TABLE team_players
	ADD CONSTRAINT teamplay_team_id_chk CHECK (team_id > 0),
	ADD CONSTRAINT teamplay_player_id_chk CHECK (player_id > 0);

---

-- Team_Player_Histories --

ALTER TABLE team_player_histories
	ADD CONSTRAINT tphist_team_id_chk CHECK (team_id > 0),
	ADD CONSTRAINT tphist_player_id_chk CHECK (player_id > 0),
	ADD CONSTRAINT tphist_team_role_chk CHECK (team_role IN ('CPT', 'VIC', 'MEM', 'UNK')),
	ALTER COLUMN history_timestamp SET DEFAULT CURRENT_TIMESTAMP,
	ALTER COLUMN team_role SET DEFAULT 'MEM',
	ALTER COLUMN is_active SET DEFAULT FALSE;

---



-- Match_Modes --

ALTER TABLE match_modes
	ADD CONSTRAINT mamo_info_un UNIQUE ( match_type, is_ranked, rounds ),
	ADD CONSTRAINT mamo_match_type_chk CHECK (match_type IN ('SOLO', 'TEAM')),
	ADD CONSTRAINT mamo_rounds_chk CHECK (rounds > 0),
	ALTER COLUMN match_type SET DEFAULT 'SOLO',
	ALTER COLUMN is_ranked SET DEFAULT FALSE,
	ALTER COLUMN rounds SET DEFAULT 1;

---

-- Matches --

ALTER TABLE matches
	ADD CONSTRAINT mat_match_mode_id_chk CHECK (match_mode_id > 0),
	ADD CONSTRAINT mat_match_result_chk CHECK (match_result >= 0),
	ALTER COLUMN match_timestamp SET DEFAULT CURRENT_TIMESTAMP,
	ALTER COLUMN match_result SET DEFAULT NULL;

---

-- Solo_Matches --


ALTER TABLE solo_matches
	ADD CONSTRAINT solomat_player_id_chk CHECK (player_id > 0),
	ADD CONSTRAINT solomat_match_id_chk CHECK (match_id > 0),
	ADD CONSTRAINT solomat_match_mode_id_chk CHECK (match_mode_id > 0);

---

-- Team_Matches --

ALTER TABLE team_matches
	ADD CONSTRAINT teamat_team_id_chk CHECK (team_id > 0),
	ADD CONSTRAINT teamat_match_id_chk CHECK (match_id > 0),
	ADD CONSTRAINT teamat_match_mode_id_chk CHECK (match_mode_id > 0);

---



-- Seasons --

ALTER TABLE seasons
	ADD CONSTRAINT seas_unique_intervalls_exc EXCLUDE USING gist (tsrange(date_begin, date_end) WITH &&),
	ALTER COLUMN is_current SET DEFAULT FALSE;

---

-- Leagues --

ALTER TABLE leagues
	ADD CONSTRAINT leag_cutoff_points_chk CHECK (cutoff_points >= 0),
	ALTER COLUMN league_name SET DEFAULT 'Unranked',
	ALTER COLUMN cutoff_points SET DEFAULT 0;

---

-- League_Seasons --

ALTER TABLE league_seasons
	ADD CONSTRAINT leagseas_season_id_chk CHECK (season_id > 0),
	ADD CONSTRAINT leagseas_league_id_chk CHECK (league_id > 0);

---



-- Player_Rankings --

ALTER TABLE player_rankings
	ADD CONSTRAINT prank_player_id_chk CHECK (player_id > 0),
	ADD CONSTRAINT prank_league_id_chk CHECK (league_id > 0),
	ADD CONSTRAINT prank_ranking_chk CHECK (ranking >= 0),
	ADD CONSTRAINT prank_season_start_state_chk CHECK (season_start_state BETWEEN 0 and 10),
	ALTER COLUMN ranking SET DEFAULT 0,
	ALTER COLUMN season_start_state SET DEFAULT 0;

---

-- Team_Rankings --

ALTER TABLE team_rankings
	ADD CONSTRAINT trank_team_id_chk CHECK (team_id > 0),
	ADD CONSTRAINT trank_league_id_chk CHECK (league_id > 0),
	ADD CONSTRAINT trank_ranking_chk CHECK (ranking >= 0),
	ADD CONSTRAINT trank_season_start_state_chk CHECK (season_start_state BETWEEN 0 and 10),
	ALTER COLUMN ranking SET DEFAULT 0,
	ALTER COLUMN season_start_state SET DEFAULT 0;

---

-- Ranking_Histories --

ALTER TABLE ranking_histories
	ADD CONSTRAINT rankhist_entry_un UNIQUE ( history_timestamp, player_id, team_id ),
	ADD CONSTRAINT rankhist_player_id_chk CHECK (player_id > 0),
	ADD CONSTRAINT rankhist_team_id_chk CHECK (team_id > 0),
	ADD CONSTRAINT rankhist_league_id_chk CHECK (league_id > 0),
	ADD CONSTRAINT rankhist_ranking_chk CHECK (ranking >= 0),
	ADD CONSTRAINT rankhist_season_start_state_chk CHECK (season_start_state BETWEEN 0 and 10),
	ALTER COLUMN history_timestamp SET DEFAULT CURRENT_TIMESTAMP,
	ALTER COLUMN ranking SET DEFAULT 0,
	ALTER COLUMN season_start_state SET DEFAULT 0;

---



--------------------------------------------
-- INDEXES +  PARTIAL INDEXES --
--------------------------------------------


-- by postgres default standard:
-- there is an index for every primary key
-- there is an index for every unique key


-- Accounts --

DROP INDEX IF EXISTS acc_del_login_idx;
CREATE INDEX acc_del_login_idx
	ON accounts (date_last_login, del_process_started);

---

-- Players --

-- none (besides the above) --

---



-- Teams --

DROP INDEX IF EXISTS tea_player_id_idx;
CREATE INDEX tea_player_id_idx
	ON teams (player_id);

---

-- Team_Players --

-- none (besides the above) --

---

-- Team_Player_Histories --

DROP INDEX IF EXISTS tphist_role_active_idx;
CREATE INDEX tphist_role_active_idx
	ON team_player_histories (team_role, is_active);

---



-- Match_Modes --

-- none (besides the above) --

---

-- Matches --

DROP INDEX IF EXISTS mat_match_timestamp_idx;
CREATE INDEX mat_match_timestamp_idx
	ON matches (match_timestamp);

---

-- Solo_Matches --

-- none (besides the above) --

---

-- Team_Matches --

-- none (besides the above) --

---



-- Seasons --

DROP INDEX IF EXISTS seas_timespan_idx;
CREATE INDEX seas_timespan_idx
	ON seasons (date_begin, date_end);

DROP INDEX IF EXISTS seas_current_idx;
CREATE UNIQUE INDEX seas_current_idx
	ON seasons (is_current)
	WHERE is_current IS TRUE;

---

-- Leagues --

DROP INDEX IF EXISTS leag_cutoff_points_idx;
CREATE INDEX leag_cutoff_points_idx
	ON leagues (cutoff_points);

---

-- League_Seasons --

-- none (besides the above) --

---



-- Player_Rankings --

DROP INDEX IF EXISTS prank_league_id_idx;
CREATE INDEX prank_league_id_idx
	ON player_rankings (league_id);

DROP INDEX IF EXISTS prank_ranking_idx;
CREATE INDEX prank_ranking_idx
	ON player_rankings (ranking);

DROP INDEX IF EXISTS prank_season_start_state_idx;
CREATE INDEX prank_season_start_state_idx
	ON player_rankings (season_start_state);

---

-- Team_Rankings --

DROP INDEX IF EXISTS trank_league_id_idx;
CREATE INDEX trank_league_id_idx
	ON team_rankings (league_id);

DROP INDEX IF EXISTS trank_ranking_idx;
CREATE INDEX trank_ranking_idx
	ON team_rankings (ranking);

DROP INDEX IF EXISTS trank_season_start_state_idx;
CREATE INDEX trank_season_start_state_idx
	ON team_rankings (season_start_state);

---

-- Ranking_Histories --

DROP INDEX IF EXISTS rankhist_league_id_idx;
CREATE INDEX rankhist_league_id_idx
	ON ranking_histories (league_id);

DROP INDEX IF EXISTS rankhist_ranking_idx;
CREATE INDEX rankhist_ranking_idx
	ON ranking_histories (ranking);

DROP INDEX IF EXISTS rankhist_season_start_state_idx;
CREATE INDEX rankhist_season_start_state_idx
	ON ranking_histories (season_start_state);

---


