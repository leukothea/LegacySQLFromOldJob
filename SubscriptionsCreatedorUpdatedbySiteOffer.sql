//
// Subscriptions Created or Updated by Site Offer
// Catherine Warren, June 2015
//

var startDate = p["start"];
var dateType = p["date_type"];

if(dateType == "update_date"){
	sql = "select s.site_offer_id, so.description as site_offer_name, count(*) as subscription_count ";
	sql += " from pheme.subscription s, pheme.site_offer so ";
	sql += " where s.site_offer_id = so.site_offer_id ";
	sql += " and not s.date_record_added = s.date_record_modified ";
	sql += " and s.date_record_modified >= '" + startDate + "' ";
	sql += " group by s.site_offer_id, so.description ";
	sql += " order by s.site_offer_id ";
}

if(dateType == "create_date"){
	sql = " select s.site_offer_id, so.description as site_offer_name, count(*) as subscription_count ";
	sql += " from pheme.subscription s, pheme.site_offer so ";
	sql += " where s.site_offer_id = so.site_offer_id ";
	sql += " and s.date_record_added > '" + startDate + "' ";
	sql += " and s.date_record_added < ('" + startDate + "'::Date + INTERVAL '1 day') ";
	sql += " group by s.site_offer_id, so.description ";
	sql += " order by s.site_offer_id ";
}