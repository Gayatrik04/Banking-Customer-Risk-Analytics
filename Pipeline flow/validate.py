import pandas as pd


def validate_data(data):

    validation_results = []

    for table_name, df in data.items():

        rows = len(df)
        columns = len(df.columns)

        duplicate_rows = df.duplicated().sum()
        missing_values = df.isnull().sum().sum()

        # Find columns containing missing values
        missing_columns = []

        for column in df.columns:
            missing_count = df[column].isnull().sum()

            if missing_count > 0:
                missing_columns.append(
                    f"{column}: {missing_count}"
                )

        missing_details = ", ".join(missing_columns) if missing_columns else "None"

        status = "PASS"

        if duplicate_rows > 0 or missing_values > 0:
            status = "CHECK"

        validation_results.append({
            "table": table_name,
            "rows": rows,
            "columns": columns,
            "duplicate_rows": duplicate_rows,
            "missing_values": missing_values,
            "missing_details": missing_details,
            "status": status
        })

    return pd.DataFrame(validation_results)


def print_validation_report(report):

    print("\nDATA QUALITY REPORT")
    print("=" * 100)
    print(report.to_string(index=False))
    print("=" * 100)


if __name__ == "__main__":
    print("Validation module ready.")
    
