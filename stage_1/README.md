# Database Project: World Cup Management System (World Cup DB)

**Submitted by:** 
* Binyamin Eliyahu Forkovich - 330995135
* Eitan Dahan - 330824061

**Selected Unit:** Management of matches, players, and tournament statistics.

---

## Table of Contents
1. [Introduction](#introduction)
2. [System Characterization (AI Studio)](#system-characterization-ai-studio)
3. [ERD and DSD Diagrams](#erd-and-dsd-diagrams)
4. [Design Decisions](#design-decisions)
5. [Data Insertion Methods](#data-insertion-methods)
6. [Backup and Restore](#backup-and-restore)

---

## Introduction
This system is designed to manage the complex data surrounding an international football tournament (such as the World Cup). The database stores information about national teams, stadiums, referees, and players. The core functionality of the system is managing and documenting matches, including specific match events (goals, cards, substitutions) down to the minute, and collecting precise statistics for each player at the end of a match (minutes played, distance covered). The system supports complex data retrieval for analyzing player and team performance throughout the tournament.

---

## System Characterization (AI Studio)
**Link to the AI Studio project:** [Insert your AI Studio link here]

---

## ERD and DSD Diagrams
The Entity-Relationship Diagram (ERD) and Data Structure Diagram (DSD) have been generated and are included in the project files under the main directory.

---

## Design Decisions
During the database design phase, we made several key architectural decisions:
* **Super-type / Sub-type Entities:** We created a central `PERSON` table containing shared attributes (ID, Name, Date of Birth). The `PLAYER` and `REFEREE` tables inherit from it. This normalizes the database, prevents data duplication, and simplifies entity management.
* **Association Tables for Events and Stats:** Instead of storing complex arrays within a match record, we created dedicated tables (`MATCH_EVENT` and `PLAYER_MATCH_STATS`) linked to both the match and the player. This allows us to insert an unlimited number of events and efficiently retrieve statistics using `GROUP BY` aggregations.
* **Cascade Deletion:** We utilized the `CASCADE` constraint in our drop scripts to ensure a safe and efficient teardown of the database environment without encountering foreign key violation errors.

---

## Data Insertion Methods
For this project, we populated the database using 3 distinct methods, fulfilling the requirement of at least 500 records per table and over 20,000 records in two specific tables:

1. **Manual Insertion (INSERT Statements):** A generated SQL script containing 500 explicit `INSERT` statements to populate the `STADIUM` table.
2. **External Tool (Mockaroo):** Generated highly realistic dummy data for the `TEAM` and `PERSON` tables using Mockaroo, exporting the results as ready-to-run SQL scripts.
3. **Programming Method (Python - Critical Mass):** Developed a Python script utilizing the `psycopg2` library. The script connects to the database, reads the base data, and generates referees, players, 550 matches, and over 20,000 match events and player statistics based on defined business logic.

---

## Backup and Restore
We performed a full database backup using two different methods as required:

1. **Graphical User Interface (pgAdmin UI):** A full backup was executed via the pgAdmin interface and successfully restored to a newly created, empty database to verify its integrity.
2. **Command Line Interface (CLI):** A backup was generated using the `pg_dump` utility directly from within the Docker container to the host machine.
