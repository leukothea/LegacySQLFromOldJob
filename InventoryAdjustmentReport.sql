//
// Inventory Adjustment Report
// Catherine Warren, 2015-06-30
//

var startDate = p["start"];
var endDate = p["end"];
var sku_id = p["sku_id"];
var sku_name = p["sku_name"];
var reason = p["inventoryitem_adjustment_reason"];

var sqlProcessor = new SelectSQLBuilder();

sqlProcessor.setSelect("select s.sku_id, s.name as sku_name, a.adjustment_quantity as inventoryitem_adjustment_quantity, a.reason as inventoryitem_adjustment_reason, t.inventoryitem_adjustment_type, a.adjusted_by as inventoryitem_adjusted_by, a.date_record_added as inventoryitem_adjustment_date, a.destination_inventoryitem_id as inventoryitem_adjustment_destination_id");
sqlProcessor.setFrom("from ecommerce.rsinventoryitem as ii, ecommerce.inventoryitem_adjustment as a, ecommerce.sku as s, ecommerce.inventoryitem_adjustment_type as t");
sqlProcessor.setWhere("where ii.sku_id = s.sku_id and a.destination_inventoryitem_id = ii.oid and a.inventoryitem_adjustment_type_id = t.inventoryitem_adjustment_type_id");

if (notEmpty(startDate)) {
    sqlProcessor.appendWhere("a.date_record_added >= '" + startDate + "'");
} else {
    sqlProcessor.appendWhere("a.date_record_added >= date_trunc('month',now()::DATE)");
}
if (notEmpty(endDate)) {
    sqlProcessor.appendWhere("a.date_record_added < '" + endDate + "'");
}
if (notEmpty (sku_id)) {
  sqlProcessor.appendWhere ("s.sku_id IN ( '" + sku_id  + "')" );
}
if (notEmpty (sku_name)) {
  sqlProcessor.appendWhere("s.name ILIKE '%" + sku_name + "%'");
}
if (notEmpty (reason)) {
  sqlProcessor.appendWhere("a.reason ILIKE '%" + reason + "%'");
}

sqlProcessor.setOrderBy("order by s.sku_id asc");

sql = sqlProcessor.queryString();


