WITH core AS (  WITH phemeSum AS (  WITH phemeAdd AS (select phad.account_id, phad.address_id, phad.first_name, phad.last_name, phad.address_1, phad.address_2, phad.city, phad.region_code as state, phad.postal_code as zip, phad.country_code 
from pheme.address as phad 
where true 
group by phad.account_id, phad.address_id, phad.first_name, phad.last_name, phad.address_1, phad.address_2, phad.city, phad.region_code, phad.postal_code, phad.country_code 
 )
 select phac.account_id, phac.email, COALESCE(phac.first_name, phad.first_name) as first_name, COALESCE(phac.last_name, phad.last_name) as last_name, COALESCE(phad.address_1, NULL) as address_1, COALESCE(phad.address_2, NULL) as address_2, COALESCE(phad.city, NULL) as city, COALESCE(phad.state, NULL) as state, COALESCE(phad.zip, NULL) as zip, COALESCE(phad.country_code, NULL) as country_code 
from pheme.account as phac LEFT OUTER JOIN phemeAdd as phad ON phac.account_id = phad.account_id 
where true 
group by phac.account_id, phac.email, phac.first_name, phad.first_name, phac.last_name, phad.last_name, phad.address_1, phad.address_2, phad.city, phad.state, phad.zip, phad.country_code 
 )
 select o.account_id, COALESCE(phemeSum.first_name, rsAdd.firstname, NULL) as first_name, COALESCE(phemeSum.last_name, rsAdd.lastname, NULL) as last_name ,COALESCE(o.email, phemeSum.email) as email ,COALESCE(phemeSum.address_1, rsAdd.address1) as address_1, COALESCE(phemeSum.address_2, rsAdd.address2) as address_2 ,COALESCE(phemeSum.city, rsAdd.city) as city, COALESCE(phemeSum.state, rsAdd.state) as state, COALESCE(phemeSum.zip, rsAdd.zip) as zip ,COALESCE(phemeSum.country_code, rsAdd.iso_country_code) as country_code, rsAdd.phone as billphone ,o.oid as order_id, pa.authdate::DATE as order_date, rsli.quantity, rsli.customerprice as customer_price, (rsli.quantity * rsli.customerprice) as lineitem_total 
from ecommerce.rsorder as o LEFT OUTER JOIN phemeSum ON o.account_id = phemeSum.account_id ,ecommerce.rsaddress as rsAdd, ecommerce.paymentauthorization as pa, ecommerce.rslineitem as rsli, ecommerce.productversion as pv, ecommerce.item as i 
where o.oid = pa.order_id and o.billingaddress_id = rsAdd.oid  and pa.payment_transaction_result_id = 1 and pa.payment_status_id IN (3, 5, 6) and o.oid = rsli.order_id and rsli.productversion_id = pv.productversion_id and pv.item_id = i.item_id  and o.site_id = 351 and o.account_id IS NOT NULL and pa.authdate >= '2015-10-01' and pa.authdate < '2016-01-01' 
group by o.account_id, phemeSum.first_name, rsAdd.firstname, phemeSum.last_name, rsAdd.lastname, o.email, phemeSum.email, phemeSum.address_1, rsAdd.address1, phemeSum.address_2, rsAdd.address2 ,phemeSum.city, rsAdd.city, phemeSum.state, rsAdd.state, phemeSum.zip, rsAdd.zip, phemeSum.country_code, rsAdd.iso_country_code, rsAdd.phone ,o.oid, pa.authdate, pv.productversion_id, pv.name, rsli.quantity, rsli.customerprice 
order by o.oid asc 
 )
 select core.account_id, (CASE WHEN core.first_name = core.last_name THEN core.first_name ELSE core.first_name || ' ' || core.last_name END) as billname ,core.email ,(CASE WHEN core.address_2 IS NULL THEN core.address_1 ELSE (core.address_1 || ' ' || core.address_2) END) as address ,core.city, core.state, core.zip, core.country_code, core.billphone ,core.order_id, core.order_date, core.quantity, core.customer_price, core.lineitem_total 
from core 
where true 
group by core.account_id, core.first_name,core.last_name, core.email, core.address_1, core.address_2 ,core.city, core.state, core.zip, core.country_code, core.billphone ,core.order_id, core.order_date, core.quantity, core.customer_price, core.lineitem_total 
order by core.order_id desc;

FAULTY ATTEMPT: 

