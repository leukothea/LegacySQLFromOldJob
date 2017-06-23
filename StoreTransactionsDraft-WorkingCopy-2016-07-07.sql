//
// Accounting - Store Transactions
// Created Ted Kubaitis, 2016-06-29
// Edited Catherine Warren, 2016-07-05&06 | JIRA RPT-408
//

var startDate = p["start"];
var endDate = p["end"];
var site_abbrv = p["site_abbrev"];


var sitestring = ""

if (notEmpty(site_abbrv)) {
    if (site_abbrv == "ignoreAll") {
        hide.push('site_abbrv');
        sitestring = "'%'";
    } else if (site_abbrv == "showAll" ) {
        sitestring = "'%'";
    } else if (site_abbrv == "all_ctg") {
        sitestring = "'THS', 'BCS', 'ARS', 'CHS', 'DBS', 'TRS', 'LIT', 'VET', 'AUT', 'ALZ', 'TES'";
    } else if (site_abbrv == "all_std") {
        sitestring = "'PRS', 'GGF', 'HFL', 'JG', 'CK', 'SB', 'GGC', 'CPW', 'DGL', 'RB'" ;
    } else {
        sitestring = "'" + site_abbrv + "'";
    }
}


var ordersProcessor = new SelectSQLBuilder();

ordersProcessor.setSelect("select o.orderdate::DATE as order_date, COALESCE(count(*),0) as order_count, o.site_id, s.abbreviation as site_abbrv ");
ordersProcessor.appendSelect("COALESCE(SUM(CASE WHEN o.processingstatus = 'PROCESSED' THEN 1 ELSE 0 END ),0) as authed_orders ");
ordersProcessor.appendSelect("COALESCE(SUM(CASE WHEN o.processingstatus = 'NOT PROCESSED' THEN 1 ELSE 0 END ),0) as not_authed_orders ");
ordersProcessor.setFrom("from ecommerce.rsorder as o, ecommerce.paymentauthorization as pa, ecommerce.site as s ");
ordersProcessor.setWhere("where pa.order_id = o.oid and pa.payment_transaction_result_id = 1 and pa.payment_status_id in (3,5,6) and o.site_id = s.site_id ");
ordersProcessor.setGroupBy("group by o.orderdate::DATE, o.site_id, s.abbreviation ");

if (notEmpty(startDate)) {
    ordersProcessor.appendWhere("o.orderdate >= '" + startDate+ "' ");
} 

if (notEmpty(endDate)) {
    ordersProcessor.appendWhere("o.orderdate < '" + endDate + "' ");
} 

if (notEmpty(site_abbrv)) {
    if (site_abbrv == "ignoreAll") {
      hide.push('site_abbrv');
    } else if (site_abbrv == "showAll") {
    // leave the site abbreviation parameter blank
      } else { 
    ordersProcessor.appendWhere("s.abbreviation IN (" + sitestring + ") ");
    }
}

var trafficProcessor = new SelectSQLBuilder();

trafficProcessor.setSelect("select t.traffic_date, sum(t.session_count) as session_count, UPPER(pa.abbrv) as site_abbrv ");
trafficProcessor.setFrom("from traffic.daily_traffic as t, panacea.site as pa ");
trafficProcessor.setWhere("where t.application_id = 2 and t.site_id = pa.site_id ");
trafficProcessor.setGroupBy("group by t.traffic_date, pa.abbrv ");

if (notEmpty(startDate)) {
    trafficProcessor.appendWhere("t.traffic_date::DATE >= '" + startDate + "' ");
} 

if (notEmpty(endDate)) {
    trafficProcessor.appendWhere("t.traffic_date::DATE < '" + endDate + "' ");
} 

if (notEmpty(site_abbrv)) {
    if (site_abbrv == "ignoreAll") {
      // do nothing; let all orders through
    } else if (site_abbrv == "showAll") {
    // leave the site abbreviation parameter blank
      } else { 
      trafficProcessor.appendWhere("UPPER(pa.abbrv) IN (" + sitestring + ") ");
    }
}

