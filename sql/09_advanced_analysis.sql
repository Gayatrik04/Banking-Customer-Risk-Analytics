USE banking_customer_risk_analytics;

-- 1. Running transaction value by month
WITH monthly AS (
    SELECT
        DATE_FORMAT(date, '%Y-%m') AS month,
        SUM(amount) AS monthly_value
    FROM transactions
    GROUP BY DATE_FORMAT(date, '%Y-%m')
)
SELECT
    month,
    ROUND(monthly_value, 2) AS monthly_value,
    ROUND(
        SUM(monthly_value) OVER (
            ORDER BY month
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ),
        2
    ) AS cumulative_transaction_value
FROM monthly
ORDER BY month;

-- 2. Percentage contribution of each payment mode
SELECT
    payment_mode,
    ROUND(SUM(amount), 2) AS transaction_value,
    ROUND(
        100.0 * SUM(amount) / SUM(SUM(amount)) OVER (),
        2
    ) AS value_contribution_pct
FROM transactions
GROUP BY payment_mode
ORDER BY transaction_value DESC;

-- 3. Customers whose deposit balance is above their account-type average
WITH account_benchmarks AS (
    SELECT
        account_type,
        AVG(balance) AS avg_type_balance
    FROM accounts
    GROUP BY account_type
)
SELECT
    a.account_id,
    a.customer_id,
    a.account_type,
    ROUND(a.balance, 2) AS balance,
    ROUND(ab.avg_type_balance, 2) AS avg_type_balance,
    ROUND(a.balance - ab.avg_type_balance, 2) AS difference_from_average
FROM accounts a
JOIN account_benchmarks ab
    ON a.account_type = ab.account_type
WHERE a.balance > ab.avg_type_balance
ORDER BY difference_from_average DESC;

-- 4. Customer-level deposit concentration
WITH customer_deposits AS (
    SELECT
        customer_id,
        SUM(balance) AS total_balance
    FROM accounts
    GROUP BY customer_id
)
SELECT
    customer_id,
    ROUND(total_balance, 2) AS total_balance,
    ROUND(
        100.0 * total_balance / SUM(total_balance) OVER (),
        2
    ) AS deposit_contribution_pct,
    DENSE_RANK() OVER (ORDER BY total_balance DESC) AS customer_rank
FROM customer_deposits
ORDER BY customer_rank;

-- 5. Customers with both high transaction activity and loan exposure
WITH customer_activity AS (
    SELECT
        c.customer_id,
        CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
        COALESCE(t.transaction_value, 0) AS transaction_value,
        COALESCE(l.outstanding_balance, 0) AS outstanding_balance
    FROM customers c
    LEFT JOIN (
        SELECT customer_id, SUM(amount) AS transaction_value
        FROM transactions
        GROUP BY customer_id
    ) t ON c.customer_id = t.customer_id
    LEFT JOIN (
        SELECT customer_id, SUM(remaining_balance) AS outstanding_balance
        FROM loans
        GROUP BY customer_id
    ) l ON c.customer_id = l.customer_id
)
SELECT
    customer_id,
    customer_name,
    ROUND(transaction_value, 2) AS transaction_value,
    ROUND(outstanding_balance, 2) AS outstanding_balance
FROM customer_activity
WHERE transaction_value > (
    SELECT AVG(transaction_value)
    FROM customer_activity
)
AND outstanding_balance > (
    SELECT AVG(outstanding_balance)
    FROM customer_activity
)
ORDER BY outstanding_balance DESC, transaction_value DESC;
