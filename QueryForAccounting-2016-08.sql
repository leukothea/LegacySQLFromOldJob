WITH giftcerts as (
select o.oid as order_id, pa.authdate::DATE as order_date, abs(gce.adjustment_amount) as giftcert_amount
from ecommerce.rsorder as o, ecommerce.gift_certificate_event as gce, ecommerce.gift_certificate as gc, ecommerce.paymentauthorization as pa, ecommerce.payment_status as ps, ecommerce.payment_transaction_result as ptr
where o.oid = gce.order_id and gce.gift_certificate_id = gc.gift_certificate_id and o.oid = pa.order_id and pa.payment_status_id = ps.payment_status_id and pa.payment_transaction_result_id = ptr.payment_transaction_result_id
and pa.authdate::DATE > '2016-05-31'
and pa.authdate::DATE < '2016-07-01'
), shippingadjustments as (
select 
a.order_id
, a.adjustment_type_id
, a.amount as adjustment
, a.promotion_id 
from 
ecommerce.rsadjustment as a
where a.adjustment_type_id = 6
)
select distinct o.oid as order_id, pa.authdate::DATE as authorization_date, s.name as site_name, (pa.amount + COALESCE(giftcerts.giftcert_amount,0.00)) as total_amount_paid, o.tax as order_tax
, (o.shippingcost - COALESCE(shippingadjustments.adjustment,0.00)) as order_shipping_charge, rsli.quantity as lineitem_quantity, pv.name as lineitem_name, rsli.customerprice as lineitem_customerprice, t.tax_code as lineitem_taxcode, t.description as lineitem_tax_code_description, a2.address1, a2.address2, a2.city, a2.state, a2.zip
from ecommerce.rsorder as o 
LEFT OUTER JOIN giftcerts ON o.oid = giftcerts.order_id 
LEFT OUTER JOIN shippingadjustments ON o.oid = shippingadjustments.order_id , ecommerce.paymentauthorization as pa, ecommerce.rsaddress as a2, ecommerce.rslineitem as rsli, ecommerce.productversion as pv, ecommerce.item as i, ecommerce.tax_category as t, ecommerce.site as s
where o.oid = pa.order_id
and o.site_id = s.site_id
and pa.payment_status_id IN (3, 5, 6)
and pa.payment_transaction_result_id = 1
and o.shippingaddress_id = a2.oid
and o.oid = rsli.order_id
and rsli.productversion_id = pv.productversion_id
and pv.item_id = i.item_id
and i.primarycategory_id = t.tax_category_id
and a2.state = 'MN'
and rsli.lineitemtype_id IN (1, 5)
and rsli.quantity > 0
and pa.authdate::DATE > '2016-05-31'
and pa.authdate::DATE < '2016-07-01'
UNION
select distinct o.oid as order_id, pa.authdate::DATE as authorization_date, s.name as site_name, (pa.amount + COALESCE(giftcerts.giftcert_amount,0.00)) as total_amount_paid, o.tax as order_tax
, (o.shippingcost - COALESCE(shippingadjustments.adjustment,0.00)) as order_shipping_charge, rsli.quantity as lineitem_quantity, pv.name as lineitem_name, rsli.customerprice as lineitem_customerprice, t.tax_code as lineitem_taxcode, t.description as lineitem_tax_code_description, a1.address1, a1.address2, a1.city, a1.state, a1.zip
from ecommerce.rsorder as o 
LEFT OUTER JOIN giftcerts ON o.oid = giftcerts.order_id 
LEFT OUTER JOIN shippingadjustments ON o.oid = shippingadjustments.order_id, ecommerce.paymentauthorization as pa, ecommerce.rsaddress as a1, ecommerce.rslineitem as rsli, ecommerce.productversion as pv, ecommerce.item as i, ecommerce.tax_category as t, ecommerce.site as s
where o.oid = pa.order_id
and o.site_id = s.site_id
and pa.payment_status_id IN (3, 5, 6)
and pa.payment_transaction_result_id = 1
and o.billingaddress_id = a1.oid
and o.shippingaddress_id IS NULL
and o.oid = rsli.order_id
and rsli.productversion_id = pv.productversion_id
and pv.item_id = i.item_id
and i.primarycategory_id = t.tax_category_id
and a1.state = 'MN'
and rsli.lineitemtype_id IN (1, 5)
and rsli.quantity > 0
and pa.authdate::DATE > '2016-05-31'
and pa.authdate::DATE < '2016-07-01'
order by order_id asc;