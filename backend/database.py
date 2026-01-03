# backend/database.py
# postgres db connection

import os # pristup k env vars
import psycopg2 # postresql driver
from psycopg2.extras import RealDictCursor # vraci dict namiesto tuple


def get_db_connection():
    database_url = os.getenv("DATABASE_URL") # z docker-compose env

    if not database_url:
        raise ValueError("DATABASE_URL environment variable is not set")
        # app okamzite zastane s jasnym errorom

    conn = psycopg2.connect(database_url, cursor_factory = RealDictCursor) # dict output

    return conn

def test_db_connection():
    try:
        conn = get_db_connection()
        cur = conn.cursor() # kurzor pre dopyty

        cur.execute("SELECT 1") # minimal test
        cur.fetchone() # python dostane data(riadok) od DB

        cur.close()
        conn.close()

        print("Database connection successful")
        return True

    except Exception as e:
        print(f"Database connection failed: {e}")
        return False
