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

// Sub-query to get all the dates having to do with an order. Date filters are applied here. 

pick_time_period_filtered_orders_aggregate = new SelectSQLBuilder();

pick_time_period_filtered_orders_aggregate.setSelect("select rsorder_id as order_id, pickstart, pickend, qcstart, qcend, packstart, packend, itemstate ");
pick_time_period_filtered_orders_aggregate.setFrom("from fulfillmentcenter.fcordertracker ");
pick_time_period_filtered_orders_aggregate.setWhere("where true ");

if (notEmpty(startDate) || notEmpty(endDate)) {
    if (notEmpty(startDate)) { 
        pick_time_period_filtered_orders_aggregate.appendWhere("pickstart >= '" + startDate + "' ");
    } if (notEmpty(endDate)) { 
        pick_time_period_filtered_orders_aggregate.appendWhere("pickend < '" + endDate + "' ");
    }
} else {
    pick_time_period_filtered_orders_aggregate.appendWhere("pickstart >= '" + dateString0 + "' ");
    pick_time_period_filtered_orders_aggregate.appendWhere("pickend < '" + dateString1 + "' ");
}


// Sub-sub-query to find details of SKUs that were successfully picked. Needed for the columns that count up the number of total and unique SKUs. 
pickDetailProcessor = new SelectSQLBuilder();

pickDetailProcessor.setSelect("select fcpicker_id, pickstart, pickend, (pickend - pickstart)::time as picktime, fcskutracker_id, rsorder_id, sku_id ");
pickDetailProcessor.appendSelect("skulocation_id, quantity, productversionskuquantity, lineitemquantity, itemstate ");
pickDetailProcessor.setFrom("from fulfillmentcenter.fcskutracker ");
pickDetailProcessor.setWhere("where itemstate & 512 = 512 ");
pickDetailProcessor.setGroupBy("group by fcpicker_id, pickstart, pickend, fcskutracker_id, rsorder_id, sku_id, pickedquantity, productversionskuquantity, lineitemquantity, itemstate ");

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


// Sub-query to find aggregated SKU picking data by picker_id. Needed for the columns that count up the number of total and unique SKUs. 
successfully_picked_skus_aggregated = new SelectSQLBuilder();

successfully_picked_skus_aggregated.setSelect("select pick.fcpicker_id, COALESCE(SUM(pick.quantity),0) as count_skus_picked, COALESCE(COUNT(pick.sku_id),0) as unique_pieces_picked_during_timeframe, AVG(pick.picktime) as average_sku_pick_time ");
successfully_picked_skus_aggregated.addCommonTableExpression("pickDetail", pickDetailProcessor);
successfully_picked_skus_aggregated.setFrom("from pickDetail as pick ");
successfully_picked_skus_aggregated.setWhere("where true ");
successfully_picked_skus_aggregated.setGroupBy("group by pick.fcpicker_id ");


// Sub-sub-query to find details of SKUs that were successfully QCed -- this could be used in the future if we report on SKU-level QCing. 
qcDetailProcessor = new SelectSQLBuilder();

qcDetailProcessor.setSelect("select fcqc_id, qcstart, qcend, (qcend - qcstart)::time as qctime, fcskutracker_id, rsorder_id, sku_id ");
qcDetailProcessor.appendSelect("skulocation_id, quantity, productversionskuquantity, lineitemquantity, itemstate ");
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

// Sub-query to find aggregated SKU QC data -- this could be used in the future if we report on SKU-level QCing.  

successfully_qced_skus_aggregated = new SelectSQLBuilder();

successfully_qced_skus_aggregated.setSelect("select qc.fcqc_id, COALESCE(SUM(qc.quantity),0) as count_skus_qced, AVG(qc.qctime) as average_qc_time ");
successfully_qced_skus_aggregated.addCommonTableExpression("qcDetail", qcDetailProcessor);
successfully_qced_skus_aggregated.setFrom("from qcDetail as qc ");
successfully_qced_skus_aggregated.setWhere("where true ");
successfully_qced_skus_aggregated.setGroupBy("group by qc.fcqc_id ");


// Sub-sub-query to find details of SKUs that were successfully packed -- this could be used in the future if we report on SKU-level packing.  
packDetailProcessor = new SelectSQLBuilder();

packDetailProcessor.setSelect("select fcpacker_id, packstart, packend, (packend - packstart)::time as packtime, fcskutracker_id, rsorder_id, sku_id ");
packDetailProcessor.appendSelect("skulocation_id, quantity, productversionskuquantity, lineitemquantity, itemstate ");
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

