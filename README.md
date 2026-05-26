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
* **Stage 2:** Advanced SQL queries (JOINs, Window Functions, Grouping), Views, and data analysis. *(To be added)*

## Technologies Used
* **Database:** PostgreSQL (Dockerized)
* **Data Processing & ETL:** Python for data processing.
* **Design Tools:** ERDPlus, Google AI Studio

## Quick Start

If you have Docker and Docker Compose installed, use these commands.

1) First-time (start DB + pgAdmin, then run importer):

```bash
docker compose up -d db pgadmin
docker compose --profile import run --rm importer
```

2) Troubleshooting / explicit run (bypass image CMD and show script errors directly):

```bash
docker compose --profile import run --rm -T importer python -u stage_1/Programing/generate_data.py
```

