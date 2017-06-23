//
// Unsubscribe Report
// 2015-06-02 ~ Catherine
//

var startDate = p["start"];
var endDate = p["end"];
var offerId = p["offerId"];

var sqlProcessor = new SelectSQLBuilder();

sqlProcessor.setSelect("select s.date_unsubscribed::DATE AS unsubscribed_date ");
sqlProcessor.appendSelect("to_char(s.date_unsubscribed,'Day') AS Weekday ");
sqlProcessor.appendSelect("avg(s.date_unsubscribed::DATE - s.date_record_added::DATE) AS avg_days_active ");
sqlProcessor.appendSelect("count(*) AS unsubscribed_count ");
sqlProcessor.appendSelect("count(distinct s.account_id) AS accounts_affected ");
sqlProcessor.setFrom("from pheme.subscription s,pheme.site_offer so ");
sqlProcessor.setWhere("where s.site_offer_id = so.site_offer_id ");

if (notEmpty(offerId)) {
    sqlProcessor.appendWhere("so.site_offer_id = '" + offerId + "'");
}
if (notEmpty(startDate)) {
    sqlProcessor.appendWhere("s.date_unsubscribed >= '" + startDate + "'");
}
if (notEmpty(endDate)) {
    sqlProcessor.appendWhere("s.date_unsubscribed < '" + endDate + "'");
}

sqlProcessor.setGroupBy("group by s.date_unsubscribed::DATE,to_char(s.date_unsubscribed,'Day')");

sql = sqlProcessor.queryString();