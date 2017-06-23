-- Throughout our tenure as an online store, what percentage of successfully completed (not-later-totally-refunded) orders had just a billing address, vs. what percentage had a billing and a shipping address?

with billonly as (
	select 
		count(*) as count
	from 
		ecommerce.rsorder as o
		, ecommerce.paymentauthorization as pa
	where 
		o.oid = pa.order_id 
		and pa.payment_status_id in (3,5,6)
		and pa.payment_transaction_result_id = 1
		and o.shippingaddress_id IS NULL
), shipandbill as (
	select 
		count(*) as count
	from 
		ecommerce.rsorder as o
		, ecommerce.paymentauthorization as pa
	where 
		o.oid = pa.order_id 
		and pa.payment_status_id in (3,5,6)
		and pa.payment_transaction_result_id = 1
		and o.shippingaddress_id IS NOT NULL
)
select 
	billonly.count
	,cast(100.0* billonly.count/(billonly.count+shipandbill.count) as numeric(10,2)) as pcnt1
	,shipandbill.count
	,cast(100.0 *shipandbill.count / (billonly.count+shipandbill.count) as numeric(10,2)) as pcnt2 
from 
	billonly
	, shipandbill