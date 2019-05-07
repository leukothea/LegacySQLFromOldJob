
  WITH ry AS (
  	select 
  		li.order_id
  		, sum(COALESCE(sli.quantity,0.00) * coalesce(df.royaltyFactor,0.00)) AS royalty 
	from 
		ecommerce.RSLineItem as li
		, ecommerce.SiteLineItem as sli
		, ecommerce.DonationFactor as df
		, ecommerce.PaymentAuthorization as pa
		, ecommerce.productversion as pv
		, ecommerce.item as i 
	where 
		li.oid = sli.lineItem_id 
		and sli.site_id = df.site_id 
		and li.productversion_id = pv.productversion_id 
		and pv.item_id = i.item_id 
		and pa.order_id = li.order_id  
		and COALESCE(li.customerprice,0.00) >= df.minPrice 
		and COALESCE(li.customerprice,0.00) < df.maxPrice  
		and i.itembitmask &2 != 2  
		and pa.authDate >= now()::DATE - cast('1 day' as interval) 
		and pa.authDate < now()::DATE 
		and pa.payment_transaction_result_id = 1 
		and pa.payment_status_id in (3,5,6)
	group by 
		li.order_id
	 )
 , gtgm AS (
 	select 
 		li.order_id
 		, sum(li.customerPrice * li.quantity) as gtgm_total 
	from 
		ecommerce.rslineitem as li
		, ecommerce.productversion as pv
		, ecommerce.item as i
		, ecommerce.PaymentAuthorization as pa
		, ecommerce.rsorder as o4 
	where 
		li.order_id = o4.oid 
		and li.productversion_id = pv.productversion_id 
		and pv.item_id = i.item_id 
		and i.itembitmask & 32 = 32 
		and pa.order_id = li.order_id  
		and pa.authDate >= now()::DATE - cast('1 day' as interval) 
		and pa.authDate < now()::DATE 
		and pa.payment_transaction_result_id = 1 
		and pa.payment_status_id in (3,5,6) 
	group by 
		li.order_id 
 	)
 , noShipPromo AS (  
 		WITH q AS (
 			select 
 				o11.oid
 				, true as to_exclude 
			from 
				ecommerce.rsorder as o11
				, ecommerce.promotion as p11
				, ecommerce.orderpromotion as op11
				, ecommerce.promotionaction as pact11
				, ecommerce.paymentauthorization as pa 
			where 
				o11.oid = pa.order_id 
				and o11.oid = op11.order_id 
				and op11.promotion_id = p11.promotion_id 
				and p11.promotion_id = pact11.promotion_id 
				and pa.payment_transaction_result_id = 1 
				and pa.payment_status_id IN (3, 5, 6) 
				and pact11.inputparam ILIKE 'SHIPPING%'  
				and pa.authDate >= now()::DATE - cast('1 day' as interval) 
				and pa.authDate < now()::DATE
			group by 
				o11.oid 
 		)
 		select 
 			o1.oid as order_id
 			, o1.shippingcost
 			, o1.shippingcost AS shipping_price 
		from 
			ecommerce.rsorder as o1 
			LEFT OUTER JOIN q ON o1.oid = q.oid
			, ecommerce.paymentauthorization as pa 
		where 
			o1.oid = pa.order_id 
			and pa.payment_transaction_result_id = 1 
			and pa.payment_status_id IN (3, 5, 6)  
			and pa.authDate >= now()::DATE - cast('1 day' as interval) 
			and pa.authDate < now()::DATE
		group by 
			o1.oid
			, o1.shippingcost 
 	)
 , shippingPrice AS (
 		select 
 			o2.oid as order_id
 			, adj.promotion_id 
 			, o2.shippingcost
 			, pact.inputparam
 			, pact.amount
 			, sum(pact.amount) AS shipping_price 
		from 
			ecommerce.rsorder as o2
			, ecommerce.orderpromotion as op
			, ecommerce.rsadjustment as adj
			, ecommerce.promotion as p
			, ecommerce.promotionaction as pact
			, ecommerce.paymentauthorization as pa 
		where 
			o2.oid = adj.order_id 
			and o2.oid = op.order_id 
			and op.promotion_id = p.promotion_id 
			and p.promotion_id = pact.promotion_id 
			and o2.oid = pa.order_id 
			and pa.payment_transaction_result_id = 1 
			and pa.payment_status_id IN (3, 5, 6) 
			and pact.inputparam = 'SHIPPING_PRICE'  
			and pa.authDate >= now()::DATE - cast('1 day' as interval) 
			and pa.authDate < now()::DATE
		group by 
			o2.oid
			, adj.promotion_id
			, o2.shippingcost
			, pact.inputparam
			, pact.amount 
 	)
 , shippingDiscount AS (
 		select 
 			o3.oid as order_id
 			, adj.promotion_id 
 			, o3.shippingcost
 			, -(adj.amount) AS shipping_price 
		from 
			ecommerce.rsorder as o3
			, ecommerce.orderpromotion as op
			, ecommerce.rsadjustment as adj
			, ecommerce.promotion as p
			, ecommerce.promotionaction as pact
			, ecommerce.paymentauthorization as pa 
		where 
			o3.oid = adj.order_id 
			and o3.oid = op.order_id 
			and op.promotion_id = p.promotion_id 
			and p.promotion_id = pact.promotion_id 
			and o3.oid = pa.order_id 
			and pa.payment_transaction_result_id = 1 
			and pa.payment_status_id IN (3, 5, 6) 
			and adj.adjustment_type_id = 6 
			and pact.inputparam = 'SHIPPING_DISCOUNT'  
			and pa.authDate >= now()::DATE - cast('1 day' as interval) 
			and pa.authDate < now()::DATE
		group by 
			o3.oid
			, adj.promotion_id
			, o3.shippingcost
			, adj.amount 
 	)
