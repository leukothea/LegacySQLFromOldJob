-- First names on accounts, in descending order by popularity.

select distinct 
	first_name
	, count(first_name) 
from 
	pheme.account
group by 
	first_name
order by 
	count(first_name) desc;

-- First names on billing addresses for orders completed in the past year.

select 
	ad.firstname
	, o.email
from 
	ecommerce.rsorder as o
	, ecommerce.rsaddress as ad
	, ecommerce.paymentauthorization as pa
where 
	o.oid = pa.order_id
	and ad.oid = o.billingaddress_id
	and pa.payment_transaction_result_id = 1
	and pa.payment_status_id in (3,5)
	and pa.authDate::DATE > '2013-03-01'
order by 
	d.firstname;

-- Firstname and email on billing addresses for orders completed in the past year (not subsequently voided out) with firstname Linda, including lowercased names and names with a suffix:

select 
	ad.firstname
	, o.email
from 
	ecommerce.rsorder as o
	, ecommerce.rsaddress as ad
	, ecommerce.paymentauthorization as pa
where 
	o.oid = pa.order_id
	and ad.oid = o.billingaddress_id
	and pa.payment_transaction_result_id = 1
	and pa.payment_status_id in (3,5)
	and pa.authDate::DATE > '2013-03-01'
	and lower(ad.firstname) like 'linda%'
order by 
	ad.firstname;


-- Count of the firstnames on the billingaddresses of completed (not voided out) orders since March 1, 2013

select 
	count(ad.firstname)
	, ad.firstname
from 
	ecommerce.rsorder as o
	, ecommerce.rsaddress as ad
	, ecommerce.paymentauthorization as pa
where 
	o.oid = pa.order_id
	and ad.oid = o.billingaddress_id
	and pa.payment_transaction_result_id = 1
	and pa.payment_status_id in (3,5)
	and pa.authDate::DATE > '2013-03-01'
group by 
	ad.firstname
order by 
	count(ad.firstname) desc;

