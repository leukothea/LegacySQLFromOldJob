//
// PO Information Report - DRAFT
// Catherine Warren, 2016-01-22 & on
// Edited Catherine Warren, 2016-02-11 | JIRA RPT-261
// Edited Catherine Warren, 2016-02-17 | JIRA RPT-263
// Edited Catherine Warren, 2016-02-24 | JIRA RPT-130
// Edited Catherine Warren, 2016-02-29 | JIRA RPT-130
//

var po_id = p["po_id"];
var paymentterms = p["paymentterms"];
var shipDateStart = p["shipDateStart"];
var shipDateEnd = p["shipDateEnd"];
var createDateStart = p["createDateStart"];
var createDateEnd = p["createDateEnd"];
var poStatus = p["poStatus"];
var groupBy = p["poGroupBy"];
var buyer = p["poBuyer"];
var reorder = p["reorder"];
var showSupplier = p["showSupplier"];
var showSupplierType = p["showSupplierType"];
var surcharge = p["surchargeTypeId"];
var surcharge2 = p["surchargeType2Id"];
var surcharge3 = p["surchargeType3Id"];
var show_all_line_items = p["show_all_line_items"];

if(buyer == "All"){ buyer = ""; }
if(reorder == "All"){ reorder = ""; }
if(poStatus == "All"){ poStatus = ""; }
if(paymentterms == "All"){ paymentterms = ""; }
if(surcharge == "All"){ surcharge = ""; }
if(surcharge2 == "All"){ surcharge2 = ""; }
if(surcharge3 == "All"){ surcharge3 = ""; }

count.push('po_id');
sum.push('po_value');
sum.push('po_charges');
sum.push('po_count');
sum.push('po_duty');
sum.push('poli_summed_duty');
sum.push('line_item_count');
sum.push('qty_ordered');
sum.push('po_grand_total');

var tmpPoQuantitySqlProcessor = new SelectSQLBuilder();

tmpPoQuantitySqlProcessor.setSelect("select pol.purchaseorder_id as po_id, sum(pol.quantityordered) as po_quantity");
tmpPoQuantitySqlProcessor.setFrom("from ecommerce.purchaseorderlineitem pol");
tmpPoQuantitySqlProcessor.setGroupBy("group by pol.purchaseorder_id");

var surchargeWhereString = "(po.surcharge_type_id = st.surchargetype_id OR poli.surchargetype_id = st.surchargetype_id";
var surchargeIdList = "(";

var sqlProcessor = new SelectSQLBuilder();

sqlProcessor.setSelect("select sum(poli.unitPrice * poli.quantityOrdered) AS po_value");
sqlProcessor.appendSelect("sum(COALESCE(poli.unitSurcharge,0.00) * poli.quantityOrdered + COALESCE(poli.flatratesurcharge,0.00)) + COALESCE(po.flat_rate_surcharge,0.00) + COALESCE(po.flat_rate_surcharge2,0.00) + COALESCE(po.flat_rate_surcharge3,0.00) AS po_charges");
if (notEmpty(surcharge)) {
    surchargeIdList += surcharge;
    if (notEmpty(surcharge2)) {
        surchargeWhereString += " OR po.surcharge_type2_id = st.surchargetype_id OR poli.surchargetype_id = st.surchargetype_id";
        surchargeIdList += "," + surcharge2;
    }
    if (notEmpty(surcharge3)) {
        surchargeWhereString += " OR po.surcharge_type3_id = st.surchargetype_id OR poli.surchargetype_id = st.surchargetype_id";
        surchargeIdList += "," + surcharge3;
    }
	surchargeWhereString += ")";
	surchargeIdList += ")";

    tmpPoQuantitySqlProcessor.appendWhere("(pol.surchargetype_id is null or pol.surchargetype_id = " + surcharge + ")");
    sqlProcessor.appendSelect("st.description AS charge_type");
    sqlProcessor.appendFrom("ecommerce.surchargetype AS st");
    sqlProcessor.appendWhere(surchargeWhereString.toString());
    sqlProcessor.appendWhere("st.surchargetype_id in " + surchargeIdList.toString());
    sqlProcessor.appendGroupBy("st.description");
} else {
	hide.push('charge_type');
}

