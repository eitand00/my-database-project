#!/bin/bash
set -e

echo "======================================================"
echo "  WORLD CUP DATABASE - FULL SETUP"
echo "======================================================"

# Wait for database to be ready
echo "[1/5] Waiting for database..."
until PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -U $DB_USER -d $DB_NAME -c "SELECT 1" > /dev/null 2>&1; do
  sleep 2
done
echo "  Database is ready."

PSQL="psql -h $DB_HOST -U $DB_USER -d $DB_NAME -v ON_ERROR_STOP=1"

# Step 1: World Cup tables only
echo "[2/5] Creating World Cup tables..."
PGPASSWORD=$DB_PASSWORD $PSQL -f /app/stage_5/sql/full_install.sql
echo "  Tables created."

# Step 2: World Cup data
echo "[3/5] Importing World Cup data..."
python -u /app/stage_1/Programing/generate_data.py
echo "  World Cup data imported."

# Step 3: Betting tables + data (backup2.sql creates its own 6 tables)
echo "[4/5] Importing betting data..."
PGPASSWORD=$DB_PASSWORD $PSQL -f /app/stage_3/backup2.sql
PGPASSWORD=$DB_PASSWORD $PSQL -f /app/stage_3/Integrate.sql
echo "  Betting data imported + integrated."

# Step 4: Everything else — constraints, views, functions, procedures, triggers
echo "[5/5] Installing DB objects (constraints, views, functions, procedures, triggers)..."
PGPASSWORD=$DB_PASSWORD $PSQL -f /app/stage_5/setup/install_objects.sql
echo "  All DB objects installed."

echo ""
echo "======================================================"
echo "  DATABASE SETUP COMPLETE!"
echo "  You can now run the web app."
echo "======================================================"
