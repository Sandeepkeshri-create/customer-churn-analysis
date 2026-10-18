USE churn_db;

-- customer_clean: remove duplicates, standardize gender, fill country from state
DROP TABLE IF EXISTS customer_clean;

with cte as (
    select *,
        ROW_NUMBER() over (partition by customerid order by customerid) as rn,
        case
            when gender in ('Men', 'Male') then 'Male'
            when gender in ('Women', 'Female') then 'Female'
            else 'other'
        end as new_gender_name,
        case
            when country is not null then country
            when state in ('Kathmandu', 'Pokhara', 'Lalitpur') then 'Nepal'
            else 'India'
        end as new_country_name
    from db_customer
)
select customerid, name, new_country_name as country, state,
       new_gender_name as gender, dob, interests
into customer_clean
from cte
where rn = 1;

-- Validation checks
select count(*) as total_customers from customer_clean;                          -- 10000
select gender, count(*) as cnt from customer_clean group by gender;              -- Male, Female
select country, count(*) as cnt from customer_clean group by country;            -- India, Nepal
select customerid from customer_clean group by customerid having count(*) > 1;