// query to use when broken-out results are required

var brokenOutProcessor = new SelectSQLBuilder();

brokenOutProcessor.setSelect("select x.site_abbrv, pt.trandate::DATE AS tran_date, to_char(pt.trandate::DATE,'Dy') AS day_of_week, x.session_count ");
brokenOutProcessor.appendSelect("COALESCE(ord.order_count,0) as order_count, COALESCE(ord.authed_orders,0) as authed_orders, COALESCE(ord.not_authed_orders,0) as not_authed_orders, COUNT(*) AS tran_count ");
brokenOutProcessor.appendSelect("SUM(CASE WHEN pt.payment_transaction_result_id = 1 THEN 1 ELSE 0 END ) as approved_count ");
brokenOutProcessor.appendSelect("SUM(CASE WHEN pt.payment_transaction_result_id = 2 THEN 1 ELSE 0 END ) as declined_count ");
brokenOutProcessor.appendSelect("SUM(CASE WHEN pt.payment_transaction_result_id = 3 THEN 1 ELSE 0 END ) as error_count ");
brokenOutProcessor.appendSelect("SUM(CASE WHEN pt.payment_transaction_result_id = 4 THEN 1 ELSE 0 END ) as not_supported_count ");
brokenOutProcessor.appendSelect("SUM(CASE WHEN pt.payment_transaction_type_id = 3 THEN 1 ELSE 0 END ) as void_count ");
brokenOutProcessor.appendSelect("SUM(CASE WHEN pt.payment_transaction_type_id = 4 THEN 1 ELSE 0 END ) as capture_count ");
brokenOutProcessor.appendSelect("SUM(CASE WHEN pt.payment_transaction_type_id = 5 THEN 1 ELSE 0 END ) as credit_count  ");
brokenOutProcessor.appendSelect("SUM(CASE WHEN pt.payment_transaction_type_id = 3 AND pt.payment_transaction_result_id = 1 THEN pt.amount ELSE 0 END ) as void_amount_approved ");
brokenOutProcessor.appendSelect("SUM(CASE WHEN pt.payment_transaction_type_id = 3 AND pt.payment_transaction_result_id = 2 THEN pt.amount ELSE 0 END ) as void_amount_declined ");
brokenOutProcessor.appendSelect("SUM(CASE WHEN pt.payment_transaction_type_id = 4 AND pt.payment_transaction_result_id = 1 THEN pt.amount ELSE 0 END ) as capture_amount_approved ");
brokenOutProcessor.appendSelect("SUM(CASE WHEN pt.payment_transaction_type_id = 4 AND pt.payment_transaction_result_id = 2 THEN pt.amount ELSE 0 END ) as capture_amount_declined  ");
brokenOutProcessor.appendSelect("SUM(CASE WHEN pt.payment_transaction_type_id = 5 AND pt.payment_transaction_result_id = 1 THEN pt.amount ELSE 0 END ) as credit_amount_approved  ");
brokenOutProcessor.appendSelect("SUM(CASE WHEN pt.payment_transaction_type_id = 5 AND pt.payment_transaction_result_id = 2 THEN pt.amount ELSE 0 END ) as credit_amount_declined  ");
brokenOutProcessor.setFrom("from ecommerce.rsorder as o, ecommerce.site as s LEFT OUTER JOIN ord ON s.abbreviation = ord.site_abbrv LEFT OUTER JOIN x ON s.abbreviation = x.site_abbrv ");
brokenOutProcessor.addCommonTableExpression("ord",ordersProcessor);
brokenOutProcessor.addCommonTableExpression("x",trafficProcessor);
brokenOutProcessor.appendFrom("ecommerce.paymentauthorization as pa, ecommerce.payment_status as ps ");
brokenOutProcessor.appendFrom("ecommerce.paymenttransaction as pt, ecommerce.payment_transaction_type as ptt, ecommerce.payment_transaction_result as ptr ");
brokenOutProcessor.setWhere("where o.oid = pa.order_id and o.site_id = s.site_id and pt.payment_transaction_type_id = ptt.payment_transaction_type_id ");
brokenOutProcessor.appendWhere("pt.authorization_id = pa.authorization_id and pa.payment_status_id = ps.payment_status_id ");
brokenOutProcessor.appendWhere("pt.payment_transaction_result_id = ptr.payment_transaction_result_id ");
brokenOutProcessor.setGroupBy("group by x.site_abbrv, x.session_count, ord.order_count, ord.authed_orders, ord.not_authed_orders, pt.trandate::DATE, to_char(pt.trandate::DATE,'Dy') ");
brokenOutProcessor.setOrderBy("order by pt.trandate::DATE ");
                                 
