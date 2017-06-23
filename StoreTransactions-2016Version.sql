//
// Store Transactions
// Edited by Catherine Warren, 2016-09-19 | JIRA RPT-471
// Made into the report of record 2016-10-19
// Edited Catherine Warren, 2016-12-08 to 15 | RPT-506
//

var startDate = p["start"];
var endDate = p["end"];
var store_name = p["storefront_name_withextras"];
var site_abbrv = p["site_abbrv_withextras"];
var period = p["period2"];
var state = p["nexus_states"];
var show_previous_calendar_month = p["show_previous_calendar_month"];

var now = new Date();

var firstDayPrevMonth = new Date(now.getFullYear(), now.getMonth() - 1, 1);
var firstDayThisMonth = new Date(now.getFullYear(), now.getMonth(), 1);

var day0 = "" + (firstDayPrevMonth.getDate() < 10 ? "0" : "") + firstDayPrevMonth.getDate();
var month0 = "" + ( (firstDayPrevMonth.getMonth()+1) < 10 ? "0" : "") + (firstDayPrevMonth.getMonth()+1);
var year0 = firstDayPrevMonth.getFullYear();

var day1 = "" + (firstDayThisMonth.getDate() < 10 ? "0" : "") + firstDayThisMonth.getDate();
var month1 = "" + ( (firstDayThisMonth.getMonth()+1) < 10 ? "0" : "") + (firstDayThisMonth.getMonth()+1);
var year1 = firstDayThisMonth.getFullYear();

var dateString0 = year0 + "-" + month0 + "-" + day0;
var dateString1 = year1 + "-" + month1 + "-" + day1;

var sitestring = ""

if (notEmpty(site_abbrv)) {
    if (site_abbrv == "show_all" || site_abbrv == "rollup_all") {
        sitestring = "(220, 224, 310, 348, 221, 2001, 345, 346, 349, 2006, 343, 344, 347, 350, 351, 352, 353, 354, 355, 2005)";
    } else if (site_abbrv == "rollup_ctg" || site_abbrv == "show_ctg") {
        sitestring = "(220, 224, 310, 348, 221, 2001, 345, 346, 349, 2006)";
    } else if (site_abbrv == "rollup_std" || site_abbrv == "show_std") {
        sitestring = "(343, 344, 347, 350, 351, 352, 353, 354, 355, 2005)" ;
    } else {
        sitestring = "'" + site_abbrv + "'";
    }
}


var taxAddProcessor = new SelectSQLBuilder();

taxAddProcessor.setSelect("select o.oid as order_id, COALESCE(o.shippingaddress_id, o.billingaddress_id) as address_id ");
taxAddProcessor.setFrom("from ecommerce.rsorder as o, ecommerce.paymentauthorization as pa ");
taxAddProcessor.setWhere("where o.oid = pa.order_id and pa.payment_transaction_result_id = 1 and pa.payment_status_id in (3, 5, 6) ");

if (notEmpty(show_previous_calendar_month)) {
    taxAddProcessor.appendWhere("pa.authdate >= '" + dateString0 + "' ");
    taxAddProcessor.appendWhere("pa.authdate < '" + dateString1 + "' ");
} else if (notEmpty(startDate)) {
    taxAddProcessor.appendWhere("pa.authdate >= '" + startDate + "' ");
} if (notEmpty(endDate)) {
    taxAddProcessor.appendWhere("pa.authdate < '" + endDate + "' ");
} else {
  	// do nothing
}

var ordersProcessor = new SelectSQLBuilder();

ordersProcessor.setSelect("select o.oid as order_id, pt.trandate::DATE as order_date, 1 as order_count, o.site_id, s.abbreviation as site_abbrv ");
ordersProcessor.appendSelect("(CASE WHEN o.processingstatus = 'PROCESSED' THEN 1 ELSE 0 END ) as authed_orders ");
ordersProcessor.appendSelect("(CASE WHEN o.processingstatus = 'NOT PROCESSED' THEN 1 ELSE 0 END ) as not_authed_orders ");
ordersProcessor.setFrom("from ecommerce.rsorder as o, ecommerce.paymentauthorization as pa, ecommerce.paymenttransaction as pt, ecommerce.site as s ");
ordersProcessor.setWhere("where pt.authorization_id = pa.authorization_id and pa.order_id = o.oid and pa.payment_transaction_result_id = 1 and pa.payment_status_id in (3, 5, 6) and o.site_id = s.site_id ");
ordersProcessor.setGroupBy("group by o.oid, pt.trandate::DATE, o.site_id, o.processingstatus, s.abbreviation ");