sqlProcessor.appendSelect("count(distinct po.purchaseOrder_id) AS po_count ");
sqlProcessor.appendSelect("sum(poli.unitPrice * poli.quantityOrdered * coalesce(poli.duty_perc,0.00) * 0.01)::numeric(12,4) AS po_duty ");
sqlProcessor.appendSelect("count(*) AS line_item_count, sum(poli.quantityOrdered) AS qty_ordered ");
sqlProcessor.appendSelect("(sum(poli.unitPrice * poli.quantityOrdered) + (sum(COALESCE(poli.unitSurcharge,0.00) * poli.quantityOrdered + COALESCE(poli.flatratesurcharge,0.00)) + COALESCE(po.flat_rate_surcharge,0.00) + COALESCE(po.flat_rate_surcharge2,0.00) + COALESCE(po.flat_rate_surcharge3,0.00))) as po_grand_total ");
sqlProcessor.setFrom("from ecommerce.PurchaseOrder as po, ecommerce.purchaseorderlineitem as poli, ecommerce.Supplier as s ");
sqlProcessor.appendRelationToFromWithAlias(tmpPoQuantitySqlProcessor, "tpoq");
sqlProcessor.setWhere("where po.purchaseOrder_id = poli.purchaseOrder_id and tpoq.po_id = po.purchaseorder_id ");
sqlProcessor.appendWhere("po.supplier_id = s.supplier_id ");

if (notEmpty(po_id)) {
    sqlProcessor.appendWhere("po.purchaseorder_id = " + po_id );
}

if (notEmpty(paymentterms)) {
    sqlProcessor.appendWhere("po.paymentterms_id = " + paymentterms );
}

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

if ("0" == poStatus) { // All Except Cancelled
    sqlProcessor.appendWhere("po.purchaseOrderStatus_id != 6");
   } else if ("New and Incomplete" == poStatus) { // New and Incomplete
      sqlProcessor.appendWhere("po.purchaseOrderStatus_id IN (1, 3) ");
   } else if (notEmpty(poStatus)) {
            sqlProcessor.appendWhere("po.purchaseOrderStatus_id = " + poStatus);
}

switch(groupBy) {
    case "buyer":
        sqlProcessor.appendSelect("COALESCE(po.buyerUid,'unknown') AS buyer ");
        sqlProcessor.appendSelect("s.supplierName AS supplier_name ");
        sqlProcessor.appendSelect("pos.status AS po_status, pt.paymentterms ");
        sqlProcessor.appendFrom("ecommerce.PurchaseOrderStatus as pos, ecommerce.paymentterms as pt ");
        sqlProcessor.appendWhere("po.purchaseOrderStatus_id = pos.purchaseOrderStatus_id and po.paymentterms_id = pt.paymentterms_id ");
        sqlProcessor.setGroupBy("group by COALESCE(po.buyerUid,'unknown') ");
        sqlProcessor.appendGroupBy("s.supplierName, pos.status, pt.paymentterms ");
        hide.push('po_id');
        hide.push('po_name');
        hide.push('ship_date');
        hide.push('issued_date');
        hide.push('ship_quarter');
        hide.push('eta_date');
        break;
    case "buyer-poid":
        sqlProcessor.appendSelect("COALESCE(po.buyerUid,'unknown') AS buyer ");
        sqlProcessor.setGroupBy("group by COALESCE(po.buyerUid,'unknown') ");
        sqlProcessor.appendSelect("po.purchaseOrder_id AS po_id ");
        sqlProcessor.appendGroupBy("po.purchaseOrder_id ");
        sqlProcessor.appendSelect("po.ponumber AS po_name ");
        sqlProcessor.appendGroupBy("po.ponumber ");
        sqlProcessor.appendSelect("po.shipDate::DATE AS ship_date ");
        sqlProcessor.appendSelect("po.dateIssued::DATE AS issued_date ");
        sqlProcessor.appendSelect("po.expectedarrivaldate::DATE AS eta_date ");
        sqlProcessor.appendGroupBy("po.expectedarrivaldate::DATE ");
        sqlProcessor.appendGroupBy("po.shipDate::DATE ");
        sqlProcessor.appendGroupBy("po.dateIssued::DATE ");
        sqlProcessor.appendSelect("pos.status AS po_status, pt.paymentterms ");
        sqlProcessor.appendFrom("ecommerce.PurchaseOrderStatus as pos, ecommerce.paymentterms as pt ");
        sqlProcessor.appendWhere("po.purchaseOrderStatus_id = pos.purchaseOrderStatus_id and po.paymentterms_id = pt.paymentterms_id ");
        sqlProcessor.appendGroupBy("pos.status, pt.paymentterms ");
        if (notEmpty(showSupplier)) {
            sqlProcessor.appendSelect("s.supplierName AS supplier_name");
            sqlProcessor.appendGroupBy("s.supplierName");
        } else {
        	hide.push('supplier_name');
        }
        hide.push('ship_quarter');
        hide.push('po_count');
        break;
    case "buyer-roll":
        sqlProcessor.appendSelect("COALESCE(po.buyerUid,'unknown') AS buyer");
        sqlProcessor.setGroupBy("group by COALESCE(po.buyerUid,'unknown')");
        hide.push('po_id');
        hide.push('po_name');
        hide.push('paymentterms');
        hide.push('ship_date');
        hide.push('issued_date');
        hide.push('ship_quarter');
        hide.push('supplier_name');
        hide.push('po_status');
        hide.push('ship_quarter');
        hide.push('eta_date');
        break;
    default:
        sqlProcessor.appendSelect("to_char(po.shipDate::DATE,'YYYY-Q') AS ship_quarter ");
        sqlProcessor.appendSelect("pos.status AS po_status, pt.paymentterms ");
        sqlProcessor.appendFrom("ecommerce.PurchaseOrderStatus as pos, ecommerce.paymentterms as pt ");
        sqlProcessor.appendWhere("po.purchaseOrderStatus_id = pos.purchaseOrderStatus_id and po.paymentterms_id = pt.paymentterms_id ");
        sqlProcessor.appendSelect("s.supplierName AS supplier_name ");
        sqlProcessor.setGroupBy("group by to_char(po.shipDate::DATE,'YYYY-Q') ");
        sqlProcessor.appendGroupBy("s.supplierName,pos.status ");
        sqlProcessor.appendGroupBy("pt.paymentterms ");
        hide.push('buyer');
        hide.push('po_id');
        hide.push('po_name');
        hide.push('ship_date');
        hide.push('issued_date');
        hide.push('eta_date');
}

