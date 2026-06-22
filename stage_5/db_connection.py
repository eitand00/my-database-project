import psycopg2
import os
from pathlib import Path
from dotenv import load_dotenv

dotenv_path = Path(__file__).resolve().parent.parent / ".env"
load_dotenv(dotenv_path)

DB_CONFIG = {
    "host": os.getenv("DB_HOST", "localhost"),
    "port": int(os.getenv("DB_PORT", 5432)),
    "dbname": os.getenv("DB_NAME_SECRET", "world_cup_db"),
    "user": os.getenv("DB_USER_SECRET", "user_db"),
    "password": os.getenv("DB_PASSWORD_SECRET", "password_db"),
}


def get_connection():
    return psycopg2.connect(**DB_CONFIG)


def execute_query(query, params=None, fetch=True):
    conn = get_connection()
    try:
        with conn.cursor() as cur:
            cur.execute(query, params)
            if fetch and cur.description:
                columns = [desc[0] for desc in cur.description]
                rows = cur.fetchall()
                return columns, rows
            conn.commit()
            return None, None
    except Exception as e:
        conn.rollback()
        raise e
    finally:
        conn.close()


def execute_procedure_call(query, params=None):
    conn = get_connection()
    try:
        with conn.cursor() as cur:
            cur.execute(query, params)
            conn.commit()
            if cur.description:
                columns = [desc[0] for desc in cur.description]
                rows = cur.fetchall()
                return columns, rows
            return None, None
    except Exception as e:
        conn.rollback()
        raise e
    finally:
        conn.close()