// Sub-query to find aggregated SKU packing data -- this could be used in the future if we report on SKU-level packing.  
successfully_packed_skus_aggregated = new SelectSQLBuilder();

successfully_packed_skus_aggregated.setSelect("select pack.fcpacker_id, COALESCE(SUM(pack.quantity),0) as count_skus_packed, AVG(pack.packtime) as average_pack_time ");
successfully_packed_skus_aggregated.addCommonTableExpression("packDetail", packDetailProcessor);
successfully_packed_skus_aggregated.setFrom("from packDetail as pack ");
successfully_packed_skus_aggregated.setWhere("where true ");
successfully_packed_skus_aggregated.setGroupBy("group by pack.fcpacker_id ");



// Sub-sub-query to find order-level picking data -- Used to find the order-level picking data. 
orderPickDetailProcessor = new SelectSQLBuilder();

orderPickDetailProcessor.setSelect("select fco.rsorder_id, fcuser_id as fcpicker_id, 1 as pickcount, fco.pickstart, fco.pickend, (fco.pickend - fco.pickstart) as order_pick_time, fco.itemstate");
orderPickDetailProcessor.setFrom("from fulfillmentcenter.fcordertracker as fco ");
orderPickDetailProcessor.setWhere("where fco.itemstate & 512 = 512 ");

// Subquery to group together the Order Pick Detail results by user

orderPickInfoProcessor = new SelectSQLBuilder();

orderPickInfoProcessor.setSelect("select orderpick.fcpicker_id, COUNT(orderpick.rsorder_id) as order_pick_count, AVG(orderpick.order_pick_time) as avg_order_pick_time ");
orderPickInfoProcessor.addCommonTableExpression("orderPickDetail", orderPickDetailProcessor);
orderPickInfoProcessor.setFrom("from fulfillmentcenter.fcuser as fcu RIGHT JOIN orderPickDetail AS orderpick ON fcu.fcuser_id = orderpick.fcpicker_id ");
orderPickInfoProcessor.setGroupBy("group by orderpick.fcpicker_id ");

// Sub-sub-query to find order-level QC data -- Used to find the order-level QC data. 
orderQcDetailProcessor = new SelectSQLBuilder();

orderQcDetailProcessor.setSelect("select rsorder_id, fcuser_id as fcqc_id, 1 as qccount, qcstart, qcend, (qcend - qcstart) as order_qc_time, itemstate ");
orderQcDetailProcessor.setFrom("from fulfillmentcenter.fcordertracker ");
orderQcDetailProcessor.setWhere("where itemstate & 1024 = 1024 ");

// Subquery to group together the Order QC Detail results by user
orderQcInfoProcessor = new SelectSQLBuilder();

orderQcInfoProcessor.setSelect("select orderqc.fcqc_id, COUNT(orderqc.rsorder_id) as order_qc_count, AVG(orderqc.order_qc_time) as avg_order_qc_time ");
orderQcInfoProcessor.addCommonTableExpression("orderqcDetail", orderQcDetailProcessor);
orderQcInfoProcessor.setFrom("from fulfillmentcenter.fcuser as fcu RIGHT JOIN orderqcDetail AS orderqc ON fcu.fcuser_id = orderqc.fcqc_id ");
orderQcInfoProcessor.setGroupBy("group by orderqc.fcqc_id ");

// Sub-sub-query to find order-level packing data -- Used to find the order-level packing data. 
orderPackDetailProcessor = new SelectSQLBuilder();

orderPackDetailProcessor.setSelect("select rsorder_id, fcuser_id as fcpacker_id, 1 as packcount, packstart, packend, (packend - packstart) as order_pack_time, itemstate ");
orderPackDetailProcessor.setFrom("from fulfillmentcenter.fcordertracker ");
orderPackDetailProcessor.setWhere("where itemstate & 2048 = 2048 ");

// Subquery to group together the Order Pack Detail results by user
orderPackInfoProcessor = new SelectSQLBuilder();

