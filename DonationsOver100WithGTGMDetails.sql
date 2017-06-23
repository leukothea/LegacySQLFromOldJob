-- Accounts that have placed one or more orders after Sept.30, that are now status "processed," that had a summed tax-deductible amount of $100+, with detail about what GTGM(s) they ordered.

-- step 1

-- (create temp table)

select 
	o.account_id
	,sum(COALESCE(li.quantity,0) * COALESCE(pr.customerPrice,0.00)) AS tax_deduct_amount
into 
	temp_accounts
from 
	ecommerce.Item as i
	, ecommerce.rsorder as o
	, ecommerce.rslineitem as li
	, ecommerce.productversion as pv
	, ecommerce.price as pr
	, ecommerce.PaymentAuthorization as pa
	, ecommerce.MerchantAccount as ma
where 
	i.vendor_id = 77
	and i.item_id = pv.item_id
	and o.oid = li.order_id
	and li.productversion_id = pv.productversion_id
	and li.order_id = pa.order_id
	and pr.source_id = li.productVersion_id
	and pr.priceType_id = 4 and pr.sourceClass_id = 9
	and pa.payment_transaction_result_id = 1
	and pa.payment_status_id in (3,5)
	and pa.authDate::DATE >= '20121001'
	and pa.merchantaccount_id = ma.merchantaccount_id
group by 
	o.account_id
having 
	sum(COALESCE(li.quantity,0) * COALESCE(pr.customerPrice,0.00)) > 100.00
order by 
	o.account_id asc;


-- step 2

-- (join to temp table)

select 
	o.account_id
	, a.email
	, rsa.firstname
	, rsa.lastname
	, rsa.phone
	, o.oid as order_id
	, pv.name
	, sum(COALESCE(li.quantity,0) * COALESCE(pr.customerPrice,0.00)) AS tax_deduct_amount
	,ta.tax_deduct_amount as total_contribution
from 
	ecommerce.Item as i
	, ecommerce.rsorder as o
	, ecommerce.rslineitem as li
	, ecommerce.productversion as pv
	, ecommerce.price as pr
	, ecommerce.PaymentAuthorization as pa
	, ecommerce.MerchantAccount as ma
	, pheme.account as a
	, ecommerce.rsaddress as rsa
	,temp_accounts as ta
where 
	ta.account_id = o.account_id
	and i.vendor_id = 77
	and i.item_id = pv.item_id
	and o.oid = li.order_id
	and li.productversion_id = pv.productversion_id
	and li.order_id = pa.order_id
	and rsa.oid = o.billingaddress_id
	and pr.source_id = li.productVersion_id
	and pr.priceType_id = 4 and pr.sourceClass_id = 9
	and pa.payment_transaction_result_id = 1
	and pa.payment_status_id in (3,5)
	and pa.authDate::DATE > '20121001'
	and pa.merchantaccount_id = ma.merchantaccount_id
	and o.account_id = a.account_id
group by 
	o.account_id
	, a.email
	, rsa.firstname
	, rsa.lastname
	, rsa.phone
	, o.oid
	, pv.name
	,ta.tax_deduct_amount
order by 
	o.account_id asc;