if (notEmpty(show_previous_calendar_month)) {
    ordersProcessor.appendWhere("pt.trandate >= '" + dateString0 + "' ");
    ordersProcessor.appendWhere("pt.trandate < '" + dateString1 + "' ");
} else if (notEmpty(startDate)) {
    ordersProcessor.appendWhere("pt.trandate >= '" + startDate + "' ");
} if (notEmpty(endDate)) {
    ordersProcessor.appendWhere("pt.trandate < '" + endDate + "' ");
} else {
  // do nothing 
}

if (notEmpty(store_name)) {
    if (store_name == "show_all_stores") {
        ordersProcessor.appendSelect("st.name as store_name ");
        ordersProcessor.appendFrom("ecommerce.store as st ");
        ordersProcessor.appendWhere("o.store_id = st.store_id ");
        ordersProcessor.appendGroupBy("st.name ");
    } else {
        ordersProcessor.appendSelect("st.name as store_name ");
        ordersProcessor.appendFrom("ecommerce.store as st ");
        ordersProcessor.appendWhere("o.store_id = st.store_id ");
        ordersProcessor.appendWhere("st.name = '" + store_name + "' ");
        ordersProcessor.appendGroupBy("st.name ");
    }
} 

if (notEmpty(site_abbrv)) {
    if (site_abbrv == "show_all" || site_abbrv == "rollup_all") {
        // do nothing - do not filter the results
    } else {
    ordersProcessor.appendWhere("s.site_id IN " + sitestring);
    }
}

// query for broken-out results

var brokenOutProcessor = new SelectSQLBuilder();

brokenOutProcessor.setSelect("select COALESCE(SUM(ord.order_count),0) as order_count, COALESCE(SUM(ord.authed_orders),0) as authed_orders, COALESCE(SUM(ord.not_authed_orders),0) as not_authed_orders, COUNT(*) AS tran_count ");
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
brokenOutProcessor.appendSelect("SUM(CASE WHEN pt.payment_transaction_type_id = 4 AND pt.payment_transaction_result_id = 1 THEN(COALESCE(o.shippingcost,0.00) - COALESCE(ra.amount,0.00)) ELSE 0 END) AS shipping_revenue ");
brokenOutProcessor.appendSelect("SUM(CASE WHEN pt.payment_transaction_type_id = 4 AND pt.payment_transaction_result_id = 1 THEN o.tax ELSE 0 END) as tax_captured ");
brokenOutProcessor.setFrom("from ecommerce.rsorder as o LEFT OUTER JOIN ord ON o.oid = ord.order_id LEFT OUTER JOIN ecommerce.RSAdjustment as ra ON o.oid = ra.order_id and ra.adjustment_type_id = 6 LEFT OUTER JOIN taxAdd ON o.oid = taxAdd.order_id ");
brokenOutProcessor.addCommonTableExpression("ord",ordersProcessor);
brokenOutProcessor.addCommonTableExpression("taxAdd",taxAddProcessor);
brokenOutProcessor.appendFrom("ecommerce.site as s, ecommerce.paymentauthorization as pa, ecommerce.payment_status as ps ");
brokenOutProcessor.appendFrom("ecommerce.paymenttransaction as pt, ecommerce.payment_transaction_type as ptt, ecommerce.payment_transaction_result as ptr ");
brokenOutProcessor.setWhere("where o.oid = pa.order_id and o.site_id = s.site_id and pt.payment_transaction_type_id = ptt.payment_transaction_type_id ");
brokenOutProcessor.appendWhere("pt.authorization_id = pa.authorization_id and pa.payment_status_id = ps.payment_status_id ");
brokenOutProcessor.appendWhere("pt.payment_transaction_result_id = ptr.payment_transaction_result_id and pt.trandate::DATE = ord.order_date ");
brokenOutProcessor.setGroupBy("group by ord.order_count, ord.authed_orders, ord.not_authed_orders ");

