//
// SKU Landed Cost Report
//

var sku_id = p["sku_id"];
var skuName = p["sku_name"];
var po_id = p["po_id"];
var shipmentId = p["shipmentId"];
var status = p["status"];
var vendorId = p["vendor"];
var inStock = p["inStockOnly"];

if(status == "All"){
	status = "";
}
sum.push("initial_quantity");
sum.push("current_quantity");
sum.push("inventory_value");
weightedAverage['landed_cost']='landed_cost';

var tmpShipmentQuantitySqlProcessor = new SelectSQLBuilder();
var tmpPoQuantitySqlProcessor = new SelectSQLBuilder();
var tmpDutyPercentSqlProcessor = new SelectSQLBuilder();
var sqlProcessor = new SelectSQLBuilder(); 
var unshippedSqlProcessor = new SelectSQLBuilder(); 
var unreceivedSqlProcessor = new SelectSQLBuilder(); 
var skuLimiterBuilder = new SelectSQLBuilder();

// Bug Fix: unshipped ids are created for all inventory items... but they are only used when a shipped ID doesn't exist
// So in the unshippedSqlProcessor we need "where ii.oid in ( unshippedIDs EXCEPT shippedIds )"
// The following two SQLBuilders are used for this purpose
var sqlProcessorForIds = new SelectSQLBuilder(); 
var unshippedSqlProcessorForIds = new SelectSQLBuilder(); 

tmpPoQuantitySqlProcessor.setSelect("select pol.purchaseorder_id as po_id, sum(pol.quantityordered) as po_quantity");
tmpPoQuantitySqlProcessor.setFrom("from ecommerce.purchaseorderlineitem pol");
tmpPoQuantitySqlProcessor.setGroupBy("group by pol.purchaseorder_id");
if (notEmpty(po_id)) {
    tmpPoQuantitySqlProcessor.setWhere(" where pol.purchaseorder_id = " + po_id);
}

tmpShipmentQuantitySqlProcessor.setSelect("select sli.inbound_shipment_id as shipment_id,sum(sli.quantity) as shipment_quantity");
tmpShipmentQuantitySqlProcessor.setFrom("from ecommerce.inbound_shipment_line_item sli");
tmpShipmentQuantitySqlProcessor.setGroupBy("group by inbound_shipment_id");

tmpDutyPercentSqlProcessor.setSelect("select sli.inbound_shipment_id as shipment_id, sli.shipment_line_item_id as sli_id, sum(COALESCE(sli.duty_percent,0.00) *.01 * sli.quantity * COALESCE(poli.unitprice,0.00))::numeric(10,2) as total_duty_percent_cost");
tmpDutyPercentSqlProcessor.setFrom("from ecommerce.inbound_shipment_line_item sli, ecommerce.purchaseorderlineitem poli");
tmpDutyPercentSqlProcessor.setWhere("where sli.po_line_item_id = poli.polineitem_id");
if (notEmpty(po_id)) {
    tmpDutyPercentSqlProcessor.appendWhere("poli.purchaseorder_id = " + po_id);
}
if (notEmpty(shipmentId)) {
    tmpDutyPercentSqlProcessor.appendWhere("sli.inbound_shipment_id = " + shipmentId);
}
tmpDutyPercentSqlProcessor.setGroupBy("group by sli.inbound_shipment_id,sli.shipment_line_item_id");

