-- Accounts that have placed one or more orders after Sept.30, that are now status "processed," that had a summed tax-deductible amount of $100+. (On Nov. 6 2012, I got 401 records returned.)

select 
	o.account_id
	, a.email
	, rsa.firstname
	, rsa.lastname
	, rsa.phone
	, sum(COALESCE(li.quantity,0) * COALESCE(pr.customerPrice,0.00)) AS tax_deduct_amount
from 
	ecommerce.Item as i
	, ecommerce.rsorder as o
	, ecommerce.rslineitem as li
	, ecommerce.productversion as pv
	, ecommerce.price as pr
	, ecommerce.PaymentAuthorization as pa
	, ecommerce.MerchantAccount as ma
	, pheme.account as a, 
	ecommerce.rsaddress as rsa
where 
	i.vendor_id = 77
	and i.item_id = pv.item_id
	and o.oid = li.order_id
	and li.productversion_id = pv.productversion_id
	and li.order_id = pa.order_id
	and rsa.oid = o.billingaddress_id
	and pr.source_id = li.productVersion_id
	and pr.priceType_id = 4 and pr.sourceClass_id = 9
	and pa.payment_transaction_result_id = 1
	and pa.payment_status_id in (3,5)
	and pa.authDate::DATE > '2012-09-30'
	and COALESCE(pv.initialLaunchDate,date_trunc('month',now()::DATE) - cast('1 month' as interval))::DATE <= pa.authDate::DATE
	and pa.merchantaccount_id = ma.merchantaccount_id
	and o.account_id = a.account_id
	and li.quantity * li.customerPrice >= 100
group by 
	o.account_id
	, a.email
	, rsa.firstname
	, rsa.lastname
	, rsa.phone
order by 
	tax_deduct_amount desc;