orderPackInfoProcessor.setSelect("select orderpack.fcpacker_id, COUNT(orderpack.rsorder_id) as order_pack_count, AVG(orderpack.order_pack_time) as avg_order_pack_time ");
orderPackInfoProcessor.addCommonTableExpression("orderpackDetail", orderPackDetailProcessor);
orderPackInfoProcessor.setFrom("from fulfillmentcenter.fcuser as fcu RIGHT JOIN orderpackDetail AS orderpack ON fcu.fcuser_id = orderpack.fcpacker_id ");
orderPackInfoProcessor.setGroupBy("group by orderpack.fcpacker_id ");

// Sub-query to group together pickers and their orders by the filtered time period -- NECESSARY??

//time_period_pickers_and_orders = new SelectSQLBuilder();

//time_period_pickers_and_orders.setSelect("select skus.fcpicker_id as fcpicker_id, filtered_orders.order_id as order_id, filtered_orders.itemstate as itemstate ");
//time_period_pickers_and_orders.addCommonTableExpression("filtered_orders", pick_time_period_filtered_orders_aggregate);
//time_period_pickers_and_orders.setFrom("from fulfillmentcenter.fcskutracker as skus RIGHT JOIN filtered_orders ON skus.rsorder_id = filtered_orders.order_id ");
//time_period_pickers_and_orders.setWhere("where filtered_orders.order_id = skus.rsorder_id ");

// Sub-query to group together QCers and their orders by the filtered time period -- NECESSARY??

//time_period_qcers_and_orders = new SelectSQLBuilder();

//time_period_qcers_and_orders.setSelect("select skus.fcqc_id as fcqc_id, filtered_orders.order_id as order_id, filtered_orders.itemstate as itemstate ");
//time_period_qcers_and_orders.addCommonTableExpression("filtered_orders", pick_time_period_filtered_orders_aggregate);
//time_period_qcers_and_orders.setFrom("from fulfillmentcenter.fcskutracker as skus RIGHT JOIN filtered_orders ON skus.rsorder_id = filtered_orders.order_id ");
//time_period_qcers_and_orders.setWhere("where filtered_orders.order_id = skus.rsorder_id ");


// Sub-sub-query to find SKUs that the picker picked that later failed QC

pickfail1Processor = new SelectSQLBuilder();

pickfail1Processor.setSelect("select skus.fcpicker_id as fcpicker_id, filtered_orders.order_id as order_id, filtered_orders.itemstate as itemstate ");
pickfail1Processor.addCommonTableExpression("filtered_orders", pick_time_period_filtered_orders_aggregate);
pickfail1Processor.setFrom("from fulfillmentcenter.fcskutracker as skus LEFT OUTER JOIN filtered_orders ON skus.rsorder_id = filtered_orders.order_id ");
pickfail1Processor.setWhere("where filtered_orders.order_id = skus.rsorder_id ");


// Sub-query to group together the results of the pickfail1 query

pickfail1SumProcessor = new SelectSQLBuilder();

pickfail1SumProcessor.setSelect("select users.fcuser_id as fcpicker_id, COUNT(pickfail1.order_id) as qty_skus_user_picked_that_later_failed_qc ");
pickfail1SumProcessor.addCommonTableExpression("pickfail1", pickfail1Processor);
pickfail1SumProcessor.setFrom("from fulfillmentcenter.fcuser as users LEFT OUTER JOIN pickfail1 ON users.fcuser_id = pickfail1.fcpicker_id ");
pickfail1SumProcessor.setWhere("where true ");
pickfail1SumProcessor.setGroupBy("group by users.fcuser_id ");


// Sub-sub-query to find SKUs that the QCer QCed that turned out to have failed

pickfail2Processor = new SelectSQLBuilder();

pickfail2Processor.setSelect("select skus.fcqc_id as fcqc_id, filtered_orders.order_id as order_id, filtered_orders.itemstate as itemstate ");
pickfail2Processor.addCommonTableExpression("filtered_orders", pick_time_period_filtered_orders_aggregate);
pickfail2Processor.setFrom("from fulfillmentcenter.fcskutracker as skus LEFT OUTER JOIN filtered_orders ON skus.rsorder_id = filtered_orders.order_id ");
pickfail2Processor.setWhere("where filtered_orders.order_id = skus.rsorder_id ");


// Sub-query to group together the results of the pickfail2 query

pickfail2SumProcessor = new SelectSQLBuilder();

