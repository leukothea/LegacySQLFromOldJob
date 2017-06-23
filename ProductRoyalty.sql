-- Product Royalty Report query (unaltered)

select 
	r.store_name
	,r.site_name
	,r.item_name
	,r.customer_price
	,r.quantity
	,r.royalty_factor
	,r.quantity * r.royalty_factor AS royalty_amount
	,r.donation_factor_conversion
	,r.quantity * r.royalty_factor * r.donation_factor_conversion AS commodity_amount
	,r.commodity_name
from
( 
 	select 
 		li.store_name AS store_name
 		,s.name AS site_name
 		,li.item_name AS item_name
 		,sum(COALESCE(sli.quantity,0)) AS quantity
 		,sum(COALESCE(sli.quantity,0) * COALESCE(li.customer_price,0.00)) AS customer_price
 		,df.royaltyFactor AS royalty_factor
 		,COALESCE(s.donationUnitPhrase,'No Assigned Commodity') AS commodity_name
 		,COALESCE(s.donationFactorConversion,1) AS donation_factor_conversion
	from 
		ecommerce.Site s
		,ecommerce.SiteLineItem sli
		,ecommerce.DonationFactor df
		,ecommerce.DonationFactor df2,
  		( select 
  			t.name AS store_name
  			,i.name AS item_name
  			,li.oid
  			,COALESCE(li.customerPrice,0.00) AS customer_price
  		from 
  			ecommerce.store t
  			,ecommerce.Item i
  			,ecommerce.ProductVersion pv
  			,ecommerce.RSLineItem li
  			,ecommerce.RSOrder o
  			,ecommerce.PaymentAuthorization pa
  		where 
  			t.store_id = o.store_id 
  			and o.oid = li.order_id 
  			and li.productVersion_id = pv.productVersion_id 
  			and li.customerPrice > 0.00 
  			and COALESCE(li.lineItemType_id,1) in (1,5) 
  			and pv.item_id = i.item_id 
  			and i.itemBitMask & 2 != 2 
  			and o.oid = pa.order_id 
  			and pa.payment_transaction_result_id = 1 
  			and pa.payment_status_id in (3,5) 
  			and pa.authDate::DATE >= date_trunc('month',now()::DATE) - cast('1 month' as interval) 
  			and pa.authDate::DATE < date_trunc('month',now()::DATE)
   		) as li
 	where 
 		li.oid = sli.lineItem_id 
 		and sli.site_id = s.site_id 
 		and s.site_id = df.site_id 
 		and s.site_id = df2.site_id 
 		and df2.minPrice = 0.00 
 		and sli.site_id = df.site_id 
 		and COALESCE(li.customer_price,0.00) >= df.minPrice 
 		and COALESCE(li.customer_price,0.00) < df.maxPrice
 	group by 
 		li.store_name
 		,s.name
 		,li.item_name
 		,df.royaltyFactor
 		,COALESCE(s.donationUnitPhrase,'No Assigned Commodity')
 		,COALESCE(s.donationFactorConversion,1)
) as r
order by 
	commodity_amount
	,r.item_name;

	