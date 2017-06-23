// 
// Fulfillment Center Activity
// Catherine Warren, 2016-12-05 to 2017-02-21 | JIRA RPT-413 & RPT-414
// Edited Catherine Warren, 2017-03-15 | JIRA RPT-413 & 414
// Edited Catherine Warren, 2017-03-23 | JIRA RPT-413
// Edited Catherine Warren, 2017-04-20 | JIRA RPT-630 & 641
// 

// First, we set up the date range information. 

var working_timeframe = p["working_timeframe"];
var startDate = p["start"];
var endDate = p["end"];
var targetMonth = "";
var now = new Date();

if (notEmpty(working_timeframe)) {
    if (working_timeframe == 'Yesterday') {
        startDate = new Date(now.getFullYear(), now.getMonth(), now.getDate() - 1).toISOString().slice(0, 10);
        endDate = new Date(now.getFullYear(), now.getMonth(), now.getDate() - 1).toISOString().slice(0, 10);
    } else if (working_timeframe == 'Last Week') { 
        startDate = new Date(now.getFullYear(), now.getMonth(), now.getDate() - 7).toISOString().slice(0, 10); // Returns 7 days ago
        endDate = new Date(now.getFullYear(), now.getMonth(), now.getDate() - 1).toISOString().slice(0, 10); // returns yesterday
    } else if (working_timeframe == 'Last Month') {
        startDate = new Date(now.getFullYear(), now.getMonth() - 1, 1).toISOString().slice(0, 10);
        endDate = new Date(now.getFullYear(), now.getMonth(), 1).toISOString().slice(0, 10);
        targetMonth = now.getMonth();
    } else if (working_timeframe == 'Custom') {
        // let the user-entered start and end dates flow through
    } 
} 
// else if (notEmpty(startDate) || notEmpty(endDate)) { 
       // do nothing; let user-entered start and end dates flow through
//   } else if (notEmpty(startDate)) { 
//       endDate = new Date(now.getFullYear(), now.getMonth(), now.getDate()).toISOString().slice(0, 10);
//   } else if (notEmpty(startDate)) { 
//       startDate = new Date(now.getFullYear(), now.getMonth() - 1, 1).toISOString().slice(0, 10);
//   } 
//} 

var daterangeGenerator = new SelectSQLBuilder();

daterangeGenerator.setSelect("select (generate_series( '" + startDate + "', '" + endDate + "', '1 day'::interval))::date as date ");

daterange = daterangeGenerator.queryString();

// Now that the daterange has been sorted out, we begin to build the subqueries and queries to find the data we want. 

pick_time_period_filtered_orders_aggregate = new SelectSQLBuilder();

pick_time_period_filtered_orders_aggregate.setSelect("select dr.date, fcot.rsorder_id as order_id, fcot.pickstart, fcot.pickend, fcot.qcstart, fcot.qcend, fcot.packstart, fcot.packend, fcot.itemstate ");
pick_time_period_filtered_orders_aggregate.setFrom("from (" + daterange + ") as dr INNER JOIN fulfillmentcenter.fcordertracker as fcot ON dr.date = fcot.pickstart::DATE ");
pick_time_period_filtered_orders_aggregate.setWhere("where true ");
pick_time_period_filtered_orders_aggregate.setGroupBy("group by dr.date, fcot.rsorder_id, fcot.pickstart, fcot.pickend, fcot.qcstart, fcot.qcend, fcot.packstart, fcot.packend, fcot.itemstate ");


// Sub-sub-query to find details of SKUs that were successfully picked. Needed for the columns that count up the number of total and unique SKUs. 
pickDetailProcessor = new SelectSQLBuilder();

pickDetailProcessor.setSelect("select fcpicker_id, pickstart, pickend, (pickend - pickstart)::time as picktime, fcskutracker_id, rsorder_id, sku_id ");
pickDetailProcessor.appendSelect("skulocation_id, quantity, productversionskuquantity, lineitemquantity, itemstate ");
pickDetailProcessor.setFrom("from fulfillmentcenter.fcskutracker ");
pickDetailProcessor.setWhere("where itemstate & 512 = 512 ");

// Sub-query to find aggregated SKU picking data by picker_id. Needed for the columns that count up the number of total and unique SKUs. 
successfully_picked_skus_aggregated = new SelectSQLBuilder();

