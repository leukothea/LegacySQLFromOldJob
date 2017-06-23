with wrapper as (
	with orderlevel as(
		WITH order_item_types AS (
SELECT
				o.oid as order_id
				,SUM(CASE WHEN (i.itembitmask & 32 = 32 AND rsli.lineitemtype_id = 1 AND (sli.sourceclass_id != 22 OR sli.sourceclass_id IS NULL)) THEN rsli.quantity ELSE 0 END) as realGTGM
				,SUM(CASE WHEN (i.itembitmask & 32 = 32 AND rsli.lineitemtype_id = 1 AND (sli.sourceclass_id != 22 OR sli.sourceclass_id IS NULL)) THEN (rsli.quantity * rsli.customerprice) ELSE 0 END) as realGTGMrev
				,SUM(CASE WHEN (i.itembitmask & 32 = 32 AND rsli.lineitemtype_id = 1 AND sli.sourceclass_id = 22 ) THEN rsli.quantity ELSE 0 END) as checkboxGTGM
				,SUM(CASE WHEN (i.itembitmask & 32 = 32 AND rsli.lineitemtype_id = 1 AND sli.sourceclass_id = 22 ) THEN (rsli.quantity * rsli.customerprice) ELSE 0 END) as checkboxGTGMrev
				,SUM(CASE WHEN (i.name ILIKE 'Extra Donation%' AND rsli.lineitemtype_id = 5) THEN rsli.quantity ELSE 0 END) as freebieGTGM
				,SUM(CASE WHEN (i.name ILIKE 'Extra Donation%' AND rsli.lineitemtype_id = 5) THEN (rsli.quantity * rsli.customerprice) ELSE 0 END) as freebieGTGMrev
				,SUM(CASE WHEN (i.itembitmask & 32 != 32 AND i.name NOT ILIKE 'Extra Donation%' AND rsli.customerprice = 0.0000 AND rsli.lineitemtype_id = 5) THEN rsli.quantity ELSE 0 END) as freebieproduct
				,SUM(CASE WHEN (i.itembitmask & 32 != 32 AND i.name NOT ILIKE 'Extra Donation%' AND rsli.customerprice = 0.0000 AND rsli.lineitemtype_id = 5) THEN (rsli.quantity * rsli.customerprice) ELSE 0 END) as freebieproductrev
				,SUM(CASE WHEN (i.itembitmask & 32 != 32 AND i.name NOT ILIKE 'Extra Donation%' AND rsli.customerprice > 0 AND rsli.lineitemtype_id IN (1, 5)) THEN rsli.quantity ELSE 0 END) as realproduct
				,SUM(CASE WHEN (i.itembitmask & 32 != 32 AND i.name NOT ILIKE 'Extra Donation%' AND rsli.customerprice > 0 AND rsli.lineitemtype_id IN (1, 5)) THEN (rsli.quantity * rsli.customerprice) ELSE 0 END) as realproductrev
			FROM
				ecommerce.rsorder o
				,ecommerce.paymentauthorization pa
				,ecommerce.rslineitem rsli
				,ecommerce.sitelineitem sli 
				,ecommerce.productversion pv
				,ecommerce.item i
			WHERE
				o.oid = rsli.order_id
				and rsli.oid = sli.lineItem_id 
				AND pa.order_id = o.oid
				AND pa.payment_status_id in (3,5,6)
				AND pa.authdate >= '2016-07-01'
				AND pa.authdate < '2016-10-01'
				AND rsli.lineitemtype_id IN (1, 5)
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
				AND rsli.lineitemtype_id IN (1, 5)
				AND rsli.productversion_id = pv.productversion_id
				AND pv.item_id = i.item_id
			GROUP BY
				pa.authdate
				,pa.amount
				,rsli.order_id
	) SELECT 
		oit.order_id
		, CASE WHEN (oit.realGTGM > 0 OR oit.checkboxGTGM > 0 OR oit.freebieGTGM > 0) AND oit.realproduct = 0 THEN 'gtgm only'
			WHEN oit.realGTGM > 0 AND oit.checkboxGTGM = 0 AND oit.realproduct > 0 THEN 'mixed_product_and_realGTGMonly'
			WHEN oit.realGTGM = 0 AND oit.checkboxGTGM > 0 AND oit.realproduct > 0 THEN 'mixed_product_and_checkboxGTGMonly'
			WHEN oit.realGTGM > 0 AND oit.checkboxGTGM > 0 AND oit.realproduct > 0 THEN 'mixed_product_real_and_checkboxGTGM'
			WHEN (oit.realGTGM = 0 AND oit.checkboxGTGM = 0) AND oit.realproduct > 0 THEN 'product only'
			ELSE 'bogus' END as order_type
		,so.revenue
		,so.items
	FROM
		order_item_types AS oit	
		,site_orders AS so
	WHERE
		oit.order_id = so.order_id
	GROUP BY 
		oit.order_id
		, oit.realGTGM
		, oit.checkboxGTGM
		, oit.freebieGTGM
		, oit.realproduct
		, so.revenue
		, so.items
	) 

	SELECT 
		orderlevel.order_id
		, (CASE WHEN orderlevel.order_type = 'gtgm only' THEN 1 ELSE 0 END) as gtgmonlyorders
		, (CASE WHEN orderlevel.order_type = 'gtgm only' THEN orderlevel.revenue ELSE 0 END) as gtgmonlyrevenue
		, (CASE WHEN orderlevel.order_type = 'mixed_product_and_realGTGMonly' THEN 1 ELSE 0 END) as mixed_product_and_realGTGMonly 
		, (CASE WHEN orderlevel.order_type = 'mixed_product_and_realGTGMonly' THEN orderlevel.revenue ELSE 0 END) as mixed_product_and_realGTGMrev
		, (CASE WHEN orderlevel.order_type = 'mixed_product_and_checkboxGTGMonly' THEN 1 ELSE 0 END) as mixed_product_and_checkboxGTGMonly 
		, (CASE WHEN orderlevel.order_type = 'mixed_product_and_checkboxGTGMonly' THEN orderlevel.revenue ELSE 0 END) as mixed_product_and_checkboxGTGMonlyrev
		, (CASE WHEN orderlevel.order_type = 'mixed_product_real_and_checkboxGTGM' THEN 1 ELSE 0 END) as mixed_product_real_and_checkboxGTGM 
		, (CASE WHEN orderlevel.order_type = 'mixed_product_real_and_checkboxGTGM' THEN orderlevel.revenue ELSE 0 END) as mixed_product_real_and_checkboxGTGMrev
		, (CASE WHEN orderlevel.order_type = 'product only' THEN 1 ELSE 0 END) as productonlyorders
		, (CASE WHEN orderlevel.order_type = 'product only' THEN orderlevel.revenue ELSE 0 END) as productonlyrevenue

	FROM
		orderlevel as orderlevel	
	WHERE
		true)
select 
	SUM(wrapper.gtgmonlyorders) as gtgmonlyorders
	, SUM(wrapper.gtgmonlyrevenue) as gtgmonlyrevenue
	, SUM(wrapper.mixed_product_and_realGTGMonly) as mixed_product_and_realGTGMonly
	, SUM(wrapper.mixed_product_and_realGTGMrev) as mixed_product_and_realGTGMrev
	, SUM(wrapper.mixed_product_and_checkboxGTGMonly) as mixed_product_and_checkboxGTGMonly
	, SUM(wrapper.mixed_product_and_checkboxGTGMonlyrev) as mixed_product_and_checkboxGTGMonlyrev
	, SUM(wrapper.mixed_product_real_and_checkboxGTGM) as mixed_product_real_and_checkboxGTGM
	, SUM(wrapper.mixed_product_real_and_checkboxGTGMrev) as mixed_product_real_and_checkboxGTGMrev
	, SUM(wrapper.productonlyorders) as productonlyorders
	, SUM(wrapper.productonlyrevenue) as productonlyrevenue
from
	wrapper
where
	true;