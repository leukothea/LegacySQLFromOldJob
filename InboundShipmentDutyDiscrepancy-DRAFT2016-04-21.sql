//
// Inbound Shipment Duty Discrepancy Report
// Edited Catherine Warren, 2015-11-05 | JIRA RPT-134
// Edited Catherine Warren, 2015-12-23 | JIRA RPT-178
// Edited Catherine Warren, 2016-04-21 | JIRA RPT-320
//

var shipmentId = p["shipmentId"];
var deliveryDateAfter = p["deliveryDateAfter"];
var deliveryDateBefore = p["deliveryDateBefore"];
var show_all_line_items = p["show_all_line_items"];
var show_all_shipments = p["show_all_shipments"];

var sli_tmpProcessor = new SelectSQLBuilder();
// This subquery gathers information about shipmentlineitems 
sli_tmpProcessor.setSelect("select sli.inbound_shipment_id as shipment_id, sum(COALESCE(sli.duty_percent,0.00) *.01 * COALESCE(poli.unitprice) * sli.quantity) as sli_duty, sum(coalesce(re.totalreceivedcount * poli.unitprice )) as summed_shipmentlineitem_value, 'true' as true, sum(ii.quantity) as remaining_quantity ");
sli_tmpProcessor.setFrom("from ecommerce.inbound_shipment_line_item sli, ecommerce.purchaseorderlineitem poli, ecommerce.receivingevent as re, ecommerce.rsinventoryitem as ii ");
sli_tmpProcessor.setWhere("where sli.po_line_item_id = poli.polineitem_id and poli.polineitem_id = re.polineitem_id and sli.shipment_line_item_id = re.shipment_line_item_id and ii.receivingevent_id = re.receivingevent_id ");
sli_tmpProcessor.setGroupBy("group by true ");

if(notEmpty(show_all_line_items)) {
    sli_tmpProcessor.appendSelect("poli.purchaseorder_id as po_id, poli.polineitem_id as polineitem_id, poli.description, sum(COALESCE(re.totalreceivedcount,0.00)) as qty_received, sum(re.totalreceivedcount * poli.unitprice) as shipmentlineitem_value ");
    sli_tmpProcessor.appendGroupBy("poli.purchaseorder_id, poli.polineitem_id, poli.description, re.totalReceivedCount, poli.unitprice ");
    hide.push("summed_shipmentlineitem_value");
    hide.push("delta");
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


if (notEmpty(show_all_shipments)) {
    sli_tmpProcessor.appendGroupBy("sli.inbound_shipment_id  ");
} else {
    sli_tmpProcessor.appendGroupBy("sli.inbound_shipment_id having sum(ii.quantity) > 0 ");
}

var sqlProcessor = new SelectSQLBuilder();
// This is the main query. 
sqlProcessor.setSelect("select ibs.inbound_shipment_id as shipment_id, COALESCE(ibs.duty_invoice_amount,0.00) as shipment_duty_amount, sli_tmp.sli_duty as line_item_duty_amount");
sqlProcessor.appendSelect("CAST(abs((COALESCE(ibs.duty_invoice_amount,0.00) - (sli_tmp.sli_duty))) as numeric(9,2)) as delta ");
sqlProcessor.appendSelect("sli_tmp.summed_shipmentlineitem_value ");
sqlProcessor.addCommonTableExpression("sli_tmp", sli_tmpProcessor);
sqlProcessor.setFrom("from ecommerce.inbound_shipment as ibs, ecommerce.inbound_shipment_line_item as sli LEFT OUTER JOIN sli_tmp ON sli.inbound_shipment_id = sli_tmp.shipment_id, ecommerce.purchaseorderlineitem as poli, ecommerce.receivingevent as re ");
sqlProcessor.setWhere("where ibs.inbound_shipment_id = sli.inbound_shipment_id and poli.polineitem_id = sli.po_line_item_id and ibs.inbound_shipment_id = sli_tmp.shipment_id and poli.polineitem_id = re.polineitem_id and (COALESCE(ibs.duty_invoice_amount,0.00) + COALESCE(ibs.additional_duty_amount,0.00) + sli_tmp.sli_duty != 0) ");
sqlProcessor.setGroupBy("group by ibs.inbound_shipment_id, ibs.duty_invoice_amount, ibs.additional_duty_amount, sli_tmp.sli_duty, sli_tmp.summed_shipmentlineitem_value ");

if (notEmpty(deliveryDateAfter)) {
    sqlProcessor.appendWhere("ibs.delivery_date::DATE >= '" + deliveryDateAfter + "'");
}

if (notEmpty(deliveryDateBefore)) {
    sqlProcessor.appendWhere("ibs.delivery_date::DATE <= '" + deliveryDateBefore + "'");
}

if (notEmpty(shipmentId)) {
    sqlProcessor.appendWhere("ibs.inbound_shipment_id = " + shipmentId);
    sqlProcessor.setOrderBy("order by delta desc");
} else {
    sqlProcessor.setOrderBy("order by delta desc");
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

if (notEmpty(show_all_shipments)) {
    sqlProcessor.appendSelect("sli_tmp.remaining_quantity as remaining ");
    sqlProcessor.appendGroupBy("sli_tmp.remaining_quantity");
} else {
    sqlProcessor.appendSelect("sli_tmp.remaining_quantity as remaining ");
    sqlProcessor.appendWhere("sli_tmp.true IS NOT NULL ");
    sqlProcessor.appendGroupBy("sli_tmp.remaining_quantity");
}

sqlProcessor.appendWhere("CAST(abs((COALESCE(ibs.duty_invoice_amount,0.00) - (sli_tmp.sli_duty))) as numeric(9,2)) > 0.009 ");

sql = sqlProcessor.queryString();