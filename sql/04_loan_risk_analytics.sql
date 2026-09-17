USE banking_customer_risk_analytics;

-- Loan portfolio KPIs
SELECT
    COUNT(*) AS total_loans,
    ROUND(SUM(loan_amount), 2) AS total_loan_amount,
    ROUND(SUM(remaining_balance), 2) AS total_outstanding_balance,
    ROUND(AVG(loan_amount), 2) AS avg_loan_amount,
    ROUND(AVG(credit_score), 1) AS avg_credit_score,
    ROUND(
        100.0 * SUM(CASE WHEN default_flag = 'Yes' THEN 1 ELSE 0 END) / COUNT(*),
        2
    ) AS default_rate_pct
FROM loans;

-- Default rate by loan type
SELECT
    loan_type,
    COUNT(*) AS total_loans,
    SUM(CASE WHEN default_flag = 'Yes' THEN 1 ELSE 0 END) AS defaulted_loans,
    ROUND(SUM(loan_amount), 2) AS total_loan_amount,
    ROUND(SUM(remaining_balance), 2) AS outstanding_balance,
    ROUND(
        100.0 * SUM(CASE WHEN default_flag = 'Yes' THEN 1 ELSE 0 END) / COUNT(*),
        2
    ) AS default_rate_pct
FROM loans
GROUP BY loan_type
ORDER BY default_rate_pct DESC;

-- Corrected credit-score bands
SELECT
    CASE
        WHEN credit_score < 580 THEN 'Poor'
        WHEN credit_score BETWEEN 580 AND 669 THEN 'Fair'
        WHEN credit_score BETWEEN 670 AND 739 THEN 'Good'
        WHEN credit_score BETWEEN 740 AND 799 THEN 'Very Good'
        ELSE 'Excellent'
    END AS credit_category,
    COUNT(*) AS total_loans,
    ROUND(AVG(loan_amount), 2) AS avg_loan_amount,
    ROUND(
        100.0 * SUM(CASE WHEN default_flag = 'Yes' THEN 1 ELSE 0 END) / COUNT(*),
        2
    ) AS default_rate_pct
FROM loans
GROUP BY credit_category
ORDER BY default_rate_pct DESC;

-- Default rate by customer segment
SELECT
    c.customer_segment,
    COUNT(l.loan_id) AS total_loans,
    SUM(CASE WHEN l.default_flag = 'Yes' THEN 1 ELSE 0 END) AS defaulted_loans,
    ROUND(
        100.0 * SUM(CASE WHEN l.default_flag = 'Yes' THEN 1 ELSE 0 END)
        / COUNT(l.loan_id),
        2
    ) AS default_rate_pct
FROM customers c
JOIN loans l
    ON c.customer_id = l.customer_id
GROUP BY c.customer_segment
ORDER BY default_rate_pct DESC;

-- Default rate by state
SELECT
    c.state,
    COUNT(l.loan_id) AS total_loans,
    ROUND(
        100.0 * SUM(CASE WHEN l.default_flag = 'Yes' THEN 1 ELSE 0 END)
        / COUNT(l.loan_id),
        2
    ) AS default_rate_pct
FROM customers c
JOIN loans l
    ON c.customer_id = l.customer_id
GROUP BY c.state
HAVING COUNT(l.loan_id) >= 10
ORDER BY default_rate_pct DESC;

-- High repayment-burden customers
SELECT
    c.customer_id,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    c.annual_income,
    l.loan_id,
    l.loan_type,
    l.credit_score,
    l.emi,
    ROUND(c.annual_income / 12, 2) AS monthly_income,
    ROUND(100.0 * l.emi / NULLIF(c.annual_income / 12, 0), 2) AS emi_to_income_pct,
    l.default_flag
FROM customers c
JOIN loans l
    ON c.customer_id = l.customer_id
WHERE c.annual_income > 0
ORDER BY emi_to_income_pct DESC
LIMIT 20;
 