if (notEmpty(show_previous_calendar_month)) {
    brokenOutProcessor.appendWhere("pt.trandate >= '" + dateString0 + "' ");
    brokenOutProcessor.appendWhere("pt.trandate < '" + dateString1 + "' ");
} else if (notEmpty(startDate)) {
    brokenOutProcessor.appendWhere("pt.trandate >= '" + startDate + "' ");
} if (notEmpty(endDate)) {
    brokenOutProcessor.appendWhere("pt.trandate < '" + endDate + "' ");
} else {
  // do nothing 
}


if (notEmpty(store_name)) {
    if (store_name == "show_all_stores") {
        brokenOutProcessor.appendSelect("ord.store_name ");
        brokenOutProcessor.appendGroupBy("ord.store_name ");
    } else {
        brokenOutProcessor.appendSelect("ord.store_name as store_name ");
        brokenOutProcessor.appendWhere("ord.store_name = '" + store_name + "' ");
        brokenOutProcessor.appendGroupBy("ord.store_name ");
    }
} 

if (notEmpty(site_abbrv)) { 
  if (site_abbrv == "rollup_all") {
      // do nothing, do not filter the results 
    } else if (site_abbrv == "rollup_ctg" || site_abbrv == "rollup_std") {
	   brokenOutProcessor.appendWhere("ord.site_id IN " + sitestring);
    } else if (site_abbrv == "show_all") { 
       brokenOutProcessor.appendSelect("ord.site_id, ord.site_abbrv ");
       brokenOutProcessor.appendGroupBy("ord.site_id, ord.site_abbrv ");
    } else { 
       brokenOutProcessor.appendSelect("ord.site_id, ord.site_abbrv ");
       brokenOutProcessor.appendGroupBy("ord.site_id, ord.site_abbrv ");
       brokenOutProcessor.appendWhere("ord.site_id IN " + sitestring);
    }
}

if (notEmpty(period)) {
	if("day" == period) {
            brokenOutProcessor.appendSelect("to_char(pt.trandate,'yyyy-MM-DD') AS tran_date, to_char(pt.trandate::DATE,'Dy') AS day_of_week ");
            brokenOutProcessor.appendGroupBy("to_char(pt.trandate,'yyyy-MM-DD'), to_char(pt.trandate::DATE,'Dy') ");
            brokenOutProcessor.setOrderBy("order by to_char(pt.trandate,'yyyy-MM-DD') ");
	} if("Month" == period) {
            brokenOutProcessor.appendSelect("to_char(pt.trandate,'yyyy-MM') AS tran_date ");
            brokenOutProcessor.appendGroupBy("to_char(pt.trandate,'yyyy-MM') ");
            brokenOutProcessor.setOrderBy("order by to_char(pt.trandate,'yyyy-MM') ");
	} 
} else {
    brokenOutProcessor.appendSelect(" ''::text AS tran_date ");
    brokenOutProcessor.appendGroupBy("pt.trandate ");
    brokenOutProcessor.setOrderBy("order by pt.trandate ");
}

if (notEmpty(state)) { 
    brokenOutProcessor.appendSelect("a.state ");
    brokenOutProcessor.appendFrom("ecommerce.rsaddress as a ");
    brokenOutProcessor.appendWhere("o.oid = taxAdd.order_id and taxAdd.address_id = a.oid ");
    brokenOutProcessor.appendGroupBy("a.state ");
    if (state == 'nexus_states') {
        brokenOutProcessor.appendFrom("ecommerce.countryregion as cr ");
        brokenOutProcessor.appendWhere("a.state = cr.countryregion and cr.taxnexis = 1 ");
    } else {
        brokenOutProcessor.appendWhere("a.state = '" + state + "' ");
    }
}

var brokenOutResults = brokenOutProcessor.queryString();

var rolledUpProcessor = new SelectSQLBuilder();

