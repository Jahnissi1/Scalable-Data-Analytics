import os                              # read environment variables (.env)
from decimal import Decimal             # handle Decimal -> float conversion
from dotenv import load_dotenv          # load .env file
import psycopg2                         # PostgreSQL connector
from psycopg2.extras import RealDictCursor  # rows as dictionaries
from pymongo import MongoClient         # MongoDB driver
# pyright: ignore[reportMissingImports]
load_dotenv()                           # load environment variables from .env

# ---------- Read DB settings with safe defaults ----------
PGHOST = os.getenv("PGHOST", "localhost")     # Postgres host
PGPORT = int(os.getenv("PGPORT", "5432"))     # Postgres port
PGDB   = os.getenv("PGDB", "Assignment_2")      # Postgres database name
PGUSER = os.getenv("PGUSER", "postgres")      # Postgres user
PGPASS = os.getenv("PGPASSWORD", "Your Password here")          # Postgres password
MONGO_URI = os.getenv("MONGODB_URI", "mongodb://localhost:27017")  # Mongo connection string

print(f"[ETL] Connecting to PostgreSQL {PGDB} at {PGHOST}:{PGPORT} ...")
pg = psycopg2.connect(host=PGHOST, port=PGPORT, dbname=PGDB, user=PGUSER, password=PGPASS)  # open PG conn

# ---------- Fetch the as-of rows ----------
sql = "SELECT * FROM orders_asof;"      # single view contains all final fields we need
with pg.cursor(cursor_factory=RealDictCursor) as cur:  # dict rows (column -> value)
    cur.execute(sql)                           # run query
    rows = list(cur.fetchall())                # pull all results into a Python list
print(f"[ETL] Fetched {len(rows)} rows from PostgreSQL.")

# ---------- Convert Decimal to float (Mongo-friendly) ----------
def cast_decimal(record: dict) -> dict:
    out = {}
    for k, v in record.items():
        out[k] = float(v) if isinstance(v, Decimal) else v  # Mongo stores numbers as float/int
    return out

# ---------- Connect to MongoDB & collection ----------
mongo = MongoClient(MONGO_URI)                 # open Mongo connection
coll = mongo["Assignment_2_db"]["orders_summary"]   # choose DB + collection
coll.create_index("order_id", unique=True)        # Create collection. avoid duplicates across runs (idempotent)

# ---------- Upsert each appointment document ----------
upserts = 0
for row in rows:
    doc = cast_decimal(row)                    # ensure all numerics are JSON-safe
    coll.update_one(
        {"order_id": doc["order_id"]},   # match by appointment_id
        {"$set": doc},                               # set/replace fields
        upsert=True                                  # insert if not found
    )
    upserts += 1

print(f"[ETL] Upsert complete. Documents upserted: {upserts}.")  # summary log
print("[ETL] Done.")                                             # finished