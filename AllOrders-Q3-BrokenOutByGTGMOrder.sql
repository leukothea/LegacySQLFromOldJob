with wrapper as (
with orderlevel as(
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
	AND pa.authdate >= '2016-07-01'
	AND pa.authdate < '2016-10-01'
	AND rsli.lineitemtype_id = 1
	AND rsli.productversion_id = pv.productversion_id
	AND pv.item_id = i.item_id
GROUP BY
	o.oid
),site_orders AS (
SELECT
	pa.amount as revenue
	,rsli.order_id as order_id
	,count(*) as items
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
	AND pa.authdate >= '2016-07-01'
	AND pa.authdate < '2016-10-01'
	AND rsli.lineitemtype_id = 1
	AND rsli.productversion_id = pv.productversion_id
	AND pv.item_id = i.item_id
GROUP BY
	pa.authdate
	,pa.amount
	,rsli.order_id
)  SELECT 
	oit.order_id
	, CASE WHEN oit.GTGM > 0 AND oit.nonGTGM = 0 THEN 'gtgm only'
	WHEN oit.GTGM > 0 AND oit.nonGTGM > 0 THEN 'mixed'
	WHEN oit.GTGM = 0 AND oit.nonGTGM > 0 THEN 'product only'
	ELSE 'bogus' END as order_type
	,so.revenue
	,so.items
FROM
	order_item_types oit	
	,site_orders so
WHERE
	oit.order_id = so.order_id
	) 

SELECT 
	orderlevel.order_id
	, (CASE WHEN orderlevel.order_type = 'gtgm only' THEN 1 ELSE 0 END) as gtgmonlyorders
	, (CASE WHEN orderlevel.order_type = 'gtgm only' THEN orderlevel.revenue ELSE 0 END) as gtgmonlyrevenue
	, (CASE WHEN orderlevel.order_type = 'mixed' THEN 1 ELSE 0 END) as mixedorders
	, (CASE WHEN orderlevel.order_type = 'mixed' THEN orderlevel.revenue ELSE 0 END) as mixedorderrevenue
	, (CASE WHEN orderlevel.order_type = 'product only' THEN 1 ELSE 0 END) as productonlyorders
	, (CASE WHEN orderlevel.order_type = 'product only' THEN orderlevel.revenue ELSE 0 END) as productonlyrevenue

FROM
	orderlevel as orderlevel	
WHERE
	true)
select 
	SUM(wrapper.gtgmonlyorders) as gtgmonlyorders
	, SUM(wrapper.gtgmonlyrevenue) as gtgmonlyrevenue
	, SUM(wrapper.mixedorders) as mixedorders
	, SUM(wrapper.mixedorderrevenue) as mixedorderrevenue
	, SUM(wrapper.productonlyorders) as productonlyorders
	, SUM(wrapper.productonlyrevenue) as productonlyrevenue
from
	wrapper
where
	true;