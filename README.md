# World Cup Statistics Database Project

## Overview
This project is a comprehensive database system focused on **analyzing statistics and historical data** from FIFA World Cup tournaments. Instead of generating artificial data, the database is populated entirely by processing and adapting a **real historical dataset** to fit our normalized database schema. This provides an authentic and robust foundation for running advanced SQL queries, aggregations, and performance analytics.

## Key Features
* **Historical Data Analysis:** Built upon authentic datasets covering past World Cup matches, teams, and stadiums.
* **Data Transformation (ETL):** Python and SQL were utilized to process, clean, and map the raw external dataset into our specific relational tables.
* **Comprehensive Tracking:** Stores detailed match events (goals, fouls, cards, substitutions) and post-match statistics for individual players.
* **Robust Architecture:** Built on PostgreSQL using Docker, featuring a normalized schema with inherited entities (Super-type/Sub-type).

## Project Structure
* **Stage 1:** Database initialization, system characterization (AI Studio), ERD/DSD design, massive data insertion (3 methods), and backup/restore procedures.
* **Stage 2:** Advanced SQL queries (JOINs, Window Functions, Grouping), Views, and data analysis.
* **Stage 3:** System integration with betting database, reverse engineering, super-type mapping, data migration, and views.
* **Stage 4:** PL/pgSQL programming - functions, procedures, triggers, cursors, and main programs.
* **Stage 5:** Web-based graphical interface (Flask + Bootstrap 5) for database management: CRUD operations, query execution, and procedure/function execution.

## Technologies Used
* **Database:** PostgreSQL (Dockerized)
* **Data Processing & ETL:** Python for data processing.
* **Design Tools:** ERDPlus, Google AI Studio

## Quick Start
Required configuration:

- `DB_USER_SECRET` - PostgreSQL username used by the database container
- `DB_PASSWORD_SECRET` - PostgreSQL password used by the database container
- `DB_NAME_SECRET` - PostgreSQL database name
- `PGADMIN_EMAIL` - login email for pgAdmin
- `PGADMIN_PASSWORD` - login password for pgAdmin

You can copy `.env.example` to `.env` and edit the values before running Docker Compose.

build importer image:
docker compose build importer

1) First-time (start DB + pgAdmin, then run importer):

```bash
docker compose up -d db pgadmin
docker compose --profile import run --rm importer
```

2) If the schema file changed, recreate the DB schema using the mounted file:

```bash
docker compose exec db sh -lc 'psql -U user_db -d world_cup_db -f /stage_1/createTables.sql'
```

3) Troubleshooting / explicit run (bypass image CMD and show script errors directly):

```bash
docker compose --profile import run --rm -T importer python -u stage_1/Programing/generate_data.py
```

Notes:
- The database container only mounts `./stage_1` at `/stage_1`, which is the path used in the schema command above.
- The importer mounts `./stage_1` and `./dataset` so it can read the ETL script and CSV files from the host.

