# Database Project: World Cup Management System (World Cup DB)

**Submitted by:** 
* Binyamin Eliyahu Forkovich - 330995135
* [Partner's Name, if applicable] - [Partner's ID]

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

**System Screens:**
![Screen 1](images/screen1_image.png)
*(Add more UI mockup images here as needed)*

---

## ERD and DSD Diagrams
**Entity-Relationship Diagram (ERD):**
![ERD Diagram](images/erd_image.png)

**Data Structure Diagram (DSD):**
![DSD Diagram](images/dsd_image.png)

---

## Design Decisions
During the database design phase, we made several key architectural decisions:
* **Super-type / Sub-type Entities:** We created a central `PERSON` table containing shared attributes (ID, Name, Date of Birth). The `PLAYER` and `REFEREE` tables inherit from it. This normalizes the database, prevents data duplication, and simplifies entity management.
* **Association Tables for Events and Stats:** Instead of storing complex arrays within a match record, we created dedicated tables (`MATCH_EVENT` and `PLAYER_MATCH_STATS`) linked to both the match and the player. This allows us to insert an unlimited number of events and efficiently retrieve statistics using `GROUP BY` aggregations.
* **Cascade Deletion:** We utilized the `CASCADE` constraint in our drop scripts to ensure a safe and efficient teardown of the database environment without encountering foreign key violation errors.

---

## Data Insertion Methods
For this project, we populated the database using 3 distinct methods, fulfilling the requirement of at least 500 records per table and over 20,000 records in two specific tables:

### 1. Manual Insertion (INSERT Statements)
A generated SQL script containing 500 explicit `INSERT` statements to populate the `STADIUM` table.
![Manual Insert](images/manual_insert_screenshot.png)

### 2. External Tool (Mockaroo)
Generated highly realistic dummy data for the `TEAM` and `PERSON` tables using Mockaroo, exporting the results as ready-to-run SQL scripts.
![Mockaroo Generation](images/mockaroo_screenshot.png)

### 3. Programming Method (Python - Critical Mass)
Developed a Python script utilizing the `psycopg2` library. The script connects to the database, reads the base data, and generates referees, players, 550 matches, and over 20,000 match events and player statistics based on defined business logic.
![Python Script Success](images/python_success_screenshot.png)

---

## Backup and Restore
We performed a full database backup using two different methods as required:

### Method 1: Graphical User Interface (pgAdmin UI)
A full backup was executed via the pgAdmin interface and successfully restored to a newly created, empty database (`test_restore_db`) to verify its integrity.
**Screenshot - Executing the Backup:**
![UI Backup](images/ui_backup_screenshot.png)
**Screenshot - Executing the Restore:**
![UI Restore](images/ui_restore_screenshot.png)

### Method 2: Command Line Interface (CLI)
A backup was generated using the `pg_dump` utility directly from within the Docker container to the host machine.
**Screenshot - Running the Backup Command:**
![CLI Backup](images/cli_backup_screenshot.png)