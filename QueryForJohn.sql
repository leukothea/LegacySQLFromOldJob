with zz as ((select ((extract(year from pa.authdate::DATE)) || '-' || (extract(month from pa.authdate::DATE))) as date, sum(rsli.customerprice) as summed_customerprice, sum(o.tax) as summed_tax, sum(o.shippingcost) as summed_shipping
from ecommerce.rsorder as o, ecommerce.paymentauthorization as pa, ecommerce.rsaddress as a2, ecommerce.rslineitem as rsli
where o.oid = pa.order_id
and o.oid = rsli.order_id
and pa.payment_status_id IN (3, 5, 6)
and pa.payment_transaction_result_id = 1
and o.shippingaddress_id = a2.oid
and a2.state = 'MN'
and rsli.lineitemtype_id IN (1, 5)
and pa.authdate::DATE > '2013-12-31'
and pa.authdate::DATE < now()
GROUP BY date)
UNION
(select ((extract(year from pa.authdate::DATE)) || '-' || (extract(month from pa.authdate::DATE))) as date, sum(rsli.customerprice) as summed_customerprice, sum(o.tax) as summed_tax, sum(o.shippingcost) as summed_shipping
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
and pa.authdate::DATE < now()
group by date))
select zz.date, sum(zz.summed_customerprice) as summed_customerprice, sum(zz.summed_tax) as summed_tax, sum(zz.summed_shipping) as summed_shipping
from zz
group by zz.date
order by zz.date asc;

// gives a too-high shipping amount. It gives almost $15,000 for January 2014, whereas the order-by-order version I sent in March gives only $6,000. And it gives $17,012.95 for summed shipping for February 2014, whereas the order-by-order version gives only $7,882.

// Breaking out to do the two segments separately and combine them in Excel. 

// MN-SHIPPING ADDRESS:
select ((extract(year from pa.authdate::DATE)) || '-' || (extract(month from pa.authdate::DATE))) as date, sum(rsli.customerprice) as summed_customerprice, sum(o.tax) as summed_tax, sum(o.shippingcost) as summed_shipping
from ecommerce.rsorder as o, ecommerce.paymentauthorization as pa, ecommerce.rsaddress as a2, ecommerce.rslineitem as rsli
where o.oid = pa.order_id
and o.oid = rsli.order_id
and pa.payment_status_id IN (3, 5, 6)
and pa.payment_transaction_result_id = 1
and o.shippingaddress_id = a2.oid
and a2.state = 'MN'
and rsli.lineitemtype_id IN (1, 5)
and pa.authdate::DATE > '2013-12-31'
and pa.authdate::DATE < now()
GROUP BY date
order by date asc;

// MN-BILLING ADDRESS:
select ((extract(year from pa.authdate::DATE)) || '-' || (extract(month from pa.authdate::DATE))) as date, sum(rsli.customerprice) as summed_customerprice, sum(o.tax) as summed_tax, sum(o.shippingcost) as summed_shipping
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
and pa.authdate::DATE < now()
group by date
order by date asc;

// Breaking these two queries apart did not help. I think using the year-month column as the groupby & orderby is the source of the issue; the data is multiplying itself inside each date unit. I am going to have to go to the order-level and then sum from there. 







