-- When the following script is run in PostgreSQL, two dialogue boxes will pop up to ask for the desired start and end dates. 
-- Enter the start and end dates in the format YYYY-MM-DD, _without quotation marks,_ and the query will run! 


with wrapper as (

	(WITH tax_addresses AS ( 	    select 
	        o.oid as order_id
	        , COALESCE(o.shippingaddress_id,o.billingaddress_id) as address_id
	    from 
	        ecommerce.paymentauthorization pa
	        ,ecommerce.rsorder o
	    where 
	        pa.payment_transaction_result_id = 1 
	        and pa.order_id = o.oid
	), shippingadjustments as ( 	    select 
	        adj.order_id
	        , adj.adjustment_type_id
	        , adj.amount as adjustment
	        , adj.promotion_id 
	    from 
	        ecommerce.rsadjustment as adj
	        where adj.adjustment_type_id = 6
	), promoadjustments as ( 	    select 
	        o.oid as order_id
	        , pa.authdate::DATE as order_date
	        , adj.amount as adjustment_amount
	    from 
	        ecommerce.rsorder as o
	        , ecommerce.paymentauthorization as pa
	        , ecommerce.rsadjustment as adj 
	    where 
	        o.oid = pa.order_id 
	        and o.oid = adj.order_id
	        and adj.adjustment_type_id NOT IN (2, 6)
	),  giftcerts as ( 	    select 
	        o.oid as order_id
	        , pa.authdate::DATE as order_date
	        , abs(gce.adjustment_amount) as giftcert_amount
	    from 
	        ecommerce.rsorder as o
	        , ecommerce.gift_certificate_event as gce
	        , ecommerce.gift_certificate as gc
	        , ecommerce.paymentauthorization as pa
	        , ecommerce.payment_status as ps
	        , ecommerce.payment_transaction_result as ptr
	    where 
	        o.oid = gce.order_id 
	        and gce.gift_certificate_id = gc.gift_certificate_id 
	        and o.oid = pa.order_id 
	        and pa.payment_status_id = ps.payment_status_id 
	        and pa.payment_transaction_result_id = ptr.payment_transaction_result_id
	)
		select 			ps.payment_status
			, o.oid as order_id
			, pa.authdate::date as authorization_date
			, NULL::numeric(18,4) as refund_amount 
			, NULL::date as refund_date
			, s.name as site_name
			, (pa.amount + COALESCE(SUM(COALESCE(promadj.adjustment_amount,0)),0)) as base_order_total
			, COALESCE(giftcerts.giftcert_amount,0.00) as amount_paid_via_giftcert
			, -SUM(COALESCE(promadj.adjustment_amount,0)) as orderlevel_promotionaldiscount_or_credit
			, ((o.shippingcost) - COALESCE(shipadj.adjustment,0)) as total_shipping
			, (pa.amount + COALESCE(giftcerts.giftcert_amount,0.00)) as total_amount_paid
			, o.tax as order_tax
			, NULL::int as lineitem_quantity
			, NULL::text as lineitem_name
			, NULL::int as lineitem_customerprice
			, NULL::int as lineitem_subtotal
			, NULL::numeric(18,4) as lineitem_tax
			, NULL::text as lineitem_taxcode
			, NULL::text as lineitem_taxcode_description
			, a1.address1 as ship_address1
		     , a1.address2 as ship_address2
		     , a1.city as ship_city
		     , a1.state as ship_state
		     , a1.zip as ship_zip
		from
			ecommerce.rsorder as o LEFT OUTER JOIN shippingadjustments as shipadj ON shipadj.order_id = o.oid LEFT OUTER JOIN giftcerts ON o.oid = giftcerts.order_id LEFT OUTER JOIN promoadjustments as promadj ON o.oid = promadj.order_id
			, ecommerce.paymentauthorization as pa
			, ecommerce.payment_status as ps
			, ecommerce.rsaddress as a1
			, ecommerce.site as s
			, tax_addresses as taxadd
		where 
			o.oid = pa.order_id
			and o.site_id = s.site_id
			and pa.payment_status_id = ps.payment_status_id
			and o.oid = taxadd.order_id
			and taxadd.address_id = a1.oid
			and a1.state = 'MN'
			and pa.authdate >= :startdate
			and pa.authdate < :enddate
			and pa.payment_status_id IN (5, 6, 7)
    					and pa.payment_transaction_result_id = 1
		group by 
			ps.payment_status
			, o.oid
			, pa.authdate
			, pa.amount
			, giftcerts.giftcert_amount
			, s.name
			, o.shippingcost
			, shipadj.adjustment
			, a1.address1
			, a1.address2
			, a1.city
			, a1.state
			, a1.zip
		order by 
			o.oid asc)
UNION

(WITH tax_addresses AS (     select 
        o.oid as order_id
        , COALESCE(o.shippingaddress_id,o.billingaddress_id) as address_id
    from 
        ecommerce.paymentauthorization pa
        ,ecommerce.rsorder o
    where 
        pa.payment_transaction_result_id = 1 
        and pa.order_id = o.oid
), paymentcredits as ( 	    select
	        ptt.authorization_id
	        , ptt.amount as refund_amount
	        , ptt.trandate as refund_date
	    from
	        ecommerce.paymenttransaction as ptt
	    where
	        ptt.payment_transaction_type_id = 5
	        and ptt.payment_transaction_result_id = 1
	)
select     ps.payment_status
    , o.oid as order_id
    , pa.authdate::DATE as authorization_date
    , -(ptt.refund_amount) as refund_amount
    , ptt.refund_date::date as refund_date
    , s.name as site_name
    , NULL::int as base_order_total
    , NULL::int as amount_paid_via_giftcert
    , NULL::int as orderlevel_promotionaldiscount_or_credit
    , NULL::int as total_shipping
    , NULL::int as total_amount_paid
    , NULL::int as order_tax
    , NULL::int as lineitem_quantity
    , 'Partial Refund' as lineitem_name
    , NULL::int as lineitem_customerprice
    , NULL::int as lineitem_subtotal
    , NULL::numeric(18,4) as lineitem_tax
    , NULL::text as lineitem_taxcode
    , NULL::text as lineitem_taxcode_description
    , a.address1 as ship_address1
    , a.address2 as ship_address2
    , a.city as ship_city
    , a.state as ship_state
    , a.zip as ship_zip

from 
    ecommerce.rsorder as o 
    , ecommerce.paymentauthorization as pa LEFT OUTER JOIN paymentcredits as ptt ON pa.authorization_id = ptt.authorization_id
    , ecommerce.payment_status as ps
    , ecommerce.site as s 
    , ecommerce.rsaddress as a
    , tax_addresses as taxadd 
where o.oid = taxadd.order_id
    and o.oid = pa.order_id
    and o.site_id = s.site_id
    and pa.payment_status_id = ps.payment_status_id
    and ptt.refund_date::date >= :startdate
    and ptt.refund_date::date < :enddate
    and pa.payment_transaction_result_id = 1
    and pa.payment_status_id IN (6, 7) 
        and o.oid = taxadd.order_id
    and taxadd.address_id = a.oid
    and a.state = 'MN'
group by
    ps.payment_status
    , o.oid
    , pa.authdate
    , ptt.refund_amount
    , ptt.refund_date
    , a.oid
    , s.name
    , pa.amount
    , o.tax
    , a.address1
    , a.address2
    , a.city
    , a.state
    , a.zip
order by
    o.oid asc)

UNION 
(WITH tax_addresses AS ( 	    select 
	        o.oid as order_id
	        , COALESCE(o.shippingaddress_id,o.billingaddress_id) as address_id
	    from 
	        ecommerce.paymentauthorization pa
	        ,ecommerce.rsorder o
	    where 
	        pa.payment_transaction_result_id = 1 
	        and pa.order_id = o.oid
	)
select     ps.payment_status
    , o.oid as order_id
    , pa.authdate::DATE as authorization_date
    , NULL::numeric(18,4) as refund_amount
    , NULL::date AS refund_date
    , s.name as site_name
    , NULL::int as base_order_total
    , NULL::int as amount_paid_via_giftcert
    , NULL::int as orderlevel_promotionaldiscount_or_credit
    , NULL::int as total_shipping
    , NULL::int as total_amount_paid
    , NULL::int as order_tax
    , rsli.quantity as lineitem_quantity
    , pv.name as lineitem_name
    , rsli.customerprice as lineitem_customerprice
    , (rsli.quantity * rsli.customerprice) as lineitem_subtotal
    , cast(rsli.tax as numeric(18,4)) as lineitem_tax
    , t.tax_code as lineitem_taxcode
    , t.description as lineitem_tax_code_description
    , a.address1 as ship_address1
    , a.address2 as ship_address2
    , a.city as ship_city
    , a.state as ship_state
    , a.zip as ship_zip

from 
    ecommerce.rsorder as o
    , ecommerce.paymentauthorization as pa 
    , ecommerce.rslineitem as rsli
    , ecommerce.productversion as pv
    , ecommerce.item as i
    , ecommerce.tax_category as t
    , ecommerce.site as s 
    , ecommerce.payment_status as ps
    , ecommerce.rsaddress as a
    , tax_addresses as taxadd 
where o.oid = taxadd.order_id
    and o.oid = pa.order_id
    and o.oid = rsli.order_id
    and o.site_id = s.site_id
    and pa.payment_status_id = ps.payment_status_id
    and rsli.productversion_id = pv.productversion_id
    and pv.item_id = i.item_id
    and i.primarycategory_id = t.tax_category_id
    and pa.authdate::DATE >= :startdate
    and pa.authdate::DATE < :enddate
    and pa.payment_transaction_result_id = 1
    and pa.payment_status_id IN (5, 6, 7)
         and o.oid = taxadd.order_id
    and taxadd.address_id = a.oid
    and a.state = 'MN'
group by
    ps.payment_status
    , o.oid
    , pa.authdate
    , s.name
    , pa.amount
    , rsli.quantity 
    , pv.name
    , rsli.customerprice 
    , rsli.tax
    , t.tax_code 
    , t.description 
    , a.address1
    , a.address2
    , a.city
    , a.state
    , a.zip
    )
  )
