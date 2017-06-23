-- 30-day Sales query.
-- Popular items algorithm from Ron (last gathered July 11, 2012). This query returns all items on THS in ascending order by item ID, then the last 30 days' worth of sales (labeled as "customer price"), then 10% of unit quantities sold in the prior 335 days before that (labeled as "run count").

select 
	pv.item_id as id
	,sum( 
		case when now()::date - pa.authDate::date <= 30 then li.customerPrice * sli.quantity else li.customerPrice * sli.quantity / 10.0 end 
		) as customerPrice
	, sum( 
		case when now()::date - pa.authDate::date <= 30 then sli.quantity else sli.quantity / 10.0 end 
		) as runCount
from 
	ecommerce.PaymentAuthorization as pa
	,ecommerce.RSLineItem as li
	,ecommerce.SiteLineItem as sli
	,ecommerce.ProductVersion as pv
where 
	pv.itemstatus_id = 0
	and pa.payment_transaction_result_id = 1
	and pa.payment_status_id in (3,5,6)
	and pa.order_id = li.order_id
	and pa.authDate >= now ()::date - interval '365 days'
	and li.lineItemType_id = 1
	and li.oid = sli.lineItem_id
	and sli.site_id = 220
	and pv.productVersion_id = li.productVersion_id
group by 
	pv.item_id
order by 
	customerprice desc
	, runcount desc;