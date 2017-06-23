-- Show any orders with more than one auth

select 
	order_id
	,count(*) 
from 
	ecommerce.paymentauthorization
where 
	payment_status_id = 3
	and payment_transaction_result_id = 1
group by 
	order_id 
having 
	count(*) > 1;
