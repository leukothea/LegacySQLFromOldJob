//
// Item Revenue Summary Report
// Edited 2015-11-10, Catherine Warren, for RPT-171 and other cleanup
//

var itemId = p["itemId"];
var startDate = p["start"];
var endDate = p["end"];
var showsite = p["showSite"];

sum.push('order_count');
sum.push('item_count');
sum.push('customer_price');

var sqlProcessor = new SelectSQLBuilder();

sqlProcessor.setSelect("select CAST(pa.authdate as DATE) as auth_date, i.item_id, i.name as item_name, pv.productversion_id as version_id, pv.name AS version_name, count(distinct li.order_id) AS order_count, sum(li.quantity) AS item_count, sum(li.quantity * li.customerPrice) AS customer_price ");
sqlProcessor.setFrom("from ecommerce.productversion as pv, ecommerce.rslineitem as li, ecommerce.item as i, ecommerce.rsorder as o, ecommerce.paymentauthorization as pa, ecommerce.site as s ");
sqlProcessor.setWhere("where pv.productversion_id = li.productversion_id and pv.item_id = i.item_id and li.order_id = o.oid and o.oid = pa.order_id and o.site_id = s.site_id ");
sqlProcessor.appendWhere("pa.payment_transaction_result_id = 1 and pa.payment_status_id in (3,5,6) ");
sqlProcessor.setGroupBy("group by pa.authdate, i.item_id, i.name, o.oid, pv.productversion_id, pv.name");

if (notEmpty(itemId)) {
    sqlProcessor.appendWhere("pv.item_id IN (" + itemId + ") ");
}

if (notEmpty(startDate)) {
    sqlProcessor.appendWhere("pa.authDate::DATE >= '" + startDate + "'");
} else {
    sqlProcessor.appendWhere("pa.authDate::DATE >= date_trunc('month',now()::DATE)");
}

if (notEmpty(endDate)) {
    sqlProcessor.appendWhere("pa.authDate::DATE < '" + endDate + "'");
}

if (notEmpty(showsite)) {
    sqlProcessor.appendSelect("s.name as site_name");
    sqlProcessor.appendGroupBy("s.name");
  } else {
    hide.push('site_name');
}
       
sql = sqlProcessor.queryString();