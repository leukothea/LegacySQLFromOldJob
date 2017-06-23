//
// Circulation Report
// Edited Catherine Warren, 2015-12-17 | JIRA RPT-126
//

var days=p["days2"];
var startDate=p["start"];
var endDate=p["end"];
var showDate=p["showDate"];

sum.push('subscribed_count');

var dateClause = "";
if (notEmpty(days)) {
    dateClause = dateClause + "a.date_confirmed >= now()::DATE - cast('" + days + " day' as interval)";
    if (days == 0) {
         dateClause = dateClause + " and a.date_confirmed > now()::DATE";
    } else {
         dateClause = dateClause + " and a.date_confirmed < now()::DATE";
    }
} else {
    // empty interval, so we are using only dates...
    if (notEmpty(startDate)) {
        dateClause = dateClause + "a.date_confirmed >= '" + startDate + "'";
        if (notEmpty(endDate)) {
            dateClause = dateClause + " and a.date_confirmed < '" + endDate + "'";
        }
    } else {
        dateClause = dateClause + "a.date_confirmed >= date_trunc('month',now()::DATE)";
    }
}

var dateProcessor = new SelectSQLBuilder();

dateProcessor.setSelect("select so.description AS offer_name ");
dateProcessor.appendSelect("count(*) AS subscribed_count, a.date_confirmed::DATE as date_confirmed ");
dateProcessor.setFrom("from pheme.account as a, pheme.subscription as s, pheme.site_offer as so ");
dateProcessor.setWhere("where a.account_id = s.account_id ");
dateProcessor.appendWhere("s.date_unsubscribed is null ");
dateProcessor.appendWhere("s.site_offer_id = so.site_offer_id ");
dateProcessor.appendWhere("( a.date_confirmed is not NULL or a.legacy_account = 1 ) and coalesce(a.bounce_count,0) < 6 ");
dateProcessor.appendWhere("( ( a.date_subscription_hold_start is NULL and a.date_subscription_hold_end is NULL ) OR ( a.date_subscription_hold_start > now() ) OR ( a.date_subscription_hold_end < now() ) ) ");
dateProcessor.appendWhere(dateClause);
dateProcessor.setGroupBy("group by so.description, a.date_confirmed::DATE ");
dateProcessor.setOrderBy("order by so.description asc ");

var sqlProcessor = new SelectSQLBuilder();

sqlProcessor.setSelect("select so.description AS offer_name,count(*) AS subscribed_count ");
sqlProcessor.setFrom("from pheme.account a,pheme.subscription s,pheme.site_offer so ");
sqlProcessor.setWhere("where a.account_id = s.account_id ");
sqlProcessor.appendWhere("s.date_unsubscribed is null ");
sqlProcessor.appendWhere("s.site_offer_id = so.site_offer_id ");
sqlProcessor.appendWhere("( a.date_confirmed is not NULL or a.legacy_account = 1 ) and coalesce(a.bounce_count,0) < 6 ");
sqlProcessor.appendWhere("( ( a.date_subscription_hold_start is NULL and a.date_subscription_hold_end is NULL ) OR ( a.date_subscription_hold_start > now() ) OR ( a.date_subscription_hold_end < now() ) ) ");
sqlProcessor.appendWhere(dateClause);
sqlProcessor.setGroupBy("group by so.description ");
sqlProcessor.setOrderBy("order by so.description asc ");

if (notEmpty(showDate)) {
    sql = dateProcessor.queryString();
} else {
    sql = sqlProcessor.queryString();
    hide.push("date_confirmed");
}