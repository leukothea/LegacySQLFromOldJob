
select 
	main.auth_date
	, main.day_of_week 
	,sum(main.us_order_count) as us_order_count
	, sum(main.intl_order_count) as intl_order_count
	, sum(main.total_order_count) as total_order_count 
	,sum(main.us_items_sold) as us_items_sold
	, sum(main.intl_items_sold) as intl_items_sold
	, sum(main.total_sold) as total_sold 
	,sum(main.us_sales_tax) as us_sales_tax
	, sum(main.intl_sales_tax) as intl_sales_tax
	, sum(main.total_sales_tax) as total_sales_tax 
	,sum(main.us_shipping) as us_shipping
	, sum(main.intl_shipping) as intl_shipping
	, sum(main.total_shipping) as total_shipping 
	,sum(main.us_adjustments) as us_adjustments
	, sum(main.intl_adjustments) as intl_adjustments
	, sum(main.shipping_adjustments) as shipping_adjustments 
	,sum(main.promotion_adjustments) as promotion_adjustments
	, sum(main.product_adjustments) as product_adjustments
	, sum(main.total_adjustments) as total_adjustments
	, sum(main.shipping_revenue) as shipping_revenue 
	,sum(main.us_payment_amount) as us_payment_amount
	, sum(main.intl_payment_amount) as intl_payment_amount 
	, sum(main.total_payment_amount as total_payment_amount)
	,CAST(CASE WHEN sum(main.total_gross_revenue) > 0 THEN (sum(main.intl_gross_revenue) / sum(main.total_gross_revenue)) ELSE 0 END AS numeric(10,2)) AS percent_intl_gross_sales 
	,sum(main.us_gross_revenue) as us_gross_revenue
	, sum(main.intl_gross_revenue) as intl_gross_revenue
	, sum(main.total_gross_revenue) as total_gross_revenue 
	,sum(main.us_customer_price) as us_customer_price
	, sum(main.intl_customer_price) as intl_customer_price
	, sum(main.total_customer_price) as total_customer_price 
	,SUM(main.amount_credited) as amount_credited 
	,(SUM(main.total_gross_revenue) - SUM(main.amount_credited) - SUM(main.total_sales_tax))::numeric(10,2) AS simple_gross_revenue 
	,main.store_name 
	,main.site_abbrv 

