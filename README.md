# 🏦 Banking Customer & Risk Analytics

An end-to-end data analytics project that combines Python, MySQL, Power BI, machine learning, and FastAPI to analyze banking customers, loan portfolios, transactions, and credit risk.

## Project Overview
This project analyzes banking data to understand customer behavior, loan distribution, repayment risk, transaction patterns, and branch performance. It includes data processing, SQL-based analysis, interactive dashboards, machine learning models for loan default prediction, and an API for demonstrating model predictions.

## Project Objectives
- Analyze customer demographics and account distribution.
- Evaluate loan portfolios and identify patterns associated with loan defaults.
- Analyze transaction channels and customer activity.
- Compare business performance across branches.
- Build machine learning models to estimate loan default risk.
- Present key metrics through interactive Power BI dashboards.
- Expose a demonstration prediction endpoint using FastAPI.

## Tech Stack

- Python — data cleaning, exploratory data analysis, and machine learning.
- Pandas and NumPy — data manipulation and numerical analysis.
- Matplotlib and Seaborn — data visualization.
- MySQL — relational database storage and SQL analysis.
- Power BI — interactive reporting and dashboards.
- Scikit-learn — model training and evaluation.
- FastAPI — model prediction API.
- Git and GitHub — version control and project management.

## Dataset Overview

The full working dataset contains approximately **690,100 records** across five datasets.

| Dataset | Records | Description |
|---|---:|---|
| Customers | 75,000 | Demographics, income, occupation, and segments |
| Accounts | 85,000 | Account types and balances |
| Loans | 30,000 | Loan amounts, interest rates, EMI, and default-related fields |
| Transactions | 500,000 | Transaction amounts, dates, payment methods, and statuses |
| Branches | 100 | Branch locations, regions, and related information |


## Project Workflow

```text
Banking CSV datasets
        ↓
Python: cleaning, validation and exploratory analysis
        ↓
MySQL: relational data and business SQL analysis
        ↓
Power BI: interactive business dashboards
        ↓
Machine learning: exploratory loan-default classification
        ↓
FastAPI: validated prediction endpoint
        ↓
Pytest: automated API checks
```

### 1. Data Cleaning and Analysis
Used Python to inspect datasets, handle data-quality issues, validate relationships, and prepare analytical features such as age groups, income groups, and credit-score categories.

### 2. SQL Business Analysis
Used MySQL queries, JOINs, aggregations, CTEs, and other SQL techniques to investigate customer segments, loan performance, transaction behavior, and branch activity.

### 3. Power BI Dashboard
Created a four-page interactive dashboard for different business audiences.

## Power BI Dashboard

The dashboard includes four analytical pages:

- **Executive Overview:** Key performance indicators, customer segments, loan status, and transaction trends.
- **Customer Analytics:** Customer demographics, occupations, income groups, and segments.
- **Loan & Risk Analytics:** Loan distribution, credit scores, EMI-to-income ratio, and default patterns.
- **Branch & Transaction Analytics:** Branch comparisons, payment methods, transaction values, and deposit-related measures.

### Dashboard Screenshots

**1. Executive Overview**

Add your screenshot here by uploading it to the `images/` folder.

![Executive Overview](images/executive_overview.png)

**2. Customer Analytics**

![Customer Analytics](images/customer_analysis.png)

**3. Loan & Risk Analytics**

![Loan & Risk Analytics](images/loan_and_risk_analysis.png)

**4. Branch & Transaction Analytics**

![Branch & Transaction Analytics](images/branch_and_transaction_analytics.png)


## Key Business Insights

The following findings were observed in the current working dataset:
- Observed positive default-label rate: 1,617 of 30,000 loans, or approximately 5.39%, have default_flag = Yes.
- Credit-score pattern: The reported default-label rate for the category classified as poor credit score was approximately 21.68%.
- Transaction channel: UPI represented approximately 49.8% of recorded transactions.
- Customer segmentation: Platinum customers represented approximately 43.8% of the customer base.

These are descriptive findings from the project dataset, not general conclusions about real-world banking portfolios. Validate the business definitions, category boundaries, and source data before using them for operational decisions.

## Machine Learning: Loan-Default Prediction

Two classification models were evaluated for loan default prediction:
- Logistic Regression
- Random Forest Classifier
The models use features such as loan amount, interest rate, EMI, credit score, age, annual income, loan type, occupation, marital status, and customer segment.
Model Evaluation
The reported results at a classification threshold of 0.50 are:
| Metric for the positive class | Logistic Regression | Random Forest |
|---|---:|---:|
| Accuracy | 94.47% | 93.12% |
| Precision | 9.09% | 21.43% |
| Recall | 0.31% | 7.43% |
| F1-score | 0.60% | 11.03% |
| ROC-AUC | 0.7783 | 0.7648 |
| Average precision | 0.1474 | 0.1348 |
| Brier score | 0.0489 | 0.0586 |

The evaluation set contained 6,000 records, including 323 positive default labels and 5,677 negative labels.

Although accuracy is relatively high, both models have low recall at the 0.50 threshold. This means they miss many positive default cases. Accuracy alone is therefore not sufficient to judge model usefulness for this imbalanced classification problem.

A lower threshold was also explored for Logistic Regression. Threshold selection should be performed using validation data before evaluating the final model on a separate test set.

## FastAPI Prediction Service
The project includes a FastAPI service for demonstrating loan default predictions.

Available endpoints:
- GET / — returns a welcome message and model name.
- GET /health — checks service health.
- GET /debug/model — displays model-related diagnostic information.
- POST /predict — accepts loan and applicant details and returns a prediction.
Run the API
Install the dependencies and start the service using:

py -m uvicorn api.app:app --reload

Open the interactive API documentation at:

http://127.0.0.1:8000/docs

The API is intended for demonstration and educational purposes, not for making real lending decisions.

## Business Recommendations

- Investigate credit-score and affordability indicators when assessing loan risk.
- Monitor transaction failures and payment-channel performance.
- Compare branch workloads and deposit measures to identify operational improvement opportunities.
- Use customer segmentation to investigate suitable products and relationship strategies.
- Standardize default definitions and monetary units to improve reporting reliability.

## Repository Structure

```text
Banking-Customer-Risk-Analytics/
├── api/
├── artifacts/
├── data/
├── images/
├── ml/
├── notebook/
├── Pipeline flow/
├── report/
├── sql/
├── tests/
│   └── test_api.py
└── README.md
```

## Current Limitations and Future Improvements
- **Synthetic Data:** The project uses synthetic banking data for analysis and demonstration. Results may differ from real-world banking data.
- **Model Performance:** The classification models were evaluated using multiple metrics, including accuracy, precision, recall, and ROC-AUC. Further tuning could improve the identification of loan default cases.
- **Future Enhancements:** Additional model validation, explainability techniques, and API improvements could strengthen the project in future iterations.

## Conclusion
This project demonstrates an end-to-end banking analytics workflow involving data preparation, relational SQL analysis, interactive Power BI reporting, machine learning experimentation, and API-based prediction. It highlights how data analytics and predictive modeling can support the investigation of customer behavior and loan risk while emphasizing the importance of data quality and appropriate model evaluation.


## Author

**Gayatri Kasbekar**

- **GitHub:** [Gayatrik04](https://github.com/Gayatrik04)
- **LinkedIn:** [Gayatri Kasbekar](https://www.linkedin.com/in/gayatri-kasbekar-674a883a3/)
- **Email:** gayatrikasbekar1311@gmail.com