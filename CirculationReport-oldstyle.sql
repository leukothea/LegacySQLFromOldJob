//
// Circulation Report
//


var sqlProcessor = new SelectSQLBuilder();

sum.push('subscribed_count');

sqlProcessor.setSelect("select so.description AS offer_name");
sqlProcessor.appendSelect("count(*) AS subscribed_count");
sqlProcessor.setFrom("from pheme.account a,pheme.subscription s,pheme.site_offer so");
sqlProcessor.setWhere("where a.account_id = s.account_id");
sqlProcessor.appendWhere("s.date_unsubscribed is null");
sqlProcessor.appendWhere("s.site_offer_id = so.site_offer_id");
sqlProcessor.appendWhere("( a.date_confirmed is not NULL or a.legacy_account = 1 ) and coalesce(a.bounce_count,0) < 6");
sqlProcessor.appendWhere("( ( a.date_subscription_hold_start is NULL and a.date_subscription_hold_end is NULL ) OR ( a.date_subscription_hold_start > now() ) OR ( a.date_subscription_hold_end < now() ) )");
sqlProcessor.setGroupBy("group by so.description");
        
sql = sqlProcessor.queryString();