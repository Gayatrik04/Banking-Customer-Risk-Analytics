import pandas as pd


# --------------------------------------------------
# 1. EXPECTED TABLES, COLUMNS AND PRIMARY KEYS
# --------------------------------------------------

EXPECTED_TABLES = {
    "customers",
    "accounts",
    "loans",
    "transactions",
    "branches",
}

PRIMARY_KEYS = {
    "customers": ["customer_id"],
    "accounts": ["account_id"],
    "loans": ["loan_id"],
    "transactions": ["transaction_id"],
    "branches": ["branch_id"],
}

REQUIRED_COLUMNS = {
    "customers": [
        "customer_id",
        "age",
        "annual_income",
        "customer_tenure"
    ],
    "accounts": [
        "account_id",
        "customer_id",
        "branch_id",
        "balance",
        "account_type",
    ],
    "loans": [
        "loan_id",
        "customer_id",
        "loan_amount",
        "remaining_balance",
        "credit_score",
        "emi",
    ],
    "transactions": [
        "transaction_id",
        "customer_id",
        "account_id",
        "amount",
    ],
    "branches": [
        "branch_id",
    ],
}

EXPECTED_NUMERIC_COLUMNS = {
    "customers": ["age", "annual_income"],
    "accounts": ["balance"],
    "loans": [
        "loan_amount",
        "remaining_balance",
        "credit_score",
        "emi",
    ],
    "transactions": ["amount"],
}

RELATIONSHIPS = [
    ("accounts", "customer_id", "customers", "customer_id"),
    ("accounts", "branch_id", "branches", "branch_id"),
    ("loans", "customer_id", "customers", "customer_id"),
    ("transactions", "customer_id", "customers", "customer_id"),
    ("transactions", "account_id", "accounts", "account_id"),
]


# --------------------------------------------------
# 2. VALIDATION FUNCTION
# --------------------------------------------------

