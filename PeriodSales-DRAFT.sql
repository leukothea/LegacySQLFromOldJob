
  WITH s AS (
  	select 
  		o.store_id
  		, li.order_id
  		, pa.authDate::DATE AS auth_date 
  		,sum(li.quantity) AS items_sold
  		, round((sum(li.customerPrice * li.quantity))::numeric,2) AS customer_price 
  		,t.name AS store
	from 
		ecommerce.RSOrder AS o
		, ecommerce.SiteLineItem as sli 
		,ecommerce.RSLineItem as li
		, ecommerce.PaymentAuthorization as pa
		, ecommerce.ProductVersion as pv 
		,ecommerce.store as t 
	where 
		o.oid = li.order_id 
		and li.oid = sli.lineItem_id  
		and li.productversion_id = pv.productversion_id 
		and o.oid = pa.order_id 
		and pa.payment_transaction_result_id = 1 
		and pa.payment_status_id in (3,5,6) 
		and pa.authDate >= now()::DATE - cast('0 day' as interval) 
		and pa.authDate > now()::DATE 
		and o.order_source_id IN (1,5) 
		and o.store_id = t.store_id  
		and pv.item_id != 1348
	group by 
		o.store_id
		, li.order_id
		, pa.authDate::DATE 
		,t.name
 	)
 , ry AS (  
 		WITH rysub AS (
 			select 
 				li.order_id
 				, sum(COALESCE(sli.quantity,0.00) * coalesce(df.royaltyFactor,0.00)) AS royalty 
 				,t.name AS store
			from 
				ecommerce.rsorder as o
				, ecommerce.RSLineItem as li
				, ecommerce.SiteLineItem as sli
				, ecommerce.DonationFactor as df
				, ecommerce.PaymentAuthorization as pa
				, ecommerce.productversion as pv
				, ecommerce.item as i 
				,ecommerce.store as t 
			where 
				li.order_id = o.oid 
				and li.oid = sli.lineItem_id 
				and sli.site_id = df.site_id 
				and li.productversion_id = pv.productversion_id 
				and pv.item_id = i.item_id 
				and pa.order_id = li.order_id  
				and COALESCE(li.customerprice,0.00) >= df.minPrice 
				and COALESCE(li.customerprice,0.00) < df.maxPrice  
				and i.itembitmask &2 != 2  
				and pa.authDate >= now()::DATE - cast('0 day' as interval) 
				and pa.authDate > now()::DATE 
				and pa.payment_transaction_result_id = 1 
				and pa.payment_status_id in (3,5,6)  
				and o.order_source_id IN (1,5) 
				and o.store_id = t.store_id 
			group by 
				li.order_id,
				t.name
 			)
 		select 
 			coalesce(sum(rysub.royalty),0.00) as royalty
 			, pa.authDate::DATE AS auth_date 
 			,t.name AS store
		from 
			ecommerce.rsorder as o LEFT OUTER JOIN rysub ON o.oid = rysub.order_id
			, ecommerce.paymentauthorization as pa
			, ecommerce.site as si 
			,ecommerce.store as t 
		where 
			o.oid = pa.order_id 
			and o.site_id = si.site_id 
			and pa.payment_transaction_result_id = 1 
			and pa.payment_status_id IN (3, 5, 6)  
			and pa.authDate >= now()::DATE - cast('0 day' as interval) 
			and pa.authDate > now()::DATE 
			and o.order_source_id IN (1,5) 
			and o.store_id = t.store_id 
		group by 
			pa.authdate::DATE 
			,t.name
 		)
select 
	s.auth_date AS auth_date
	,count(*) AS orders
	, sum(s.items_sold) AS items
	,round((sum(s.customer_price))::numeric,2) AS customer_price
	,round((COALESCE(ry.royalty,0.00))::numeric,2) AS royalty
	,round((sum(COALESCE(o.shippingCost,0.00)))::numeric,2) AS shipping
	,round((sum(COALESCE(o.tax,0.00)))::numeric,2) AS tax
	,round((sum(COALESCE(o.adjustmentAmount,0.00)))::numeric,2) AS adjust
	,round((sum(pa.amount - COALESCE(o.tax,0.00)))::numeric,2) AS gross_revenue
	,round((sum(pa.amount - COALESCE(o.tax,0.00))/count(*))::numeric,2) AS avg_order
	,os.order_source as order_source 
	,t.name AS store
from 
	ecommerce.rsorder as o LEFT OUTER JOIN s on o.oid = s.order_id
	, ecommerce.store as t
	, ecommerce.paymentauthorization as pa LEFT OUTER JOIN ry ON pa.authDate::DATE = ry.auth_date::DATE
	, ecommerce.site as si 
	,ecommerce.order_source as os 
where 
	o.oid = s.order_id 
	and o.site_id = si.site_id 
	and o.store_id = t.store_id 
	and o.oid = pa.order_id 
	and pa.payment_transaction_result_id = 1 
	and pa.payment_status_id in (3,5,6) 
	and pa.authDate >= now()::DATE - cast('0 day' as interval) 
	and pa.authDate > now()::DATE 
	and o.order_source_id = os.order_source_id 
	and o.order_source_id IN (1,5)
group by 
	s.auth_date
	, ry.royalty
	,os.order_source 
	,t.name
order by 
	s.auth_date