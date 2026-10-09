
from extract import load_raw_data
from transform import transform_data
from validate import (
    validate_data,
    print_validation_report,
    has_critical_failures,
)
from load import (
    save_clean_data,
    load_to_mysql,
    check_loaded_counts,
)


def main():

    print("=" * 60)
    print("BANKING CUSTOMER & RISK ANALYTICS PIPELINE")
    print("=" * 60)

    # Step 1: Extract raw data
    print("\nSTEP 1: EXTRACT DATA")

    data = load_raw_data()

    for table_name, df in data.items():
        print(f"{table_name}: {len(df):,} rows x {len(df.columns)} columns")

    print("Data extraction completed.")

    # Step 2: Transform data
    print("\nSTEP 2: TRANSFORM DATA")

    data = transform_data(data)

    print("Data transformation completed.")

    # Step 3: Validate transformed data
    print("\nSTEP 3: VALIDATE DATA")

    validation_report = validate_data(data)
    print_validation_report(validation_report)

    if has_critical_failures(validation_report):
        print("\nPIPELINE STOPPED")
        print("Critical validation failures were found.")
        print("Fix the data issues before loading.")
        return

    print("\nData validation passed critical checks.")

    # Step 4: Save clean CSV files
    print("\nSTEP 4: SAVE CLEAN DATA")

    save_clean_data(data)

    print("Clean data saved successfully.")

    # Step 5: Load into existing MySQL main tables
    print("\nSTEP 5: LOAD DATA INTO MYSQL MAIN TABLES")

    load_to_mysql(data)

    # Step 6: Verify row counts
    print("\nSTEP 6: VERIFY MYSQL DATA")

    check_loaded_counts()

    print("\n" + "=" * 60)
    print("PIPELINE COMPLETED SUCCESSFULLY")
    print("=" * 60)


if __name__ == "__main__":
    try:
        main()
    except Exception as error:
        print(f"\nPIPELINE FAILED: {error}")
        raise
