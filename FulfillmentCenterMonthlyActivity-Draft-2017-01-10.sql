// 
// Fulfillment Center Monthly Activity
// Catherine Warren, 2016-12-05 & on | JIRA RPT-414
// 

var startDate = p["start"];
var endDate = p["end"];

var now = new Date();

var firstDayPrevMonth = new Date(now.getFullYear(), now.getMonth() - 1, 1);
var firstDayThisMonth = new Date(now.getFullYear(), now.getMonth(), 1);

var day0 = "" + (firstDayPrevMonth.getDate() < 10 ? "0" : "") + firstDayPrevMonth.getDate();
var month0 = "" + ( (firstDayPrevMonth.getMonth()+1) < 10 ? "0" : "") + (firstDayPrevMonth.getMonth()+1);
var year0 = firstDayPrevMonth.getFullYear();

var day1 = "" + (firstDayThisMonth.getDate() < 10 ? "0" : "") + firstDayThisMonth.getDate();
var month1 = "" + ( (firstDayThisMonth.getMonth()+1) < 10 ? "0" : "") + (firstDayThisMonth.getMonth()+1);
var year1 = firstDayThisMonth.getFullYear();

var targetMonth = year0 + "-" + month0;
var dateString0 = year0 + "-" + month0 + "-" + day0;
var dateString1 = year1 + "-" + month1 + "-" + day1;

// Sub-sub-query to find details of SKUs that were successfully picked
pickDetailProcessor = new SelectSQLBuilder();

pickDetailProcessor.setSelect("select fcpicker_id, pickstart, pickend, rsorder_id, sku_id, pickedquantity, productversionskuquantity, lineitemquantity, itemstate ");
pickDetailProcessor.appendSelect("(pickend - pickstart) as timespan, sum(pickedquantity) as sum_skus_per_order "); 
pickDetailProcessor.setFrom("from fulfillmentcenter.fcskutracker ");
pickDetailProcessor.setWhere("where itemstate & 512 = 512 ");
pickDetailProcessor.setGroupBy("group by fcpicker_id, pickstart, pickend, rsorder_id, sku_id, pickedquantity, productversionskuquantity, lineitemquantity, itemstate ");

if (notEmpty(startDate) || notEmpty(endDate)) {
    if (notEmpty(startDate)) { 
        pickDetailProcessor.appendWhere("pickstart >= '" + startDate + "' ");
    } if (notEmpty(endDate)) { 
        pickDetailProcessor.appendWhere("pickend < '" + endDate + "' ");
    }
} else {
    pickDetailProcessor.appendWhere("pickstart >= '" + dateString0 + "' ");
    pickDetailProcessor.appendWhere("pickend < '" + dateString1 + "' ");
}


// Sub-query to find aggregated picking data by picker_id
pickSumProcessor = new SelectSQLBuilder();

pickSumProcessor.setSelect("select pickDet.fcpicker_id, sum(pickDet.pickedquantity) as pickedquantity, avg(pickDet.timespan) as avg_sku_pick_time, avg(pickDet.pickedquantity) as avg_pieces_picked_per_order ");
pickSumProcessor.addCommonTableExpression("pickDetail", pickDetailProcessor);
pickSumProcessor.setFrom("from fulfillmentcenter.fcuser as fcu RIGHT JOIN pickDetail as pickDet ON fcu.fcuser_id = pickDet.fcpicker_id ");
pickSumProcessor.setWhere("where true ");
pickSumProcessor.setGroupBy("group by pickDet.fcpicker_id ");


// Sub-sub-query to find details of SKUs that were successfully packed
packDetailProcessor = new SelectSQLBuilder();

packDetailProcessor.setSelect("select fcpacker_id, packstart, packend, fcskutracker_id, rsorder_id, sku_id, skulocation_id, productversionskuquantity, lineitemquantity, itemstate, (packend - packstart) as timespan ");
packDetailProcessor.setFrom("from fulfillmentcenter.fcskutracker ");
packDetailProcessor.setWhere("where itemstate & 2048 = 2048 ");

if (notEmpty(startDate) || notEmpty(endDate)) {
    if (notEmpty(startDate)) { 
        packDetailProcessor.appendWhere("packstart >= '" + startDate + "' ");
    } if (notEmpty(endDate)) { 
        packDetailProcessor.appendWhere("packend < '" + endDate + "' ");
    }
} else {
    packDetailProcessor.appendWhere("packstart >= '" + dateString0 + "' ");
    packDetailProcessor.appendWhere("packend < '" + dateString1 + "' ");
}

// Sub-query to find aggregated packing data
packSumProcessor = new SelectSQLBuilder();

packSumProcessor.setSelect("select packDet.fcpacker_id, sum(packDet.lineitemquantity) as packedquantity, avg(packDet.timespan) as avg_sku_pack_time ");
packSumProcessor.addCommonTableExpression("packDetail", packDetailProcessor);
packSumProcessor.setFrom("from fulfillmentcenter.fcuser as fcu RIGHT JOIN packDetail as packDet ON fcu.fcuser_id = packDet.fcpacker_id ");
packSumProcessor.setWhere("where true ");
packSumProcessor.setGroupBy("group by packDet.fcpacker_id ");


// Sub-sub-query to find details of SKUs that were successfully QCed
qcDetailProcessor = new SelectSQLBuilder();

