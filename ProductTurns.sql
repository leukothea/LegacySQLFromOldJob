//
// Product Turns Report
// (formerly called Slow Seller Report)
// Edited 2015-10-15, Catherine Warren, to clean up some obvious weird things
// Edited 2015-10-20, Catherine Warren, to add an input and output for "buyer" from the SKU Category table, change the product name, and remove cost columns. 
// Edited 2015-11-09, Catherine Warren, to revise formula used for product turns. 
//

var interval = p["interval"];
var buyerName = p["buyer"];

var sqlProcessor = new SelectSQLBuilder();
var inventoryProcessor = new SelectSQLBuilder();
var runrateProcessor = new SelectSQLBuilder();
var salesProcessor = new SelectSQLBuilder();

inventoryProcessor.setSelect("select s.sku_id,sum(COALESCE(inv.quantity,0)) as quantity ");
inventoryProcessor.setFrom("from ecommerce.SKU as s, ecommerce.RSInventoryItem as inv ");
inventoryProcessor.setWhere("where inv.sku_id = s.sku_id and inv.quantity > 0 and inv.active = TRUE ");
inventoryProcessor.setGroupBy("group by s.sku_id ");

runrateProcessor.setSelect("select li.productversion_id, pa.authDate::DATE as runDate, sum(li.quantity) as runCount ");
runrateProcessor.setFrom("from ecommerce.rslineitem as li,ecommerce.paymentauthorization as pa ");
runrateProcessor.setWhere("where li.order_id = pa.order_id ");
runrateProcessor.appendWhere("pa.payment_transaction_result_id = 1 and pa.payment_status_id in (3,5,6) ");
runrateProcessor.setGroupBy("group by li.productversion_id,pa.authDate::DATE ");

if (notEmpty(interval)) {
    runrateProcessor.appendWhere("pa.authDate >= now()::DATE - cast('" + interval + " day' as interval) ");
}

salesProcessor.setSelect("select pv.name,max(pv.productVersion_id) productVersion_id ");
salesProcessor.appendSelect("sum(COALESCE(pvrr.runCount,0)) sold ");
salesProcessor.setFrom("from ecommerce.ProductVersion pv ");
salesProcessor.appendRelationToFromWithAlias(runrateProcessor, "pvrr");
salesProcessor.setWhere("where pv.productVersion_id = pvrr.productVersion_id and pvrr.runDate >= now()::DATE - cast('" + interval + " day' as interval) ");
salesProcessor.setGroupBy("group by pv.name ");

sqlProcessor.setSelect("select distinct pv.name as version_name,s.name as sku_name, COALESCE(ns.sold,0) as sold, vi.quantity, sc.buyer ");
sqlProcessor.appendSelect("CASE WHEN COALESCE(ns.sold,0) = 0 THEN 1000000 ELSE round((sum(COALESCE(pvrr.runCount,0)) / vi.quantity), 3) END AS turns ");
sqlProcessor.appendSelect("CASE WHEN COALESCE(ns.sold,0) = 0 THEN 1 WHEN (vi.quantity * 1.0 / ns.sold * 1.0) > 0 and (vi.quantity * 1.0 / ns.sold * 1.0) > 15 THEN 1 ELSE 0 END AS color ");
sqlProcessor.setFrom("from ecommerce.SKU s,ecommerce.ProductVersionSKU pvs,ecommerce.ProductVersion pv,ecommerce.Item i, ecommerce.skuCategory sc ");
sqlProcessor.appendRelationToFromWithAlias(salesProcessor, "ns");
sqlProcessor.appendRelationToFromWithAlias(inventoryProcessor, "vi");
sqlProcessor.appendRelationToFromWithAlias(runrateProcessor, "pvrr");
sqlProcessor.setWhere("where pv.productVersion_id = pvrr.productVersion_id and pv.item_id = i.item_id and i.vendor_id = 83 ");
sqlProcessor.appendWhere("pv.productVersion_id = pvs.productVersion_id and pvs.sku_id = s.sku_id and s.skuBitMask & 1 = 1 ");
sqlProcessor.appendWhere("s.sku_id = vi.sku_id and pv.productversion_id = ns.productversion_id and sc.sku_id = s.sku_id ");
sqlProcessor.setGroupBy("group by pv.name, s.name, ns.sold, vi.quantity, sc.buyer ");

if (notEmpty(buyerName)) {
      sqlProcessor.appendWhere("sc.buyer = '" + buyerName + "'");
}

sql = sqlProcessor.queryString();

