WITH tax_addresses AS ( 	    select 
	        o.oid as order_id
	        , COALESCE(o.shippingaddress_id,o.billingaddress_id) as address_id
	    from 
	        ecommerce.paymentauthorization pa
	        ,ecommerce.rsorder o
	    where 
	        pa.payment_transaction_result_id = 1 
	        and pa.order_id = o.oid
	), paymentcredits as ( 	    select
	        ptt.authorization_id
	        , ptt.amount as refund_amount
	        , ptt.trandate as refund_date
	    from
	        ecommerce.paymenttransaction as ptt
	    where
	        ptt.payment_transaction_type_id = 5
	        and ptt.payment_transaction_result_id = 1
	)
select     ps.payment_status
    , o.oid as order_id
    , pa.authdate::DATE as original_order_authorization_date
    , -(ptt.refund_amount) as refund_amount
    , ptt.refund_date::date as refund_date
    , ptt.authorization_id as refund_authorization_id
from 
    ecommerce.rsorder as o 
    , ecommerce.paymentauthorization as pa LEFT OUTER JOIN paymentcredits as ptt ON pa.authorization_id = ptt.authorization_id
    , ecommerce.payment_status as ps
    , ecommerce.rsaddress as a
    , tax_addresses as taxadd 
where o.oid = taxadd.order_id
    and o.oid = pa.order_id
        and pa.payment_status_id = ps.payment_status_id
    and ptt.refund_date::date >= :startdate
    and ptt.refund_date::date < :enddate
    and pa.payment_transaction_result_id = 1
    and pa.payment_status_id IN (5, 6, 7) 
        and o.oid = taxadd.order_id
    and taxadd.address_id = a.oid
    and a.state = 'MN'
group by
    ps.payment_status
    , o.oid
    , pa.authdate
    , ptt.refund_amount
    , ptt.refund_date
    , ptt.authorization_id
    , a.oid