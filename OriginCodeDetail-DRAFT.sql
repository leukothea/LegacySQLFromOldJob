
select 
	COALESCE(o.originCode,'No Origin Code') as origin_code
	, i.item_id, i.name AS item_name
	, sum(li.quantity) AS item_count
	, sum(li.quantity * li.customerPrice) AS customer_price 
from 
	ecommerce.item as i
	, ecommerce.productversion as pv
	, ecommerce.RSLineItem li
	,ecommerce.RSOrder o
	,ecommerce.PaymentAuthorization pa 
where 
	o.oid = pa.order_id  
	and pa.payment_transaction_result_id = 1 
	and pa.payment_status_id in (3,5,6)  
	and o.oid = li.order_id 
	and COALESCE(li.lineItemType_id,1) = 1 
	and li.productVersion_id = pv.productversion_id 
	and pv.item_id = i.item_id  
	and o.originCode ILIKE '%' 
	and pa.authDate >= now()::DATE - cast('1 day' as interval) 
	and pa.authDate::DATE < now()::DATE
group by 
	COALESCE(o.originCode, 'No Origin Code')
	, i.item_id
	, i.name 
order by 
	COALESCE(o.originCode, 'No Origin Code')
	, sum(li.quantity) desc 
 