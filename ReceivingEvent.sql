//
// Receiving Event Report
// Edited Catherine Warren, 2015-12-16 | JIRA RPT-122
//

var start = p["start"];
var end = p["end"];
var skuId = p["sku_id"];
var buyer = p["poBuyer"];
var supplierName = p["supplier_name"];
var itemId = p["itemId"];
var inventory_id = p["inventoryitem_id"];
var poId = p["po_id"];
var poNumber = p["poNumber"];
var countryOfOrigin = p["countryOfOrigin"];
var receivingevent_id = p["receivingevent_id"];

if(buyer == "All"){buyer="";}
if(countryOfOrigin == "All"){countryOfOrigin="";}

var sqlProcessor = new SelectSQLBuilder();

sqlProcessor.setSelect("select po.buyeruid AS buyer,po.purchaseOrder_id AS po_id, po.poNumber AS po_number, pos.status AS po_status,s.sku_id AS sku_id, s.name AS sku_name,s.item_id, ii.oid as inventory_id, COALESCE(poli.supplier_part_number,'N/A') as supplier_part_number,re.receiveddate::DATE AS received_date");
sqlProcessor.appendSelect("case when poli.is_reorder = 't' then 'Reorder' else 'New' end AS reorder_status");
sqlProcessor.appendSelect("COALESCE(re.receivingEvent_id,0) AS receiving_event_id,re.totalreceivedcount AS total_received, re.badreceivedcount AS bad_received,poli.unitPrice * re.totalreceivedcount AS total_received_value,poli.unitPrice * re.badreceivedcount AS bad_received_value");
sqlProcessor.setFrom("from ecommerce.PurchaseOrder po, ecommerce.PurchaseOrderLineItem poli, ecommerce.PurchaseOrderStatus pos, ecommerce.SKU s, ecommerce.ReceivingEvent re, ecommerce.rsinventoryitem as ii ");
sqlProcessor.setWhere("where po.purchaseOrder_id = poli.purchaseOrder_id and poli.sku_id = s.sku_id and poli.poLineItem_id = re.poLineItem_id and ii.sku_id = s.sku_id and ii.receivingevent_id = re.receivingevent_id ");

if (notEmpty(poId)) {
    sqlProcessor.appendWhere("po.purchaseOrder_id =  " + poId);
}

if (notEmpty(supplierName)) {
    sqlProcessor.appendFrom("ecommerce.supplier AS u");
    sqlProcessor.appendWhere("po.supplier_id = u.supplier_id");
    sqlProcessor.appendWhere("u.suppliername ILIKE '" + supplierName + "'");
}

if (notEmpty(countryOfOrigin)) {
    sqlProcessor.appendWhere("s.isocountrycodeoforigin = '" + countryOfOrigin + "'");
}

sqlProcessor.appendWhere("po.purchaseOrderStatus_id = pos.purchaseOrderStatus_id");

if (notEmpty(start)) {
    sqlProcessor.appendWhere("re.receiveddate >= '" + start + "'");
}

if (notEmpty(end)) {
    sqlProcessor.appendWhere("re.receiveddate < '" + end + "'");
}

if (notEmpty(buyer)) {
    sqlProcessor.appendWhere("COALESCE(po.buyerUid,'unknown') = '" + buyer + "'");
}

if (notEmpty(skuId)) {
    sqlProcessor.appendWhere("poli.sku_id = " + skuId);
}

if (notEmpty(poNumber)) {
    sqlProcessor.appendWhere("po.poNumber ILIKE '" + poNumber + "'");
}

if (notEmpty(itemId)) {
    sqlProcessor.appendWhere("s.item_id = " + itemId);
}

if (notEmpty(inventory_id)) {
    sqlProcessor.appendWhere("ii.oid = " + inventory_id);
}

if (notEmpty(receivingevent_id)) {
    sqlProcessor.appendWhere("re.receivingevent_id = " + receivingevent_id);
}

sqlProcessor.setOrderBy("order by po.poNumber, pos.status");

sql = sqlProcessor.queryString();