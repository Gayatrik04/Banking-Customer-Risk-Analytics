from sqlalchemy import create_engine, text
from urllib.parse import quote_plus


def get_engine():

    username = "root"
    password = "Gayatri@1311"
    host = "localhost"
    database = "banking_customer_risk_analytics"

    encoded_password = quote_plus(password)

    connection_string = (
        f"mysql+pymysql://{username}:{encoded_password}@{host}/{database}"
    )

    return create_engine(connection_string)


def data_already_loaded():

    engine = get_engine()

    with engine.connect() as connection:

        result = connection.execute(
            text("SELECT COUNT(*) FROM customers")
        )

        customer_count = result.scalar()

    engine.dispose()

    return customer_count > 0
