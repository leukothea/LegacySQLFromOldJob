select i.item_id, i.name, st.itemstatus, min(CAST(sh.date_record_added as DATE))
from ecommerce.source_product_status_history as sh, ecommerce.item as i, ecommerce.itemstatus as st
where i.item_id = sh.source_id
and i.itemstatus_id = st.itemstatus_id
and sh.sourceclass_id = 5
and sh.previous_itemstatus_id IN (2, 3, 4)
and sh.new_itemstatus_id = 0
and i.itemstatus_id IN (0, 1)
and i.vendor_id = 83
and i.itembitmask & 256 != 256
and i.name NOT LIKE 'FP - %'
and sh.date_record_added >= '2015-01-15'
group by i.item_id, i.name, st.itemstatus, sh.date_record_added
UNION
(select distinct i.item_id, i.name, st.itemstatus, MIN(CAST(pv.initiallaunchdate as DATE)) as recentversions
from ecommerce.item as i, ecommerce.itemstatus as st, ecommerce.productversion as pv
where i.item_id = pv.item_id
and i.itemstatus_id = st.itemstatus_id
and pv.initiallaunchdate >= '2015-01-15'
and i.itemstatus_id IN (0, 1)
and i.name NOT LIKE 'FP - %'
and i.vendor_id = 83
and i.itembitmask & 256 != 256
and i.item_id NOT IN 
(select i.item_id
from ecommerce.source_product_status_history as sh, ecommerce.item as i, ecommerce.itemstatus as st 
where i.item_id = sh.source_id
and i.itemstatus_id = st.itemstatus_id
and sh.sourceclass_id = 5
and sh.previous_itemstatus_id IN (2, 3, 4)
and sh.new_itemstatus_id = 0
and i.itemstatus_id IN (0, 1)
and i.vendor_id = 83
and i.itembitmask & 256 != 256
and i.name NOT LIKE 'FP - %'
and sh.date_record_added >= '2015-01-15')
and i.item_id NOT IN 
(select i.item_id from ecommerce.item as i, ecommerce.itemstatus as st, ecommerce.productversion as pv 
where i.item_id = pv.item_id
and i.itemstatus_id = st.itemstatus_id
and pv.initiallaunchdate < '2015-01-15'
and i.itemstatus_id IN (0, 1)
and i.name NOT LIKE 'FP - %'
and i.vendor_id = 83
and i.itembitmask & 256 != 256)
group by i.item_id, i.name, st.itemstatus, pv.initiallaunchdate);