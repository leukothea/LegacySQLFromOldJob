//
// Sales By Supplier Report
// Catherine Warren, 2015-07-30
//

var startDate = p["start"];
var endDate = p["end"];
var supplierName = p["supplier_name"];
var showDates = p["showDate"];
var showversion = p["sv"];
var buyerName = p["buyer"];

var buyerProcessor = new SelectSQLBuilder();
var skuProcessor = new SelectSQLBuilder();

sum.push('total_sold');
sum.push('customer_price');

buyerProcessor.setSelect("select distinct pvsku.productversion_id,sc.buyer");
buyerProcessor.setFrom("from ecommerce.productversionsku pvsku,ecommerce.skucategory sc");
buyerProcessor.setWhere("where pvsku.sku_id = sc.sku_id");


var sqlProcessor = new SelectSQLBuilder();

skuProcessor.setSelect("select s.supplierName AS supplier_name,sku.sku_id,sum(ii.quantity) AS remaining_inventory");
skuProcessor.setFrom("from ecommerce.Supplier AS s ,ecommerce.RSInventoryItem AS ii ,ecommerce.SKU AS sku ");
skuProcessor.setWhere("where s.supplier_id = ii.supplier_id and ii.sku_id = sku.sku_id ");
if (notEmpty(supplierName)) {
   skuProcessor.appendWhere("s.supplierName ILIKE '" + supplierName + "%' ");
}



skuProcessor.setGroupBy("group by s.supplierName ,sku.sku_id ");

sqlProcessor.setSelect("select s.supplier_name AS supplier_name");
sqlProcessor.appendSelect("sum(li.quantity) AS total_sold,sum(COALESCE(li.customerPrice,0.00)) AS customer_price");
sqlProcessor.setFrom("from ecommerce.ProductVersionSKU pvs, ecommerce.productversion as pv, ecommerce.SKU as sku,ecommerce.RSLineItem as li, ecommerce.item as i ");
sqlProcessor.appendRelationToFromWithAlias(skuProcessor,"s");
sqlProcessor.setWhere("where pvs.productversion_id = pv.productversion_id and s.sku_id = sku.sku_id and sku.sku_id = pvs.sku_id and pv.item_id = i.item_id ");
sqlProcessor.appendWhere("pvs.productVersion_id = li.productVersion_id and li.fulfillmentDate is not null and i.vendor_id = 83 ");
sqlProcessor.setGroupBy("group by s.supplier_name");

if (notEmpty(buyerName)) {
  	sqlProcessor.appendSelect("bp.buyer");
	sqlProcessor.appendRelationToFromWithAlias(buyerProcessor, "bp");	
	sqlProcessor.appendWhere("bp.productversion_id = pv.productversion_id and bp.buyer ILIKE '" + buyerName.replace("'", "''") + "%'");
	sqlProcessor.appendGroupBy("bp.buyer");
} else {
	hide.push('buyer');
}

if (notEmpty(showDates)) {
    sqlProcessor.appendSelect("date_part('year',li.fulfillmentDate::DATE)::CHAR(4) AS fulfillment_year,date_part('month',li.fulfillmentDate::DATE)::CHAR(2) AS fulfillment_month");
    sqlProcessor.appendGroupBy("date_part('year',li.fulfillmentDate::DATE)::CHAR(4),date_part('month',li.fulfillmentDate::DATE)::CHAR(2)");
} else {
	hide.push('fulfillment_year');
	hide.push('fulfillment_month');
}

sqlProcessor.setOrderBy("order by s.supplier_name");

if (notEmpty(showversion)) {
    sqlProcessor.appendSelect("pv.productversion_id as version_id, pv.name as version_name, st.itemstatus as versionStatus");
    sqlProcessor.appendFrom("ecommerce.itemstatus as st ");
    sqlProcessor.appendWhere("pv.itemstatus_id = st.itemstatus_id ");
    sqlProcessor.appendGroupBy("pv.productversion_id, pv.name, st.itemstatus");
    sqlProcessor.appendOrderBy("pv.name");
} else {
	hide.push('version_id');
	hide.push('version_name');
  	hide.push('versionStatus');
}
if (notEmpty(startDate)) {
    sqlProcessor.appendWhere("li.fulfillmentDate >= '" + startDate + "'");
} else {
    sqlProcessor.appendWhere("li.fulfillmentDate >= '20010701'");
}
if (notEmpty(endDate)) {
    sqlProcessor.appendWhere("li.fulfillmentDate < '" + endDate + "'");
}

sql = sqlProcessor.queryString();