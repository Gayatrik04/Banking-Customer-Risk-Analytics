
from pathlib import Path
import json
import joblib
import pandas as pd
from fastapi import FastAPI
from pydantic import BaseModel, Field

# Locate saved model files
PROJECT_ROOT = Path(__file__).resolve().parent.parent

# If your notebook is running from the project root
ARTIFACTS_DIR = PROJECT_ROOT / "artifacts"

# print("Project root:", PROJECT_ROOT)
# print("Artifacts folder:", ARTIFACTS_DIR)
# print("Model exists:", (ARTIFACTS_DIR / "loan_default_model.joblib").exists())
# print("Metadata exists:", (ARTIFACTS_DIR / "model_metadata.json").exists())

MODEL_PATH = ARTIFACTS_DIR / "loan_default_model.joblib"
METADATA_PATH = ARTIFACTS_DIR / "model_metadata.json"

if not MODEL_PATH.exists():
    raise FileNotFoundError(f"Model not found: {MODEL_PATH}")

if not METADATA_PATH.exists():
    raise FileNotFoundError(f"Metadata not found: {METADATA_PATH}")


# Load model and metadata once when the API starts
model = joblib.load(MODEL_PATH)

with open(METADATA_PATH, "r") as file:
    metadata = json.load(file)

THRESHOLD = metadata["threshold"]
FEATURES = metadata["features"]

# print("Model loaded successfully!")
# print("Model type:", type(model).__name__)
# print("Threshold:", THRESHOLD)
# print("Features:", FEATURES)

app = FastAPI(
    title="Loan Default Prediction API",
    description="Predicts loan default risk using a trained ML pipeline.",
    version="1.0.0"
)


class LoanApplication(BaseModel):
    loan_type: str
    loan_amount: float = Field(gt=0)
    interest_rate: float = Field(ge=0, le=1)
    emi: float = Field(gt=0)
    credit_score: int = Field(ge=300, le=900)
    age: int = Field(ge=18, le=100)
    annual_income: float = Field(gt=0)
    occupation: str
    marital_status: str
    customer_segment: str


@app.get("/")
def home():
    return {
        "message": "Loan Default Prediction API is running",
        "model": metadata["model_name"]
    }


@app.get("/health")
def health():
    return {"status": "healthy"}


@app.post("/predict")
def predict(application: LoanApplication):
    # Convert request into the exact feature order expected by the model
    input_data = pd.DataFrame(
        [application.model_dump()]
    )[FEATURES]

    probabilities = model.predict_proba(input_data)[0]
    class_indices = list(model.classes_)

    if 1 not in class_indices:
        raise ValueError("Model does not contain the default class (1).")

    default_probability = float(
        probabilities[class_indices.index(1)]
    )

    predicted_default = default_probability >= THRESHOLD

    return {
        "default_probability": round(default_probability, 4),
        "threshold": THRESHOLD,
        "predicted_class": (
            "Default" if predicted_default else "No Default"
        ),
        "risk_flag": (
            "Review recommended" if predicted_default
            else "No default alert from model"
        ),
        "notice": (
            "Demonstration prediction only; not a lending decision."
        )
    }



@app.get("/debug/model")
def debug_model():
    return {
        "model_type": type(model).__name__,
        "features": FEATURES,
        "threshold": THRESHOLD,
        "classes": model.classes_.tolist()
    }