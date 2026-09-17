USE banking_customer_risk_analytics;

-- Customer overview
SELECT
    COUNT(*) AS total_customers,
    ROUND(AVG(age), 1) AS avg_customer_age,
    ROUND(AVG(annual_income), 2) AS avg_annual_income,
    ROUND(AVG(customer_tenure), 1) AS avg_tenure_years
FROM customers;

-- Customer distribution by segment
SELECT
    customer_segment,
    COUNT(*) AS customer_count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS customer_share_pct,
    ROUND(AVG(annual_income), 2) AS avg_income
FROM customers
GROUP BY customer_segment
ORDER BY customer_count DESC;

-- Geographic customer concentration
SELECT
    state,
    COUNT(*) AS customer_count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS customer_share_pct
FROM customers
GROUP BY state
ORDER BY customer_count DESC;

-- Customer tenure bands
SELECT
    CASE
        WHEN customer_tenure < 2 THEN '0-1 Years'
        WHEN customer_tenure < 5 THEN '2-4 Years'
        WHEN customer_tenure < 10 THEN '5-9 Years'
        ELSE '10+ Years'
    END AS tenure_band,
    COUNT(*) AS customer_count,
    ROUND(AVG(annual_income), 2) AS avg_income
FROM customers
GROUP BY tenure_band
ORDER BY customer_count DESC;

-- Top customers by income within each state
WITH ranked_customers AS (
    SELECT
        customer_id,
        CONCAT(first_name, ' ', last_name) AS customer_name,
        state,
        annual_income,
        ROW_NUMBER() OVER (
            PARTITION BY state
            ORDER BY annual_income DESC
        ) AS rn
    FROM customers
)
SELECT
    customer_id,
    customer_name,
    state,
    annual_income
FROM ranked_customers
WHERE rn <= 3
ORDER BY state, annual_income DESC;
