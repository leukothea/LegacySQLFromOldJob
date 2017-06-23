with promoitemtrue as ((select rsli.oid as lineitem_id, o.oid as order_id, ((extract(year from pa.authdate::DATE)) || '-' || (extract(month from pa.authdate::DATE))) as date, (rsli.quantity * rsli.customerprice) as customerprice, o.tax as tax, o.shippingcost as shipping, 'true' as promoitem
from ecommerce.rsorder as o, ecommerce.paymentauthorization as pa, ecommerce.rsaddress as a2, ecommerce.rslineitem as rsli
where o.oid = pa.order_id
and o.oid = rsli.order_id
and pa.payment_status_id IN (3, 5, 6)
and pa.payment_transaction_result_id = 1
and o.shippingaddress_id = a2.oid
and a2.state = 'MN'
and rsli.customerprice < 0.01 
AND rsli.lineitemtype_id = 5
and pa.authdate::DATE > '2013-12-31'
and pa.authdate::DATE < '2014-02-01'
group by rsli.oid, o.oid, rsli.quantity, rsli.customerprice, date, o.tax, o.shippingcost, rsli.quantity, rsli.customerprice, rsli.lineitemtype_id
order by date asc)
UNION 
(select rsli.oid as lineitem_id, o.oid as order_id, ((extract(year from pa.authdate::DATE)) || '-' || (extract(month from pa.authdate::DATE))) as date, (rsli.quantity * rsli.customerprice) as customerprice, o.tax as tax, o.shippingcost as shipping, 'true' as promoitem
from ecommerce.rsorder as o, ecommerce.paymentauthorization as pa, ecommerce.rsaddress as a1, ecommerce.rslineitem as rsli
where o.oid = pa.order_id
and o.oid = rsli.order_id
and pa.payment_status_id IN (3, 5, 6)
and pa.payment_transaction_result_id = 1
and o.billingaddress_id = a1.oid
and o.shippingaddress_id IS NULL
and a1.state = 'MN'
and rsli.lineitemtype_id IN (1, 5)
and pa.authdate::DATE > '2013-12-31'
and pa.authdate::DATE < '2014-02-01'
group by rsli.oid, o.oid, date, o.tax, o.shippingcost, pv.name, rsli.quantity, rsli.customerprice, rsli.lineitemtype_id
order by date asc))
, promoitemfalse as ((select rsli.oid as lineitem_id, o.oid as order_id, ((extract(year from pa.authdate::DATE)) || '-' || (extract(month from pa.authdate::DATE))) as date, (rsli.quantity * rsli.customerprice) as customerprice, o.tax as tax, o.shippingcost as shipping, 'false' as promoitem
from ecommerce.rsorder as o, ecommerce.paymentauthorization as pa, ecommerce.rsaddress as a2, ecommerce.rslineitem as rsli
where o.oid = pa.order_id
and o.oid = rsli.order_id
and pa.payment_status_id IN (3, 5, 6)
and pa.payment_transaction_result_id = 1
and o.shippingaddress_id = a2.oid
and a2.state = 'MN'
and rsli.customerprice > 0.00 
AND rsli.lineitemtype_id = 1
and pa.authdate::DATE > '2013-12-31'
and pa.authdate::DATE < '2014-02-01'
group by rsli.oid, o.oid, rsli.quantity, rsli.customerprice, date, o.tax, o.shippingcost, rsli.quantity, rsli.customerprice, rsli.lineitemtype_id
order by date asc)
UNION 
(select rsli.oid as lineitem_id, o.oid as order_id, ((extract(year from pa.authdate::DATE)) || '-' || (extract(month from pa.authdate::DATE))) as date, (rsli.quantity * rsli.customerprice) as customerprice, o.tax as tax, o.shippingcost as shipping, 'false' as promoitem
from ecommerce.rsorder as o, ecommerce.paymentauthorization as pa, ecommerce.rsaddress as a1, ecommerce.rslineitem as rsli
where o.oid = pa.order_id
and o.oid = rsli.order_id
and pa.payment_status_id IN (3, 5, 6)
and pa.payment_transaction_result_id = 1
and o.billingaddress_id = a1.oid
and o.shippingaddress_id IS NULL
and a1.state = 'MN'
and rsli.customerprice > 0.00 
AND rsli.lineitemtype_id = 1
and pa.authdate::DATE > '2013-12-31'
and pa.authdate::DATE < '2014-02-01'
group by rsli.oid, o.oid, date, o.tax, o.shippingcost, pv.name, rsli.quantity, rsli.customerprice, rsli.lineitemtype_id
order by date asc))