if (notEmpty(reorder)) {
    sqlProcessor.appendSelect("case when poli.is_reorder = 't' then 'Reorder' else 'New' end AS reorder_status");
    sqlProcessor.appendWhere("poli.is_reorder = '" + reorder + "'");
    sqlProcessor.appendGroupBy("case when poli.is_reorder = 't' then 'Reorder' else 'New' end");
} else {
	hide.push('reorder_status');
}

if (notEmpty(surcharge)) {
    sqlProcessor.appendFrom("ecommerce.surchargetype AS st");
    sqlProcessor.appendWhere(surchargeWhereString.toString());
    sqlProcessor.appendWhere("st.surchargetype_id in " + surchargeIdList.toString());
    sqlProcessor.appendGroupBy("st.description");
}

if (notEmpty(buyer)) {
    sqlProcessor.appendWhere("COALESCE(po.buyerUid,'unknown') = '" + buyer + "'");
}

if(notEmpty(showSupplierType)) {
    sqlProcessor.appendSelect("spt.supplier_type");
    sqlProcessor.appendFrom("ecommerce.supplier_type as spt ");
    sqlProcessor.appendWhere("s.supplier_type_id = spt.supplier_type_id ");
    sqlProcessor.appendGroupBy("spt.supplier_type");
} else {
    hide.push('supplier_type');
}

sqlProcessor.appendGroupBy("po.flat_rate_surcharge, po.flat_rate_surcharge2, po.flat_rate_surcharge3 ");

var poliProcessor = new SelectSQLBuilder();

poliProcessor.setSelect("select po.purchaseOrder_id AS po_id, po.poNumber AS po_name, po.buyeruid as buyer,pos.status AS po_status, po.dateIssued::DATE AS create_date ");
poliProcessor.appendSelect("po.shipDate::DATE AS ship_date, po.expectedarrivaldate::DATE as eta_date, poli.quantityOrdered AS qty_ordered ");
poliProcessor.appendSelect("pv.sku_id AS sku_id, pv.name AS sku_name, case when poli.is_reorder = 't' then 'Reorder' else 'New' end AS reorder_status ");
poliProcessor.appendSelect("(CASE WHEN poli.quantityOrdered > 0 THEN (sum(COALESCE(po.flat_rate_surcharge,0.00) + COALESCE(po.flat_rate_surcharge2,0.00) + COALESCE(po.flat_rate_surcharge3,0.00)) / (select sum(poli2.quantityOrdered) from ecommerce.purchaseorderlineitem as poli2 where poli2.purchaseorder_id = po.purchaseorder_id)) ELSE 0 END) as po_level_charges_appliedto_poli ");
poliProcessor.appendSelect("poli.unitPrice AS unit_price, poli.unitsurcharge as unit_surcharge, poli.flatratesurcharge as unit_flat_rate_surcharge, (poli.duty_perc * poli.unitprice) as poli_summed_duty, rs.status AS line_item_status, COALESCE(sum(re.totalReceivedCount),0) AS qty_received ");
poliProcessor.appendSelect("COALESCE(COALESCE(a.state, a.country_code) || ' ' || a.postal_code,'--') AS supplier_location ");
poliProcessor.setFrom("from ecommerce.PurchaseOrder as po, ecommerce.PurchaseOrderStatus as pos, ecommerce.SKU as pv ");
poliProcessor.appendFrom("ecommerce.ReceivingStatus as rs, ecommerce.Supplier as s, ecommerce.supplier_address as a, ecommerce.supplier_type as st ");
poliProcessor.appendFrom("ecommerce.PurchaseOrderLineItem as poli LEFT OUTER JOIN ecommerce.ReceivingEvent as re ON poli.poLineItem_id = re.poLineItem_id ");
poliProcessor.setWhere("where po.purchaseOrder_id = poli.purchaseOrder_id and poli.sku_id = pv.sku_id ");
poliProcessor.appendWhere("poli.receivingStatus_id = rs.receivingStatus_id and po.purchaseOrderStatus_id = pos.purchaseOrderStatus_id ");
poliProcessor.appendWhere("po.supplier_id = s.supplier_id and s.supplier_id = a.supplier_id and a.is_primary = true and s.supplier_type_id = st.supplier_type_id ");