sqlProcessor.setSelect("select COALESCE(tsq.shipment_quantity,0) as shipment_quantity, COALESCE(tpoq.po_quantity,0) as po_quantity_ordered, ii.oid as inventory_id, sku.sku_id as sku_id, sku.name as sku_name, i.item_id as item_id, i.name as item_name, poli.purchaseorder_id as po_id, ii.initialquantity as initial_quantity, ii.quantity as current_quantity, (COALESCE(poli.unitprice,0.00))::numeric(10,2) as unit_price, COALESCE(s.inbound_shipment_id,0) as shipment_id, (COALESCE(s.freight_cost,0.00) / shipment_quantity)::numeric(10,2) as unit_freight_cost, (COALESCE(s.freight_forward_invoice_amount,0.00) / shipment_quantity)::numeric(10,2) as unit_ff_invoice_cost, (COALESCE(s.duty_invoice_amount,0.00) / shipment_quantity)::numeric(10,2) as unit_duty_invoice_cost, (COALESCE(s.additional_duty_amount,0.00) / shipment_quantity)::numeric(10,2) as unit_added_duty_cost");
sqlProcessor.appendSelect("(COALESCE(s.exam_fee,0.00) / shipment_quantity)::numeric(10,2) as unit_exam_fee, COALESCE(s.duty_invoice_amount,0.00) as duty_invoice_amount, COALESCE(sli.duty_percent,0.00) as duty_percent, (COALESCE(sli.duty_percent,0.00) *.01 * COALESCE(poli.unitprice,0.00))::numeric(10,2) as unit_duty_percent_cost, (COALESCE(sli.fees,0.00) / sli.quantity)::numeric(10,2) as unit_fees, COALESCE(poli.unitSurcharge,0.00)::numeric(10,2) as poli_unit_surcharge, (COALESCE(poli.flatRateSurcharge,0.00) / cast(poli.quantityordered as float))::numeric(10,2) as unit_flat_rate_surcharge, ((COALESCE(po.flat_rate_surcharge,0.00) + COALESCE(po.flat_rate_surcharge2,0.00) + COALESCE(po.flat_rate_surcharge3,0.00)) / cast(COALESCE(tpoq.po_quantity,0) as float))::numeric(10,2) as po_flat_rate_surcharge");
sqlProcessor.appendSelect("(COALESCE(poli.unitprice,0.00) + ((COALESCE(s.freight_cost,0.00) + COALESCE(s.freight_forward_invoice_amount,0.00) + COALESCE(s.additional_duty_amount,0.00) + COALESCE(s.exam_fee,0.00)) / shipment_quantity) + (COALESCE(sli.fees,0.00) / sli.quantity) + ((COALESCE(po.flat_rate_surcharge,0.00) + COALESCE(po.flat_rate_surcharge2,0.00) + COALESCE(po.flat_rate_surcharge3,0.00)) / cast(COALESCE(tpoq.po_quantity,0) as float)) + (COALESCE(poli.flatRateSurcharge,0.00) / cast(poli.quantityordered as float)) + (COALESCE(sli.duty_percent,0.00) *.01 * COALESCE(poli.unitprice,0.00)) +  COALESCE(poli.unitSurcharge,0.00))::numeric(10,2) as landed_cost");
sqlProcessor.appendSelect("(ii.quantity * (COALESCE(poli.unitprice,0.00) + ((COALESCE(s.freight_cost,0.00) + COALESCE(s.freight_forward_invoice_amount,0.00) + COALESCE(s.additional_duty_amount,0.00) + COALESCE(s.exam_fee,0.00)) / shipment_quantity) + (COALESCE(sli.fees,0.00) / sli.quantity) + ((COALESCE(po.flat_rate_surcharge,0.00) + COALESCE(po.flat_rate_surcharge2,0.00) + COALESCE(po.flat_rate_surcharge3,0.00)) / cast(COALESCE(tpoq.po_quantity,0) as float)) + (COALESCE(poli.flatRateSurcharge,0.00) / cast(poli.quantityordered as float)) + (COALESCE(sli.duty_percent,0.00) *.01 * COALESCE(poli.unitprice,0.00)) +  COALESCE(poli.unitSurcharge,0.00)))::numeric(10,2) as inventory_value");
sqlProcessor.setFrom("from ecommerce.ItemStatus stat, ecommerce.rsinventoryitem ii, ecommerce.sku sku, ecommerce.receivingevent re, ecommerce.purchaseorder po, ecommerce.purchaseorderlineitem poli, ecommerce.inbound_shipment_line_item sli, ecommerce.inbound_shipment s, ecommerce.item i");
sqlProcessor.appendRelationToFromWithAlias(tmpShipmentQuantitySqlProcessor, "tsq");
sqlProcessor.appendRelationToFromWithAlias(tmpPoQuantitySqlProcessor, "tpoq");
sqlProcessor.appendRelationToFromWithAlias(tmpDutyPercentSqlProcessor, "tdpc");
sqlProcessor.setWhere("where re.polineitem_id = poli.polineitem_id and re.shipment_line_item_id = sli.shipment_line_item_id and sli.po_line_item_id = poli.polineitem_id and sli.inbound_shipment_id = s.inbound_shipment_id and sku.sku_id = ii.sku_id and ii.receivingevent_id = re.receivingevent_id and sku.item_id = i.item_id and s.inbound_shipment_id = tsq.shipment_id and po.purchaseorder_id = poli.purchaseorder_id and tpoq.po_id = poli.purchaseorder_id and tdpc.sli_id = sli.shipment_line_item_id and sku.itemstatus_id = stat.itemstatus_id");

