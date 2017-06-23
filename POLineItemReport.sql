//
// PO Line Item Report
// edited Catherine Warren, 2015-07-24 (adding Show Supplier Type checkbox)
// edited Catherine Warren, 2015-08-20 (fixing bug RPT-92)
//

var shipDateStart = p["shipDateStart"];
var shipDateEnd = p["shipDateEnd"];
var createDateStart = p["createDateStart"];
var createDateEnd = p["createDateEnd"];
var poNumber = p["poNumber"];
var lineItem = p["lineItem"];
var poStatus = p["poStatus"];
var lineItemStatus = p["lineItemStatus"];
var showSupplierType = p["showSupplierType"];
var showSupplier = p["showSupplier"];
var buyer = p["poBuyer"];
var reorder = p["reorder"];

if(buyer == "All"){ buyer = ""; }
if(reorder == "All"){ reorder = ""; }
if(poStatus == "All"){ poStatus = ""; }
if(lineItemStatus == "All"){ lineItemStatus = ""; }

var sqlProcessor = new SelectSQLBuilder();

sqlProcessor.setSelect("select po.purchaseOrder_id AS po_id, po.poNumber AS po_number, po.buyeruid as buyer,pos.status AS po_status, po.dateIssued::DATE AS create_date ");
sqlProcessor.appendSelect("po.shipDate::DATE AS ship_date, poli.quantityOrdered AS qty_ordered ");
sqlProcessor.appendSelect("pv.sku_id AS sku_id, pv.name AS sku_name, case when poli.is_reorder = 't' then 'Reorder' else 'New' end AS reorder_status ");
sqlProcessor.appendSelect("poli.unitPrice AS unit_price, rs.status AS line_item_status, COALESCE(sum(re.totalReceivedCount),0) AS qty_received ");
sqlProcessor.appendSelect("COALESCE(COALESCE(a.state, a.country_code) || ' ' || a.postal_code,'--') AS supplier_location ");
sqlProcessor.setFrom("from ecommerce.PurchaseOrder as po, ecommerce.PurchaseOrderStatus as pos, ecommerce.SKU as pv ");
sqlProcessor.appendFrom("ecommerce.ReceivingStatus as rs, ecommerce.Supplier as s, ecommerce.supplier_address as a, ecommerce.supplier_type as st ");
sqlProcessor.appendFrom("ecommerce.PurchaseOrderLineItem as poli LEFT OUTER JOIN ecommerce.ReceivingEvent as re ON poli.poLineItem_id = re.poLineItem_id ");
sqlProcessor.setWhere("where po.purchaseOrder_id = poli.purchaseOrder_id and poli.sku_id = pv.sku_id ");
sqlProcessor.appendWhere("poli.receivingStatus_id = rs.receivingStatus_id and po.purchaseOrderStatus_id = pos.purchaseOrderStatus_id ");
sqlProcessor.appendWhere("po.supplier_id = s.supplier_id and s.supplier_id = a.supplier_id and a.is_primary = true and s.supplier_type_id = st.supplier_type_id ");

if (notEmpty(shipDateStart)) {
    sqlProcessor.appendWhere("po.shipDate >= '" + shipDateStart + "'");
}
if (notEmpty(shipDateEnd)) {
    sqlProcessor.appendWhere("po.shipDate < '" + shipDateEnd + "'");
}
if (notEmpty(createDateStart)) {
    sqlProcessor.appendWhere("po.dateIssued >= '" + createDateStart + "'");
}
if (notEmpty(createDateEnd)) {
    sqlProcessor.appendWhere("po.dateIssued < '" + createDateEnd + "'");
}
if (notEmpty(poNumber)) {
    sqlProcessor.appendWhere("po.poNumber ILIKE '" + poNumber + "%'");
}
if (notEmpty(buyer)) {
    sqlProcessor.appendWhere("po.buyeruid = '" + buyer + "'");
}
if (notEmpty(reorder)) {
    sqlProcessor.appendWhere("poli.is_reorder = '" + reorder + "'");
}
if (notEmpty(lineItem)) {
    sqlProcessor.appendWhere("pv.name ILIKE '" + lineItem + "%'");
}
if (notEmpty(poStatus)) {
    if("0" == poStatus) {
        sqlProcessor.appendWhere("po.purchaseOrderStatus_id != 6");
    } else {
        sqlProcessor.appendWhere("po.purchaseOrderStatus_id = " + poStatus);
    }
}
if (notEmpty(lineItemStatus)) {
    sqlProcessor.appendWhere("poli.receivingStatus_id = " + lineItemStatus);
}
      
sqlProcessor.setGroupBy("group by po.purchaseOrder_id, po.poNumber, po.buyeruid,pos.status, po.dateIssued::DATE, po.shipDate::DATE, poli.quantityOrdered ");
sqlProcessor.appendGroupBy("pv.sku_id,pv.name,case when poli.is_reorder = 't' then 'Reorder' else 'New' end, poli.unitPrice, rs.status, COALESCE(COALESCE(a.state, a.country_code) || ' ' || a.postal_code,'--') ");
sqlProcessor.setOrderBy("order by po.poNumber, pos.status, poli.quantityOrdered desc ");

if(notEmpty(showSupplierType)) {
    sqlProcessor.appendSelect("st.supplier_type");
    sqlProcessor.appendGroupBy("st.supplier_type");
} else {
  	hide.push('supplier_type');
}

if(notEmpty(showSupplier)) {
    sqlProcessor.appendSelect("s.suppliername as supplier_name");
    sqlProcessor.appendGroupBy("s.suppliername");
} else {
  	hide.push('supplier_name');
}

sql = sqlProcessor.queryString();