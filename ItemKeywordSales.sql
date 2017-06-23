//
// Item Keyword Sales Report
// Revised 2015-11-10, Catherine Warren, to add output column for item_id (RPT-170).
//

var startDate = p["start"];
var endDate = p["end"];
var keyword = p["item_keywords"];
var showexactmatches = p["showexactmatches"];
var showVersion = p["sv"];

sum.push('quantity_sold');
sum.push('customer_price');
sum.push('total_sale_amount');

var sqlProcessor = new SelectSQLBuilder();

sqlProcessor.setSelect("select i.item_id, i.name AS item_name, sum(li.quantity) as quantity_sold, sum(li.quantity * li.customerprice) as customer_price ");
sqlProcessor.appendSelect("sum(pa.amount) AS total_sale_amount, i.keywords ");
sqlProcessor.setFrom("from ecommerce.item as i, ecommerce.rslineitem as li, ecommerce.productversion as pv, ecommerce.paymentauthorization as pa ");
sqlProcessor.setWhere("where i.item_id = pv.item_id and pv.productversion_id = li.productversion_id and li.order_id = pa.order_id ");
sqlProcessor.appendWhere("pa.payment_transaction_result_id = 1 and pa.payment_status_id in (3,5,6) ");
sqlProcessor.setGroupBy("group by i.item_id, i.name, i.keywords ");

if (notEmpty(showVersion)) {
    sqlProcessor.appendSelect("pv.productversion_id as version_id, pv.name AS version_name ");
    sqlProcessor.appendGroupBy("pv.productversion_id, pv.name ");
} else {
    hide.push('version_id');
    hide.push('version_name');
}

if ((notEmpty (showexactmatches)) && (notEmpty(keyword))) {
 sqlProcessor.appendWhere("i.keywords ~ '[^a-zA-Z0-9]?" + keyword + "(?![a-zA-Z0-9])'");
}

else if (notEmpty(keyword)) {
   sqlProcessor.appendWhere("i.keywords ILIKE '%" + keyword + "%'");
}
  
if (notEmpty(startDate)) {
    sqlProcessor.appendWhere("pa.authDate >= '" + startDate + "'");
}
if (notEmpty(endDate)) {
    sqlProcessor.appendWhere("pa.authDate < '" + endDate + "'");
}

sql = sqlProcessor.queryString();