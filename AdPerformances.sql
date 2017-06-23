-- Ad performance for certain placement IDs for Dafny (note: I didn’t limit this by date, since these 5 placements all began today)

select 
	o.placement_id
	, sit.abbreviation
	, o.oid
	, s.payment_status
	, r.payment_transaction_result
	, pa.amount AS orderprice
	, o.adjustmentamount AS orderadjustment
	, o.shippingcost AS shippingcost
	, o.tax AS tax
	, pa.authdate
	, o.origincode
from 
	ecommerce.rsorder as o
	, ecommerce.paymentauthorization as pa
	, ecommerce.payment_status as s
	, ecommerce.payment_transaction_result as r
	, ecommerce.site as sit
where 
	o.oid = pa.order_id
	and pa.payment_status_id = s.payment_status_id
	and pa.payment_transaction_result_id = r.payment_transaction_result_id
	and o.site_id = sit.site_id
	and pa.payment_status_id IN (3, 5, 6)
	and o.placement_id IN (396994, 396996, 396997, 396998, 396999)
order 
	by o.oid asc;