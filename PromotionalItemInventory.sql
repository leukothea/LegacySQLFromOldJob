//
// Promotional Item Inventory Report
// Revised 2015-10-22, Catherine Warren, to add a column for merchantprice and remove logic for product version math (since it was not accurate)
// Revising 2015-10-23 to provide just one row per item with multiple inventory records, and the correct summed quantity. 
// To do: Provide a merchantprice average that's weighted according to quantity. 
// 

var status = p["status"];
var vendorId = p["vendor"];

var inventoryProcessor = new SelectSQLBuilder();

inventoryProcessor.setSelect("select ii.sku_id, s.name, sum(ii.quantity) as sellable_inventory, avg(ii.merchantprice) as avg_unit_price ");
inventoryProcessor.setFrom("from ecommerce.rsinventoryitem as ii, ecommerce.sku as s ");
inventoryProcessor.setWhere("where ii.sku_id = s.sku_id and s.itemstatus_id != 5 and ii.active = TRUE ");
inventoryProcessor.setGroupBy("group by ii.sku_id, s.name ");
inventoryProcessor.setOrderBy("order by ii.sku_id asc ");

var sqlProcessor = new SelectSQLBuilder();

sqlProcessor.setSelect("select i.item_id,its.itemstatus as item_status,i.name as item_name ");
sqlProcessor.setFrom("from ecommerce.item as i, ecommerce.itemstatus as its, ecommerce.sku as s ");
sqlProcessor.setWhere("where i.name like 'PROMO%' and i.itemstatus_id = its.itemstatus_id ");
if (notEmpty(status) && status != "All") {
    sqlProcessor.appendWhere("i.itemstatus_id = " + status);
} else {
    sqlProcessor.appendWhere("i.itemstatus_id != 5");
}
if (notEmpty(vendorId)) {
    sqlProcessor.appendWhere("i.vendor_id = " + vendorId);
}

sqlProcessor.appendSelect("sum(inv.sellable_inventory) as sellable_inventory, CASE WHEN sum(inv.sellable_inventory) > 0 THEN sum(inv.sellable_inventory*inv.avg_unit_price)/sum(inv.sellable_inventory) ELSE 0 END as itemWeightedAverageCost ");
sqlProcessor.appendRelationToFromWithAlias(inventoryProcessor, "inv");
sqlProcessor.appendWhere("s.item_id = i.item_id ");
sqlProcessor.appendWhere("inv.sku_id = s.sku_id ");
sqlProcessor.setGroupBy("group by i.item_id, its.itemstatus, i.name ");
sqlProcessor.setOrderBy("order by sum(inv.sellable_inventory) desc, its.itemstatus ");

sql = sqlProcessor.queryString();