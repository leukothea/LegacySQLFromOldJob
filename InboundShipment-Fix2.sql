//
// Inbound Shipment Duty Discrepancy - Test
// Catherine Warren, 2016-05-16 to 18 | JIRA RPT-365
//

var shipmentId = p["shipmentId"];
var deliveryDateAfter = p["deliveryDateAfter"];
var deliveryDateBefore = p["deliveryDateBefore"];
var show_all_line_items = p["show_all_line_items"];
var show_all_shipments = p["show_all_shipments"];

// SECTION for ROLLED-UP SHIPMENTS

var sli_tmpProcessor = new SelectSQLBuilder();
// This subquery gathers base information about shipmentlineitems, rolled up
sli_tmpProcessor.setSelect("select sli.inbound_shipment_id as shipment_id, sum(((COALESCE(sli.duty_percent,0.00) * 0.01) * (COALESCE(poli.unitprice,0.00) * sli.quantity))) as sli_duty, sum(coalesce(re.totalreceivedcount * poli.unitprice )) as summed_shipmentlineitem_value, 'true' as true, sum(ii.quantity) as remaining_quantity ");
sli_tmpProcessor.setFrom("from ecommerce.inbound_shipment_line_item sli, ecommerce.purchaseorderlineitem poli, ecommerce.receivingevent as re, ecommerce.rsinventoryitem as ii ");
sli_tmpProcessor.setWhere("where sli.po_line_item_id = poli.polineitem_id and poli.polineitem_id = re.polineitem_id and sli.shipment_line_item_id = re.shipment_line_item_id and ii.receivingevent_id = re.receivingevent_id ");
sli_tmpProcessor.setGroupBy("group by true ");

if (notEmpty(show_all_shipments)) {
    sli_tmpProcessor.appendGroupBy("sli.inbound_shipment_id  ");
} else {
    sli_tmpProcessor.appendGroupBy("sli.inbound_shipment_id having sum(ii.quantity) > 0 ");
}

var sum_sliProcessor = new SelectSQLBuilder();
// This subquery sums the results of the base subquery to get total values 

sum_sliProcessor.setSelect("select sli_tmp.shipment_id, sum(sli_tmp.sli_duty) as sli_duty, sum(sli_tmp.summed_shipmentlineitem_value) as summed_shipmentlineitem_value, sum(sli_tmp.remaining_quantity) as remaining_quantity, 'true' as true ");
sum_sliProcessor.addCommonTableExpression("sli_tmp", sli_tmpProcessor);
sum_sliProcessor.setFrom("from sli_tmp ");
sum_sliProcessor.setWhere("where true ");
sum_sliProcessor.setGroupBy("group by sli_tmp.shipment_id, sli_tmp.sli_duty ");

var sqlProcessor = new SelectSQLBuilder();
// This is the main query for the first case.
sqlProcessor.setSelect("select ibs.inbound_shipment_id as shipment_id, COALESCE(ibs.duty_invoice_amount,0.00) as shipment_duty_amount, sum_sli.sli_duty as line_item_duty_amount");
sqlProcessor.appendSelect("CAST(abs((COALESCE(ibs.duty_invoice_amount,0.00) - (sum_sli.sli_duty))) as numeric(9,2)) as delta ");
sqlProcessor.appendSelect("sum_sli.summed_shipmentlineitem_value ");
sqlProcessor.addCommonTableExpression("sum_sli", sum_sliProcessor);
sqlProcessor.setFrom("from ecommerce.inbound_shipment as ibs, ecommerce.inbound_shipment_line_item as sli LEFT OUTER JOIN sum_sli ON sli.inbound_shipment_id = sum_sli.shipment_id, ecommerce.purchaseorderlineitem as poli, ecommerce.receivingevent as re ");
sqlProcessor.setWhere("where ibs.inbound_shipment_id = sli.inbound_shipment_id and poli.polineitem_id = sli.po_line_item_id and ibs.inbound_shipment_id = sum_sli.shipment_id and poli.polineitem_id = re.polineitem_id and (COALESCE(ibs.duty_invoice_amount,0.00) + COALESCE(ibs.additional_duty_amount,0.00) + sum_sli.sli_duty != 0) ");
sqlProcessor.setGroupBy("group by ibs.inbound_shipment_id, ibs.duty_invoice_amount, ibs.additional_duty_amount, sum_sli.sli_duty, sum_sli.summed_shipmentlineitem_value ");

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

