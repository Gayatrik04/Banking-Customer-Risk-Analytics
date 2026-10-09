import pandas as pd


def standardize_column_names(df):
    """Standardize column names for consistent processing."""

    df = df.copy()

    df.columns = (
        df.columns.astype(str)
        .str.strip()
        .str.lower()
        .str.replace(r"[\s-]+", "_", regex=True)
        .str.replace(r"[^a-z0-9_]", "", regex=True)
        .str.replace(r"_+", "_", regex=True)
        .str.strip("_")
    )

    return df


def standardize_data_types(data):
    """Normalize common text and date formats without guessing
    the meaning of numeric columns."""

    transformed_data = {}

    for table_name, df in data.items():
        df = df.copy()

        # Remove leading/trailing spaces from text values.
        for column in df.select_dtypes(include=["object", "string"]).columns:
            df[column] = df[column].map(
                lambda value: value.strip()
                if isinstance(value, str)
                else value
            )

        # Normalize date columns only when their names indicate dates.
        for column in df.columns:
            if "date" in column or column.endswith("_at"):
                df[column] = pd.to_datetime(
                    df[column],
                    errors="coerce"
                )

        transformed_data[table_name] = df

    return transformed_data


def transform_data(data):
    """Standardize tables and calculate customer tenure."""

    transformed_data = {}

    for table_name, df in data.items():
        transformed_data[table_name] = standardize_column_names(df)

    transformed_data = standardize_data_types(transformed_data)

    customers = transformed_data["customers"]

    if "customer_since" in customers.columns:
        customer_since = pd.to_datetime(
            customers["customer_since"],
            errors="coerce"
        )

        today = pd.Timestamp.today().normalize()

        transformed_data["customers"]["customer_tenure"] = (
            today.year
            - customer_since.dt.year
            - (
                (
                    customer_since.dt.month > today.month
                )
                | (
                    (customer_since.dt.month == today.month)
                    & (customer_since.dt.day > today.day)
                )
            ).astype("Int64")
        ).where(customer_since.notna()).astype("Int64")

    return transformed_data


if __name__ == "__main__":
    print(
        "This module defines transformation functions. "
    )
