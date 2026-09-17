USE banking_customer_risk_analytics;

-- Branch operational overview
SELECT
    b.branch_id,
    b.branch_name,
    b.region,
    b.employees,
    COUNT(DISTINCT a.customer_id) AS customers_served,
    COUNT(DISTINCT a.account_id) AS accounts_managed,
    ROUND(SUM(a.balance), 2) AS total_deposits
FROM branches b
LEFT JOIN accounts a
    ON b.branch_id = a.branch_id
GROUP BY b.branch_id, b.branch_name, b.region, b.employees
ORDER BY total_deposits DESC;

-- Deposit productivity per employee
SELECT
    b.branch_id,
    b.branch_name,
    b.employees,
    ROUND(SUM(a.balance), 2) AS total_deposits,
    ROUND(SUM(a.balance) / NULLIF(b.employees, 0), 2) AS deposits_per_employee
FROM branches b
JOIN accounts a
    ON b.branch_id = a.branch_id
GROUP BY b.branch_id, b.branch_name, b.employees
ORDER BY deposits_per_employee DESC;

-- Branch transaction activity
SELECT
    b.branch_id,
    b.branch_name,
    b.region,
    COUNT(t.transaction_id) AS transaction_count,
    ROUND(SUM(t.amount), 2) AS transaction_value,
    ROUND(AVG(t.amount), 2) AS avg_transaction_value
FROM branches b
JOIN accounts a
    ON b.branch_id = a.branch_id
JOIN transactions t
    ON a.account_id = t.account_id
GROUP BY b.branch_id, b.branch_name, b.region
ORDER BY transaction_value DESC;

-- Branch loan risk
SELECT
    b.branch_id,
    b.branch_name,
    b.region,
    COUNT(l.loan_id) AS total_loans,
    ROUND(SUM(l.loan_amount), 2) AS total_loan_amount,
    ROUND(SUM(l.remaining_balance), 2) AS outstanding_balance,
    ROUND(
        100.0 * SUM(CASE WHEN l.default_flag = 'Yes' THEN 1 ELSE 0 END)
        / NULLIF(COUNT(l.loan_id), 0),
        2
    ) AS default_rate_pct
FROM branches b
JOIN accounts a
    ON b.branch_id = a.branch_id
JOIN loans l
    ON a.customer_id = l.customer_id
GROUP BY b.branch_id, b.branch_name, b.region
ORDER BY default_rate_pct DESC;