with top as
(WITH core AS (  WITH phemeSum AS (  WITH phemeAdd AS (select phad.account_id, phad.address_id, phad.first_name, phad.last_name, phad.address_1, phad.address_2, phad.city, phad.region_code as state, phad.postal_code as zip, phad.country_code 
from pheme.address as phad 
where true 
group by phad.account_id, phad.address_id, phad.first_name, phad.last_name, phad.address_1, phad.address_2, phad.city, phad.region_code, phad.postal_code, phad.country_code 
 )
 select phac.account_id, phac.email, COALESCE(phac.first_name, phad.first_name) as first_name, COALESCE(phac.last_name, phad.last_name) as last_name, COALESCE(phad.address_1, NULL) as address_1, COALESCE(phad.address_2, NULL) as address_2, COALESCE(phad.city, NULL) as city, COALESCE(phad.state, NULL) as state, COALESCE(phad.zip, NULL) as zip, COALESCE(phad.country_code, NULL) as country_code 
from pheme.account as phac LEFT OUTER JOIN phemeAdd as phad ON phac.account_id = phad.account_id 
where true 
group by phac.account_id, phac.email, phac.first_name, phad.first_name, phac.last_name, phad.last_name, phad.address_1, phad.address_2, phad.city, phad.state, phad.zip, phad.country_code 
 )
 select o.account_id, COALESCE(phemeSum.first_name, rsAdd.firstname, NULL) as first_name, COALESCE(phemeSum.last_name, rsAdd.lastname, NULL) as last_name ,COALESCE(o.email, phemeSum.email) as email ,COALESCE(phemeSum.address_1, rsAdd.address1) as address_1, COALESCE(phemeSum.address_2, rsAdd.address2) as address_2 ,COALESCE(phemeSum.city, rsAdd.city) as city, COALESCE(phemeSum.state, rsAdd.state) as state, COALESCE(phemeSum.zip, rsAdd.zip) as zip ,COALESCE(phemeSum.country_code, rsAdd.iso_country_code) as country_code, rsAdd.phone as billphone ,o.oid as order_id, pa.authdate::DATE as order_date, rsli.quantity, rsli.customerprice as customer_price, (rsli.quantity * rsli.customerprice) as lineitem_total 
from ecommerce.rsorder as o LEFT OUTER JOIN phemeSum ON o.account_id = phemeSum.account_id ,ecommerce.rsaddress as rsAdd, ecommerce.paymentauthorization as pa, ecommerce.rslineitem as rsli, ecommerce.productversion as pv, ecommerce.item as i 
where o.oid = pa.order_id and o.billingaddress_id = rsAdd.oid  and pa.payment_transaction_result_id = 1 and pa.payment_status_id IN (3, 5, 6) and o.oid = rsli.order_id and rsli.productversion_id = pv.productversion_id and pv.item_id = i.item_id  and o.site_id = 351 and pa.authdate >= '2015-10-01' and pa.authdate < now() 
group by o.account_id, phemeSum.first_name, rsAdd.firstname, phemeSum.last_name, rsAdd.lastname, o.email, phemeSum.email, phemeSum.address_1, rsAdd.address1, phemeSum.address_2, rsAdd.address2 ,phemeSum.city, rsAdd.city, phemeSum.state, rsAdd.state, phemeSum.zip, rsAdd.zip, phemeSum.country_code, rsAdd.iso_country_code, rsAdd.phone ,o.oid, pa.authdate, pv.productversion_id, pv.name, rsli.quantity, rsli.customerprice 
order by o.oid asc 
 )
 select core.account_id, (CASE WHEN core.first_name = core.last_name THEN core.first_name ELSE core.first_name || ' ' || core.last_name END) as billname ,core.email ,(CASE WHEN core.address_2 IS NULL THEN core.address_1 ELSE (core.address_1 || ' ' || core.address_2) END) as address ,core.city, core.state, core.zip, core.country_code, core.billphone ,core.order_id, core.order_date, core.quantity, core.customer_price, core.lineitem_total 
from core 
where true 
group by core.account_id, core.first_name,core.last_name, core.email, core.address_1, core.address_2 ,core.city, core.state, core.zip, core.country_code, core.billphone ,core.order_id, core.order_date, core.quantity, core.customer_price, core.lineitem_total 
order by core.order_id desc)
select top.account_id, top.billname, top.email, top.address, top.city, top.state, top.zip, top,country_code, top.billphone, count(top.order_id) as order_id, sum(top.quantity) as quantity, sum(top.customer_price) as customer_price, sum(top.lineitem_total) as lineitem_total
from top
group by top.account_id, top.billname, top.email, top.address, top.city, top.state, top.zip, top,country_code, top.billphone;