successfully_picked_skus_aggregated.setSelect("select dr.date, pick.fcpicker_id, COALESCE(SUM(pick.quantity),0) as count_skus_picked, COALESCE(COUNT(pick.sku_id),0) as unique_pieces_picked_during_timeframe, AVG(pick.picktime) as average_sku_pick_time ");
successfully_picked_skus_aggregated.addCommonTableExpression("pickDetail", pickDetailProcessor);
successfully_picked_skus_aggregated.setFrom("from (" + daterange + ") as dr INNER JOIN pickDetail as pick ON dr.date = pick.pickstart::DATE ");
successfully_picked_skus_aggregated.setWhere("where true ");
successfully_picked_skus_aggregated.setGroupBy("group by dr.date, pick.fcpicker_id ");


// Sub-sub-query to find details of SKUs that were successfully QCed -- this could be used in the future if we report on SKU-level QCing. 
qcDetailProcessor = new SelectSQLBuilder();

qcDetailProcessor.setSelect("select dr.date, qcd.fcqc_id, qcd.qcstart, qcd.qcend, (qcd.qcend - qcd.qcstart)::time as qctime, qcd.fcskutracker_id, qcd.rsorder_id, qcd.sku_id ");
qcDetailProcessor.appendSelect("qcd.skulocation_id, qcd.quantity, qcd.productversionskuquantity, qcd.lineitemquantity, qcd.itemstate ");
qcDetailProcessor.setFrom("from (" + daterange + ") as dr INNER JOIN fulfillmentcenter.fcskutracker AS qcd ON dr.date = qcd.qcstart::date ");
qcDetailProcessor.setWhere("where qcd.itemstate & 1024 = 1024 ");
qcDetailProcessor.setGroupBy("group by dr.date, qcd.fcqc_id, qcd.qcstart, qcd.qcend, qcd.fcskutracker_id, qcd.rsorder_id, qcd.sku_id ");


// Sub-query to find aggregated SKU QC data -- this could be used in the future if we report on SKU-level QCing.  

successfully_qced_skus_aggregated = new SelectSQLBuilder();

successfully_qced_skus_aggregated.setSelect("select qc.fcqc_id, COALESCE(SUM(qc.quantity),0) as count_skus_qced, AVG(qc.qctime) as average_qc_time ");
successfully_qced_skus_aggregated.addCommonTableExpression("qcDetail", qcDetailProcessor);
successfully_qced_skus_aggregated.setFrom("from qcDetail as qc ");
successfully_qced_skus_aggregated.setWhere("where true ");
successfully_qced_skus_aggregated.setGroupBy("group by qc.fcqc_id ");


// Sub-sub-query to find details of SKUs that were successfully packed -- this could be used in the future if we report on SKU-level packing.  
packDetailProcessor = new SelectSQLBuilder();

packDetailProcessor.setSelect("select dr.date, pad.fcpacker_id, pad.packstart, pad.packend, (pad.packend - pad.packstart)::time as packtime, pad.fcskutracker_id, pad.rsorder_id, pad.sku_id ");
packDetailProcessor.appendSelect("pad.skulocation_id, pad.quantity, pad.productversionskuquantity, pad.lineitemquantity, pad.itemstate ");
packDetailProcessor.setFrom("from (" + daterange + ") as dr INNER JOIN fulfillmentcenter.fcskutracker as pad ON dr.date = pad.packstart::DATE ");
packDetailProcessor.setWhere("where pad.itemstate & 2048 = 2048 ");
packDetailProcessor.setGroupBy("group by dr.date, pad.fcpacker_id, pad.packstart, pad.packend, pad.fcskutracker_id, pad.rsorder_id, pad.sku_id ");


// Sub-query to find aggregated SKU packing data -- this could be used in the future if we report on SKU-level packing.  
successfully_packed_skus_aggregated = new SelectSQLBuilder();

successfully_packed_skus_aggregated.setSelect("select pack.fcpacker_id, COALESCE(SUM(pack.quantity),0) as count_skus_packed, AVG(pack.packtime) as average_pack_time ");
successfully_packed_skus_aggregated.addCommonTableExpression("packDetail", packDetailProcessor);
successfully_packed_skus_aggregated.setFrom("from packDetail as pack ");
successfully_packed_skus_aggregated.setWhere("where true ");
successfully_packed_skus_aggregated.setGroupBy("group by pack.fcpacker_id ");

// Sub-sub-query to find order-level picking data -- Used to find the order-level picking data. 
orderPickDetailProcessor = new SelectSQLBuilder();

