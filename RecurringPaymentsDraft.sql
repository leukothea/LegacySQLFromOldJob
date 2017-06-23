WITH minorder_lineitems as (select min(pa.authorization_id) as authorization_id, pa.order_id, 1 as min_lineitem
 from ecommerce.paymentauthorization as pa 
 where pa.payment_status_id IN (3, 5, 6) and pa.payment_transaction_result_id = 1 
 group by pa.order_id
 order by pa.order_id asc)
, paymentauths AS (select pa.authorization_id, pa.order_id, pa.authdate, pa.payment_method_id
from ecommerce.paymentauthorization as pa 
where pa.payment_status_id IN (3, 5, 6) and pa.payment_transaction_result_id = 1 
group by pa.authorization_id, pa.order_id, pa.authdate, pa.payment_method_id
order by pa.authorization_id asc )
select pa.authorization_id, pa.order_id, pa.authdate, pa.payment_method_id, (CASE WHEN min.min_lineitem = 1 THEN 1 ELSE 0 END) as initial_subscription, (CASE WHEN min.min_lineitem IS NULL THEN 1 ELSE 0 END) as recurring_subscription
from paymentauths as pa LEFT OUTER JOIN minorder_lineitems as min ON pa.authorization_id = min.authorization_id

SELECT DISTINCT li.order_id, o.account_id ,(CASE WHEN a.firstname = a.lastname AND a.firstname LIKE '% %' THEN a.firstname ELSE a.firstname || ' ' || a.lastname END) AS name ,COALESCE (o.email, act.email) AS email ,li.productversion_id AS version_id, pv.name AS version_name, li.quantity ,(CASE WHEN ss.subscription_status_id = 1 THEN li.quantity * li.customerprice ELSE 0 END) as lineitem_total ,pa.authdate AS authdate, ss.subscription_status AS subscription_status , minorder_lineitems.mincount as count_initial_subscription 
FROM ecommerce.subscription_payment_authorization AS spa JOIN paymentauths AS pa ON spa.authorization_id = pa.authorization_id LEFT OUTER JOIN minorder_lineitems ON spa.authorization_id = minorder_lineitems.minimum_authid, ecommerce.subscription AS s, ecommerce.subscription_status AS ss, ecommerce.rsaddress AS a, pheme.account AS act ,ecommerce.rsorder AS o, ecommerce.productversion AS pv, ecommerce.rslineitem AS li 
WHERE li.order_id = o.oid AND o.billingaddress_id = a.oid AND o.account_id = act.account_id  and li.productversion_id = pv.productversion_id AND li.subscription_id = s.subscription_id  and s.subscription_status_id = ss.subscription_status_id AND spa.subscription_id = s.subscription_id  and li.lineitemtype_id = 8 AND li.subscription_id is not NULL and o.oid = 31809986;



select pa.authorization_id, pa.authdate, pa.avsaddress, pa.cvv2match, pa.payment_method_id 
from ecommerce.paymentauthorization as pa 
where pa.payment_status_id IN (3, 5, 6) and pa.payment_transaction_result_id = 1  and pa.authdate >= '04/06/2017' 
and pa.order_id = 31809986
order by pa.authorization_id asc 

select * from ecommerce.subscription_payment_authorization as spa, ecommerce.paymentauthorization as pa where spa.authorization_id = pa.authorization_id and pa.order_id = 31809986;

