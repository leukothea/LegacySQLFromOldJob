// 
// Active GTGMs Missing Tax Receipt Email
// Catherine Warren, 2015-07-20
// Revised to add a column to show the product version status, 2015-10-06
// 

var sqlProcessor = new SelectSQLBuilder();

sqlProcessor.setSelect("select pv.productversion_id as version_id, pv.name as version_name, ist.itemstatus as status ");
sqlProcessor.setFrom("from chimera.content as cc, ecommerce.productversion as pv, ecommerce.item as i, ecommerce.itemstatus as ist ");
sqlProcessor.setWhere("where i.item_id = pv.item_id and pv.itemstatus_id = ist.itemstatus_id ");
sqlProcessor.appendWhere("i.vendor_id IN (37, 77) and pv.productversion_id not in (select cc.source_id from chimera.content as cc, panacea.source_class as psc, ecommerce.productversion as pv where pv.productversion_id = cc.source_id and cc.source_class_id = psc.source_class_id and psc.source_class_id = 10) and pv.itemstatus_id IN (0, 1)  ");
sqlProcessor.setGroupBy("group by pv.productversion_id, pv.name, ist.itemstatus ");
sqlProcessor.setOrderBy("order by pv.productversion_id desc ");

sql = sqlProcessor.queryString();