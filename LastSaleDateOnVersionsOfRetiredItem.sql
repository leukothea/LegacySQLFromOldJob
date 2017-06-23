-- Last sale date on versions of retired item

select 
	max(li.fulfillmentdate)
	, v.name
	, i.item_id
	, i.name
from 
	ecommerce.rslineitem as li
	, ecommerce.productversion as v
	, ecommerce.item as i
where 
	li.productversion_id = v.productversion_id
	and v.item_id = i.item_id
	and i.itemstatus_id = 5
	and i.vendor_id = 83
	and li.fulfillmentdate is not null
group by 
	v.name
	, i.item_id
	, i.name
order by 
	v.name asc;