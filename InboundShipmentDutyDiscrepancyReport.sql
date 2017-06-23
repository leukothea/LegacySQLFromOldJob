//
// Inbound Shipment Duty Discrepancy Report
// Revised Catherine Warren, 2015-11-05 (RPT-134)
// Revised Catherine Warren, 2015-12-23, to add "show line items" option (RPT-178)
//

var shipmentId = p["shipmentId"];
var dateAdded = p["dateAdded"];
var show_all_line_items = p["show_all_line_items"];

var sli_tmpProcessor = new SelectSQLBuilder();
// This subquery gathers information about shipmentlineitems 
sli_tmpProcessor.setSelect("select sli.inbound_shipment_id as shipment_id, sum(COALESCE(sli.duty_percent,0.00) *.01 * COALESCE(poli.unitprice) * sli.quantity) as sli_duty, sum(coalesce(re.totalreceivedcount * poli.unitprice )) as summed_shipmentlineitem_value ");
sli_tmpProcessor.setFrom("from ecommerce.inbound_shipment_line_item sli, ecommerce.purchaseorderlineitem poli, ecommerce.receivingevent as re ");
sli_tmpProcessor.setWhere("where sli.po_line_item_id = poli.polineitem_id and poli.polineitem_id = re.polineitem_id and sli.shipment_line_item_id = re.shipment_line_item_id ");
sli_tmpProcessor.setGroupBy("group by sli.inbound_shipment_id ");

if(notEmpty(show_all_line_items)) {
    sli_tmpProcessor.appendSelect("poli.purchaseorder_id as po_id, poli.polineitem_id as polineitem_id, poli.description, sum(COALESCE(re.totalreceivedcount,0.00)) as qty_received, sum(re.totalreceivedcount * poli.unitprice) as shipmentlineitem_value ");
    sli_tmpProcessor.appendGroupBy("poli.purchaseorder_id, poli.polineitem_id, poli.description, re.totalReceivedCount, poli.unitprice ");
    hide.push("summed_shipmentlineitem_value");
    sum.push("line_item_duty_amount");
    sum.push("qty_received");
}  else {
    hide.push("po_id");
    hide.push("polineitem_id");
    hide.push("poli_description");
    hide.push("qty_received");
    hide.push("shipmentlineitem_value");
    count.push("shipment_id");
}

var sqlProcessor = new SelectSQLBuilder();
// This is the main query. 
sqlProcessor.setSelect("select ibs.inbound_shipment_id as shipment_id, COALESCE(ibs.duty_invoice_amount,0.00) as shipment_duty_amount, sli_tmp.sli_duty as line_item_duty_amount");
sqlProcessor.appendSelect("sli_tmp.summed_shipmentlineitem_value ");
sqlProcessor.addCommonTableExpression("sli_tmp", sli_tmpProcessor);
sqlProcessor.setFrom("from ecommerce.inbound_shipment as ibs, ecommerce.inbound_shipment_line_item as sli LEFT OUTER JOIN sli_tmp ON sli.inbound_shipment_id = sli_tmp.shipment_id, ecommerce.purchaseorderlineitem as poli, ecommerce.receivingevent as re ");
sqlProcessor.setWhere("where ibs.inbound_shipment_id = sli.inbound_shipment_id and poli.polineitem_id = sli.po_line_item_id and ibs.inbound_shipment_id = sli_tmp.shipment_id and poli.polineitem_id = re.polineitem_id and (COALESCE(ibs.duty_invoice_amount,0.00) + COALESCE(ibs.additional_duty_amount,0.00) + sli_tmp.sli_duty != 0) ");
sqlProcessor.setGroupBy("group by ibs.inbound_shipment_id, ibs.duty_invoice_amount, ibs.additional_duty_amount, sli_tmp.sli_duty, sli_tmp.summed_shipmentlineitem_value ");

if(notEmpty(dateAdded)) {
    sqlProcessor.appendWhere("ibs.date_record_added >= '" + dateAdded + "'");
}

if (notEmpty(shipmentId)) {
    sqlProcessor.appendWhere("ibs.inbound_shipment_id = " + shipmentId);
} else {
    sqlProcessor.setOrderBy("order by shipment_id");
}

if(notEmpty(show_all_line_items)) {
    sqlProcessor.appendSelect("sli_tmp.po_id as po_id, sli_tmp.polineitem_id as polineitem_id, sli_tmp.description as poli_description, sli_tmp.qty_received as qty_received, sli_tmp.shipmentlineitem_value as shipmentlineitem_value ");
    sqlProcessor.appendGroupBy("sli_tmp.po_id, sli_tmp.polineitem_id, sli_tmp.description, sli_tmp.qty_received, sli_tmp.shipmentlineitem_value ");
    hide.push("summed_shipmentlineitem_value");
    sum.push("line_item_duty_amount");
    sum.push("qty_received");
}  else {
    hide.push("po_id");
    hide.push("polineitem_id");
    hide.push("poli_description");
    hide.push("qty_received");
    hide.push("shipmentlineitem_value");
    count.push("shipment_id");
}

sql = sqlProcessor.queryString();