if (notEmpty(po_id)) {
    poliProcessor.appendWhere("po.purchaseorder_id = " + po_id );
}

if (notEmpty(shipDateStart)) {
    poliProcessor.appendWhere("po.shipDate >= '" + shipDateStart + "'");
}

if (notEmpty(shipDateEnd)) {
    poliProcessor.appendWhere("po.shipDate < '" + shipDateEnd + "'");
}

if (notEmpty(createDateStart)) {
    poliProcessor.appendWhere("po.dateIssued >= '" + createDateStart + "'");
}

if (notEmpty(createDateEnd)) {
    poliProcessor.appendWhere("po.dateIssued < '" + createDateEnd + "'");
}

//if (notEmpty(poNumber)) {
//    poliProcessor.appendWhere("po.poNumber ILIKE '" + poNumber + "%'");
//}

if (notEmpty(buyer)) {
    poliProcessor.appendWhere("po.buyeruid = '" + buyer + "'");
}

if (notEmpty(reorder)) {
    poliProcessor.appendWhere("poli.is_reorder = '" + reorder + "'");
}

//if (notEmpty(lineItem)) {
//    poliProcessor.appendWhere("pv.name ILIKE '" + lineItem + "%'");
//}

if (notEmpty(poStatus)) {
    if("0" == poStatus) {
        poliProcessor.appendWhere("po.purchaseOrderStatus_id != 6 ");
    } else if ("New and Incomplete" == poStatus) {
        poliProcessor.appendWhere("po.purchaseOrderStatus_id IN (1, 3) ");
    } else {
        poliProcessor.appendWhere("po.purchaseOrderStatus_id = " + poStatus);
    }
}

poliProcessor.setGroupBy("group by po.purchaseOrder_id, po.poNumber, po.buyeruid,pos.status, po.dateIssued::DATE, po.shipDate::DATE, po.expectedarrivaldate::DATE, poli.quantityOrdered ");
poliProcessor.appendGroupBy("pv.sku_id,pv.name,case when poli.is_reorder = 't' then 'Reorder' else 'New' end, poli.unitPrice, poli.unitsurcharge, poli.flatratesurcharge, poli.duty_perc, rs.status, COALESCE(COALESCE(a.state, a.country_code) || ' ' || a.postal_code,'--') ");
poliProcessor.setOrderBy("order by po.poNumber, pos.status, poli.quantityOrdered desc ");

if(notEmpty(showSupplierType)) {
    poliProcessor.appendSelect("st.supplier_type");
    poliProcessor.appendGroupBy("st.supplier_type");
} else {
  	hide.push('supplier_type');
}

if(notEmpty(showSupplier)) {
    poliProcessor.appendSelect("s.suppliername as supplier_name");
    poliProcessor.appendGroupBy("s.suppliername");
} else {
  	hide.push('supplier_name');
}

//if (notEmpty(lineItemStatus)) {
//    poliProcessor.appendWhere("poli.receivingStatus_id = " + lineItemStatus);
//}

if (notEmpty(show_all_line_items)) {
    sql = poliProcessor.queryString();
    hide.push("issued_date");
    hide.push("ship_quarter");
    hide.push("paymentterms");
    hide.push("po_count");
    hide.push("line_item_count");
    hide.push("po_value");
    hide.push("po_charges");
    hide.push("po_grand_total");
    hide.push("po_duty");
    hide.push("charge_type");
} else {
    sql = sqlProcessor.queryString();
    hide.push("sku_id");
    hide.push("sku_name");
    hide.push("create_date");
    hide.push("unit_price");
    hide.push("unit_surcharge");
    hide.push("unit_flat_rate_surcharge");
    hide.push("poli_summed_duty");
    hide.push("line_item_status");
    hide.push("qty_received");
    hide.push("supplier_location");
    hide.push("po_level_charges_appliedto_poli");
}

