-- Customers in the past 12 months who have purchased more than $100 worth of real items (not CS resends, not promo items, not GTGM) on orders through ARS that were not later fully refunded.
 
WITH pool AS (
	select 
		sum((rsli.customerprice-COALESCE(rsli.customerpriceadjustment,0.00))*rsli.quantity) as customerprice
		, lower(COALESCE(o.email,a.email)) as email
	from 
		ecommerce.rslineitem as rsli
		, ecommerce.rsorder as o
		, ecommerce.paymentauthorization as pa
		, ecommerce.productversion as pv
		, ecommerce.item as i
		, pheme.account as a
	where 
		rsli.order_id = o.oid 
		and o.oid = pa.order_id
		and rsli.productversion_id = pv.productversion_id
		and pv.item_id = i.item_id
		and o.account_id = a.account_id
		and pa.payment_status_id in (3,5,6)
		and pa.payment_transaction_result_id = 1
		and o.site_id = 310 
		and i.itembitmask & 32 != 32
		and i.name NOT ILIKE '%Promo%'
		and i.name NOT ILIKE '%Extra Donation%'
		and rsli.lineitemtype_id = 1
		and pa.authDate::DATE >= date_trunc('month',now()::DATE) - cast('12 months' as interval)
	group by 
		o.email
		, o.adjustmentamount
		, a.email
)
select 
	pool.email
	, sum(pool.customerprice)
from 
	pool
where 
	pool.customerprice > '100.00'
group by 
	pool.email
order by 
	pool.email asc;
