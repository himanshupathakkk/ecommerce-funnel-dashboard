-- =========================================================
-- 📊 E-Commerce Funnel & Revenue Analysis Queries
-- Description:
-- This file contains SQL queries for funnel analysis, 
-- user segmentation, revenue concentration, and cohort analysis.
-- =========================================================


-- =========================================================
-- 📊 Funnel Analysis (User-Level Conversion)
-- =========================================================

WITH funnel AS (
    SELECT 
        customer_id,
        MAX(CASE WHEN event_type = 'view' THEN 1 ELSE 0 END) AS viewed,
        MAX(CASE WHEN event_type = 'cart' THEN 1 ELSE 0 END) AS carted,
        MAX(CASE WHEN event_type = 'purchase' THEN 1 ELSE 0 END) AS purchased
    FROM events
    GROUP BY customer_id
)

SELECT 
    COUNT(*) AS total_users,
    SUM(viewed) AS viewed_users,
    SUM(carted) AS cart_users,
    SUM(purchased) AS purchase_users,

    ROUND(SUM(carted) * 100.0 / NULLIF(SUM(viewed), 0), 2) AS view_to_cart_rate,
    ROUND(SUM(purchased) * 100.0 / NULLIF(SUM(carted), 0), 2) AS cart_to_purchase_rate

FROM funnel;



-- =========================================================
-- ⏱️ Sequential Funnel Analysis (Time-Based)
-- =========================================================

WITH user_events AS (
    SELECT 
        customer_id,
        MIN(CASE WHEN event_type = 'view' THEN event_time END) AS view_time,
        MIN(CASE WHEN event_type = 'cart' THEN event_time END) AS cart_time,
        MIN(CASE WHEN event_type = 'purchase' THEN event_time END) AS purchase_time
    FROM events
    GROUP BY customer_id
)

SELECT 
    COUNT(*) AS total_users,

    COUNT(view_time) AS viewed_users,

    COUNT(CASE 
        WHEN cart_time IS NOT NULL AND cart_time > view_time THEN 1 
    END) AS cart_users,

    COUNT(CASE 
        WHEN purchase_time IS NOT NULL AND purchase_time > cart_time THEN 1 
    END) AS purchase_users,

    ROUND(
        COUNT(CASE WHEN cart_time > view_time THEN 1 END) * 100.0 
        / NULLIF(COUNT(view_time), 0), 2
    ) AS view_to_cart_rate,

    ROUND(
        COUNT(CASE WHEN purchase_time > cart_time THEN 1 END) * 100.0 
        / NULLIF(COUNT(CASE WHEN cart_time > view_time THEN 1 END), 0), 2
    ) AS cart_to_purchase_rate

FROM user_events;



-- =========================================================
-- 👥 User Activity Segmentation
-- =========================================================

WITH user_activity AS (
    SELECT 
        customer_id,
        COUNT(*) AS total_events,
        MAX(event_type = 'purchase') AS purchased
    FROM events
    GROUP BY customer_id
)

SELECT 
    CASE 
        WHEN total_events <= 5 THEN 'Low Activity'
        WHEN total_events <= 20 THEN 'Medium Activity'
        ELSE 'High Activity'
    END AS activity_segment,
    
    COUNT(*) AS users,
    SUM(purchased) AS buyers,
    ROUND(SUM(purchased) * 100.0 / COUNT(*), 2) AS conversion_rate

FROM user_activity
GROUP BY activity_segment
ORDER BY conversion_rate DESC;



-- =========================================================
-- 💰 Revenue Concentration (Pareto Analysis)
-- =========================================================

WITH customer_revenue AS (
    SELECT 
        customer_id,
        SUM(revenue) AS total_spent
    FROM orders
    GROUP BY customer_id
),

ranked_customers AS (
    SELECT 
        customer_id,
        total_spent,
        NTILE(5) OVER (ORDER BY total_spent DESC) AS revenue_bucket
    FROM customer_revenue
)

SELECT 
    revenue_bucket,
    COUNT(*) AS users,
    ROUND(SUM(total_spent), 2) AS total_revenue
FROM ranked_customers
GROUP BY revenue_bucket
ORDER BY revenue_bucket;



-- =========================================================
-- 📆 Cohort Analysis (Monthly Retention)
-- =========================================================

WITH cohort AS (
    SELECT 
        customer_id,
        DATE_FORMAT(MIN(order_date), '%Y-%m-01') AS cohort_month
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
GROUP BY c.cohort_month, a.order_month
ORDER BY c.cohort_month, a.order_month;