orderPickDetailProcessor.setSelect("select dr.date, fco.rsorder_id, fcuser_id as fcpicker_id, 1 as pickcount, fco.pickstart, fco.pickend, (fco.pickend - fco.pickstart) as order_pick_time, fco.itemstate");
orderPickDetailProcessor.setFrom("from (" + daterange + ") as dr INNER JOIN fulfillmentcenter.fcordertracker as fco ON dr.date = fco.pickstart::DATE ");
orderPickDetailProcessor.setWhere("where fco.itemstate & 512 = 512 ");
orderPickDetailProcessor.setGroupBy("group by dr.date, fco.rsorder_id, fcuser_id, fco.pickstart, fco.pickend, fco.itemstate");


// Subquery to group together the Order Pick Detail results by user

orderPickInfoProcessor = new SelectSQLBuilder();

orderPickInfoProcessor.setSelect("select orderpick.fcpicker_id, COUNT(orderpick.rsorder_id) as order_pick_count, AVG(orderpick.order_pick_time) as avg_order_pick_time ");
orderPickInfoProcessor.addCommonTableExpression("orderPickDetail", orderPickDetailProcessor);
orderPickInfoProcessor.setFrom("from fulfillmentcenter.fcuser as fcu RIGHT JOIN orderPickDetail AS orderpick ON fcu.fcuser_id = orderpick.fcpicker_id ");
orderPickInfoProcessor.setGroupBy("group by orderpick.fcpicker_id ");


// Sub-sub-query to find order-level QC data -- Used to find the order-level QC data. 
orderQcDetailProcessor = new SelectSQLBuilder();

orderQcDetailProcessor.setSelect("select dr.date, qcod.rsorder_id, qcod.fcuser_id as fcqc_id, 1 as qccount, qcod.qcstart, qcod.qcend, (qcod.qcend - qcod.qcstart) as order_qc_time, qcod.itemstate ");
orderQcDetailProcessor.setFrom("from (" + daterange + ") as dr INNER JOIN fulfillmentcenter.fcordertracker as qcod ON dr.date = qcod.qcstart::DATE ");
orderQcDetailProcessor.setWhere("where qcod.itemstate & 1024 = 1024 ");
orderQcDetailProcessor.setGroupBy("group by dr.date, qcod.rsorder_id, qcod.fcuser_id, qcod.qcstart, qcod.qcend, qcod.itemstate ");


// Subquery to group together the Order QC Detail results by user
orderQcInfoProcessor = new SelectSQLBuilder();

orderQcInfoProcessor.setSelect("select orderqc.fcqc_id, COUNT(orderqc.rsorder_id) as order_qc_count, AVG(orderqc.order_qc_time) as avg_order_qc_time ");
orderQcInfoProcessor.addCommonTableExpression("orderqcDetail", orderQcDetailProcessor);
orderQcInfoProcessor.setFrom("from fulfillmentcenter.fcuser as fcu RIGHT JOIN orderqcDetail AS orderqc ON fcu.fcuser_id = orderqc.fcqc_id ");
orderQcInfoProcessor.setGroupBy("group by orderqc.fcqc_id ");

// Sub-sub-query to find order-level packing data -- Used to find the order-level packing data. 
orderPackDetailProcessor = new SelectSQLBuilder();

orderPackDetailProcessor.setSelect("select dr.date, ordp.rsorder_id, ordp.fcuser_id as fcpacker_id, 1 as packcount, ordp.packstart, ordp.packend, (ordp.packend - ordp.packstart) as order_pack_time, ordp.itemstate ");
orderPackDetailProcessor.setFrom("from (" + daterange + ") as dr INNER JOIN fulfillmentcenter.fcordertracker as ordp ON dr.date = ordp.packstart::DATE ");
orderPackDetailProcessor.setWhere("where ordp.itemstate & 2048 = 2048 ");
orderPackDetailProcessor.setGroupBy("group by dr.date, ordp.rsorder_id, ordp.fcuser_id, ordp.packstart, ordp.packend, ordp.itemstate ");


// Subquery to group together the Order Pack Detail results by user
orderPackInfoProcessor = new SelectSQLBuilder();

orderPackInfoProcessor.setSelect("select orderpack.fcpacker_id, COUNT(orderpack.rsorder_id) as order_pack_count, AVG(orderpack.order_pack_time) as avg_order_pack_time ");
orderPackInfoProcessor.addCommonTableExpression("orderpackDetail", orderPackDetailProcessor);
orderPackInfoProcessor.setFrom("from fulfillmentcenter.fcuser as fcu RIGHT JOIN orderpackDetail AS orderpack ON fcu.fcuser_id = orderpack.fcpacker_id ");
orderPackInfoProcessor.setGroupBy("group by orderpack.fcpacker_id ");