if (notEmpty(show_all_shipments)) {
    sqlProcessor.appendSelect("sum_sli.remaining_quantity as remaining ");
    sqlProcessor.appendGroupBy("sum_sli.remaining_quantity");
} else {
    sqlProcessor.appendSelect("sum_sli.remaining_quantity as remaining ");
    sqlProcessor.appendWhere("sum_sli.true IS NOT NULL ");
    sqlProcessor.appendGroupBy("sum_sli.remaining_quantity");
}

sqlProcessor.appendWhere("CAST(abs((COALESCE(ibs.duty_invoice_amount,0.00) - (sum_sli.sli_duty))) as numeric(9,2)) > 0.009 ");

// SECTION for ALL SHIPMENT LINE ITEMS

var sli_tmpProcessor2 = new SelectSQLBuilder();
// This subquery gathers base information about shipmentlineitems, split out into separate lines. 
sli_tmpProcessor2.setSelect("select sli.inbound_shipment_id as shipment_id, sum(((COALESCE(sli.duty_percent,0.00) * 0.01) * (COALESCE(poli.unitprice,0.00) * sli.quantity))) as sli_duty, sum(coalesce(re.totalreceivedcount * poli.unitprice )) as summed_shipmentlineitem_value, 'true' as true, sum(ii.quantity) as remaining_quantity, poli.purchaseorder_id as po_id, poli.polineitem_id as polineitem_id, poli.description, sum(COALESCE(re.totalreceivedcount,0.00)) as qty_received, sum((re.totalreceivedcount-re.badreceivedcount) * poli.unitprice) as shipmentlineitem_value ");
sli_tmpProcessor2.setFrom("from ecommerce.inbound_shipment_line_item sli, ecommerce.purchaseorderlineitem poli, ecommerce.receivingevent as re, ecommerce.rsinventoryitem as ii ");
sli_tmpProcessor2.setWhere("where sli.po_line_item_id = poli.polineitem_id and poli.polineitem_id = re.polineitem_id and sli.shipment_line_item_id = re.shipment_line_item_id and ii.receivingevent_id = re.receivingevent_id ");
sli_tmpProcessor2.setGroupBy("group by sli.duty_percent, poli.purchaseorder_id, poli.polineitem_id, poli.description, poli.unitprice ");

if (notEmpty(show_all_shipments)) {
    sli_tmpProcessor2.appendGroupBy("sli.inbound_shipment_id  ");
} else {
    sli_tmpProcessor2.appendGroupBy("sli.inbound_shipment_id having sum(ii.quantity) > 0 ");
}

var sum_sliProcessor2 = new SelectSQLBuilder();
// This subquery sums the results of the base subquery to get total values 

sum_sliProcessor2.setSelect("select sli_tmp2.shipment_id, sum(sli_tmp2.sli_duty) as sli_duty, sum(sli_tmp2.summed_shipmentlineitem_value) as summed_shipmentlineitem_value, sum(sli_tmp2.remaining_quantity) as remaining_quantity, 'true' as true, sli_tmp2.po_id, sli_tmp2.polineitem_id, sli_tmp2.description, sum(sli_tmp2.qty_received) as qty_received, sum(sli_tmp2.shipmentlineitem_value) as shipmentlineitem_value ");
sum_sliProcessor2.addCommonTableExpression("sli_tmp2", sli_tmpProcessor2);
sum_sliProcessor2.setFrom("from sli_tmp2 ");
sum_sliProcessor2.setWhere("where true ");
sum_sliProcessor2.setGroupBy("group by sli_tmp2.shipment_id, sli_tmp2.sli_duty, sli_tmp2.po_id, sli_tmp2.polineitem_id, sli_tmp2.description ");

