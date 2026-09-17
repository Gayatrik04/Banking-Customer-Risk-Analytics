from extract import load_raw_data
from validate import validate_data, print_validation_report
from transform import transform_data
from load import load_to_mysql, data_already_loaded


def main():

    print("Starting Banking Customer & Risk Analytics Pipeline...\n")

    # Check whether data is already loaded into MySQL
    if data_already_loaded():

        print("✓ Data already exists in MySQL")
        print("✓ Skipping Excel extraction")
        print("✓ Skipping validation")
        print("✓ Skipping transformation")
        print("✓ Skipping data loading")

        print("\nPipeline completed using existing MySQL data.")

        return

    # Step 1: Extract
    data = load_raw_data()
    print("✓ Data extraction completed")

    # Step 2: Validate
    validation_report = validate_data(data)
    print("✓ Data validation completed")

    print_validation_report(validation_report)

    # Step 3: Transform
    data = transform_data(data)
    print("\n✓ Data transformation completed")

    # Step 4: Load
    load_to_mysql(data)


if __name__ == "__main__":
    main()