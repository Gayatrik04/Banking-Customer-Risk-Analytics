import pandas as pd
from pathlib import Path


# Project root
PROJECT_ROOT = Path(__file__).resolve().parent.parent

# Raw data folder
RAW_DATA_PATH = PROJECT_ROOT / "data" / "raw"


def load_raw_data():

    customers = pd.read_excel(RAW_DATA_PATH / "Customers.xlsx")
    accounts = pd.read_excel(RAW_DATA_PATH / "Banking_Account.xlsx")
    loans = pd.read_excel(RAW_DATA_PATH / "Loan_Data.xlsx")
    transactions = pd.read_excel(RAW_DATA_PATH / "transaction_data.xlsx")
    branches = pd.read_excel(RAW_DATA_PATH / "Branch.xlsx")

    return {
        "customers": customers,
        "accounts": accounts,
        "loans": loans,
        "transactions": transactions,
        "branches": branches
    }


if __name__ == "__main__":

    data = load_raw_data()

    print("Data extraction completed.\n")

    for table_name, df in data.items():
        print(
            f"{table_name}: "
            f"{len(df):,} rows × {len(df.columns)} columns"
        )