// Sub-sub-query to find SKUs that the picker picked that later failed QC

pickfail1Processor = new SelectSQLBuilder();

pickfail1Processor.setSelect("select distinct skus.fcpicker_id as fcpicker_id, filtered_orders.order_id as order_id, filtered_orders.itemstate as itemstate ");
pickfail1Processor.addCommonTableExpression("filtered_orders", pick_time_period_filtered_orders_aggregate);
pickfail1Processor.setFrom("from fulfillmentcenter.fcskutracker as skus INNER JOIN filtered_orders ON skus.rsorder_id = filtered_orders.order_id ");
pickfail1Processor.setWhere("where filtered_orders.order_id = skus.rsorder_id and skus.itemstate & 61440 > 0");

// Sub-query to group together the results of the pickfail1 query

pickfail1SumProcessor = new SelectSQLBuilder();

pickfail1SumProcessor.setSelect("select distinct users.fcuser_id as fcpicker_id, COUNT(pickfail1.order_id) as qty_skus_user_picked_that_later_failed_qc ");
pickfail1SumProcessor.addCommonTableExpression("pickfail1", pickfail1Processor);
pickfail1SumProcessor.setFrom("from fulfillmentcenter.fcuser as users INNER JOIN pickfail1 ON users.fcuser_id = pickfail1.fcpicker_id ");
pickfail1SumProcessor.setWhere("where true ");
pickfail1SumProcessor.setGroupBy("group by users.fcuser_id ");

// Sub-sub-query to find SKUs that the QCer QCed that turned out to have failed

pickfail2Processor = new SelectSQLBuilder();

pickfail2Processor.setSelect("select skus.fcqc_id as fcqc_id, filtered_orders.order_id as order_id, filtered_orders.itemstate as itemstate ");
pickfail2Processor.addCommonTableExpression("filtered_orders", pick_time_period_filtered_orders_aggregate);
pickfail2Processor.setFrom("from fulfillmentcenter.fcskutracker as skus INNER JOIN filtered_orders ON skus.rsorder_id = filtered_orders.order_id ");
pickfail2Processor.setWhere("where filtered_orders.order_id = skus.rsorder_id and skus.itemstate & 61440 > 0 ");

// Sub-query to group together the results of the pickfail2 query

pickfail2SumProcessor = new SelectSQLBuilder();

pickfail2SumProcessor.setSelect("select users.fcuser_id as fcqc_id, COUNT(pickfail2.order_id) as qty_failing_skus_that_user_caught ");
pickfail2SumProcessor.addCommonTableExpression("pickfail2", pickfail2Processor);
pickfail2SumProcessor.setFrom("from fulfillmentcenter.fcuser as users INNER JOIN pickfail2 ON users.fcuser_id = pickfail2.fcqc_id ");
pickfail2SumProcessor.setWhere("where true ");
pickfail2SumProcessor.setGroupBy("group by users.fcuser_id ");

// Main query, joining up results of all previous subqueries based on FC User
sqlProcessor = new SelectSQLBuilder();

