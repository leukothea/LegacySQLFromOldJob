//
// SKU Location Report
// Catherine Warren, 2015-06
//

var sku_id = p["sku_id"];
var sku_name = p["sku_name"];
var showinactivelocations = p["showinactivelocations"];

var sqlProcessor = new SelectSQLBuilder();

sqlProcessor.setSelect("select s.sku_id, s.name as sku_name, l.aisle as sku_location_aisle, l.bay as sku_location_bay, l.shelf as sku_location_shelf, l.bin as sku_location_bin, sl.sku_location_status ");
sqlProcessor.setFrom("from ecommerce.sku as s, ecommerce.sku_location as l, ecommerce.sku_location_status as sl");
sqlProcessor.setWhere("where s.sku_id = l.sku_id and l.sku_location_status_id = sl.sku_location_status_id ");

if (notEmpty (showinactivelocations)) {
  sqlProcessor.appendWhere ("l.sku_location_status_id IN (1, 2)" );
}

else { sqlProcessor.appendWhere ("l.sku_location_status_id = 1 " );
     }

if (notEmpty (sku_id)) {
  sqlProcessor.appendWhere ("s.sku_id IN ( " + sku_id  + ")" );
}

if (notEmpty (sku_name)) {
  sqlProcessor.appendWhere ("s.name ILIKE ( %" + sku_name  + "%)" );
}

sqlProcessor.setOrderBy("order by l.aisle ");

sql = sqlProcessor.queryString();