from (  
	WITH brokenOutOrders AS (  
		WITH lineitem AS (  
			WITH lineitemadj AS (
				select 
					li.oid AS lineitem_id
					, sum(ra.amount) AS adjustment 
				from 
					ecommerce.RSLineItem li
					, ecommerce.RSAdjustment as ra
					, ecommerce.paymentauthorization as pa 
					,ecommerce.rsorder as o
					, ecommerce.site as st 
				where 
					li.order_id = pa.order_id 
					and li.oid = ra.lineItem_id 
					and pa.payment_transaction_result_id = 1 
					and pa.payment_status_id in (3,5,6)  
					and pa.authdate >= '06/01/2016'  
					and pa.authdate < '07/01/2016'  
					and li.order_id = o.oid 
					and o.site_id = st.site_id  
					and st.abbreviation IN ('THS', 'BCS', 'ARS', 'CHS', 'DBS', 'TRS', 'LIT', 'VET', 'AUT', 'ALZ', 'TES') 
				group by 
					li.oid 
 			)
 		select 
 			li.order_id
 			, li.oid as lineitem_id
 			, li.quantity as lineitem_quantity
 			, li.customerprice
 			, ((li.quantity * li.customerPrice) - COALESCE(lineitemadj.adjustment,0.00)) AS lineitem_subtotal 
		from 
			ecommerce.rslineitem as li 
				LEFT OUTER JOIN lineitemadj ON li.oid = lineitemadj.lineitem_id
			, ecommerce.rsorder as o
			, ecommerce.paymentauthorization as pa 
			,ecommerce.site as st 
		where 
			li.order_id = o.oid 
			and o.oid = pa.order_id  
			and pa.authdate >= '06/01/2016'  
			and pa.authdate < '07/01/2016'  
			and o.site_id = st.site_id  
			and st.abbreviation IN ('THS', 'BCS', 'ARS', 'CHS', 'DBS', 'TRS', 'LIT', 'VET', 'AUT', 'ALZ', 'TES') 
		group by 
			li.order_id
			, li.oid
			, li.quantity
			, li.customerprice
			, lineitemadj.adjustment 
		order by 
			li.order_id asc 
 		)
 	, shipadj AS (
 		select 
 			o.oid as order_id
 			, COALESCE(ra.amount, 0.00) as shipping_adjustment 
		from 
			ecommerce.RSOrder as o
			, ecommerce.paymentauthorization as pa
			, ecommerce.RSAdjustment as ra 
			,ecommerce.site as st 
		where 
			o.oid = pa.order_id 
			and o.oid = ra.order_id 
			and ra.adjustment_type_id = 6  
			and pa.payment_transaction_result_id = 1 
			and pa.payment_status_id in (3, 5, 6)  
			and pa.authdate >= '06/01/2016'  
			and pa.authdate < '07/01/2016'  
			and o.site_id = st.site_id  
			and st.abbreviation IN ('THS', 'BCS', 'ARS', 'CHS', 'DBS', 'TRS', 'LIT', 'VET', 'AUT', 'ALZ', 'TES') 
 		)
 	, promadj AS (
 		select 
 			o.oid as order_id
 			, COALESCE(ra.amount,0.00) as promotion_adjustment 
		from 
			ecommerce.RSOrder as o
			, ecommerce.paymentauthorization as pa
			, ecommerce.RSAdjustment as ra 
			,ecommerce.site as st 
		where 
			o.oid = pa.order_id 
			and o.oid = ra.order_id 
			and ra.adjustment_type_id = 1  
			and pa.payment_transaction_result_id = 1 
			and pa.payment_status_id in (3,5,6)  
			and pa.authdate >= '06/01/2016'  
			and pa.authdate < '07/01/2016'  
			and o.site_id = st.site_id  
			and st.abbreviation IN ('THS', 'BCS', 'ARS', 'CHS', 'DBS', 'TRS', 'LIT', 'VET', 'AUT', 'ALZ', 'TES') 
 		)
 	, credit AS (
 		select 
 			pa.order_id as order_id
 			, COALESCE(pt.amount,0) as amount_credited 
		from 
			ecommerce.paymentauthorization as pa
			, ecommerce.paymenttransaction as pt
			, ecommerce.payment_transaction_result as r
			, ecommerce.payment_transaction_type as t 
		where 
			pa.authorization_id = pt.authorization_id 
			and pt.payment_transaction_type_id = t.payment_transaction_type_id 
			and pt.payment_transaction_result_id = r.payment_transaction_result_id  
			and pa.payment_transaction_result_id = 1 
			and pa.payment_status_id in (3,5,6) 
			and pt.payment_transaction_type_id = 5  
			and pa.authdate >= '06/01/2016'  
			and pa.authdate < '07/01/2016' 
 		)
 	select 
 		o.oid AS order_id
 		, sum(lineitem.lineitem_quantity) as lineitem_quantity
 		, sum(lineitem.lineitem_subtotal) as lineitem_total 
 		,pa.amount as base_amount_paid
 		, COALESCE(o.shippingcost,0) as base_shipping
 		, COALESCE(shipadj.shipping_adjustment,0) AS shipping_adjustment
 		, COALESCE(o.shippingcost,0) - COALESCE(shipadj.shipping_adjustment,0) as amount_paid_for_shipping 
 		,COALESCE(promadj.promotion_adjustment,0) AS promotion_adjustment
 		, st.abbreviation as site_abbrv
 		, COALESCE(ash.iso_country_code,'US') AS country 
 		,COALESCE(credit.amount_credited,0) as amount_credited 
 		,(CASE WHEN ash.iso_country_code = 'US' THEN 1 ELSE 0 END) as us_order_count
 		, (CASE WHEN ash.iso_country_code != 'US' THEN 1 ELSE 0 END) as intl_order_count 
	from 
		ecommerce.RSOrder as o 
			LEFT OUTER JOIN ecommerce.RSAddress as ash ON COALESCE(o.shippingaddress_id, o.billingaddress_id) = ash.oid 
			LEFT OUTER JOIN shipadj ON o.oid = shipadj.order_id 
			LEFT OUTER JOIN promadj ON o.oid = promadj.order_id 
			LEFT OUTER JOIN lineitem ON o.oid = lineitem.order_id 
			LEFT OUTER JOIN credit ON o.oid = credit.order_id 
		,ecommerce.site as st
		, ecommerce.PaymentAuthorization as pa 
	where 
		o.oid = pa.order_id 
		and o.site_id = st.site_id 
		and pa.payment_transaction_result_id = 1 
		and pa.payment_status_id in (3,5,6)  
		and pa.authdate >= '06/01/2016'  
		and pa.authdate < '07/01/2016'  
		and st.abbreviation IN ('THS', 'BCS', 'ARS', 'CHS', 'DBS', 'TRS', 'LIT', 'VET', 'AUT', 'ALZ', 'TES') 
	group by 
		o.oid
		, pa.amount
		, promadj.promotion_adjustment
		, shipadj.shipping_adjustment
		, credit.amount_credited
		, ash.iso_country_code
		, st.abbreviation 
	order by 
		o.oid asc 
 	)
	select distinct 
		pa.authdate::DATE AS auth_date 
		,to_char(pa.authdate::DATE,'Dy') AS day_of_week 
		,SUM(brokenOutOrders.us_order_count) AS us_order_count 
		,SUM(brokenOutOrders.intl_order_count) AS intl_order_count 
		,count(o.oid) AS total_order_count 
		,SUM(brokenOutOrders.lineitem_quantity * (position(brokenOutOrders.country IN 'US') * position('US' IN brokenOutOrders.country))) AS us_items_sold 
		,SUM(brokenOutOrders.lineitem_quantity * (1 - position(brokenOutOrders.country IN 'US') * position('US' IN brokenOutOrders.country))) AS intl_items_sold 
		,SUM(brokenOutOrders.lineitem_quantity) AS total_sold 
		,SUM(o.tax * (position(brokenOutOrders.country IN 'US') * position('US' IN brokenOutOrders.country))) AS us_sales_tax 
		,SUM(o.tax * (1 - position(brokenOutOrders.country IN 'US') * position('US' IN brokenOutOrders.country))) AS intl_sales_tax 
		,SUM(o.tax) AS total_sales_tax 
		,SUM((brokenOutOrders.amount_paid_for_shipping) * (position(brokenOutOrders.country IN 'US') * position('US' IN brokenOutOrders.country))) AS us_shipping 
		,SUM((brokenOutOrders.amount_paid_for_shipping) * (1 - position(brokenOutOrders.country IN 'US') * position('US' IN brokenOutOrders.country))) AS intl_shipping 
		,SUM(o.shippingcost) AS total_shipping 
		,SUM(o.adjustmentamount * (position(brokenOutOrders.country IN 'US') * position('US' IN brokenOutOrders.country))) AS us_adjustments 
		,SUM(o.adjustmentamount * (1 - position(brokenOutOrders.country IN 'US') * position('US' IN brokenOutOrders.country))) AS intl_adjustments 
		,SUM(COALESCE(brokenOutOrders.shipping_adjustment,0.00)) AS shipping_adjustments 
		,SUM(COALESCE(brokenOutOrders.promotion_adjustment,0.00)) AS promotion_adjustments 
		,SUM(o.adjustmentamount - COALESCE(brokenOutOrders.shipping_adjustment,0.00) - COALESCE(brokenOutOrders.promotion_adjustment,0.00)) AS product_adjustments 
		,SUM(o.adjustmentamount) AS total_adjustments 
		,SUM(brokenOutOrders.amount_paid_for_shipping) AS shipping_revenue 
		,SUM(pa.amount * (position(brokenOutOrders.country IN 'US') * position('US' IN brokenOutOrders.country))) AS us_payment_amount 
		,SUM(pa.amount * (1 - position(brokenOutOrders.country IN 'US') * position('US' IN brokenOutOrders.country))) AS intl_payment_amount 
		,SUM(pa.amount) AS total_payment_amount 
		,SUM(brokenOutOrders.lineitem_total) AS lineitem_total 
		,SUM((COALESCE(pa.amount,0.00) - COALESCE(brokenOutOrders.amount_paid_for_shipping,0.00) - COALESCE(brokenOutOrders.shipping_adjustment,0.00) - COALESCE(brokenOutOrders.promotion_adjustment,0.00))  * (position(brokenOutOrders.country IN 'US') * position('US' IN brokenOutOrders.country))) AS us_gross_revenue 
		,SUM((COALESCE(pa.amount,0.00) - COALESCE(brokenOutOrders.amount_paid_for_shipping,0.00) - COALESCE(brokenOutOrders.shipping_adjustment,0.00) - COALESCE(brokenOutOrders.promotion_adjustment,0.00))  * (1 - position(brokenOutOrders.country IN 'US') * position('US' IN brokenOutOrders.country))) AS intl_gross_revenue 
		,SUM(COALESCE(pa.amount,0.00) - COALESCE(brokenOutOrders.amount_paid_for_shipping,0.00) - COALESCE(brokenOutOrders.shipping_adjustment,0.00) - COALESCE(brokenOutOrders.promotion_adjustment,0.00)) AS total_gross_revenue 
		,SUM((COALESCE(pa.amount,0.00)) * (position(brokenOutOrders.country IN 'US') * position('US' IN brokenOutOrders.country))) AS us_customer_price 
		,SUM((COALESCE(pa.amount,0.00)) * (1 - position(brokenOutOrders.country IN 'US') * position('US' IN brokenOutOrders.country))) AS intl_customer_price 
		,SUM(COALESCE(brokenOutOrders.amount_credited,0)) as amount_credited 
		,SUM(COALESCE(pa.amount,0.00)) AS total_customer_price 
		,st.name as store_name 
		,si.abbreviation as site_abbrv 
	from 
		ecommerce.RSOrder as o 
			LEFT OUTER JOIN brokenOutOrders ON o.oid = brokenOutOrders.order_id
		, ecommerce.paymentauthorization as pa 
		,ecommerce.store as st 
		,ecommerce.site as si 
	where 
		pa.authdate IS NOT NULL 
		and o.oid = pa.order_id 
		and pa.payment_transaction_result_id = 1 
		and pa.payment_status_id in (3, 5, 6)   
		and pa.authdate >= '06/01/2016'  
		and pa.authdate < '07/01/2016'  
		and o.store_id = st.store_id  
		and st.name = 'CTDStore'  
		and o.site_id = si.site_id  
		and si.abbreviation IN ('THS', 'BCS', 'ARS', 'CHS', 'DBS', 'TRS', 'LIT', 'VET', 'AUT', 'ALZ', 'TES') 
	group by 
		pa.authdate::DATE 
		,to_char(pa.authdate::DATE,'Dy') 
		,st.name 
		,si.abbreviation 
	order by 
		pa.authdate::DATE asc
) as main 
where 
	true  
	and main.site_abbrv IN ('THS', 'BCS', 'ARS', 'CHS', 'DBS', 'TRS', 'LIT', 'VET', 'AUT', 'ALZ', 'TES') 
group by 
	main.auth_date
	, main.day_of_week 
	,main.store_name 
	,main.site_abbrv 
order by 
	main.auth_date asc 
 