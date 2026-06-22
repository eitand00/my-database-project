# Phase E - World Cup GUI Application

The Graphical User Interface for the World Cup Database has been built using **Python** and **Streamlit**. 
To align with the project's architecture, the application is fully containerized and runs as a Docker service.

## Running the Application

Since the GUI is integrated into the main `docker-compose.yml`, you do not need to install Python or any libraries on your host machine.

1. Ensure Docker is running.
2. Open a terminal in the root directory of the repository (where the main `docker-compose.yml` is located).
3. Run the following command to build and start the GUI along with the database:

```bash
docker compose up -d db pgadmin gui
```

4. Once the containers are up, open your web browser and navigate to:
   **http://localhost:8501**

## Features Included

* **Interactive Dashboard:** Easy navigation through a sidebar menu.
* **CRUD Screens:** View, Add, Update, and Delete records for `TEAM`, `PLAYER`, and `STADIUM`. The tables use SQL `JOIN`s to display readable names instead of foreign key IDs. Form updates automatically populate with existing data.
* **Stage B Queries:** Run advanced queries directly from the interface and view the results in formatted tables.
* **Stage D Betting System:** Interact with the `create_bet` PL/pgSQL procedure to place bets, and the `Calculate_Potential_Payout` function to view possible winnings.

> **Note:** The `images` folder in this directory is reserved for screenshots of the running application. Please remember to capture some screenshots and place them there before final submission.
