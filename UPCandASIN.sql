// 
// UPC & ASIN Report (for Creative Kidstuff)
// Catherine Warren, 2015-07-20
// 

var sqlProcessor = new SelectSQLBuilder();

sqlProcessor.setSelect("select sum(ii.quantity) as skuQuantity, s.sku_id, st.itemstatus as skuStatus, s.name as sku_name, s.upc_code as sku_upc_code, pv.asin as version_asin, pv.productversion_id as version_id, st2.itemstatus as versionStatus, pv.name as version_name, pv.item_id, st3.itemstatus as item_status, i.name as item_name ");
sqlProcessor.setFrom("from ecommerce.sku as s, ecommerce.productversion as pv, ecommerce.productversionsku as pvs, ecommerce.item as i, ecommerce.itemstatus as st, ecommerce.itemstatus as st2, ecommerce.itemstatus as st3, ecommerce.rsinventoryitem as ii ");
sqlProcessor.setWhere("where s.sku_id = pvs.sku_id ");
sqlProcessor.appendWhere("s.sku_id = ii.sku_id and pvs.productversion_id = pv.productversion_id and pv.item_id = i.item_id and s.itemstatus_id = st.itemstatus_id and pv.itemstatus_id = st2.itemstatus_id and i.itemstatus_id = st3.itemstatus_id ");
sqlProcessor.appendWhere("i.primary_site_id IN (351, 352) and s.itemstatus_id != 5 ");
sqlProcessor.setGroupBy("group by s.sku_id, st.itemstatus, s.name, s.upc_code, pv.asin, pv.productversion_id, st2.itemstatus, pv.name, pv.item_id, st3.itemstatus, i.name ");
sqlProcessor.setOrderBy("order by s.sku_id asc ");

sql = sqlProcessor.queryString();

