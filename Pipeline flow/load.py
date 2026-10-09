import os
from pathlib import Path

import pandas as pd
from sqlalchemy import create_engine
from sqlalchemy.engine import URL
from sqlalchemy import inspect


# --------------------------------------------------
# 1. PROJECT PATHS
# --------------------------------------------------

PROJECT_ROOT = Path(__file__).resolve().parent.parent
CLEAN_DATA_PATH = PROJECT_ROOT / "data" / "clean"

TABLE_NAMES = [
    "customers",
    "accounts",
    "loans",
    "transactions",
    "branches",
]

# Parent tables must be loaded before child tables
LOAD_ORDER = [
    "customers",
    "branches",
    "accounts",
    "loans",
    "transactions",
]


# --------------------------------------------------
# 2. MYSQL CONNECTION
# --------------------------------------------------

def get_engine():
    """Create a MySQL connection using environment variables."""

    username = os.getenv("BANKING_DB_USER", "root")
    password = os.getenv("BANKING_DB_PASSWORD")
    host = os.getenv("BANKING_DB_HOST", "localhost")
    port = int(os.getenv("BANKING_DB_PORT", "3306"))
    database = "banking_customer_risk_analytics"

    if not password:
        raise ValueError(
            "Set the BANKING_DB_PASSWORD environment variable first."
        )

    connection_url = URL.create(
        drivername="mysql+pymysql",
        username=username,
        password=password,
        host=host,
        port=port,
        database=database,
    )

    return create_engine(
        connection_url,
        pool_pre_ping=True,
    )


# --------------------------------------------------
# 3. SAVE CLEAN CSV FILES
# --------------------------------------------------

def save_clean_data(data):
    """Save approved DataFrames as CSV files."""

    CLEAN_DATA_PATH.mkdir(parents=True, exist_ok=True)

    for table_name in TABLE_NAMES:
        if table_name not in data:
            raise ValueError(
                f"Required table '{table_name}' is missing."
            )

        file_path = CLEAN_DATA_PATH / f"{table_name}_clean.csv"

        data[table_name].to_csv(
            file_path,
            index=False,
            encoding="utf-8",
        )

        print(
            f"Saved {table_name}: "
            f"{len(data[table_name]):,} rows -> {file_path.name}"
        )


# --------------------------------------------------
# 4. LOAD DATA INTO EXISTING MYSQL TABLES
# --------------------------------------------------

def load_to_mysql(data, chunksize=5_000):
    """
    Insert data into existing main tables.
    Never replace or recreate the tables.
    """

    missing_tables = set(TABLE_NAMES) - set(data.keys())

    if missing_tables:
        raise ValueError(
            f"Missing tables for MySQL loading: {sorted(missing_tables)}"
        )

    engine = get_engine()

    try:
        inspector = inspect(engine)
        existing_tables = set(inspector.get_table_names())

        missing_db_tables = set(TABLE_NAMES) - existing_tables

        if missing_db_tables:
            raise ValueError(
                "These main tables do not exist in MySQL: "
                f"{sorted(missing_db_tables)}. "
                "Create the schema before loading."
            )

        # Validate table columns before inserting anything.
        for table_name in LOAD_ORDER:
            db_columns = {
                column["name"]
                for column in inspector.get_columns(table_name)
            }
            data_columns = set(data[table_name].columns)

            if data_columns != db_columns:
                raise ValueError(
                    f"Column mismatch for '{table_name}'. "
                    f"Missing from data: {sorted(db_columns - data_columns)}. "
                    f"Extra in data: {sorted(data_columns - db_columns)}."
                )

        # Prevent accidental duplicate inserts into populated tables.
        with engine.connect() as connection:
            populated_tables = []

            for table_name in LOAD_ORDER:
                row_count = connection.exec_driver_sql(
                    f"SELECT COUNT(*) FROM `{table_name}`"
                ).scalar_one()

                if row_count > 0:
                    populated_tables.append(
                        f"{table_name} ({row_count:,} rows)"
                    )

            if populated_tables:
                raise ValueError(
                    "Main tables already contain data. "
                    "To prevent duplicate inserts, loading was stopped. "
                    "Existing data: "
                    + ", ".join(populated_tables)
                )

        # Insert into existing tables, preserving their schema and indexes.
        with engine.begin() as connection:
            for table_name in LOAD_ORDER:
                df = data[table_name]

                df.to_sql(
                    name=table_name,
                    con=connection,
                    if_exists="append",
                    index=False,
                    chunksize=chunksize,
                    method="multi",
                )

                print(
                    f"Loaded {table_name}: "
                    f"{len(df):,} rows -> existing table"
                )

        print("\nAll data inserted into the existing main tables.")

    finally:
        engine.dispose()


# --------------------------------------------------
# 5. VERIFY MAIN TABLE ROW COUNTS
# --------------------------------------------------

def check_loaded_counts():
    """Display row counts from the existing main tables."""

    engine = get_engine()
    results = []

    try:
        inspector = inspect(engine)
        existing_tables = set(inspector.get_table_names())

        with engine.connect() as connection:
            for table_name in TABLE_NAMES:
                if table_name not in existing_tables:
                    results.append({
                        "table": table_name,
                        "mysql_rows": None,
                        "status": "TABLE MISSING",
                    })
                    continue

                count = connection.exec_driver_sql(
                    f"SELECT COUNT(*) FROM `{table_name}`"
                ).scalar_one()

                results.append({
                    "table": table_name,
                    "mysql_rows": int(count),
                    "status": "OK",
                })

    finally:
        engine.dispose()

    report = pd.DataFrame(results)
    print("\nMYSQL MAIN TABLE ROW COUNTS")
    print(report.to_string(index=False))

    return report


# --------------------------------------------------
# 6. CHECK WHETHER MAIN DATA EXISTS
# --------------------------------------------------

def data_already_loaded():
    """Check whether the main customers table contains data."""

    engine = get_engine()

    try:
        inspector = inspect(engine)

        if "customers" not in inspector.get_table_names():
            return False

        with engine.connect() as connection:
            count = connection.exec_driver_sql(
                "SELECT COUNT(*) FROM customers"
            ).scalar_one()

        return count > 0

    finally:
        engine.dispose()


if __name__ == "__main__":
    print("Loading module ready.")
    print(f"Clean data folder: {CLEAN_DATA_PATH}")
    print("Run run_pipeline.py to execute the complete pipeline.")
