USE banking_customer_risk_analytics;

-- Executive KPI summary for Power BI / management reporting.
SELECT
    (SELECT COUNT(*) FROM customers) AS total_customers,
    (SELECT COUNT(*) FROM accounts) AS total_accounts,
    (SELECT ROUND(SUM(balance), 2) FROM accounts) AS total_deposits,
    (SELECT COUNT(*) FROM loans) AS total_loans,
    (SELECT ROUND(SUM(loan_amount), 2) FROM loans) AS total_loan_amount,
    (SELECT ROUND(SUM(remaining_balance), 2) FROM loans) AS total_outstanding_balance,
    (SELECT ROUND(
        100.0 * SUM(CASE WHEN default_flag = 'Yes' THEN 1 ELSE 0 END) / COUNT(*),
        2
     ) FROM loans) AS default_rate_pct,
    (SELECT COUNT(*) FROM transactions) AS total_transactions,
    (SELECT ROUND(SUM(amount), 2) FROM transactions) AS total_transaction_value,
    (SELECT ROUND(
        100.0 * SUM(CASE WHEN status <> 'Success' THEN 1 ELSE 0 END) / COUNT(*),
        2
     ) FROM transactions) AS transaction_failure_rate_pct,
    (SELECT ROUND(AVG(balance), 2) FROM accounts) AS avg_account_balance,
    (SELECT ROUND(AVG(credit_score), 1) FROM loans) AS avg_credit_score;

-- KPI breakdown by customer segment
SELECT
    c.customer_segment,
    COUNT(DISTINCT c.customer_id) AS customers,
    ROUND(SUM(DISTINCT c.annual_income), 2) AS total_income_of_customers,
    ROUND(COALESCE(SUM(a.balance), 0), 2) AS total_deposits,
    COUNT(DISTINCT l.loan_id) AS total_loans,
    ROUND(COALESCE(SUM(l.remaining_balance), 0), 2) AS outstanding_loan_balance,
    ROUND(
        100.0 * SUM(CASE WHEN l.default_flag = 'Yes' THEN 1 ELSE 0 END)
        / NULLIF(COUNT(l.loan_id), 0),
        2
    ) AS default_rate_pct
FROM customers c
LEFT JOIN accounts a
    ON c.customer_id = a.customer_id
LEFT JOIN loans l
    ON c.customer_id = l.customer_id
GROUP BY c.customer_segment
ORDER BY total_deposits DESC;
