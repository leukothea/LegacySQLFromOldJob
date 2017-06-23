//
// Supplier Inventory Report
// Revised Catherine Warren, 2015-10-23, to add an input and output for SKU partnumber (RPT-159)
//

var sku_id = p["sku_id"];
var skuName = p["sku_name"];
var supplier = p["supplier_name"];
var partNumber = p["partNumber"];
var status = p["status"];
var buyerName = p["buyer"];
var vendorId = p["vendor"];
var show_all_line_items = p["show_all_line_items"];

sum.push('inventory');

var sqlProcessor = new SelectSQLBuilder();

sqlProcessor.setSelect("select p.supplierName AS supplier_name,s.sku_id,s.name as sku_name,s.partnumber, COALESCE(ii.merchantPrice,0.00) AS merchant_price,sum(COALESCE(ii.quantity,0)) AS inventory,stat.itemStatus AS item_status,stat.ordinal ");
sqlProcessor.setFrom("from ecommerce.Supplier p,ecommerce.RSInventoryItem ii,ecommerce.SKU s,ecommerce.ItemStatus stat ");
sqlProcessor.setWhere("where ii.sku_id = s.sku_id and s.itemStatus_id = stat.itemStatus_id and s.skuBitMask & 1 = 1 and ii.supplier_id = p.supplier_id ");

if (notEmpty(sku_id)) {
    sqlProcessor.appendWhere("ii.sku_id = " + sku_id);
}

if (notEmpty(skuName)) {
    sqlProcessor.appendWhere("s.name ILIKE '" + skuName + "'");
}

if (notEmpty(supplier)) {
    sqlProcessor.appendWhere("p.supplierName ILIKE '" + supplier + "%'");
}

if (notEmpty(partNumber)) {
    sqlProcessor.appendWhere("s.partNumber ILIKE '%" + partNumber + "%'");
}

if (notEmpty(status)) { 
    if("All" == status) {
    sqlProcessor.appendWhere("stat.itemstatus_id IN (0, 1, 2, 3, 4, 5, 6, 7) ");
    	} else {
    sqlProcessor.appendWhere("stat.itemstatus_id = " + status);
    	}
}

if (notEmpty(buyerName)) {
    sqlProcessor.appendFrom("ecommerce.skuCategory sc ");
    sqlProcessor.appendWhere("sc.sku_id = s.sku_id ");
    sqlProcessor.appendWhere("sc.buyer ILIKE '" + buyerName.replace("'", "''") + "%'");
}

if (notEmpty(vendorId)) {
    sqlProcessor.appendFrom("ecommerce.item as i ");
    sqlProcessor.appendWhere("s.item_id = i.item_id ");
    sqlProcessor.appendWhere("i.vendor_id = " + vendorId);
    }

if (notEmpty(show_all_line_items)) {
   sqlProcessor.appendWhere("s.itemstatus_id IN (0, 1, 2, 3, 4, 5, 6, 7) ");
   } else {
   sqlProcessor.appendWhere("s.itemstatus_id != 5 and ii.active = TRUE ");
   }

sqlProcessor.setOrderBy("order by stat.ordinal, p.supplierName, s.name ");
sqlProcessor.setGroupBy("group by p.supplierName, s.sku_id, s.name, s.partnumber, COALESCE(ii.merchantPrice,0.00), stat.itemStatus,stat.ordinal ");
        
sql = sqlProcessor.queryString();