sqlProcessorForIds.setSelect("select ii.oid as inventory_id");
sqlProcessorForIds.setFrom("from ecommerce.ItemStatus stat, ecommerce.rsinventoryitem ii, ecommerce.sku sku, ecommerce.receivingevent re, ecommerce.purchaseorder po, ecommerce.purchaseorderlineitem poli, ecommerce.inbound_shipment_line_item sli, ecommerce.inbound_shipment s, ecommerce.item i");
sqlProcessorForIds.appendRelationToFromWithAlias(tmpShipmentQuantitySqlProcessor, "tsq");
sqlProcessorForIds.appendRelationToFromWithAlias(tmpPoQuantitySqlProcessor, "tpoq");
sqlProcessorForIds.appendRelationToFromWithAlias(tmpDutyPercentSqlProcessor, "tdpc");
sqlProcessorForIds.setWhere("where re.polineitem_id = poli.polineitem_id and re.shipment_line_item_id = sli.shipment_line_item_id and sli.po_line_item_id = poli.polineitem_id and sli.inbound_shipment_id = s.inbound_shipment_id and sku.sku_id = ii.sku_id and ii.receivingevent_id = re.receivingevent_id and sku.item_id = i.item_id and s.inbound_shipment_id = tsq.shipment_id and po.purchaseorder_id = poli.purchaseorder_id and tpoq.po_id = poli.purchaseorder_id and tdpc.sli_id = sli.shipment_line_item_id and sku.itemstatus_id = stat.itemstatus_id");

if (notEmpty(sku_id)) {
    sqlProcessor.appendWhere("ii.sku_id = " + sku_id);
    sqlProcessorForIds.appendWhere("ii.sku_id = " + sku_id);
}
if (notEmpty(skuName)) {
    sqlProcessor.appendWhere("sku.name ILIKE '" + skuName.replaceAll("'", "''") + "%'");
    sqlProcessorForIds.appendWhere("sku.name ILIKE '" + skuName.replaceAll("'", "''") + "%'");
}
if (notEmpty(po_id)) {
    sqlProcessor.appendWhere("poli.purchaseorder_id = " + po_id);
    sqlProcessorForIds.appendWhere("poli.purchaseorder_id = " + po_id);
}
if (notEmpty(shipmentId)) {
    sqlProcessor.appendWhere("s.inbound_shipment_id = " + shipmentId);
    sqlProcessorForIds.appendWhere("s.inbound_shipment_id = " + shipmentId);
}
if (notEmpty(status)) {
    sqlProcessor.appendWhere("stat.itemStatus_id = " + status);
    sqlProcessorForIds.appendWhere("stat.itemStatus_id = " + status);
}
if (notEmpty(inStock)) {
    sqlProcessor.appendWhere("ii.quantity > 0");
    sqlProcessorForIds.appendWhere("ii.quantity > 0");
}
if (notEmpty(vendorId)) {
    sqlProcessor.appendWhere("i.vendor_id = " + vendorId);
    sqlProcessorForIds.appendWhere("i.vendor_id = " + vendorId);
}
sqlProcessor.setGroupBy("group by sli.quantity, tsq.shipment_quantity,tpoq.po_quantity,ii.oid,sku.sku_id,sku.name,i.item_id,i.name,ii.initialquantity,ii.quantity,COALESCE(poli.unitprice,0.00),s.inbound_shipment_id,poli.purchaseorder_id,s.freight_cost,s.freight_forward_invoice_amount,s.duty_invoice_amount,s.additional_duty_amount,s.exam_fee,sli.duty_percent,sli.fees, poli.unitSurcharge,poli.quantityordered,po.flat_rate_surcharge,po.flat_rate_surcharge2,po.flat_rate_surcharge3,poli.flatRateSurcharge,stat.itemStatus,stat.ordinal");

// Query for records without shipment data
// ToDO: Query using outer joins?

