
-- create database
CREATE DATABASE leaguerankingdb;

-- connect to database
\c leaguerankingdb

-- create tables
\i 0_tables.sql
-- create constraints, indexes and defaults
\i 1_constraints.sql
-- create views, functions, triggers and procedures
\i 2_logic.sql
