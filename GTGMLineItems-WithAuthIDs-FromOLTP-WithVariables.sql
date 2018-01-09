WITH poolSum AS (
with lineitems AS (
with paymentauths AS (
	WITH min AS (
		select pa.authorization_id, pa.order_id, (CASE WHEN pa.authorization_id = min(pa.authorization_id) OVER (partition by pa.order_id) THEN min(pa.authorization_id) OVER (partition by pa.order_id) ELSE NULL END) as min_auth_id
		from ecommerce.paymentauthorization as pa 
		where pa.payment_status_id IN (3, 5, 6) and pa.payment_transaction_result_id = 1 
		group by pa.authorization_id, pa.order_id 
		)
	select min.min_auth_id, pa.authorization_id, pa.order_id, pa.authdate::DATE as authdate, pa.payment_method_id 
	from ecommerce.paymentauthorization as pa RIGHT JOIN min ON pa.authorization_id = min.authorization_id
	where pa.payment_status_id IN (3, 5, 6) and pa.payment_transaction_result_id = 1 and pa.authdate >= :startdate and pa.authdate < :enddate
	group by pa.authorization_id, pa.order_id, pa.authdate, pa.payment_method_id, min.min_auth_id, min.authorization_id
	order by pa.authorization_id asc
	)
,  min AS (
		select distinct pa.order_id, (min(pa.authorization_id) OVER (partition by pa.order_id) ) as min_auth_id
		from ecommerce.paymentauthorization as pa 
		where pa.payment_status_id IN (3, 5, 6) and pa.payment_transaction_result_id = 1 
		group by pa.authorization_id, pa.order_id 
		)
SELECT li.oid as lineitem_id
	 , (CASE WHEN li.subscription_payment_authorization_id IS NOT NULL THEN li.subscription_payment_authorization_id ELSE min.min_auth_id END) as lineitem_authorization_id
FROM 
	ecommerce.RSLineItem AS li RIGHT JOIN paymentauths AS pa ON li.order_id = pa.order_id RIGHT JOIN min ON li.order_id = min.order_id
	, ecommerce.SiteLineItem AS sli, ecommerce.ProductVersion AS pv, ecommerce.Item AS i ,ecommerce.site AS s 
WHERE li.productVersion_id = pv.productVersion_id  and li.lineItemType_id in (1,5,8)  and li.oid = sli.lineItem_id  and pv.item_id = i.item_id  and pa.order_id = li.order_id  and s.site_id = sli.site_id and i.vendor_id = 77
	and pa.authdate >= :startdate and pa.authdate < :enddate
GROUP BY 
	li.oid
	, li.subscription_payment_authorization_id
	, min.min_auth_id
	)
select 
	linit.lineitem_id, linit.lineitem_authorization_id, i.item_id, i.name AS item_name , li.order_id, li.lineitemtype_id, li.quantity as lineitem_quantity, li.customerprice as lineitem_customerprice, (li.customerprice * li.quantity)::numeric(10,2) AS lineitem_subtotal, sli.sourceclass_id
FROM 
	ecommerce.RSLineItem AS li RIGHT JOIN lineitems AS linit ON li.oid = linit.lineitem_id
	, ecommerce.SiteLineItem AS sli, ecommerce.ProductVersion AS pv, ecommerce.Item AS i
WHERE li.productVersion_id = pv.productVersion_id  and li.lineItemType_id in (1,5,8)  and li.oid = sli.lineItem_id  and pv.item_id = i.item_id
GROUP BY linit.lineitem_id, linit.lineitem_authorization_id, i.item_id, i.name, li.order_id, li.lineitemtype_id, li.quantity, li.customerprice, li.quantity, sli.sourceclass_id
 )
 select distinct
 	o.account_id 
	, poolSum.lineitem_id -- just for internal identification; not for integration into the final output
	, COALESCE(poolSum.lineitem_authorization_id, pa.authorization_id) as authorization_id
	, poolSum.lineitem_quantity
	, poolSum.lineitem_customerprice
	, poolSum.lineitem_subtotal
	, poolSum.order_id as gift_id -- can be used to tie this line item up to Cadmus
	, (CASE 
		WHEN (poolSum.lineitemtype_id = 1 AND (poolSum.sourceclass_id IS NULL OR poolSum.sourceclass_id != 22)) THEN 'GTGM'
		WHEN poolSum.sourceclass_id = 22 THEN 'Cart'
		WHEN (poolSum.lineitemtype_id = 8 AND (poolSum.sourceclass_id IS NULL OR poolSum.sourceclass_id != 22)) THEN 'Recurring' 
		ELSE 'Bogus' END) as gift_subtype
	, pa.authdate::DATE as date
	, poolSum.item_id as fund_id
	, poolSum.item_name as fund_description
FROM
	ecommerce.paymentauthorization as pa RIGHT JOIN poolSum on pa.authorization_id = poolSum.lineitem_authorization_id
	, ecommerce.rsorder AS o
WHERE 
	o.oid = pa.order_id AND pa.payment_status_id IN (3, 5, 6) and pa.payment_transaction_result_id = 1  and pa.authdate >= :startdate and pa.authdate < :enddate
ORDER BY poolSum.lineitem_id DESC;

