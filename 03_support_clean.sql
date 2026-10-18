use churn_db;
DROP TABLE IF EXISTS support_clean;

select customerid, 
CAST(complaint_date AS DATE)AS complaint_date, 
escalations, csat_score,
case 
	when comment = 'demaned refund' then 'demanded refund'
	else comment
end as comment
INTO support_clean 
from db_support;

select * from support_clean;  


select count(*) from support_clean;  
select comment, count(*) as cnt from support_clean group by comment;  -- demanded refund 404, demaned refund nahi, NULL 1207

select count(*) from customer_clean c
join subscription_clean s on c.customerid = s.customerid;      -- 10000

select sc.customerid 
from support_clean sc
left join customer_clean cc on sc.customerid = cc.customerid
where cc.customerid is null

select count(*) as total_rows
from customer_clean c
join subscription_clean s on c.customerid = s.customerid;