def validate_data(data):
    """Validate banking data and return a detailed report."""

    results = []

    def add_result(
        table,
        check,
        issue_count,
        details="None",
        severity="WARNING",
    ):
        issue_count = int(issue_count)

        if issue_count == 0:
            status = "PASS"
        elif severity == "CRITICAL":
            status = "FAIL"
        else:
            status = "CHECK"

        results.append({
            "table": table,
            "check": check,
            "issue_count": issue_count,
            "severity": severity,
            "status": status,
            "details": details or "None",
        })

    # --------------------------------------------------
    # 3. REQUIRED TABLE CHECK
    # --------------------------------------------------

    missing_tables = EXPECTED_TABLES - set(data.keys())

    for table_name in sorted(missing_tables):
        add_result(
            table_name,
            "Required table exists",
            1,
            "Table was not extracted or supplied to validation",
            "CRITICAL",
        )

    # Validate only tables that were supplied.
    for table_name, df in data.items():

        if not isinstance(df, pd.DataFrame):
            add_result(
                table_name,
                "DataFrame type",
                1,
                "Input must be a pandas DataFrame",
                "CRITICAL",
            )
            continue

        add_result(
            table_name,
            "Table dimensions",
            0,
            f"{len(df):,} rows x {len(df.columns)} columns",
            "INFO",
        )

        # ----------------------------------------------
        # 4. REQUIRED COLUMN CHECK
        # ----------------------------------------------

        required_columns = REQUIRED_COLUMNS.get(table_name, [])

        for column in required_columns:
            if column not in df.columns:
                add_result(
                    table_name,
                    f"Required column: {column}",
                    1,
                    f"Required column '{column}' is missing",
                    "CRITICAL",
                )

        # Skip checks that require unavailable columns.
        # Continue checking all other available columns.

        # ----------------------------------------------
        # 5. MISSING VALUE CHECK
        # ----------------------------------------------

        missing = df.isna().sum()
        missing = missing[missing > 0]

        missing_count = int(missing.sum())

        missing_details = ", ".join(
            f"{column}: {count}"
            for column, count in missing.items()
        ) or "No missing values"

        add_result(
            table_name,
            "Missing values",
            missing_count,
            missing_details,
            "WARNING",
        )

        # ----------------------------------------------
        # 6. DUPLICATE ROW CHECK
        # ----------------------------------------------

        duplicate_rows = int(df.duplicated().sum())

        add_result(
            table_name,
            "Duplicate rows",
            duplicate_rows,
            "Rows identical across all columns",
            "WARNING",
        )

        # ----------------------------------------------
        # 7. PRIMARY KEY CHECKS
        # ----------------------------------------------

        for key in PRIMARY_KEYS.get(table_name, []):

            if key not in df.columns:
                # Already reported by the required-column check.
                continue

            null_keys = int(df[key].isna().sum())

            duplicate_keys = int(
                df.loc[df[key].notna(), key].duplicated().sum()
            )

            add_result(
                table_name,
                f"Null primary keys: {key}",
                null_keys,
                f"Column: {key}",
                "CRITICAL",
            )

            add_result(
                table_name,
                f"Duplicate primary keys: {key}",
                duplicate_keys,
                f"Column: {key}",
                "CRITICAL",
            )

        # ----------------------------------------------
        # 8. NUMERIC TYPE AND VALUE CHECKS
        # ----------------------------------------------

        for column in EXPECTED_NUMERIC_COLUMNS.get(table_name, []):

            if column not in df.columns:
                # Already reported by the required-column check.
                continue

            converted = pd.to_numeric(
                df[column],
                errors="coerce",
            )

            invalid_mask = df[column].notna() & converted.isna()

            invalid_count = int(invalid_mask.sum())

            add_result(
                table_name,
                f"Numeric values: {column}",
                invalid_count,
                "Non-null values that cannot be converted to numbers",
                "CRITICAL",
            )

            # Infinity is numeric but generally invalid for banking data.
            infinite_mask = converted.isin([float("inf"), float("-inf")])
            infinite_count = int(infinite_mask.sum())

            add_result(
                table_name,
                f"Finite numeric values: {column}",
                infinite_count,
                "Infinite values require investigation",
                "CRITICAL",
            )

    # --------------------------------------------------
    # 9. FOREIGN KEY / RELATIONSHIP CHECKS
    # --------------------------------------------------

    for child_table, child_key, parent_table, parent_key in RELATIONSHIPS:

        if child_table not in data or parent_table not in data:
            # Missing tables were already reported above.
            continue

        child = data[child_table]
        parent = data[parent_table]

        if (
            not isinstance(child, pd.DataFrame)
            or not isinstance(parent, pd.DataFrame)
        ):
            continue

        if child_key not in child.columns or parent_key not in parent.columns:
            # Missing columns were already reported above.
            continue

        child_values = child.loc[
            child[child_key].notna(),
            child_key,
        ]

        parent_values = parent[parent_key].dropna()

        orphan_mask = ~child_values.isin(parent_values)
        orphan_count = int(orphan_mask.sum())

        add_result(
            child_table,
            f"Foreign key: {child_key} -> {parent_table}.{parent_key}",
            orphan_count,
            "Non-null references without a matching parent record",
            "CRITICAL",
        )

    # --------------------------------------------------
    # 10. BUSINESS RULE CHECKS
    # --------------------------------------------------

    if "accounts" in data and isinstance(data["accounts"], pd.DataFrame):

        accounts = data["accounts"]

        if {"balance", "account_type"}.issubset(accounts.columns):

            balance = pd.to_numeric(
                accounts["balance"],
                errors="coerce",
            )

            account_type = (
                accounts["account_type"]
                .astype("string")
                .str.strip()
                .str.lower()
            )

            invalid_balance = (
                balance.lt(0)
                & account_type.isin(["savings", "checking"])
            ).fillna(False)

            invalid_count = int(invalid_balance.sum())

            add_result(
                "accounts",
                "Negative Savings/Checking balances",
                invalid_count,
                "Review against business rules; rows are not deleted",
                "WARNING",
            )

    # --------------------------------------------------
    # 11. FINAL REPORT
    # --------------------------------------------------

    return pd.DataFrame(results)


# --------------------------------------------------
# 12. PRINT VALIDATION REPORT
# --------------------------------------------------

def print_validation_report(report):
    """Display validation results and summary counts."""

    print("\nBANKING DATA QUALITY REPORT")
    print("=" * 110)

    if report.empty:
        print("No validation results were generated.")
        return

    print(report.to_string(index=False))
    print("=" * 110)

    print("\nSUMMARY")

    for status in ["PASS", "CHECK", "FAIL"]:
        count = int((report["status"] == status).sum())
        print(f"{status}: {count}")

    critical_failures = report[
        (report["status"] == "FAIL")
        & (report["severity"] == "CRITICAL")
    ]

    if not critical_failures.empty:
        print("\nCRITICAL ISSUES FOUND. Do not load the data.")
    elif (report["status"] == "CHECK").any():
        print("\nWARNINGS FOUND. Review them before approving the data.")
    else:
        print("\nNo reported validation issues.")


# --------------------------------------------------
# 13. PIPELINE STATUS HELPER
# --------------------------------------------------

def has_critical_failures(report):
    """Return True if the report contains a critical failure."""

    if report.empty:
        return True

    return bool(
        (
            (report["severity"] == "CRITICAL")
            & (report["status"] == "FAIL")
        ).any()
    )


if __name__ == "__main__":
    print(
        "Validation module ready. "
    )
