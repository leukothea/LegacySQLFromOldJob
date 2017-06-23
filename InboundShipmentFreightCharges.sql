//
// Inbound Shipment Freight Costs
// Catherine Warren, 2016-04-19 | JIRA RPT-317
//

var shippingServiceId = p["shippingServiceId"];
var transportMethod = p["transportMethod"];
var countryCode = p["countryOfOrigin2"];
var deliveryDateAfter = p["deliveryDateAfter"];
var deliveryDateBefore = p["deliveryDateBefore"];
var show_all_shipments = p["show_all_shipments"];

var sqlProcessor = new SelectSQLBuilder();

sum.push('freight_forward_invoice_amount');
sum.push('duty_invoice_amount');
sum.push('freight_cost');
sum.push('exam_fee');
sum.push('additional_duty_amount');
sum.push('total_shipment_charges');

var shipProcessor = new SelectSQLBuilder();

shipProcessor.setSelect("select sli.inbound_shipment_id, 'true' as true, sum(ii.quantity) as remaining_quantity ");
shipProcessor.setFrom("from ecommerce.rsinventoryitem as ii, ecommerce.receivingevent as re, ecommerce.inbound_shipment_line_item as sli ");
shipProcessor.setWhere("where ii.receivingevent_id = re.receivingevent_id and re.shipment_line_item_id = sli.shipment_line_item_id ");
shipProcessor.setGroupBy("group by sli.inbound_shipment_id having sum(ii.quantity) > 0 ");

sqlProcessor.setSelect("select inb.inbound_shipment_id as shipment_id, inb.isocountrycode as country_code, inb.delivery_date as received_date, inb.freight_forward_invoice_amount, inb.duty_invoice_amount, inb.freight_cost, inb.exam_fee, inb.additional_duty_amount ");
sqlProcessor.appendSelect("(COALESCE(inb.freight_forward_invoice_amount,0.00) + COALESCE(inb.duty_invoice_amount,0.00) + COALESCE(inb.freight_cost,0.00) + COALESCE(inb.exam_fee,0.00) + COALESCE(inb.additional_duty_amount,0.00)) as total_shipment_charges ");
sqlProcessor.setFrom("from ecommerce.inbound_shipment as inb LEFT OUTER JOIN ship ON ship.inbound_shipment_id = inb.inbound_shipment_id  ");
sqlProcessor.addCommonTableExpression("ship",shipProcessor);
sqlProcessor.setWhere("where inb.inbound_shipment_id = inb.inbound_shipment_id ");
sqlProcessor.setOrderBy("order by inb.inbound_shipment_id asc ");

if (notEmpty(shippingServiceId)) {
    if (shippingServiceId == "All") {  
        sqlProcessor.appendSelect("ss.shippingservice as shipping_agent ");
        sqlProcessor.appendFrom("ecommerce.shippingservice as ss ");
        sqlProcessor.appendWhere("inb.shipping_service_id = ss.shippingservice_id ");
    } else {
        sqlProcessor.appendSelect("ss.shippingservice as shipping_agent ");
        sqlProcessor.appendFrom("ecommerce.shippingservice as ss ");
        sqlProcessor.appendWhere("inb.shipping_service_id = ss.shippingservice_id ");
        sqlProcessor.appendWhere("ss.shippingservice_id = " + shippingServiceId );
    }
} else {
    hide.push('shipping_agent');
}

if (notEmpty(transportMethod)) {
    if (transportMethod == "All") {
        sqlProcessor.appendSelect("coalesce(inb.transport_method, 'N/A') as transport_method ");
    	} else {
    	sqlProcessor.appendSelect("coalesce(inb.transport_method, 'N/A') as transport_method ");
        sqlProcessor.appendWhere("inb.transport_method ILIKE '" + transportMethod + "' ");
	} 
} else {
	hide.push('transport_method');
    }

if (notEmpty(countryCode)) {
    if (countryCode == "All") {
      // do nothing; let all values pass through
    } else if (countryCode == "US") {
        sqlProcessor.appendWhere("inb.isocountrycode = 'US'");
    } else if (countryCode == "INT") {
        sqlProcessor.appendWhere("inb.isocountrycode != 'US'");
    }
}

if (notEmpty(deliveryDateAfter)) {
    sqlProcessor.appendWhere("inb.delivery_date::DATE >= '" + deliveryDateAfter + "'");
}
if (notEmpty(deliveryDateBefore)) {
    sqlProcessor.appendWhere("inb.delivery_date::DATE <= '" + deliveryDateBefore + "'");
}

if (notEmpty(show_all_shipments)) {
    hide.push('remaining');
} else {
    sqlProcessor.appendSelect("ship.remaining_quantity as remaining ");
    sqlProcessor.appendWhere("ship.true IS NOT NULL ");
}

sql = sqlProcessor.queryString();