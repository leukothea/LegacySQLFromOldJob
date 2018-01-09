//
// Recurring Friends Sales
// Catherine Warren, 2018-01-08 | PivotalTracker #154155277
// NOTE: This is the multi-column version, but the users want multiple rows. 
//

var startDate = p["start"];
var endDate = p["end"];
var subscription_status = p["subscription_status"];

count.push("subscription_id");
sum.push("count_initial_subscription");
sum.push("count_recurring_subscription");
sum.push("revenue_initial_subscription");
sum.push("revenue_recurring_subscription");


// This subquery finds the maximum ID of any address set in the pheme address table on the account. Such information is rarely set, but when it is, we only want the most recent. 
var phemeAddProcessor = new SelectSQLBuilder();

phemeAddProcessor.setSelect("SELECT max(phad.address_id) as address_id, phad.account_id ");
phemeAddProcessor.setFrom("FROM pheme.address as phad ");
phemeAddProcessor.setWhere("WHERE true ");
phemeAddProcessor.setGroupBy("group by phad.account_id ");


// This subquery finds any customer contact information set on the pheme account table. Such information is rarely set. 
// Also bring in the results of phemeAdd, if any, to present a single row summarizing any customer address info from the pheme schema. 
var phemeSumProcessor = new SelectSQLBuilder();

phemeSumProcessor.setSelect("select phac.account_id, phac.email, COALESCE(phac.first_name, addr.first_name) as first_name, COALESCE(phac.last_name, addr.last_name) as last_name ");
phemeSumProcessor.appendSelect("COALESCE(addr.address_1, NULL) as address_1, COALESCE(addr.address_2, NULL) as address_2 ");
phemeSumProcessor.appendSelect("COALESCE(addr.city, NULL) as city, COALESCE(addr.region_code, NULL) as state, COALESCE(addr.postal_code, NULL) as zip, COALESCE(addr.country_code, NULL) as country_code ");
phemeSumProcessor.setFrom("from pheme.account as phac, pheme.address as addr, phemeAdd as phad ");
phemeSumProcessor.addCommonTableExpression("phemeAdd", phemeAddProcessor);
phemeSumProcessor.setWhere("where phac.account_id = addr.account_id AND addr.address_id = phad.address_id ");
phemeSumProcessor.setGroupBy("group by phac.account_id, phac.email, phac.first_name, addr.first_name, phac.last_name, addr.last_name, addr.address_1, addr.address_2, addr.city, addr.region_code, addr.postal_code, addr.country_code ");


// The friendsords subquery finds all orders that have a friends item in them. No need to search all orders throughout time. 

var friendsOrdsProcessor = new SelectSQLBuilder();

friendsOrdsProcessor.setSelect("select o.oid as order_id ");
friendsOrdsProcessor.setFrom("from ecommerce.rsorder as o, ecommerce.rslineitem as rsli ");
friendsOrdsProcessor.appendFrom("ecommerce.productversion as pv, ecommerce.item as i ");
friendsOrdsProcessor.setWhere("where o.oid = rsli.order_id and rsli.productversion_id = pv.productversion_id and pv.item_id = i.item_id ");
friendsOrdsProcessor.appendWhere("i.itembitmask & 16384 = 16384 ");


// The minimum auth subquery finds the minimum paymentauthorization_id for payment authorizations placed after Nov. 1, 2017.

var minAuthProcessor = new SelectSQLBuilder();

minAuthProcessor.setSelect("select first_value(authorization_id) OVER (PARTITION BY order_id) as authorization_id, 1 as min_lineitem ");
minAuthProcessor.setFrom("from ecommerce.paymentauthorization ");
minAuthProcessor.setWhere("where payment_transaction_result_id = 1 and payment_status_id IN (3, 5, 6) and authdate >= '2017-11-01' ");


// The main query pulls in the results (if any) from phemeSum. If there are none, it finds the first and last name set on the order. 
// It also finds the orders to look at using minAuth and friendsOrds. 
var sqlProcessor = new SelectSQLBuilder();

sqlProcessor.setSelect("select distinct (CASE WHEN ph.first_name IS NOT NULL OR ph.last_name IS NOT NULL THEN ph.first_name ELSE rsaddr.firstname END) as first_name ");
sqlProcessor.appendSelect("(CASE WHEN ph.first_name IS NOT NULL OR ph.last_name IS NOT NULL THEN ph.last_name ELSE rsaddr.lastname END) as last_name ");
sqlProcessor.appendSelect("(CASE WHEN ph.email IS NOT NULL THEN ph.email ELSE o.email END) as email_address ");
sqlProcessor.appendSelect("pa.authdate::DATE as order_date ");
sqlProcessor.appendSelect("friendsords.order_id, li.subscription_id, ss.subscription_status ");
sqlProcessor.appendSelect("pv.productversion_id as version_id, pv.name as version_name");
sqlProcessor.appendSelect("(CASE WHEN minAuth.min_lineitem = 1 THEN li.quantity ELSE 0 END) as count_initial_subscription ");
sqlProcessor.appendSelect("(CASE WHEN minAuth.min_lineitem IS NULL THEN li.quantity ELSE 0 END) as count_recurring_subscription ");
sqlProcessor.appendSelect("(CASE WHEN minAuth.min_lineitem = 1 THEN li.quantity * li.customerprice ELSE 0 END) as revenue_initial_subscription ");
sqlProcessor.appendSelect("(CASE WHEN minAuth.min_lineitem IS NULL THEN li.quantity * li.customerprice ELSE 0 END) as revenue_recurring_subscription ");
sqlProcessor.addCommonTableExpression("phemeSum", phemeSumProcessor);
sqlProcessor.addCommonTableExpression("friendsOrds", friendsOrdsProcessor);
sqlProcessor.addCommonTableExpression("minAuth", minAuthProcessor);
sqlProcessor.setFrom("from ecommerce.paymentauthorization as pa RIGHT JOIN friendsOrds USING (order_id) RIGHT JOIN minAuth USING (authorization_id) INNER JOIN ecommerce.rslineitem as li USING (order_id) INNER JOIN ecommerce.productversion as pv USING (productversion_id) INNER JOIN ecommerce.item as i USING (item_id)");
sqlProcessor.appendFrom("ecommerce.subscription AS s, ecommerce.subscription_status as ss, ecommerce.subscription_payment_authorization AS spa ");
sqlProcessor.appendFrom("ecommerce.rsorder AS o LEFT OUTER JOIN phemeSum as ph ON o.account_id = ph.account_id, ecommerce.rsaddress AS rsaddr ");
sqlProcessor.setWhere("where o.oid = friendsords.order_id and li.subscription_id = s.subscription_id ");
sqlProcessor.appendWhere("s.subscription_id = spa.subscription_id and spa.authorization_id = minAuth.authorization_id");
sqlProcessor.appendWhere("o.billingaddress_id = rsaddr.oid and s.subscription_status_id = ss.subscription_status_id ");
sqlProcessor.setOrderBy("order by li.order_id, pa.authdate ");

if (notEmpty(startDate)) {
	sqlProcessor.appendWhere("pa.authdate >= '" + startDate + "' ");
} 

if (notEmpty(endDate)) {
	sqlProcessor.appendWhere("pa.authdate < '" + endDate + "' ");
}

if (notEmpty(subscription_status)) { 
    sqlProcessor.appendWhere("s.subscription_status_id = " + subscription_status );
} 

sql = sqlProcessor.queryString();