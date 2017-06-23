-- Novica items older than 6 months, with sales in the past but not in the last year.  Doesn't look for no sales ever

select 
	i.item_id
	,i.name as item_name
	,its.itemstatus
	,i.daterecordadded
	,sum(coalesce(n.units_sold,0)) as units_sold
from 
	ecommerce.item as i
	,ecommerce.itemstatus as its
	,ecommerce.productversion as pv 
		LEFT OUTER JOIN (
			select 
				li.productversion_id
				,sum(li.quantity) as units_sold
			from 
				ecommerce.rslineitem as li
				,ecommerce.paymentauthorization as pa
				,ecommerce.productversion as pv
				,ecommerce.item as i
			where 
				li.order_id = pa.order_id 
				and pa.authDate::DATE >= date_trunc('month',now()::DATE) - cast('12 month' as interval)
				and pa.payment_transaction_result_id = 1 
				and pa.payment_status_id in (3,5,6)
				and li.productversion_Id = pv.productversion_id 
				and pv.item_id = i.item_id 
				and i.vendor_id = 81
			group by 
				li.productversion_id
		) as n on pv.productversion_id = n.productversion_id
where 
	i.item_id = pv.item_id 
	and i.vendor_id = 81 
	and i.itemstatus_id = its.itemstatus_id 
	and its.itemstatus_id in (0,1)
	and pv.daterecordadded < date_trunc('month',now()::DATE) - cast('6 month' as interval)
group by 
	i.item_id
	,i.name
	,its.itemstatus
	,i.daterecordadded
having 
	sum(coalesce(n.units_sold,0)) = 0
order by 
	i.daterecordadded
	,units_sold asc;

-- Novica items created more than 6 months ago with NO SALES EVER

select distinct 
	i.item_id
	,i.name as item_name
	,its.itemstatus
	,i.daterecordadded
from 
	ecommerce.item as i
	,ecommerce.itemstatus as its
	,ecommerce.productversion as pv
where 
	i.item_id = pv.item_id 
	and i.vendor_id = 81 
	and i.itemstatus_id = its.itemstatus_id 
	and its.itemstatus_id in (0,1)
	and pv.daterecordadded < date_trunc('month',now()::DATE) - cast('6 month' as interval)
	and pv.productversion_id not in (
		select distinct 
			productversion_id 
		from 
			ecommerce.rslineitem 
		where 
			fulfillmentdate is not null)
order by 
	i.daterecordadded;

-- rolled up by item

select 
	i.item_id
	,i.name as item_name
	,its.itemstatus
	,sum(coalesce(n.units_sold,0)) as units_sold
from 
	ecommerce.item as i
	,ecommerce.itemstatus as its
	,ecommerce.productversion as pv 
		LEFT OUTER JOIN (
			select 
				li.productversion_id
				,sum(li.quantity) as units_sold
			from 
				ecommerce.rslineitem as li
				,ecommerce.paymentauthorization as pa
				,ecommerce.productversion as pv
				,ecommerce.item as i
			where 
				li.order_id = pa.order_id 
				and pa.authDate::DATE >= date_trunc('month',now()::DATE) - cast('6 month' as interval)
				and pa.payment_transaction_result_id = 1 
				and pa.payment_status_id in (3,5,6)
				and li.productversion_Id = pv.productversion_id 
				and pv.item_id = i.item_id 
				and i.vendor_id = 81
			group by 
				li.productversion_id
		) as n on pv.productversion_id = n.productversion_id
where 
	i.item_id = pv.item_id 
	and i.vendor_id = 81 
	and i.itemstatus_id = its.itemstatus_id 
	and its.itemstatus_id in (0,1)
	and i.daterecordadded < date_trunc('month',now()::DATE) - cast('6 month' as interval)
group by 
	i.item_id
	,i.name
	,its.itemstatus
order by 
	units_sold asc;
