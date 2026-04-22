import psycopg2

import psycopg2.extras

from dotenv import load_dotenv

import os

load_dotenv()

def get_conn():

    return psycopg2.connect(

        host=os.getenv("DB_HOST", "localhost"),

        port=os.getenv("DB_PORT", 5432),

        dbname=os.getenv("DB_NAME", "stock_exchange"),

        user=os.getenv("DB_USER", "nandinee"),

        password=os.getenv("DB_PASSWORD", "")

    )

def query(sql, params=None):

    conn = get_conn()

    cur = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)

    cur.execute(sql, params)

    conn.commit()

    try:

        rows = cur.fetchall()

    except Exception:

        rows = []

    cur.close()

    conn.close()

    return [dict(r) for r in rows]

def execute(sql, params=None):

    conn = get_conn()

    cur = conn.cursor()

    cur.execute(sql, params)

    conn.commit()

    cur.close()

    conn.close()