qcDetailProcessor.setSelect("select fcqc_id, qcstart, qcend, fcskutracker_id, rsorder_id, sku_id, skulocation_id, productversionskuquantity, lineitemquantity, itemstate, (qcend - qcstart) as timespan ");
qcDetailProcessor.setFrom("from fulfillmentcenter.fcskutracker ");
qcDetailProcessor.setWhere("where itemstate & 1024 = 1024 ");

if (notEmpty(startDate) || notEmpty(endDate)) {
    if (notEmpty(startDate)) { 
        qcDetailProcessor.appendWhere("qcstart >= '" + startDate + "' ");
    } if (notEmpty(endDate)) { 
        qcDetailProcessor.appendWhere("qcend < '" + endDate + "' ");
    }
} else {
    qcDetailProcessor.appendWhere("qcstart >= '" + dateString0 + "' ");
    qcDetailProcessor.appendWhere("qcend < '" + dateString1 + "' ");
}

// Sub-query to find aggregated QC data

qcSumProcessor = new SelectSQLBuilder();

qcSumProcessor.setSelect("select qcDet.fcqc_id, count(qcDet.lineitemquantity) as qcquantity, avg(qcDet.timespan) as avg_sku_qc_time ");
qcSumProcessor.addCommonTableExpression("qcDetail", qcDetailProcessor);
qcSumProcessor.setFrom("from fulfillmentcenter.fcuser as fcu RIGHT JOIN qcDetail as qcDet ON fcu.fcuser_id = qcDet.fcqc_id ");
qcSumProcessor.setWhere("where true ");
qcSumProcessor.setGroupBy("group by qcDet.fcqc_id ");

// Subquery to find order-level picking data
orderPickInfoProcessor = new SelectSQLBuilder();

orderPickInfoProcessor.setSelect("select fco.rsorder_id, fcuser_id, 1 as pickcount, fco.pickstart, fco.pickend, (fco.pickend - fco.pickstart) as order_pick_time, fco.itemstate");
orderPickInfoProcessor.setFrom("from fulfillmentcenter.fcordertracker as fco ");
orderPickInfoProcessor.setWhere("where fco.itemstate & 512 = 512 ");

// Subquery to find order-level packing data
orderPackInfoProcessor = new SelectSQLBuilder();

orderPackInfoProcessor.setSelect("select rsorder_id, fcuser_id, 1 as packcount, packstart, packend, (packend - packstart) as order_pack_time, itemstate ");
orderPackInfoProcessor.setFrom("from fulfillmentcenter.fcordertracker ");
orderPackInfoProcessor.setWhere("where itemstate & 2048 = 2048 ");

// Subquery to find order-level QC data
orderQcInfoProcessor = new SelectSQLBuilder();

orderQcInfoProcessor.setSelect("select rsorder_id, fcuser_id, 1 as qccount, qcstart, qcend, (qcend - qcstart) as order_qc_time, itemstate ");
orderQcInfoProcessor.setFrom("from fulfillmentcenter.fcordertracker ");
orderQcInfoProcessor.setWhere("where itemstate & 1024 = 1024 ");


// Main query 
sqlProcessor = new SelectSQLBuilder();

sqlProcessor.setSelect("select fcu.fullname as employee, fcu.username ");
sqlProcessor.appendSelect("sum(orderPickInfo.pickcount) as qty_orders_picked, avg(orderPickInfo.order_pick_time) as avg_order_pick_time, COALESCE(pickSum.pickedquantity,0) as qty_lineitems_picked, COALESCE(PickSum.avg_pieces_picked_per_order,0) as avg_pieces_picked_per_order ");
sqlProcessor.appendSelect("sum(orderPackInfo.packcount) as qty_orders_packed, avg(orderPackInfo.order_pack_time) as avg_order_pack_time ");
sqlProcessor.appendSelect("sum(orderQcInfo.qccount) as qty_orders_qced, avg(orderQcInfo.order_qc_time) as avg_order_qc_time ");
sqlProcessor.addCommonTableExpression("pickSum", pickSumProcessor);
sqlProcessor.addCommonTableExpression("packSum", packSumProcessor);
sqlProcessor.addCommonTableExpression("qcSum", qcSumProcessor);
sqlProcessor.addCommonTableExpression("orderPickInfo", orderPickInfoProcessor);
sqlProcessor.addCommonTableExpression("orderPackInfo", orderPackInfoProcessor);
sqlProcessor.addCommonTableExpression("orderQcInfo", orderQcInfoProcessor);
sqlProcessor.setFrom("from fulfillmentcenter.fcuser as fcu LEFT OUTER JOIN pickSum ON fcu.fcuser_id = pickSum.fcpicker_id LEFT OUTER JOIN packSum ON fcu.fcuser_id = packSum.fcpacker_id LEFT OUTER JOIN qcSum ON fcu.fcuser_id = qcSum.fcqc_id LEFT OUTER JOIN orderPickInfo on fcu.fcuser_id = orderPickInfo.fcuser_id LEFT OUTER JOIN orderPackInfo on fcu.fcuser_id = orderPackInfo.fcuser_id LEFT OUTER JOIN orderQcInfo on fcu.fcuser_id = orderQcInfo.fcuser_id ");
sqlProcessor.setWhere("where true ");
sqlProcessor.setGroupBy("group by fcu.fullname, fcu.username, pickSum.pickedquantity, pickSum.avg_pieces_picked_per_order ");

if (notEmpty(startDate) || notEmpty(endDate)) {
    hide.push('month');
} else {
    sqlProcessor.appendSelect("'" + targetMonth + "' as month");
}

sql = sqlProcessor.queryString();