USE banking_customer_risk_analytics;

-- Rule-based customer risk profile.
-- This is analytical segmentation, not a machine-learning credit model.
WITH customer_metrics AS (
    SELECT
        c.customer_id,
        CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
        c.customer_segment,
        c.annual_income,
        COALESCE(a.total_balance, 0) AS total_balance,
        COALESCE(l.total_loan_amount, 0) AS total_loan_amount,
        COALESCE(l.total_outstanding, 0) AS total_outstanding,
        COALESCE(l.avg_credit_score, 0) AS avg_credit_score,
        COALESCE(l.default_count, 0) AS default_count,
        COALESCE(l.max_emi_to_income_pct, 0) AS max_emi_to_income_pct,
        COALESCE(t.transaction_count, 0) AS transaction_count,
        COALESCE(t.transaction_value, 0) AS transaction_value
    FROM customers c
    LEFT JOIN (
        SELECT
            customer_id,
            SUM(balance) AS total_balance
        FROM accounts
        GROUP BY customer_id
    ) a
        ON c.customer_id = a.customer_id
    LEFT JOIN (
        SELECT
            customer_id,
            SUM(loan_amount) AS total_loan_amount,
            SUM(remaining_balance) AS total_outstanding,
            AVG(credit_score) AS avg_credit_score,
            SUM(CASE WHEN default_flag = 'Yes' THEN 1 ELSE 0 END) AS default_count,
            MAX(
                100.0 * emi / NULLIF(
                    (SELECT annual_income
                     FROM customers c2
                     WHERE c2.customer_id = loans.customer_id) / 12,
                    0
                )
            ) AS max_emi_to_income_pct
        FROM loans
        GROUP BY customer_id
    ) l
        ON c.customer_id = l.customer_id
    LEFT JOIN (
        SELECT
            customer_id,
            COUNT(*) AS transaction_count,
            SUM(amount) AS transaction_value
        FROM transactions
        GROUP BY customer_id
    ) t
        ON c.customer_id = t.customer_id
)
SELECT
    *,
    CASE
        WHEN default_count > 0
             OR max_emi_to_income_pct >= 50
             OR avg_credit_score < 580
            THEN 'High Risk'
        WHEN max_emi_to_income_pct >= 35
             OR avg_credit_score < 670
            THEN 'Medium Risk'
        ELSE 'Low Risk'
    END AS risk_segment
FROM customer_metrics
ORDER BY
    CASE
        WHEN default_count > 0
             OR max_emi_to_income_pct >= 50
             OR avg_credit_score < 580 THEN 1
        WHEN max_emi_to_income_pct >= 35
             OR avg_credit_score < 670 THEN 2
        ELSE 3
    END,
    total_outstanding DESC;

-- High-value customers with active loans
SELECT
    c.customer_id,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    ROUND(SUM(a.balance), 2) AS total_balance,
    ROUND(SUM(l.remaining_balance), 2) AS outstanding_loan_balance,
    COUNT(DISTINCT l.loan_id) AS active_loan_count
FROM customers c
JOIN accounts a
    ON c.customer_id = a.customer_id
JOIN loans l
    ON c.customer_id = l.customer_id
WHERE LOWER(l.loan_status) = 'active'
GROUP BY c.customer_id, customer_name
ORDER BY total_balance DESC
LIMIT 20;
