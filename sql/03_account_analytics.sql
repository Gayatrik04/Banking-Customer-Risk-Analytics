USE banking_customer_risk_analytics;

-- Account KPIs
SELECT
    COUNT(*) AS total_accounts,
    COUNT(DISTINCT customer_id) AS customers_with_accounts,
    ROUND(SUM(balance), 2) AS total_deposits,
    ROUND(AVG(balance), 2) AS avg_account_balance
FROM accounts;

-- Account status distribution
SELECT
    account_status,
    COUNT(*) AS account_count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS account_share_pct,
    ROUND(SUM(balance), 2) AS total_balance
FROM accounts
GROUP BY account_status
ORDER BY account_count DESC;

-- Account type performance
SELECT
    account_type,
    COUNT(*) AS account_count,
    ROUND(SUM(balance), 2) AS total_balance,
    ROUND(AVG(balance), 2) AS avg_balance
FROM accounts
GROUP BY account_type
ORDER BY total_balance DESC;

-- Branch deposit performance
SELECT
    b.branch_id,
    b.branch_name,
    b.region,
    COUNT(a.account_id) AS account_count,
    ROUND(SUM(a.balance), 2) AS total_deposits,
    ROUND(AVG(a.balance), 2) AS avg_balance
FROM branches b
LEFT JOIN accounts a
    ON b.branch_id = a.branch_id
GROUP BY b.branch_id, b.branch_name, b.region
ORDER BY total_deposits DESC;

-- Branch ranking by deposits
WITH branch_deposits AS (
    SELECT
        b.branch_id,
        b.branch_name,
        b.region,
        SUM(a.balance) AS total_deposits
    FROM branches b
    JOIN accounts a
        ON b.branch_id = a.branch_id
    GROUP BY b.branch_id, b.branch_name, b.region
)
SELECT
    branch_id,
    branch_name,
    region,
    ROUND(total_deposits, 2) AS total_deposits,
    DENSE_RANK() OVER (ORDER BY total_deposits DESC) AS deposit_rank
FROM branch_deposits
ORDER BY deposit_rank;