if (isEmpty(shipmentId)) {
    unshippedSqlProcessor.setSelect("select 0 as shipment_quantity, COALESCE(tpoq.po_quantity,0) as po_quantity_ordered, ii.oid as inventory_id, sku.sku_id as sku_id, sku.name as sku_name, i.item_id as item_id, i.name as item_name, poli.purchaseorder_id as po_id, ii.initialquantity as initial_quantity, ii.quantity as current_quantity, COALESCE(poli.unitprice,0.00)::numeric(10,2) as unit_price, 0 as shipment_id, 0.00 as unit_freight_cost, 0.00 as unit_ff_invoice_cost, 0.00 as unit_duty_invoice_cost, 0.00 as unit_added_duty_cost, 0.00 as unit_exam_fee, 0 as duty_invoice_amount, 0 as duty_percent");
    unshippedSqlProcessor.appendSelect("(COALESCE(cast(poli.duty_perc as float),0.00) *.01 * COALESCE(cast(poli.unitprice as float),0.00))::numeric(10,2) as unit_duty_percent_cost, 0.00 as unit_fees, COALESCE(poli.unitSurcharge,0.00) as poli_unit_surcharge, (COALESCE(poli.flatRateSurcharge,0.00) / cast(poli.quantityordered as float))::numeric(10,2) as unit_flat_rate_surcharge, ((COALESCE(po.flat_rate_surcharge,0.00) + COALESCE(po.flat_rate_surcharge2,0.00) + COALESCE(po.flat_rate_surcharge3,0.00)) / cast(COALESCE(tpoq.po_quantity,0) as float))::numeric(10,2) as po_flat_rate_surcharge");
    unshippedSqlProcessor.appendSelect("(COALESCE(poli.unitprice,0.00) + ((COALESCE(po.flat_rate_surcharge,0.00) + COALESCE(po.flat_rate_surcharge2,0.00) + COALESCE(po.flat_rate_surcharge3,0.00)) / cast(COALESCE(tpoq.po_quantity,0) as float)) + (COALESCE(poli.flatRateSurcharge,0.00) / cast(poli.quantityordered as float)) +  COALESCE(poli.unitSurcharge,0.00))::numeric(10,2) as landed_cost");
    unshippedSqlProcessor.appendSelect("(ii.quantity * (COALESCE(poli.unitprice,0.00) + ((COALESCE(po.flat_rate_surcharge,0.00) + COALESCE(po.flat_rate_surcharge2,0.00) + COALESCE(po.flat_rate_surcharge3,0.00)) / cast(COALESCE(tpoq.po_quantity,0) as float)) + (COALESCE(poli.flatRateSurcharge,0.00) / cast(poli.quantityordered as float)) +  COALESCE(poli.unitSurcharge,0.00)))::numeric(10,2) as inventory_value");
    unshippedSqlProcessor.setFrom("from ecommerce.ItemStatus stat, ecommerce.rsinventoryitem ii, ecommerce.sku sku, ecommerce.receivingevent re, ecommerce.purchaseorder po, ecommerce.purchaseorderlineitem poli, ecommerce.item i");
    unshippedSqlProcessor.appendRelationToFromWithAlias(tmpPoQuantitySqlProcessor, "tpoq");
    unshippedSqlProcessor.setWhere("where re.polineitem_id = poli.polineitem_id and sku.sku_id = ii.sku_id and ii.receivingevent_id = re.receivingevent_id and sku.item_id = i.item_id  and po.purchaseorder_id = poli.purchaseorder_id and tpoq.po_id = poli.purchaseorder_id and sku.itemstatus_id = stat.itemstatus_id");

    unshippedSqlProcessorForIds.setSelect("select ii.oid as inventory_id");
    unshippedSqlProcessorForIds.setFrom("from ecommerce.ItemStatus stat, ecommerce.rsinventoryitem ii, ecommerce.sku sku, ecommerce.receivingevent re, ecommerce.purchaseorder po, ecommerce.purchaseorderlineitem poli, ecommerce.item i");
    unshippedSqlProcessorForIds.appendRelationToFromWithAlias(tmpPoQuantitySqlProcessor, "tpoq");
    unshippedSqlProcessorForIds.setWhere("where re.polineitem_id = poli.polineitem_id and sku.sku_id = ii.sku_id and ii.receivingevent_id = re.receivingevent_id and sku.item_id = i.item_id  and po.purchaseorder_id = poli.purchaseorder_id and tpoq.po_id = poli.purchaseorder_id and sku.itemstatus_id = stat.itemstatus_id");


    unreceivedSqlProcessor.setSelect("select 0 as shipment_quantity, 0 as po_quantity_ordered, ii.oid as inventory_id, sku.sku_id as sku_id, sku.name as sku_name, i.item_id as item_id, i.name as item_name, 0 as po_id, ii.initialquantity as initial_quantity, ii.quantity as current_quantity, 0.00 as unit_price, 0 as shipment_id, 0.00 as unit_freight_cost, 0.00 as unit_ff_invoice_cost, 0.00 as unit_duty_invoice_cost, 0.00 as unit_added_duty_cost, 0.00 as unit_exam_fee, 0.00 as duty_invoice_amount, 0 as duty_percent");
    unreceivedSqlProcessor.appendSelect("0.00 as unit_duty_percent_cost, 0.00 as unit_fees, 0.00 as poli_unit_surcharge, 0.00 as unit_flat_rate_surcharge, 0.00 as po_flat_rate_surcharge");
    unreceivedSqlProcessor.appendSelect("COALESCE(ii.merchantprice,0.00) as landed_cost, (ii.quantity * COALESCE(ii.merchantprice,0.00))::numeric(10,2) as inventory_value");
    unreceivedSqlProcessor.setFrom("from ecommerce.ItemStatus stat, ecommerce.rsinventoryitem ii, ecommerce.sku sku, ecommerce.item i");
    unreceivedSqlProcessor.setWhere("where sku.sku_id = ii.sku_id and sku.item_id = i.item_id and ii.receivingevent_id is null and sku.itemstatus_id = stat.itemstatus_id");

    if (notEmpty(sku_id)) {
        unshippedSqlProcessor.appendWhere("ii.sku_id = " + sku_id);
        unshippedSqlProcessorForIds.appendWhere("ii.sku_id = " + sku_id);
        unreceivedSqlProcessor.appendWhere("ii.sku_id = " + sku_id);
    }
    if (notEmpty(skuName)) {
        unshippedSqlProcessor.appendWhere("sku.name ILIKE '" + skuName.replaceAll("'", "''") + "%'");
        unshippedSqlProcessorForIds.appendWhere("sku.name ILIKE '" + skuName.replaceAll("'", "''") + "%'");
        unreceivedSqlProcessor.appendWhere("sku.name ILIKE '" + skuName.replaceAll("'", "''") + "%'");
    }
    if (notEmpty(po_id)) {
        unshippedSqlProcessor.appendWhere("poli.purchaseorder_id = " + po_id);
        unshippedSqlProcessorForIds.appendWhere("poli.purchaseorder_id = " + po_id);
        skuLimiterBuilder.setSelect("select poli.sku_id");
        skuLimiterBuilder.setFrom("from ecommerce.purchaseorderlineitem as poli");
        skuLimiterBuilder.setWhere("where poli.purchaseorder_id = " + po_id);
        unreceivedSqlProcessor.appendRelationToFromWithAlias(skuLimiterBuilder, "slb");
        unreceivedSqlProcessor.appendWhere("ii.sku_id = slb.sku_id");
    }
    if (notEmpty(status)) {
        unshippedSqlProcessor.appendWhere("stat.itemStatus_id = " + status);
        unshippedSqlProcessorForIds.appendWhere("stat.itemStatus_id = " + status);
        unreceivedSqlProcessor.appendWhere("stat.itemStatus_id = " + status);
    }
    if (notEmpty(inStock)) {
        unshippedSqlProcessor.appendWhere("ii.quantity > 0");
        unshippedSqlProcessorForIds.appendWhere("ii.quantity > 0");
        unreceivedSqlProcessor.appendWhere("ii.quantity > 0");
    }
    if (notEmpty(vendorId)) {
        unshippedSqlProcessor.appendWhere("i.vendor_id = " + vendorId);
        unshippedSqlProcessorForIds.appendWhere("i.vendor_id = " + vendorId);
        unreceivedSqlProcessor.appendWhere("i.vendor_id = " + vendorId);
    }
    unshippedSqlProcessor.setGroupBy("group by tpoq.po_quantity,ii.oid,sku.sku_id,sku.name,i.item_id,i.name,ii.initialquantity,poli.duty_perc,ii.quantity,poli.unitprice,poli.purchaseorder_id,poli.unitSurcharge,poli.quantityordered,po.flat_rate_surcharge,po.flat_rate_surcharge2,po.flat_rate_surcharge3,poli.flatRateSurcharge,stat.itemStatus,stat.ordinal");
    unreceivedSqlProcessor.setGroupBy("group by ii.oid,ii.merchantprice,ii.quantity,sku.sku_id,sku.name,i.item_id,i.name,ii.initialquantity,stat.itemStatus,stat.ordinal");

	unshippedSqlProcessor.appendWhere("ii.oid in ("  + unshippedSqlProcessorForIds.queryString() + " EXCEPT " + sqlProcessorForIds.queryString()  + ")");

}

var shippedSql = sqlProcessor.queryString();
var unshippedSql = unshippedSqlProcessor.queryString();
var unreceivedSql = unreceivedSqlProcessor.queryString();

var sql = "SELECT DISTINCT * FROM ( " + shippedSql;
if(isEmpty(shipmentId)){
	sql += " UNION " + unshippedSql + " UNION " + unreceivedSql ;	
}
sql += " ) zzzz";
      