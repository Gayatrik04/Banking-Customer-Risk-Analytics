USE banking_customer_risk_analytics;

-- Transaction KPIs
SELECT
    COUNT(*) AS total_transactions,
    ROUND(SUM(amount), 2) AS total_transaction_value,
    ROUND(AVG(amount), 2) AS avg_transaction_value,
    SUM(CASE WHEN status <> 'Success' THEN 1 ELSE 0 END) AS failed_transactions,
    ROUND(
        100.0 * SUM(CASE WHEN status <> 'Success' THEN 1 ELSE 0 END) / COUNT(*),
        2
    ) AS failure_rate_pct
FROM transactions;

-- Payment mode usage
SELECT
    payment_mode,
    COUNT(*) AS transaction_count,
    ROUND(SUM(amount), 2) AS transaction_value,
    ROUND(AVG(amount), 2) AS avg_transaction_value,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS transaction_share_pct
FROM transactions
GROUP BY payment_mode
ORDER BY transaction_count DESC;

-- Monthly transaction trend with MoM growth
WITH monthly AS (
    SELECT
        DATE_FORMAT(date, '%Y-%m') AS month,
        COUNT(*) AS transaction_count,
        SUM(amount) AS transaction_value,
        SUM(CASE WHEN status <> 'Success' THEN 1 ELSE 0 END) AS failed_transactions
    FROM transactions
    GROUP BY DATE_FORMAT(date, '%Y-%m')
),
with_lag AS (
    SELECT
        *,
        LAG(transaction_value) OVER (ORDER BY month) AS previous_month_value
    FROM monthly
)
SELECT
    month,
    transaction_count,
    ROUND(transaction_value, 2) AS transaction_value,
    failed_transactions,
    ROUND(
        100.0 * failed_transactions / NULLIF(transaction_count, 0),
        2
    ) AS failure_rate_pct,
    ROUND(
        100.0 * (transaction_value - previous_month_value)
        / NULLIF(previous_month_value, 0),
        2
    ) AS mom_growth_pct
FROM with_lag
ORDER BY month;

-- Transaction performance by region
SELECT
    b.region,
    COUNT(t.transaction_id) AS transaction_count,
    ROUND(SUM(t.amount), 2) AS transaction_value,
    ROUND(AVG(t.amount), 2) AS avg_transaction_value
FROM transactions t
JOIN accounts a
    ON t.account_id = a.account_id
JOIN branches b
    ON a.branch_id = b.branch_id
GROUP BY b.region
ORDER BY transaction_value DESC;

-- Top customers by transaction value
SELECT
    c.customer_id,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    COUNT(t.transaction_id) AS transaction_count,
    ROUND(SUM(t.amount), 2) AS transaction_value,
    ROUND(AVG(t.amount), 2) AS avg_transaction_value
FROM customers c
JOIN transactions t
    ON c.customer_id = t.customer_id
GROUP BY c.customer_id, customer_name
ORDER BY transaction_value DESC
LIMIT 10;
