USE churn_db;

DROP TABLE IF EXISTS subscription_clean;

select customerid,
    TRY_CAST(subscription_start_date as date) as subscription_start_date,
    case
        when subscription_type in ('Refferal') then 'Referral'
        else subscription_type
    end as subscription_type,
    TRY_CAST(renewal_date as date) as renewal_date,
    plan_type, contract_type,
    TRY_CAST(cancellation_date as date) as cancellation_date,
    cancellation_reason, monthly_charges, cltv, churn_score,
    case
        when plan_type = 'Basic' and monthly_charges not in (6.99, 7.99, 8.99) then 1
        when plan_type = 'Standard' and monthly_charges not in (13.99, 16.99, 17.99) then 1
        when plan_type = 'Premium' and monthly_charges not in (20.99, 22.99) then 1
        else 0
    end as is_price_outlier
into subscription_clean
from db_subscription;

select count(*) as total_rows from subscription_clean;
-- 10000

select subscription_type, count(*) as cnt from subscription_clean group by subscription_type;   -- Paid 2790, Organic 4166, Referral 3044

select count(*) as null_start_dates from subscription_clean where subscription_start_date is null;  -- 0

select count(*) as null_cancel_dates from subscription_clean where cancellation_date is null;       -- 7536

-------------------------------------