var sqlProcessor2 = new SelectSQLBuilder();
// This is the main query for the second case. 
sqlProcessor2.setSelect("select ibs.inbound_shipment_id as shipment_id, COALESCE(ibs.duty_invoice_amount,0.00) as shipment_duty_amount, sum_sli2.sli_duty as line_item_duty_amount");
sqlProcessor2.appendSelect("CAST(abs((COALESCE(ibs.duty_invoice_amount,0.00) - (sum_sli2.sli_duty))) as numeric(9,2)) as delta ");
sqlProcessor2.appendSelect("sum_sli2.po_id as po_id, sum_sli2.polineitem_id as polineitem_id, sum_sli2.description as poli_description, sum_sli2.qty_received as qty_received, sum_sli2.shipmentlineitem_value as shipmentlineitem_value ");
sqlProcessor2.addCommonTableExpression("sum_sli2", sum_sliProcessor2);
sqlProcessor2.setFrom("from ecommerce.inbound_shipment as ibs, ecommerce.inbound_shipment_line_item as sli LEFT OUTER JOIN sum_sli2 ON sli.inbound_shipment_id = sum_sli2.shipment_id, ecommerce.purchaseorderlineitem as poli, ecommerce.receivingevent as re ");
sqlProcessor2.setWhere("where ibs.inbound_shipment_id = sli.inbound_shipment_id and poli.polineitem_id = sli.po_line_item_id and ibs.inbound_shipment_id = sum_sli2.shipment_id and poli.polineitem_id = re.polineitem_id and (COALESCE(ibs.duty_invoice_amount,0.00) + COALESCE(ibs.additional_duty_amount,0.00) + sum_sli2.sli_duty != 0) ");
sqlProcessor2.setGroupBy("group by ibs.inbound_shipment_id, ibs.duty_invoice_amount, ibs.additional_duty_amount, sum_sli2.sli_duty, sum_sli2.summed_shipmentlineitem_value ");
sqlProcessor2.appendGroupBy("sum_sli2.po_id, sum_sli2.polineitem_id, sum_sli2.description, sum_sli2.qty_received, sum_sli2.shipmentlineitem_value ");

if (notEmpty(deliveryDateAfter)) {
    sqlProcessor2.appendWhere("ibs.delivery_date::DATE >= '" + deliveryDateAfter + "'");
}

if (notEmpty(deliveryDateBefore)) {
    sqlProcessor2.appendWhere("ibs.delivery_date::DATE <= '" + deliveryDateBefore + "'");
}

if (notEmpty(shipmentId)) {
    sqlProcessor2.appendWhere("ibs.inbound_shipment_id = " + shipmentId);
    sqlProcessor2.setOrderBy("order by delta desc");
} else {
    sqlProcessor2.setOrderBy("order by delta desc");
}

if (notEmpty(show_all_shipments)) {
    sqlProcessor2.appendSelect("sum_sli2.remaining_quantity as remaining ");
    sqlProcessor2.appendGroupBy("sum_sli2.remaining_quantity");
} else {
    sqlProcessor2.appendSelect("sum_sli2.remaining_quantity as remaining ");
    sqlProcessor2.appendWhere("sum_sli2.true IS NOT NULL ");
    sqlProcessor2.appendGroupBy("sum_sli2.remaining_quantity");
}

sqlProcessor2.appendWhere("CAST(abs((COALESCE(ibs.duty_invoice_amount,0.00) - (sum_sli2.sli_duty))) as numeric(9,2)) > 0.009 ");



var RolledUpShipments = sqlProcessor.queryString();
var AllShipmentLineItems = sqlProcessor2.queryString();

if (notEmpty(show_all_line_items)) { // if the box is checked, to show all line items
    sql = AllShipmentLineItems
    hide.push("summed_shipmentlineitem_value");
    hide.push("delta");
    sum.push("line_item_duty_amount");
    sum.push("qty_received");
    } 
else { // if the box is not checked, to roll up each shipment
    sql = RolledUpShipments
    hide.push("po_id");
    hide.push("polineitem_id");
    hide.push("poli_description");
    hide.push("qty_received");
    hide.push("shipmentlineitem_value");
    count.push("shipment_id");
    }

