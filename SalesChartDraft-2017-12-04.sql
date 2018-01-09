// Sales Chart Draft 2017-12-04

with pauth AS (SELECT MIN(payauth.authorization_id) OVER (PARTITION BY payauth.order_id) AS min_authorization_id, payauth.authorization_id ,payauth.order_id, payauth.authdate, payauth.merchantaccount_id 
FROM ecommerce.paymentauthorization payauth 
WHERE payauth.payment_transaction_result_id = 1 AND payauth.payment_status_id IN (3,5,6)
) 
select 'All Sites' AS site_name, max(pauth.authDate::DATE) AS auth_date, to_char(pauth.authDate,'HH24') AS auth_hour,sum(li.quantity) AS data
from ecommerce.RSOrder o INNER JOIN pauth ON o.oid = pauth.order_id, ecommerce.RSLineItem li, ecommerce.MerchantAccount ma
where o.oid = li.order_id and COALESCE(li.lineItemType_id,1) = 1 and pauth.merchantAccount_id = ma.merchantAccount_id and pauth.authDate >= '12/01/2017'
group by pauth.authDate::DATE, to_char(pauth.authDate,'HH24')
order by pauth.authDate::DATE, to_char(pauth.authDate,'HH24')
 