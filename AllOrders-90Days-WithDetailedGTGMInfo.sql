with wrapper as (
WITH order_item_types AS (
SELECT
	o.oid as order_id
	,SUM(CASE WHEN i.itembitmask & 32 = 32 THEN 1 ELSE 0 END) as GTGM
	,SUM(CASE WHEN i.itembitmask & 32 = 32 THEN 0 ELSE 1 END) as nonGTGM
FROM
	ecommerce.rsorder o
	,ecommerce.paymentauthorization pa
	,ecommerce.rslineitem rsli
	,ecommerce.productversion pv
	,ecommerce.item i
WHERE
	o.oid = rsli.order_id
	AND pa.order_id = o.oid
	AND pa.payment_status_id in (3,5,6)
	and pa.authDate >= '2016-07-01'
	and pa.authDate < '2016-10-01'
	AND rsli.lineitemtype_id = 1
	AND rsli.productversion_id = pv.productversion_id
	AND pv.item_id = i.item_id
GROUP BY
	o.oid
),
stuff as (
with orderdetail as 
(select 
			li.oid as lineitem_id 
			, li.order_id
			, pa.authDate::DATE AS auth_date 
			, (CASE WHEN i.itembitmask & 32 != 32 THEN li.quantity ELSE 0 END) as nongtgmlines
			, (CASE WHEN i.itembitmask & 32 != 32 THEN li.quantity * li.customerprice ELSE 0 END) as nongtgmsum
			, (CASE WHEN i.itembitmask & 32 = 32 AND li.lineitemtype_id = 1 AND (sli.sourceclass_id != 22 OR sli.sourceclass_id IS NULL) THEN li.quantity ELSE 0 END) as realgtgmlines
			, (CASE WHEN i.itembitmask & 32 = 32 AND li.lineitemtype_id = 1 AND (sli.sourceclass_id != 22 OR sli.sourceclass_id IS NULL) THEN (li.quantity * li.customerprice) ELSE 0 END) as realgtgmsum
			, (CASE WHEN i.itembitmask & 32 = 32 AND li.lineitemtype_id = 1 AND sli.sourceclass_id = 22 THEN li.quantity ELSE 0 END) as checkboxgtgms
			, (CASE WHEN i.itembitmask & 32 = 32 AND li.lineitemtype_id = 1 AND sli.sourceclass_id = 22 THEN (li.quantity * li.customerprice) ELSE 0 END) as checkboxgtgmsum
		from 
			ecommerce.RSOrder AS o
			, ecommerce.SiteLineItem as sli 
			,ecommerce.RSLineItem as li
			, ecommerce.productversion as pv
			, ecommerce.item as i
			, ecommerce.PaymentAuthorization as pa
		where 
			o.oid = li.order_id 
			and li.oid = sli.lineItem_id 
			and li.productversion_id = pv.productversion_id 
			and pv.item_id = i.item_id
			and o.oid = pa.order_id 
			and pa.payment_transaction_result_id = 1 
			and pa.payment_status_id in (3,5,6) 
			and pa.authDate >= '2016-07-01'
			and pa.authDate < '2016-10-01'
			and i.item_id != 1348
		group by 
			o.oid
			, li.oid
			, li.order_id
			, pa.authDate::DATE
			, li.quantity
			, i.itembitmask
			, li.customerprice
			, li.lineitemtype_id
			, sli.sourceclass_id
		order by 
			o.oid desc 
		)
	select 
		orderdetail.order_id
		, orderdetail.auth_date
		, sum(orderdetail.nongtgmlines) as nongtgmlines
		, sum(orderdetail.nongtgmsum) as nongtgmsum
		, sum(orderdetail.realgtgmlines) as realgtgmlines
		, sum(orderdetail.realgtgmsum) as realgtgmsum
		, sum(orderdetail.checkboxgtgms) as checkboxgtgms
		, sum(orderdetail.checkboxgtgmsum) as checkboxgtgmsum
	from
		orderdetail
	where 
		true
	group by 
		orderdetail.order_id
		, orderdetail.auth_date 
	order by 
		orderdetail.order_id desc
)
SELECT 
	oit.order_id
	, (CASE WHEN oit.GTGM > 0 AND oit.nonGTGM = 0 THEN 1 ELSE 0 END) as gtgmonlyorders
	, (CASE WHEN oit.GTGM > 0 AND oit.nonGTGM > 0 THEN 1 ELSE 0 END) as mixedorders
	, (CASE WHEN oit.GTGM = 0 AND oit.nonGTGM > 0 THEN 1 ELSE 0 END) as productonlyorders
	, s.nongtgmlines
	, s.nongtgmsum
	, s.realgtgmlines
	, s.realgtgmsum
	, s.checkboxgtgms
	, s.checkboxgtgmsum
FROM
	order_item_types as oit	
	, stuff as s
WHERE
	oit.order_id = s.order_id
GROUP BY 
	oit.order_id
	, oit.gtgm
	, oit.nonGTGM
	, s.nongtgmlines
	, s.nongtgmsum
	, s.realgtgmlines
	, s.realgtgmsum
	, s.checkboxgtgms
	, s.checkboxgtgmsum
ORDER BY oit.order_id desc)
select 
	sum(wrapper.gtgmonlyorders) as gtgmonlyorders
	, sum(wrapper.mixedorders) as mixedorders
	, sum(wrapper.productonlyorders) as productonlyorders
	, sum(wrapper.nongtgmlines) as nongtgmlines
	, sum(wrapper.nongtgmsum) as nongtgmsum
	, sum(wrapper.realgtgmlines) as realgtgmlines
	, sum(wrapper.realgtgmsum) as realgtgmsum
	, sum(wrapper.checkboxgtgms) as checkboxgtgms
	, sum(wrapper.checkboxgtgmsum) as checkboxgtgmsum
FROM
	wrapper
WHERE
	true;