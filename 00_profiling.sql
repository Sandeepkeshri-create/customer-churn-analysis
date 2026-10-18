USE churn_db;

-- 1. Quick look at the tables
select top 10 * from db_customer;
select top 10 * from db_subscription;
select top 10 * from db_support;

-- 2. db_customer checks
-- gender values
select gender, count(*) as total from db_customer group by gender;

-- country NULL count
select count(*) as null_country_cnt from db_customer where country is null;

-- duplicate customerid
select customerid, count(*) as duplicate_cnt
from db_customer
group by customerid
having count(*) > 1;

-- is it safe to fill country from state? (1 = safe)
select state, count(distinct country) as count_of_countries
from db_customer
group by state;

-- 3. db_subscription checks
-- subscription_type values
select subscription_type, count(*) as cnt_sub_type
from db_subscription
group by subscription_type;

-- monthly_charges summary
select max(monthly_charges) as max_monthly_charges,
       min(monthly_charges) as min_monthly_charges,
       round(avg(monthly_charges), 2) as avg_monthly_charges
from db_subscription;

-- top 15 charges
select top 15 customerid, plan_type, monthly_charges
from db_subscription
order by monthly_charges desc;

-- price list: how many times each price appears in each plan
select plan_type, monthly_charges, count(*) as cnt
from db_subscription
group by plan_type, monthly_charges
order by plan_type, monthly_charges;

-- wrong prices per plan (total should be 121)
select customerid, plan_type, monthly_charges
from db_subscription
where plan_type = 'Basic' and monthly_charges not in (6.99, 7.99, 8.99);

select customerid, plan_type, monthly_charges
from db_subscription
where plan_type = 'Standard' and monthly_charges not in (13.99, 16.99, 17.99);

select customerid, plan_type, monthly_charges
from db_subscription
where plan_type = 'Premium' and monthly_charges not in (20.99, 22.99);



-----------------------------db_subscription-----------------------------
/*1. Refferal → Referral
Gender wale CASE WHEN jaisa hi hai. subscription_type ko seedha na lekar CASE WHEN se lo,
aur ELSE me wahi value rakho (ELSE subscription_type), taaki Paid aur Organic safe rahein. */
select
	case
		when subscription_type in ('Refferal') then 'Referral'
		else subscription_type
	end as subscription_type
from db_subscription


/*
Isi tarah renewal_date aur cancellation_date tum khud likho. TRY_CAST text ko date banata hai,
aur format galat ho to error ki jagah NULL de deta hai. Isliye neeche ke checks zaroori hain.
*/


select TRY_CAST(renewal_date as date) as renewal_date
from db_subscription

select TRY_CAST(cancellation_date as date) as cancellation_date
from db_subscription


-- 1. start_date me NULL 0 hone chahiye
select count(*) from db_subscription
where TRY_CAST(subscription_start_date AS DATE) is null;

select
    (select count(*) from db_subscription where cancellation_date is null) as raw_nulls,
    (select count(*) from db_subscription where TRY_CAST(cancellation_date AS DATE) is null) as converted_nulls


---------------------------db_support-------------------------------------------
select * from db_support

select comment,count(*) from db_support
group by comment

select customerid, complaint_date, escalations, csat_score
from db_support
group by customerid, complaint_date, escalations, csat_score
having count(*) > 1

select count(col_1), count(*)
from db_support

select * from db_support where customerid = '9011-YEKFB';
