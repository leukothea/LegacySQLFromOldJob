//
// Unsubscribe Report
// 2015-06-04 ~ Catherine
//

var startDate = p["start"];
var endDate = p["end"];
var offerId = p["offerId"];

var sqlProcessor = new SelectSQLBuilder();

sqlProcessor.setSelect("select so.description as site_offer_name, s.date_unsubscribed as unsubscribed_date, a.email as account_email ");
sqlProcessor.setFrom("from pheme.subscription s,pheme.site_offer so, pheme.account a ");
sqlProcessor.setWhere("where s.site_offer_id = so.site_offer_id");
sqlProcessor.appendWhere("s.account_id = a.account_id");

if (notEmpty(offerId)) {
    sqlProcessor.appendWhere("so.site_offer_id = '" + offerId + "'");
}
if (notEmpty(startDate)) {
    sqlProcessor.appendWhere("s.date_unsubscribed >= '" + startDate + "'");
}
if (notEmpty(endDate)) {
    sqlProcessor.appendWhere("s.date_unsubscribed < '" + endDate + "'");
}

sqlProcessor.setGroupBy("group by so.description, s.date_unsubscribed, a.email");

sql = sqlProcessor.queryString();

