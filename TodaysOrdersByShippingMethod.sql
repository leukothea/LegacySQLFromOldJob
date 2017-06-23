-- Count of completed orders with various shipping methods

select 
	COALESCE(so.shippingoption,'none') as shipping_option
	,count(*)
from 
	ecommerce.paymentauthorization as pa
	,ecommerce.rsorder as o 
		LEFT OUTER JOIN ecommerce.shippingoption as so on o.shipping_option_id = so.shippingoption_id
where 
	o.oid = pa.order_id 
	and pa.authdate >= now()::DATE
	and pa.payment_transaction_result_id = 1 
	and pa.payment_status_id in (3,5,6)
group by 
	COALESCE(so.shippingoption,'none')
	,COALESCE(so.ordinal,0)
order by 
	COALESCE(so.ordinal,0);