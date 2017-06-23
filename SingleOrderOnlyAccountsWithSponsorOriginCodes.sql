-- All single-order-only accounts with the origin code like %sponsor% in the last 6 months, broken out by site. (for Leah) - RPT-257

WITH source as (
	select 
		lower(o.email) as email
	from 
		ecommerce.site as s
		, ecommerce.rsorder as o
		, ecommerce.paymentauthorization as pa
		, ecommerce.payment_transaction_result as pt
		, ecommerce.payment_status as ps
	where 
		o.oid = pa.order_id
		and o.site_id = s.site_id
		and pa.payment_transaction_result_id = pt.payment_transaction_result_id
		and pa.payment_status_id = ps.payment_status_id
		and pa.authDate::DATE >= date_trunc('month',now()::DATE) - cast('6 months' as interval)
		and pa.payment_transaction_result_id = 1
		and pa.payment_status_id in (3,5,6)
		and o.origincode ilike '%sponsor%'
	group by 
		o.email
	having 
		count(*) = 1
) 
select distinct 
	source.email
	, si.name as site
from 
	ecommerce.rsorder as o 
		LEFT OUTER JOIN source on o.email = source.email
	, ecommerce.site as si
where 
	o.site_id = si.site_id
group by 
	source.email
	, si.name;