
from fastapi.testclient import TestClient

from api.app import app

client = TestClient(app)

VALID_LOAN = {
    "loan_type": "Personal",
    "loan_amount": 500000,
    "interest_rate": 0.12,
    "emi": 15000,
    "credit_score": 650,
    "age": 30,
    "annual_income": 600000,
    "occupation": "Salaried",
    "marital_status": "Single",
    "customer_segment": "Mass Market",
}


def test_home_endpoint():
    response = client.get("/")
    assert response.status_code == 200
    assert response.json()["message"] == (
        "Loan Default Prediction API is running"
    )


def test_health_endpoint():
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json()["status"] == "healthy"


def test_model_debug_endpoint():
    response = client.get("/debug/model")
    assert response.status_code == 200

    data = response.json()
    assert data["model_type"] == "Pipeline"
    assert data["classes"] == [0, 1]
    assert data["threshold"] == 0.10
    assert len(data["features"]) == 10


def test_valid_prediction():
    response = client.post("/predict", json=VALID_LOAN)

    assert response.status_code == 200

    data = response.json()
    assert 0 <= data["default_probability"] <= 1
    assert data["threshold"] == 0.10
    assert data["predicted_class"] in ["Default", "No Default"]
    assert "risk_flag" in data
    assert "notice" in data


def test_invalid_credit_score():
    loan = VALID_LOAN.copy()
    loan["credit_score"] = 1000

    response = client.post("/predict", json=loan)

    assert response.status_code == 422


def test_invalid_loan_amount():
    loan = VALID_LOAN.copy()
    loan["loan_amount"] = -500

    response = client.post("/predict", json=loan)

    assert response.status_code == 422


def test_missing_required_field():
    loan = VALID_LOAN.copy()
    del loan["annual_income"]

    response = client.post("/predict", json=loan)

    assert response.status_code == 422



def test_zero_loan_amount():
    loan = VALID_LOAN.copy()
    loan["loan_amount"] = 0

    response = client.post("/predict", json=loan)

    assert response.status_code == 422


def test_underage_applicant():
    loan = VALID_LOAN.copy()
    loan["age"] = 17

    response = client.post("/predict", json=loan)

    assert response.status_code == 422


def test_interest_rate_above_maximum():
    loan = VALID_LOAN.copy()
    loan["interest_rate"] = 1.5

    response = client.post("/predict", json=loan)

    assert response.status_code == 422

