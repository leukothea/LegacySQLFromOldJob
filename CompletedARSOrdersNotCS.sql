-- Order query for Rian of all completed ARS orders, even if they later got credit back partly or fully, from May 20 to 27, NOT including CS-placed orders. Including column for origin code. 

-- Later, Doug pointed out that this query counts everything – even Coupaw orders. So, no wonder there are discrepancies between this and what Google Analytics thinks. :-/

select 
	li.order_id
	, s.name
	, pt.payment_transaction_result
	, ps.payment_status
	, pa.authdate
	, v.name
	, li.customerprice
	, li.tax
	, o.shippingcost
	, o.origincode
from 
	ecommerce.rslineitem as li
	, ecommerce.site as s
	, ecommerce.rsorder as o
	, ecommerce.productversion as v
	, ecommerce.paymentauthorization as pa
	, ecommerce.payment_transaction_result as pt
	, ecommerce.payment_status as ps
where 
	li.productversion_id = v.productversion_id
	and li.order_id = o.oid
	and li.order_id = pa.order_id
	and o.site_id = s.site_id
	and pa.payment_transaction_result_id = pt.payment_transaction_result_id
	and pa.payment_status_id = ps.payment_status_id
	and pa.authdate > '2015-05-19 23:59:59'
	and pa.authdate < '2015-05-27 00:00:00'
	and pa.payment_transaction_result_id = 1
	and pa.payment_status_id in (3,4,5,6)
	and o.origincode not like 'CS_%'
	and o.site_id = 310
order by 
	li.order_id asc;