rolledUpProcessor.setSelect("select brokenOut.tran_date, COALESCE(SUM(brokenOut.order_count),0) as order_count, COALESCE(SUM(brokenOut.authed_orders),0) as authed_orders, COALESCE(SUM(brokenOut.not_authed_orders),0) as not_authed_orders, COALESCE(SUM(brokenOut.tran_count),0) as tran_count ");
rolledUpProcessor.appendSelect("COALESCE(SUM(brokenOut.approved_count),0) as approved_count, COALESCE(SUM(brokenOut.declined_count),0) as declined_count, COALESCE(SUM(brokenOut.error_count),0) as error_count, COALESCE(SUM(brokenOut.not_supported_count),0) as not_supported_count, COALESCE(SUM(brokenOut.void_count),0) as void_count ");
rolledUpProcessor.appendSelect("COALESCE(SUM(brokenOut.capture_count),0) as capture_count, COALESCE(SUM(brokenOut.credit_count),0) as credit_count ");
rolledUpProcessor.appendSelect("COALESCE(SUM(brokenOut.void_amount_approved),0) as void_amount_approved, COALESCE(SUM(brokenOut.void_amount_declined),0) as void_amount_declined, COALESCE(SUM(brokenOut.capture_amount_approved),0) as capture_amount_approved, COALESCE(SUM(brokenOut.capture_amount_declined),0) as capture_amount_declined ");
rolledUpProcessor.appendSelect("COALESCE(SUM(brokenOut.credit_amount_approved),0) as credit_amount_approved, COALESCE(SUM(brokenOut.credit_amount_declined),0) as credit_amount_declined ");
rolledUpProcessor.appendSelect("COALESCE(SUM(brokenOut.shipping_revenue),0) as shipping_revenue ");
rolledUpProcessor.appendSelect("COALESCE(SUM(brokenOut.tax_captured),0) as tax_captured, SUM(COALESCE(brokenOut.capture_amount_approved,0) - COALESCE(brokenOut.credit_amount_approved,0) - COALESCE(brokenOut.tax_captured,0)) as simple_transaction_revenue ");
rolledUpProcessor.setFrom("from (" + brokenOutResults + ") as brokenOut ");
rolledUpProcessor.setWhere("where true ");
rolledUpProcessor.setGroupBy("group by brokenOut.tran_date ");
rolledUpProcessor.setOrderBy("order by brokenOut.tran_date asc ");

if (notEmpty(store_name)) {
    if (store_name == "show_all_stores") {
        rolledUpProcessor.appendSelect("brokenOut.store_name ");
        rolledUpProcessor.appendGroupBy("brokenOut.store_name ");
    } else {
        rolledUpProcessor.appendSelect("brokenOut.store_name as store_name ");
        rolledUpProcessor.appendWhere("brokenOut.store_name = '" + store_name + "' ");
        rolledUpProcessor.appendGroupBy("brokenOut.store_name ");
    }
} else {
    hide.push('store_name');
}

if (notEmpty(site_abbrv)) {
    if (site_abbrv == "rollup_all" || site_abbrv == "rollup_ctg" || site_abbrv == "rollup_std") { 
        // do nothing; let the rolled-up results through as-is
        hide.push('site_abbrv');
    } else if (site_abbrv == "show_all") { 
        rolledUpProcessor.appendSelect("brokenOut.site_abbrv ");
        rolledUpProcessor.appendGroupBy("brokenOut.site_abbrv ");
    } else { 
        rolledUpProcessor.appendSelect("brokenOut.site_abbrv ");
        rolledUpProcessor.appendGroupBy("brokenOut.site_abbrv ");
        rolledUpProcessor.appendWhere("brokenOut.site_id IN " + sitestring);
    }
} else {
    hide.push('site_abbrv');
}

if (notEmpty(period)) {
	if("day" == period) {
            rolledUpProcessor.appendSelect("brokenOut.day_of_week ");
            rolledUpProcessor.appendGroupBy("brokenOut.day_of_week ");
            rolledUpProcessor.appendOrderBy("brokenOut.day_of_week ");
	} if("Month" == period) {
            hide.push('day_of_week');
	} 
} else {
    hide.push('day_of_week');
}

if (notEmpty(state)) { 
    rolledUpProcessor.appendSelect("brokenOut.state as shipst ");
    rolledUpProcessor.appendGroupBy("brokenOut.state ");
} else {
    hide.push('shipst');
}

sql = rolledUpProcessor.queryString();

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
sum.push('shipping_revenue');
sum.push('tax_captured');
sum.push('simple_transaction_revenue');