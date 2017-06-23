

SKU weighted average cost: 
select sku_id , sum(quantity * merchantPrice) / sum(quantity) as cost 
from ecommerce.RSInventoryItem 
where quantity > 0 and merchantPrice > 0  and sku_id is not null group by sku_id


SKU Reorder Age: 
(abs(EXTRACT(DAY FROM COALESCE(rcvd.received_date, ii.daterecordadded, s.daterecordadded, s.initiallaunchdate) - now())))/365 as skuReorderAge
