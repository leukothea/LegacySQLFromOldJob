//
// Origin Code Detail Report
// Edited Catherine Warren, 2015-08-20 (adding item ID as an output column)
// Edited Catherine Warren, 2015-11-18 (RPT-183), and adding "No Origin Code" to output
//

var originCode = p["origin_code"];
var dayInterval = p["days2"];
var startDate = p["start"];
var endDate = p["end"];
var showAuth = p["show"];
var showVersion = p["sv"];

if("custom" == dayInterval){ dayInterval = ""; }

sum.push('item_count');
sum.push('customer_price');

var sqlProcessor = new SelectSQLBuilder();

sqlProcessor.setSelect("select COALESCE(o.originCode,'No Origin Code') AS origin_code, i.item_id, i.name AS item_name, sum(li.quantity) AS item_count, sum(li.quantity * li.customerPrice) AS customer_price ");
sqlProcessor.setFrom("from ecommerce.item as i, ecommerce.productversion as pv, ecommerce.RSLineItem li,ecommerce.RSOrder o,ecommerce.PaymentAuthorization pa ");
sqlProcessor.setWhere("where o.oid = pa.order_id ");
sqlProcessor.appendWhere("pa.payment_transaction_result_id = 1 and pa.payment_status_id in (3,5,6) ");
sqlProcessor.appendWhere("o.oid = li.order_id and li.productVersion_id = pv.productversion_id and pv.item_id = i.item_id ");

if (notEmpty(originCode)) {
    sqlProcessor.appendWhere("o.originCode ILIKE '" + originCode + "%'");
} else {
    // do nothing; let all values pass through
}

if (notEmpty(dayInterval)) {
    sqlProcessor.appendWhere("pa.authDate >= now()::DATE - cast('" + dayInterval + " day' as interval) and pa.authDate::DATE < now()::DATE");
} else {
    if (notEmpty(startDate)) {
        sqlProcessor.appendWhere("pa.authDate >= '" + startDate + "'");
        if (notEmpty(endDate)) {
            sqlProcessor.appendWhere("pa.authDate::DATE < '" + endDate + "'");
        }
    } else {
        sqlProcessor.appendWhere("pa.authDate::DATE >= now()::DATE");
    }
}

if (notEmpty(showAuth)) {
    sqlProcessor.appendSelect("pa.authDate::DATE as sale_date");
    sqlProcessor.setGroupBy("group by pa.authDate::DATE, COALESCE(o.originCode,'No Origin Code'), i.item_id, i.name ");
    sqlProcessor.setOrderBy("order by pa.authDate::DATE, customer_price desc, sum(li.quantity) desc ");
} else {
	hide.push('sale_date');
    sqlProcessor.setGroupBy("group by COALESCE(o.originCode, 'No Origin Code'), i.item_id, i.name ");
    sqlProcessor.setOrderBy("order by COALESCE(o.originCode, 'No Origin Code'), sum(li.quantity) desc ");
}

if (notEmpty(showVersion)) {
	sqlProcessor.appendSelect("pv.productversion_id as version_id,pv.name AS version_name");
    sqlProcessor.appendGroupBy("pv.productversion_id,pv.name");
} else {
    hide.push('version_id');
    hide.push('version_name');
}

sql = sqlProcessor.queryString();