pickfail2SumProcessor.setSelect("select users.fcuser_id as fcqc_id, COUNT(pickfail2.order_id) as qty_failing_skus_that_user_caught ");
pickfail2SumProcessor.addCommonTableExpression("pickfail2", pickfail2Processor);
pickfail2SumProcessor.setFrom("from fulfillmentcenter.fcuser as users LEFT OUTER JOIN pickfail2 ON users.fcuser_id = pickfail2.fcqc_id ");
pickfail2SumProcessor.setWhere("where true ");
pickfail2SumProcessor.setGroupBy("group by users.fcuser_id ");

// Main query, joining up results of all previous subqueries based on FC User
sqlProcessor = new SelectSQLBuilder();

sqlProcessor.setSelect("select fcu.fullname as employee, fcu.username ");
sqlProcessor.appendSelect("orderPickInfo.order_pick_count as qty_orders_picked, orderPickInfo.avg_order_pick_time ");
sqlProcessor.appendSelect("pick.count_skus_picked as qty_skus_picked, pick.unique_pieces_picked_during_timeframe ");
//sqlProcessor.appendSelect("pick.average_sku_pick_time as avg_sku_pick_time ");
sqlProcessor.appendSelect("pickfail1Sum.qty_skus_user_picked_that_later_failed_qc ");
//sqlProcessor.appendSelect("qc.count_skus_qced as qty_skus_qced, qc.average_qc_time as avg_sku_qc_time ");
sqlProcessor.appendSelect("orderQcInfo.order_qc_count as qty_orders_qced, orderQcInfo.avg_order_qc_time ");
sqlProcessor.appendSelect("pickfail2Sum.qty_failing_skus_that_user_caught ");
//sqlProcessor.appendSelect("pack.count_skus_packed as qty_skus_packed, pack.average_pack_time as avg_sku_pack_time ");
sqlProcessor.appendSelect("orderPackInfo.order_pack_count as qty_orders_packed, orderPackInfo.avg_order_pack_time ");
sqlProcessor.addCommonTableExpression("pick", successfully_picked_skus_aggregated);
sqlProcessor.addCommonTableExpression("pack", successfully_packed_skus_aggregated);
sqlProcessor.addCommonTableExpression("qc", successfully_qced_skus_aggregated);
sqlProcessor.addCommonTableExpression("orderPickInfo", orderPickInfoProcessor);
sqlProcessor.addCommonTableExpression("orderQcInfo", orderQcInfoProcessor);
sqlProcessor.addCommonTableExpression("orderPackInfo", orderPackInfoProcessor);
sqlProcessor.addCommonTableExpression("pickfail1Sum", pickfail1SumProcessor);
sqlProcessor.addCommonTableExpression("pickfail2Sum", pickfail2SumProcessor);
sqlProcessor.setFrom("from fulfillmentcenter.fcuser as fcu LEFT OUTER JOIN pick ON fcu.fcuser_id = pick.fcpicker_id LEFT OUTER JOIN pack ON fcu.fcuser_id = pack.fcpacker_id LEFT OUTER JOIN qc ON fcu.fcuser_id = qc.fcqc_id LEFT OUTER JOIN orderPickInfo on fcu.fcuser_id = orderPickInfo.fcpicker_id LEFT OUTER JOIN orderQcInfo on fcu.fcuser_id = orderQcInfo.fcqc_id LEFT OUTER JOIN orderPackInfo on fcu.fcuser_id = orderPackInfo.fcpacker_id LEFT OUTER JOIN pickfail1Sum ON fcu.fcuser_id = pickfail1Sum.fcpicker_id LEFT OUTER JOIN pickfail2Sum ON fcu.fcuser_id = pickfail2Sum.fcqc_id ");
sqlProcessor.setWhere("where true ");
sqlProcessor.setGroupBy("group by fcu.fullname, fcu.username, orderPickInfo.order_pick_count, orderPickInfo.avg_order_pick_time ");
sqlProcessor.appendGroupBy("pick.count_skus_picked, pick.unique_pieces_picked_during_timeframe ");
sqlProcessor.appendGroupBy("pickfail1Sum.qty_skus_user_picked_that_later_failed_qc, orderQcInfo.order_qc_count, orderQcInfo.avg_order_qc_time ");
sqlProcessor.appendGroupBy("pickfail2Sum.qty_failing_skus_that_user_caught ");
sqlProcessor.appendGroupBy("orderPackInfo.order_pack_count, orderPackInfo.avg_order_pack_time ");

if (notEmpty(startDate) || notEmpty(endDate)) {
    hide.push('month');
} else {
    sqlProcessor.appendSelect("'" + targetMonth + "' as month");
}

sql = sqlProcessor.queryString();