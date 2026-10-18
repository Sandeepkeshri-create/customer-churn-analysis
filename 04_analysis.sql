/* =====================================================================
   04_analysis.sql
   Project : Customer Churn Analysis
   Database: churn_db
   Tables  : customer_clean (10000), subscription_clean (10000), support_clean (4005)
   Rule    : churned customer = cancellation_date IS NOT NULL
   ===================================================================== */

USE churn_db;


-- =====================================================================
-- Q1. Overall churn rate
-- =====================================================================
SELECT
    COUNT(*)                 AS total_customers,
    COUNT(cancellation_date) AS churned_customers,
    CAST(COUNT(cancellation_date) * 100.0 / COUNT(*) AS DECIMAL(5,2)) AS churn_percentage
FROM subscription_clean;

-- Result : 10000 customers, 2464 churned, 24.64%
-- Insight: Har 4 me se 1 customer (24.64%) subscription cancel kar chuka hai.
--          Ye project ka baseline hai; aage ke sab numbers isi se compare honge.


-- =====================================================================
-- Q2. Plan-wise churn rate
-- =====================================================================
SELECT
    plan_type,
    COUNT(*)                 AS total_customers,
    COUNT(cancellation_date) AS churned_customers,
    CAST(COUNT(cancellation_date) * 100.0 / COUNT(*) AS DECIMAL(5,2)) AS churn_percentage
FROM subscription_clean
GROUP BY plan_type
ORDER BY churn_percentage DESC;

-- Result : Basic 29.71% | Standard 24.77% | Premium 19.42%
-- Insight: Basic plan me churn 29.71% hai, Premium me 19.42% (Basic ~1.5x zyada).
--          Basic wale 27.5% customers hain par churn me 33.2% hissa unka hai (817 / 2464).
--          Guess: sasta plan hone se commitment kam hota hai (reason Q4 me dekho).
--          Suggestion: Basic users ko Standard upgrade ka trial offer test karo.


-- =====================================================================
-- Q3. Contract-wise churn rate
-- =====================================================================
SELECT
    contract_type,
    COUNT(*)                 AS total_customers,
    COUNT(cancellation_date) AS churned_customers,
    CAST(COUNT(cancellation_date) * 100.0 / COUNT(*) AS DECIMAL(5,2)) AS churn_percentage
FROM subscription_clean
GROUP BY contract_type
ORDER BY churn_percentage DESC;

-- Result : Monthly 4502 customers, 1465 churned, 32.54%
--          Annual  5498 customers,  999 churned, 18.17%
-- Insight: Monthly me churn 32.54% hai, Annual me 18.17% (~1.8x zyada).
--          Monthly wale 45% customers hain, par churn me 59.5% hissa unka hai (1465 / 2464).
--          Guess: Monthly me cancel karna aasan hai. Check baaki: Monthly me Basic plan zyada hai ya nahi.
--          Suggestion: Monthly customers ko Annual discount ka offer do.


-- =====================================================================
-- Q4. Cancellation reasons (share of all churned customers)
-- =====================================================================
SELECT
    cancellation_reason,
    COUNT(*) AS churned_customers,
    CAST(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER () AS DECIMAL(5,2)) AS pct_of_churned
FROM subscription_clean
WHERE cancellation_reason IS NOT NULL
GROUP BY cancellation_reason
ORDER BY pct_of_churned DESC;

-- Result : Switched to competitor 24.31% | Too expensive 23.21% | Poor customer support 16.76%
--          Not enough content 15.38% | Poor streaming quality 12.42% | Forgot to cancel trial 7.91%
-- Insight: Top 2 reasons (competitor 24.31% + price 23.21%) milake 47.5% churn explain karte hain.
--          Poor support + poor streaming quality milake 29.2% hai, jo company seedha theek kar sakti hai.
--          "Forgot to cancel trial" sirf 7.9% hai, asli naraazgi nahi.
--          Suggestion: price-sensitive customers ke liye retention offer, aur support/streaming quality improve karo.
--          Baaki: competitor me kya behtar tha, ye data se pata nahi.


-- =====================================================================
-- Q5. Do customers who complained churn more?
-- =====================================================================

-- Step 1a: complaints per customer (one row per customer)
SELECT
    customerid,
    COUNT(*) AS number_of_complaint_by_customers
FROM support_clean
GROUP BY customerid;

-- Step 1b: how many unique customers complained (expected: 2917)
SELECT COUNT(DISTINCT customerid) AS unique_complaint_customers
FROM support_clean;

-- Step 2 (check): has_complaint split (expected: 0 -> 7083, 1 -> 2917)
WITH cte AS (
    SELECT customerid, COUNT(*) AS number_of_complaint_by_customers
    FROM support_clean
    GROUP BY customerid
),
complaint_flag AS (
    SELECT
        s.customerid,
        s.cancellation_date,
        CASE WHEN c.number_of_complaint_by_customers IS NULL THEN 0 ELSE 1 END AS has_complaint
    FROM subscription_clean s
    LEFT JOIN cte c ON s.customerid = c.customerid
)
SELECT has_complaint, COUNT(*) AS cnt
FROM complaint_flag
GROUP BY has_complaint;

-- Step 3: churn % for complaint vs no-complaint customers
WITH cte AS (
    SELECT customerid, COUNT(*) AS number_of_complaint_by_customers
    FROM support_clean
    GROUP BY customerid
),
complaint_flag AS (
    SELECT
        s.customerid,
        s.cancellation_date,
        CASE WHEN c.number_of_complaint_by_customers IS NULL THEN 0 ELSE 1 END AS has_complaint
    FROM subscription_clean s
    LEFT JOIN cte c ON s.customerid = c.customerid
)
SELECT
    has_complaint,
    COUNT(*)                 AS total_customers,
    COUNT(cancellation_date) AS churned_customers,
    CAST(COUNT(cancellation_date) * 100.0 / COUNT(*) AS DECIMAL(5,2)) AS churn_percentage
FROM complaint_flag
GROUP BY has_complaint
ORDER BY churn_percentage DESC;

-- Result : Complained    2917 customers, 1142 churned, 39.15%
--          No complaint  7083 customers, 1322 churned, 18.66%
-- Insight: Complaint karne wale customers ka churn 39.15% hai, bina complaint wale ka 18.66% (~2.1x).
--          Ye 29.2% customers hain par churn me 46.4% hissa unka hai (1142 / 2464).
--          Lekin 53.6% churn (1322) un customers se aaya jinhone complaint kabhi ki hi nahi.
--          Guess: support se satisfy nahi hue (Q4 me "Poor customer support" 16.76%). Complaint churn ka sign bhi ho sakta hai, cause pakka nahi.
--          Suggestion: complaint resolve hone ke baad follow-up karo (escalations aur csat_score dekho),
--          aur bina complaint wale customers se proactive feedback lo.