select promoitemtrue.order_id
from promoitemtrue RIGHT OUTER JOIN promoitemfalse ON promoitemtrue.order_id = promoitemfalse.order_id
where promoitemtrue.order_id 








with zz as ((select o.oid as order_id, ((extract(year from pa.authdate::DATE)) || '-' || (extract(month from pa.authdate::DATE))) as date, (rsli.quantity * rsli.customerprice) as customerprice, o.tax as tax, o.shippingcost as shipping, 'true' as promoitem
from ecommerce.rsorder as o, ecommerce.paymentauthorization as pa, ecommerce.rsaddress as a2, ecommerce.rslineitem as rsli
where o.oid = pa.order_id
and o.oid = rsli.order_id
and pa.payment_status_id IN (3, 5, 6)
and pa.payment_transaction_result_id = 1
and o.shippingaddress_id = a2.oid
and a2.state = 'MN'
and (rsli.customerprice < 0.01 AND rsli.lineitemtype_id = 5)
and pa.authdate::DATE > '2013-12-31'
and pa.authdate::DATE < '2016-05-27'
group by o.oid, rsli.quantity, rsli.customerprice, date, o.tax, o.shippingcost, rsli.quantity, rsli.customerprice, rsli.lineitemtype_id
order by date asc)
UNION 
(select o.oid as order_id, ((extract(year from pa.authdate::DATE)) || '-' || (extract(month from pa.authdate::DATE))) as date, (rsli.quantity * rsli.customerprice) as customerprice, o.tax as tax, o.shippingcost as shipping, 'true' as promoitem
from ecommerce.rsorder as o, ecommerce.paymentauthorization as pa, ecommerce.rsaddress as a1, ecommerce.rslineitem as rsli
where o.oid = pa.order_id
and o.oid = rsli.order_id
and pa.payment_status_id IN (3, 5, 6)
and pa.payment_transaction_result_id = 1
and o.billingaddress_id = a1.oid
and o.shippingaddress_id IS NULL
and a1.state = 'MN'
and (rsli.customerprice < 0.01 AND rsli.lineitemtype_id = 5)
and pa.authdate::DATE > '2013-12-31'
and pa.authdate::DATE < '2016-05-27'
group by o.oid, date, o.tax, o.shippingcost, rsli.quantity, rsli.customerprice, rsli.lineitemtype_id
order by date asc))
select zz.date, sum(zz.customerprice) as customerprice, sum(zz.tax) as tax, sum(zz.shipping) as shiping
from zz
where zz.order_id NOT IN ((select o.oid as order_id
from ecommerce.rsorder as o, ecommerce.paymentauthorization as pa, ecommerce.rsaddress as a2, ecommerce.rslineitem as rsli
where o.oid = pa.order_id
and o.oid = rsli.order_id
and pa.payment_status_id IN (3, 5, 6)
and pa.payment_transaction_result_id = 1
and o.shippingaddress_id = a2.oid
and a2.state = 'MN'
and (rsli.customerprice > 0.00 AND rsli.lineitemtype_id = 1)
and pa.authdate::DATE > '2013-12-31'
and pa.authdate::DATE < '2016-05-27'
group by o.oid
order by date asc)
UNION 
(select o.oid as order_id
from ecommerce.rsorder as o, ecommerce.paymentauthorization as pa, ecommerce.rsaddress as a1, ecommerce.rslineitem as rsli
where o.oid = pa.order_id
and o.oid = rsli.order_id
and pa.payment_status_id IN (3, 5, 6)
and pa.payment_transaction_result_id = 1
and o.billingaddress_id = a1.oid
and o.shippingaddress_id IS NULL
and a1.state = 'MN'
and (rsli.customerprice > 0.00 AND rsli.lineitemtype_id = 1)
and pa.authdate::DATE > '2013-12-31'
and pa.authdate::DATE < '2016-05-27'
group by o.oid
order by date asc))
group by date
order by date asc;