select wrapper.payment_status 	, wrapper.order_id
	, wrapper.authorization_date
	, wrapper.refund_amount
	, wrapper.refund_date
	, wrapper.site_name
	, wrapper.base_order_total
	, wrapper.amount_paid_via_giftcert
	, wrapper.orderlevel_promotionaldiscount_or_credit
	, wrapper.total_shipping as total_shipping_paid
	, wrapper.total_amount_paid
	, wrapper.order_tax
	, wrapper.lineitem_quantity
	, wrapper.lineitem_name
	, wrapper.lineitem_customerprice
	, wrapper.lineitem_subtotal
	, wrapper.lineitem_tax
	, wrapper.lineitem_taxcode
	, wrapper.lineitem_taxcode_description
	, wrapper.ship_address1
	, wrapper.ship_address2
	, wrapper.ship_city
	, wrapper.ship_state
	, wrapper.ship_zip
from
	wrapper
group by 
	wrapper.payment_status
	, wrapper.order_id
	, wrapper.authorization_date
	, wrapper.refund_amount
	, wrapper.refund_date
	, wrapper.site_name
	, wrapper.base_order_total
	, wrapper.amount_paid_via_giftcert
	, wrapper.orderlevel_promotionaldiscount_or_credit
	, wrapper.total_shipping
	, wrapper.total_amount_paid
	, wrapper.order_tax
	, wrapper.lineitem_quantity
	, wrapper.lineitem_name
	, wrapper.lineitem_customerprice
	, wrapper.lineitem_subtotal
	, wrapper.lineitem_tax
	, wrapper.lineitem_taxcode
	, wrapper.lineitem_taxcode_description
	, wrapper.ship_address1
	, wrapper.ship_address2
	, wrapper.ship_city
	, wrapper.ship_state
	, wrapper.ship_zip
order by
	wrapper.order_id, wrapper.base_order_total asc