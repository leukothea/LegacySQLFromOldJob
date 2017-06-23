//
// PO Information Report - DRAFT
// Catherine Warren, 2016-01-22 & on
// JIRA RPT-130
//

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
sum.push('line_item_count');
sum.push('qty_ordered');
sum.push('po_grand_total');

var sqlProcessor = new SelectSQLBuilder();
var tmpPoQuantitySqlProcessor = new SelectSQLBuilder();

tmpPoQuantitySqlProcessor.setSelect("select pol.purchaseorder_id as po_id, sum(pol.quantityordered) as po_quantity");
tmpPoQuantitySqlProcessor.setFrom("from ecommerce.purchaseorderlineitem pol");
tmpPoQuantitySqlProcessor.setGroupBy("group by pol.purchaseorder_id");

var surchargeWhereString = "(po.surcharge_type_id = st.surchargetype_id OR poli.surchargetype_id = st.surchargetype_id";
var surchargeIdList = "(";

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
sqlProcessor.appendSelect("sum(poli.unitPrice * poli.quantityOrdered * coalesce(poli.duty_perc,0.00) * 0.01)::numeric(9,4) AS po_duty ");
sqlProcessor.appendSelect("count(*) AS line_item_count, sum(poli.quantityOrdered) AS qty_ordered ");
sqlProcessor.appendSelect("(sum(poli.unitPrice * poli.quantityOrdered) + (sum(COALESCE(poli.unitSurcharge,0.00) * poli.quantityOrdered + COALESCE(poli.flatratesurcharge,0.00)) + COALESCE(po.flat_rate_surcharge,0.00) + COALESCE(po.flat_rate_surcharge2,0.00) + COALESCE(po.flat_rate_surcharge3,0.00))) as po_grand_total ");
sqlProcessor.setFrom("from ecommerce.PurchaseOrder as po, ecommerce.purchaseorderlineitem as poli, ecommerce.Supplier as s ");
sqlProcessor.appendRelationToFromWithAlias(tmpPoQuantitySqlProcessor, "tpoq");
sqlProcessor.setWhere("where po.purchaseOrder_id = poli.purchaseOrder_id and tpoq.po_id = po.purchaseorder_id ");
sqlProcessor.appendWhere("po.supplier_id = s.supplier_id ");

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
        break;
    default:
        sqlProcessor.appendSelect("to_char(po.shipDate::DATE,'YYYY-Q') AS ship_quarter ");
        sqlProcessor.appendSelect("pos.status AS po_status, pt.paymentterms ");
        sqlProcessor.appendFrom("ecommerce.PurchaseOrderStatus as pos, ecommerce.paymentterms as pt ");
        sqlProcessor.appendWhere("po.purchaseOrderStatus_id = pos.purchaseOrderStatus_id and po.paymentterms_id = pt.paymentterms_id ");
        sqlProcessor.appendSelect("s.supplierName AS supplier_name ");
        sqlProcessor.setGroupBy("group by to_char(po.shipDate::DATE,'YYYY-Q') ");
        sqlProcessor.appendGroupBy("s.supplierName,pos.status ");
        sqlProcessor.appendGroupBy("pos.status, pt.paymentterms ");
        hide.push('buyer');
        hide.push('po_id');
        hide.push('po_name');
        hide.push('ship_date');
        hide.push('issued_date');
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

sql = sqlProcessor.queryString();