select 
	'' as sale_date
	,COALESCE(o.originCode,'No Origin Code') AS origin_code
	,count(distinct o.oid) AS order_count
	, sum(pa.amount) AS auth_amount
	, sum(coalesce(shippingPrice.shipping_price,noShipPromo.shipping_price)) as order_shipping_amount
	, sum(coalesce(shippingDiscount.shipping_price,0.00)) as promo_shipping_discount
	, (sum(coalesce(shippingPrice.shipping_price,noShipPromo.shipping_price)) + sum(coalesce(shippingDiscount.shipping_price,0.00))) as summed_shipping_price 
	,sum(coalesce(gtgm.gtgm_total,0.00)) as gtgm_total
	, sum(coalesce(o.tax,0.00)) as sales_tax
	, COALESCE(sum(ry.royalty),0.00) as royalty 
	,sum(pa.amount) - (sum(coalesce(noShipPromo.shipping_price,shippingPrice.shipping_price)) + sum(coalesce(shippingDiscount.shipping_price,0.00))) - sum(coalesce(gtgm.gtgm_total,0.00)) - sum(coalesce(o.tax,0.00)) - COALESCE(sum(ry.royalty),0.00) as adj_revenue 
from 
	ecommerce.PaymentAuthorization as pa
	,ecommerce.RSOrder as o 
	LEFT OUTER JOIN gtgm ON o.oid = gtgm.order_id 
	LEFT OUTER JOIN noShipPromo ON o.oid = noShipPromo.order_id 
	LEFT OUTER JOIN shippingPrice ON o.oid = shippingPrice.order_id 
	LEFT OUTER JOIN shippingDiscount ON o.oid = shippingDiscount.order_id 
	LEFT OUTER JOIN ry ON o.oid = ry.order_id 
where 
	pa.order_id = o.oid  
	and pa.payment_transaction_result_id = 1 
	and pa.payment_status_id in (3,5,6)  
	and pa.authDate >= now()::DATE - cast('1 day' as interval) 
	and pa.authDate < now()::DATE
group by 
	COALESCE(o.originCode,'No Origin Code')
	, coalesce((noShipPromo.shipping_price + shippingPrice.shipping_price + shippingDiscount.shipping_price),0.00) 
order by 
	auth_amount desc
	,COALESCE(o.originCode,'No Origin Code') 
 