sqlProcessor.setSelect("select fcu.fullname as employee, fcu.username ");
sqlProcessor.appendSelect("orderPickInfo.order_pick_count as qty_orders_picked, orderPickInfo.avg_order_pick_time ");
sqlProcessor.appendSelect("pick.count_skus_picked as qty_skus_picked, (pick.count_skus_picked / 7.5) as qty_skus_picked_per_hour, pick.unique_pieces_picked_during_timeframe ");
//sqlProcessor.appendSelect("pick.average_sku_pick_time as avg_sku_pick_time ");
sqlProcessor.appendSelect("pickfail1Sum.qty_skus_user_picked_that_later_failed_qc ");
//sqlProcessor.appendSelect("qc.count_skus_qced as qty_skus_qced, qc.average_qc_time as avg_sku_qc_time ");
sqlProcessor.appendSelect("orderQcInfo.order_qc_count as qty_orders_qced ");
sqlProcessor.appendSelect("pickfail2Sum.qty_failing_skus_that_user_caught ");
//sqlProcessor.appendSelect("pack.count_skus_packed as qty_skus_packed, pack.average_pack_time as avg_sku_pack_time ");
sqlProcessor.appendSelect("orderPackInfo.order_pack_count as qty_orders_packed, (orderPackInfo.order_pack_count / 7.5) as qty_orders_packed_per_hour, orderPackInfo.avg_order_pack_time ");
sqlProcessor.addCommonTableExpression("pick", successfully_picked_skus_aggregated);
sqlProcessor.addCommonTableExpression("pack", successfully_packed_skus_aggregated);
sqlProcessor.addCommonTableExpression("qc", successfully_qced_skus_aggregated);
sqlProcessor.addCommonTableExpression("orderPickInfo", orderPickInfoProcessor);
sqlProcessor.addCommonTableExpression("orderQcInfo", orderQcInfoProcessor);
sqlProcessor.addCommonTableExpression("orderPackInfo", orderPackInfoProcessor);
sqlProcessor.addCommonTableExpression("pickfail1Sum", pickfail1SumProcessor);
sqlProcessor.addCommonTableExpression("pickfail2Sum", pickfail2SumProcessor);
sqlProcessor.setFrom("from fulfillmentcenter.fcuser as fcu LEFT OUTER JOIN pick ON fcu.fcuser_id = pick.fcpicker_id LEFT OUTER JOIN qc ON fcu.fcuser_id = qc.fcqc_id LEFT OUTER JOIN pack ON fcu.fcuser_id = pack.fcpacker_id LEFT OUTER JOIN orderPickInfo on fcu.fcuser_id = orderPickInfo.fcpicker_id LEFT OUTER JOIN orderQcInfo on fcu.fcuser_id = orderQcInfo.fcqc_id LEFT OUTER JOIN orderPackInfo on fcu.fcuser_id = orderPackInfo.fcpacker_id LEFT OUTER JOIN pickfail1Sum ON fcu.fcuser_id = pickfail1Sum.fcpicker_id LEFT OUTER JOIN pickfail2Sum ON fcu.fcuser_id = pickfail2Sum.fcqc_id ");
sqlProcessor.setWhere("where (orderPickInfo.order_pick_count >  0 OR pick.count_skus_picked > 0 OR pick.unique_pieces_picked_during_timeframe > 0 OR pickfail1Sum.qty_skus_user_picked_that_later_failed_qc > 0 OR orderQcInfo.order_qc_count > 0 OR pickfail2Sum.qty_failing_skus_that_user_caught > 0 OR orderPackInfo.order_pack_count > 0) ");
sqlProcessor.setGroupBy("group by fcu.fullname, fcu.username, orderPickInfo.order_pick_count, orderPickInfo.avg_order_pick_time ");
sqlProcessor.appendGroupBy("pick.count_skus_picked, pick.unique_pieces_picked_during_timeframe ");
sqlProcessor.appendGroupBy("pickfail1Sum.qty_skus_user_picked_that_later_failed_qc, orderQcInfo.order_qc_count ");
sqlProcessor.appendGroupBy("pickfail2Sum.qty_failing_skus_that_user_caught ");
sqlProcessor.appendGroupBy("orderPackInfo.order_pack_count, orderPackInfo.avg_order_pack_time ");
sqlProcessor.setOrderBy("order by fcu.username asc ");

if (working_timeframe == 'Yesterday') { 
    sqlProcessor.appendSelect("dr.date ");
    sqlProcessor.appendFrom("(" + daterange + ") as dr ");
    sqlProcessor.appendGroupBy("dr.date ");
} else {
    hide.push('date');
}

if (notEmpty(targetMonth)) { 
    (month_name = "(CASE WHEN " + targetMonth + " = 1 THEN 'January' WHEN " + targetMonth + " = 2 THEN 'February' WHEN " + targetMonth + " = 3 THEN 'March' WHEN " + targetMonth + " = 4 THEN 'April' WHEN " + targetMonth + " = 5 THEN 'May' WHEN " + targetMonth + " = 6 THEN 'June' WHEN " + targetMonth + " = 7 THEN 'July' WHEN " + targetMonth + " = 8 THEN 'August' WHEN " + targetMonth + " = 9 THEN 'September' WHEN " + targetMonth + " = 10 THEN 'October' WHEN " + targetMonth + " = 11 THEN 'November' WHEN " + targetMonth + " = 12 THEN 'December' END) " );
}

if (working_timeframe == 'Last Month') {
    sqlProcessor.appendSelect("" + month_name + " as month_name" );
} else {
    hide.push('month_name');
}

sql = sqlProcessor.queryString();