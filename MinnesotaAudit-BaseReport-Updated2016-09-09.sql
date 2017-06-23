WITH tax_addresses AS (
    select 
        o.oid as order_id
        , COALESCE(o.shippingaddress_id,o.billingaddress_id) as address_id
    from 
        ecommerce.paymentauthorization pa
        ,ecommerce.paymenttransaction pt 
        ,ecommerce.rsorder o
    where 
        pa.payment_transaction_result_id = 1 
        and pt.trandate >= '2014-09-01' 
        and pt.trandate < '2014-10-01' 
        and pa.authorization_id = pt.authorization_id
        and pa.order_id = o.oid
), giftcerts as (
    select 
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
        and pa.authdate::DATE >= '2014-09-01'
        and pa.authdate::DATE < '2014-10-01'
), shippingadjustments as (
    select 
        adj.order_id
        , adj.adjustment_type_id
        , adj.amount as adjustment
        , adj.promotion_id 
    from 
        ecommerce.rsadjustment as adj
        where adj.adjustment_type_id = 6
), promoadjustments as (
    select 
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
)

select 
    distinct o.oid as order_id
    , pa.authdate::DATE as authorization_date
    , s.name as site_name
    , pa.amount as base_order_total
    , COALESCE(giftcerts.giftcert_amount,0.00) as amount_paid_via_giftcert
    , COALESCE(promadj.adjustment_amount,0.00) as orderlevel_promotionaldiscount_or_credit
    , (pa.amount + COALESCE(giftcerts.giftcert_amount,0.00) - COALESCE(promadj.adjustment_amount,0.00)) as total_amount_paid
    , o.tax as order_tax
    , o.shippingcost as original_shippingcost
    , COALESCE(shipadj.adjustment,0.00) as promotional_shipping_discount
    , (o.shippingcost - COALESCE(shipadj.adjustment,0.00)) as total_paid_for_shipping
    , rsli.quantity as lineitem_quantity
    , pv.name as lineitem_name
    , rsli.customerprice as lineitem_customerprice
    , (rsli.quantity * rsli.customerprice) as lineitem_subtotal
    , rsli.tax as lineitem_tax
    , (rsli.tax * rsli.quantity) as lineitem_tax_total
    , t.tax_code as lineitem_taxcode
    , t.description as lineitem_tax_code_description
    , a.address1 as ship_address1
    , a.address2 as ship_address2
    , a.city as ship_city
    , a.state as ship_state
    , a.zip as ship_zip

from 
    ecommerce.rsorder as o LEFT OUTER JOIN giftcerts ON o.oid = giftcerts.order_id LEFT OUTER JOIN shippingadjustments as shipadj ON o.oid = shipadj.order_id LEFT OUTER JOIN promoadjustments as promadj ON o.oid = promadj.order_id
    , ecommerce.paymentauthorization as pa
    , ecommerce.rslineitem as rsli
    , ecommerce.productversion as pv
    , ecommerce.item as i
    , ecommerce.tax_category as t
    , ecommerce.site as s 
    , ecommerce.rsaddress as a
    , tax_addresses as taxadd 
where o.oid = taxadd.order_id
    and o.oid = pa.order_id
    and o.oid = rsli.order_id
    and o.site_id = s.site_id
    and rsli.productversion_id = pv.productversion_id
    and pv.item_id = i.item_id
    and i.primarycategory_id = t.tax_category_id
    and pa.authdate::DATE >= '2014-09-01'
    and pa.authdate::DATE < '2014-10-01'
    and o.oid = taxadd.order_id
    and taxadd.address_id = a.oid
    and a.state = 'MN'
group by
    o.oid
    , pa.authdate
    , a.oid
    , s.name
    , pa.amount
    , giftcerts.giftcert_amount
    , promadj.adjustment_amount
    , o.tax
    , o.shippingcost
    , shipadj.adjustment
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
order by
    o.oid asc;