if (notEmpty(startDate)) {
    brokenOutProcessor.appendWhere("pt.trandate >= '" + startDate + "' ");
} 

if (notEmpty(endDate)) {
    brokenOutProcessor.appendWhere("pt.trandate < '" + endDate + "' ");
} 

var brokenOutResults = brokenOutProcessor.queryString();
var rolledUpProcessor = "SELECT SUM(rolledUp.session_count) as session_count, SUM(rolledUp.order_count) as order_count, SUM(rolledUp.authed_orders) as authed_orders, SUM(rolledUp.not_authed_orders) as not_authed_orders, SUM(rolledUp.tran_count) as tran_count, SUM(rolledUp.approved_count) as approved_count, SUM(rolledUp.declined_count) as declined_count, SUM(rolledUp.error_count) as error_count, SUM(rolledUp.not_supported_count) as not_supported_count, SUM(rolledUp.void_count) as void_count, SUM(rolledUp.capture_count) as capture_count, SUM(rolledUp.credit_count) as credit_count, SUM(rolledUp.void_amount_approved) as void_amount_approved, SUM(rolledUp.void_amount_declined) as void_amount_declined, SUM(rolledUp.capture_amount_approved) as capture_amount_approved, SUM(rolledUp.capture_amount_declined) as capture_amount_declined, SUM(rolledUp.credit_amount_approved) as credit_amount_approved, SUM(rolledUp.credit_amount_declined) as credit_amount_declined FROM (" + brokenOutResults + ") as rolledUp "

// toggle which query is called 

if (notEmpty(site_abbrv)) {
    if (site_abbrv == "ignoreAll") {
        hide.push('tran_date');
        hide.push('day_of_week');
        sql = rolledUpProcessor
    } else if (site_abbrv == "showAll" ) {
        sql = brokenOutProcessor.queryString();
    } else if (site_abbrv == "all_ctg") {
        brokenOutProcessor.appendWhere("s.abbreviation IN (" + sitestring + ") ");
        sql = brokenOutProcessor.queryString();
    } else if (site_abbrv == "all_std") {
        brokenOutProcessor.appendWhere("s.abbreviation IN (" + sitestring + ") ");
        sql = brokenOutProcessor.queryString();
    } else { 
        brokenOutProcessor.appendWhere("s.abbreviation IN (" + sitestring + ") ");
        sql = brokenOutProcessor.queryString();
    }
} else { 
  brokenOutProcessor.appendWhere("s.abbreviation IN (" + sitestring + ") ");
  sql = brokenOutProcessor.queryString();
}

sum.push('session_count');
sum.push('order_count');
sum.push('authed_orders');
sum.push('not_authed_orders');
sum.push('tran_count');
sum.push('approved_count');
sum.push('declined_count');
sum.push('error_count');
sum.push('not_supported_count');
sum.push('void_count');
sum.push('capture_count');
sum.push('credit_count');
sum.push('void_amount_approved');
sum.push('void_amount_declined');
sum.push('capture_amount_approved');
sum.push('capture_amount_declined');
sum.push('credit_amount_approved');
sum.push('credit_amount_declined');