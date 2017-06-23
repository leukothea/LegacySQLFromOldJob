//
// SKUs by Country of Origin
// Catherine Warren, 2015-08-31
// Edited 2015-09-02 to add vendor select
//

var continent = p["continent"];
var countryCode = p["countryOfOrigin3"];
var vendorId = p["vendor"];
var sku_id = p["sku_id"];
var sku_name = p["sku_name"];

var sqlProcessor = new SelectSQLBuilder();

sqlProcessor.setSelect("select s.sku_id, s.name as sku_name, i.item_id, i.name as item_name, s.isoCountryCodeOfOrigin as country_code ");
sqlProcessor.setFrom("from ecommerce.sku as s, ecommerce.item as i ");
sqlProcessor.setWhere("where s.item_id = i.item_id and i.itemstatus_id != 5 ");

if (notEmpty (continent)) {
  sqlProcessor.appendWhere ("s.isocountrycodeoforigin IN ( " + continent + ")" );
}


if (notEmpty (countryCode)) {
  sqlProcessor.appendWhere ("s.isocountrycodeoforigin ILIKE ( '%" + countryCode + "%')" );
}

if (notEmpty(vendorId)) {
    sqlProcessor.appendWhere("i.vendor_id = " + vendorId);
    }

if (notEmpty (sku_id)) {
  sqlProcessor.appendWhere ("s.sku_id IN ( " + sku_id  + ")" );
}

if (notEmpty (sku_name)) {
  sqlProcessor.appendWhere ("s.name ILIKE ( %" + sku_name  + "%)" );
}

sqlProcessor.setOrderBy("order by s.item_id ");

sql = sqlProcessor.queryString();