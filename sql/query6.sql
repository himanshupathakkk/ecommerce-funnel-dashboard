-- STEP 3.4: Cohort Analysis (Retention)

-- This answers:
-- “Do users come back or churn?”

WITH cohort AS (
    SELECT 
        customer_id,
        MIN(DATE_FORMAT(order_date, '%Y-%m-01')) AS cohort_month
    FROM orders
    GROUP BY customer_id
),

activity AS (
    SELECT 
        customer_id,
        DATE_FORMAT(order_date, '%Y-%m-01') AS order_month
    FROM orders
)

SELECT 
    c.cohort_month,
    a.order_month,
    COUNT(DISTINCT a.customer_id) AS active_users
FROM cohort c
JOIN activity a 
ON c.customer_id = a.customer_id
GROUP BY 1,2
ORDER BY 1,2;