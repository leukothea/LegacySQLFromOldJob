//
// Circulation Report
// Edited Catherine Warren, 2015-12-17 | JIRA RPT-126
//

var days=p["days2"];
var showDate=p["showDate"];

var sqlProcessor = new SelectSQLBuilder();

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

sqlProcessor.setSelect("select so.description AS offer_name ");
sqlProcessor.appendSelect("count(*) AS subscribed_count, a.date_confirmed::DATE as date_confirmed ");
sqlProcessor.setFrom("from pheme.account as a, pheme.subscription as s, pheme.site_offer as so ");
sqlProcessor.setWhere("where a.account_id = s.account_id ");
sqlProcessor.appendWhere("s.date_unsubscribed is null ");
sqlProcessor.appendWhere("s.site_offer_id = so.site_offer_id ");
sqlProcessor.appendWhere("( a.date_confirmed is not NULL or a.legacy_account = 1 ) and coalesce(a.bounce_count,0) < 6 ");
sqlProcessor.appendWhere("( ( a.date_subscription_hold_start is NULL and a.date_subscription_hold_end is NULL ) OR ( a.date_subscription_hold_start > now() ) OR ( a.date_subscription_hold_end < now() ) ) ");
sqlProcessor.setGroupBy("group by so.description, a.date_confirmed::DATE ");
sqlProcessor.appendWhere(dateClause);

if (notEmpty(showDate)) {
    // do nothing; let all output columns show
} else {
    hide.push("date_confirmed");
}

sql = sqlProcessor.queryString();

