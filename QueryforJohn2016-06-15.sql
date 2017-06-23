with zz as ( 
	WITH adjustments as (
		select 
			a.order_id
			, a.adjustment_type_id
			, a.amount as adjustment
			, a.promotion_id 
		from 
			ecommerce.rsadjustment as a
		), gtgmtotal as (
			WITH gtgm as (
				select 
					rsli.order_id
					, (rsli.customerprice * rsli.quantity) as gtgm_subtotal 
				from 
					ecommerce.rslineitem as rsli
					, ecommerce.productversion as pv
					, ecommerce.item as i 
				where 
					rsli.productversion_id = pv.productversion_id 
					and pv.item_id = i.item_id 
					and i.itembitmask & 32 = 32 
					and rsli.quantity > 0)
			select 
				gtgm.order_id
				, sum(gtgm.gtgm_subtotal) as gtgm_total 
			from 
				ecommerce.rsorder as o RIGHT JOIN gtgm ON o.oid = gtgm.order_id 
			group by 
				gtgm.order_id
		)
select 
	distinct o.oid as order_id 
	, pa.authdate::DATE as authorization_date
	, (CASE WHEN EXTRACT(month FROM pa.authdate::DATE) = 1 THEN 'January' WHEN EXTRACT(month FROM pa.authdate::DATE) = 2 THEN 'February' ELSE 'March' END) as month
	, (CASE WHEN adjustments.adjustment_type_id != 6 THEN (pa.amount - adjustments.adjustment) ELSE pa.amount END) as total_amount_charged
	, o.tax as tax
	, (CASE WHEN adjustments.adjustment_type_id = 6 THEN (o.shippingcost - adjustments.adjustment) ELSE o.shippingcost END) as order_shipping_charge
	, cast((COALESCE(gtgmtotal.gtgm_total, 0.00)) AS numeric(9,2)) as gtgm_total
	, a2.state as shipto_state
from 
	ecommerce.rsorder as o LEFT OUTER JOIN adjustments ON o.oid = adjustments.order_id LEFT OUTER JOIN gtgmtotal ON o.oid = gtgmtotal.order_id 
	, ecommerce.paymentauthorization as pa
	, ecommerce.rsaddress as a2
	, ecommerce.rslineitem as rsli
where 
	o.oid = pa.order_id
	and pa.payment_status_id IN (3, 5, 6)
	and pa.payment_transaction_result_id = 1
	and o.shippingaddress_id = a2.oid
	and o.oid = rsli.order_id
	and a2.state = 'MN'
	and rsli.lineitemtype_id IN (1, 5)
	and rsli.quantity > 0
	and pa.authdate::DATE > '2015-12-31'
	and pa.authdate::DATE < '2016-04-01'
group by 
	o.oid
	, pa.authdate
	, adjustments.adjustment_type_id
	, pa.amount
	, adjustments.adjustment
	, a2.state
	, gtgmtotal.gtgm_total
UNION
select 
	distinct o.oid as order_id 
	, pa.authdate::DATE as authorization_date
	, (CASE WHEN EXTRACT(month FROM pa.authdate::DATE) = 1 THEN 'January' WHEN EXTRACT(month FROM pa.authdate::DATE) = 2 THEN 'February' ELSE 'March' END) as month
	, (CASE WHEN adjustments.adjustment_type_id != 6 THEN (pa.amount - adjustments.adjustment) ELSE pa.amount END) as total_amount_charged
	, o.tax as tax
	, (CASE WHEN adjustments.adjustment_type_id = 6 THEN (o.shippingcost - adjustments.adjustment) ELSE o.shippingcost END) as order_shipping_charge
	, cast((COALESCE(gtgmtotal.gtgm_total, 0.00)) AS numeric(9,2)) as gtgm_total
	, a1.state as shipto_state
from 
	ecommerce.rsorder as o 
		LEFT OUTER JOIN adjustments ON o.oid = adjustments.order_id 
		LEFT OUTER JOIN gtgmtotal ON o.oid = gtgmtotal.order_id 
	, ecommerce.paymentauthorization as pa
	, ecommerce.rsaddress as a1
	, ecommerce.rslineitem as rsli
where 
	o.oid = pa.order_id
	and pa.payment_status_id IN (3, 5, 6)
	and pa.payment_transaction_result_id = 1
	and o.billingaddress_id = a1.oid
	and o.shippingaddress_id IS NULL
	and o.oid = rsli.order_id
	and a1.state = 'MN'
	and rsli.lineitemtype_id IN (1, 5)
	and rsli.quantity > 0
	and pa.authdate::DATE > '2015-12-31'
	and pa.authdate::DATE < '2016-04-01'
group by 
	o.oid
	, pa.authdate
	, adjustments.adjustment_type_id
	, pa.amount
	, adjustments.adjustment
	, a1.state
	, gtgmtotal.gtgm_total
order by 
	order_id asc) 
	select * from zz order by order_id asc;