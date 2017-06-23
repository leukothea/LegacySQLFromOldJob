-- Order activity for today so far, by payment status and site: 

select 
	m.merchantaccount_id
	,m.merchantaccount
	,ps.payment_status
	,ptr.payment_transaction_result
	,m.partner
	,count(*)
	,sum(a.amount)
	,max(a.order_id)
	,max(a.authdate)
from 
	ecommerce.paymentauthorization as a
	,ecommerce.merchantaccount as m
	,ecommerce.payment_transaction_result as ptr
	,ecommerce.payment_status as ps
where 
	m.merchantaccount_id = a.merchantaccount_id
	and a.authdate::DATE = now()::DATE
	and ptr.payment_transaction_result_id = a.payment_transaction_result_id
	and a.payment_status_id = ps.payment_status_id
group by 
	m.merchantaccount_id
	,ps.payment_status
	,ptr.payment_transaction_result
	,m.merchantaccount
	,m.partner
order by 
	m.merchantaccount_id;
