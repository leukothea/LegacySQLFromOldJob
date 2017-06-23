-- Multi-order customers in the past year. (More than 2 orders, not fully refunded, on ARS). 

-- The reason for the subquery and then the larger query around it is to strip out any orders without an email address set on them. I should probably have joined to pheme.account to get the email from there for those orders. 

WITH pool AS (
	select 
		lower(o.email) as email
		, count(o.oid) as order_count 
	from 
		ecommerce.rsorder as o
		, ecommerce.paymentauthorization as pa
	where 
		o.oid = pa.order_id
		and pa.payment_status_id in (3,5,6)
		and pa.payment_transaction_result_id = 1
		and o.site_id = 310 
		and pa.authDate::DATE >= date_trunc('month',now()::DATE) - cast('12 months' as interval)
	group by 
		o.email
	having count(*) > 2
)
select distinct 
	pool.email
	, pool.order_count
from 
	ecommerce.rsorder as o 
		LEFT OUTER JOIN pool on o.email = pool.email
	, ecommerce.site as si
where 
	o.site_id = si.site_id
	and o.site_id = 310
group by 
	pool.email
	, pool.order_count
order by 
	pool.email asc;