import pandas as pd

def standardize_column_names(df):

    df = df.copy()

    df.columns = (
        df.columns
        .str.strip().str.lower()
        .str.replace(" ", "_").str.replace("-", "_")
    )

    return df


def remove_invalid_rows(data):

    cleaned_data = {}

    for table_name, df in data.items():

        df = df.copy()

        if table_name == "branches":
            df = df[df["branch_id"].notna()]

        cleaned_data[table_name] = df

    return cleaned_data


def transform_data(data):

    transformed_data = {}

    for table_name, df in data.items():

        df = standardize_column_names(df)
        transformed_data[table_name] = df

    transformed_data = remove_invalid_rows(transformed_data)

    return transformed_data