//
// Sales Chart
// Edited Catherine Warren, 2015-11-18, to change the output column "value" to be named "data"
//

var startDate = p["start"];
var endDate = p["end"];
var site = p["site2"];
var data = p["data"];
var groupBy = p["group3"];
var showOrderSource = p["showOrderSource"];

var sqlProcessor = new SelectSQLBuilder();

if ("ignoreAll" == site) {
    switch (groupBy) {
        case "week":
       		hide.push('auth_hour');
            sqlProcessor.setSelect("select 'All Sites' AS site_name, to_char(pa.authDate,'WW') AS auth_week, max(pa.authDate::DATE) AS auth_date");
            sqlProcessor.setGroupBy("group by to_char(pa.authDate,'WW')");
            sqlProcessor.setOrderBy("order by to_char(pa.authDate,'WW')");
            break;
        case "hour":
       		hide.push('auth_week');
            sqlProcessor.setSelect("select 'All Sites' AS site_name, max(pa.authDate::DATE) AS auth_date, to_char(pa.authDate,'HH24') AS auth_hour");
            sqlProcessor.setGroupBy("group by pa.authDate::DATE, to_char(pa.authDate,'HH24')");
            sqlProcessor.setOrderBy("order by pa.authDate::DATE, to_char(pa.authDate,'HH24')");
            break;
        default:
       		hide.push('auth_week');
       		hide.push('auth_hour');
            sqlProcessor.setSelect("select 'All Sites' AS site_name, pa.authDate::DATE AS auth_date");
            sqlProcessor.setGroupBy("group by pa.authDate::DATE");
            sqlProcessor.setOrderBy("order by pa.authDate::DATE");
    }
} else {
    switch (groupBy) {
       case "week":
            sqlProcessor.setSelect("select ma.merchantAccount AS site_name, to_char(pa.authDate,'WW') AS auth_week, max(pa.authDate::DATE) AS auth_date");
            sqlProcessor.setGroupBy("group by ma.merchantAccount, to_char(pa.authDate,'WW')");
            sqlProcessor.setOrderBy("order by ma.merchantAccount, to_char(pa.authDate,'WW')");
       		hide.push('auth_hour');
            break;
       case "hour":
            sqlProcessor.setSelect("select ma.merchantAccount AS site_name, pa.authDate::DATE AS auth_date, to_char(pa.authDate,'HH24') AS auth_hour");
            sqlProcessor.setGroupBy("group by ma.merchantAccount, pa.authDate::DATE, to_char(pa.authDate,'HH24')");
            sqlProcessor.setOrderBy("order by ma.merchantAccount, pa.authDate::DATE, to_char(pa.authDate,'HH24')");
            hide.push('auth_week');
            break;
       default:
       		hide.push('auth_week');
       		hide.push('auth_hour');
            sqlProcessor.setSelect("select ma.merchantAccount AS site_name, pa.authDate::DATE AS auth_date");
            sqlProcessor.setGroupBy("group by ma.merchantAccount, pa.authDate::DATE");
            sqlProcessor.setOrderBy("order by ma.merchantAccount, pa.authDate::DATE");
       }
}
switch (data) {
    case "Items":
        sqlProcessor.appendSelect("sum(li.quantity) AS data");
        sqlProcessor.setFrom("from ecommerce.RSOrder o, ecommerce.RSLineItem li, ecommerce.PaymentAuthorization pa, ecommerce.MerchantAccount ma");
        sqlProcessor.setWhere("where o.oid = pa.order_id and o.oid = li.order_id");
        sqlProcessor.appendWhere("pa.payment_transaction_result_id = 1 and pa.payment_status_id in (3,5,6)");
        sqlProcessor.appendWhere("COALESCE(li.lineItemType_id,1) = 1 and pa.merchantAccount_id = ma.merchantAccount_id");
        break;
    case "Orders":
        sqlProcessor.appendSelect("count(o.oid) AS data");
        sqlProcessor.setFrom("from ecommerce.RSOrder o, ecommerce.PaymentAuthorization pa, ecommerce.MerchantAccount ma");
        sqlProcessor.setWhere("where o.oid = pa.order_id");
        sqlProcessor.appendWhere("pa.payment_transaction_result_id = 1 and pa.payment_status_id in (3,5,6)");
        sqlProcessor.appendWhere("pa.merchantAccount_id = ma.merchantAccount_id");
        break;
    case "Gross Revenue":
        sqlProcessor.appendSelect("sum(pa.amount) AS data");
        sqlProcessor.setFrom("from ecommerce.RSOrder o, ecommerce.PaymentAuthorization pa, ecommerce.MerchantAccount ma");
        sqlProcessor.setWhere("where o.oid = pa.order_id");
        sqlProcessor.appendWhere("pa.payment_transaction_result_id = 1 and pa.payment_status_id in (3,5,6)");
        sqlProcessor.appendWhere("pa.merchantAccount_id = ma.merchantAccount_id");
        break;
}
sqlProcessor.appendWhere("pa.authDate >= '" + startDate + "'");
if (notEmpty(endDate)) {
    sqlProcessor.appendWhere("pa.authDate < '" + endDate + "'");
}
if ("showAll" != site && "ignoreAll" != site) {
    sqlProcessor.appendWhere("ma.site_id = " + site);
}
if (notEmpty(showOrderSource)) {
    sqlProcessor.appendSelect("s.name as store_name");
    sqlProcessor.appendSelect("os.order_source as order_source");
    sqlProcessor.appendFrom("ecommerce.store s");
    sqlProcessor.appendFrom("ecommerce.order_source os");
    sqlProcessor.appendWhere("o.store_id = s.store_id");
    sqlProcessor.appendWhere("o.order_source_id = os.order_source_id");
    sqlProcessor.appendGroupBy("s.name,os.order_source");
} else {
	hide.push('store_name');
	hide.push('order_source');
}

sql = sqlProcessor.queryString();