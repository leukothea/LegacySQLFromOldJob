// 
// Fraud Detection
// Catherine Warren, 2017-11-17 | PivotalTracker #152897657
// Edited Catherine Warren, 2017-11-20 to 27 | PivotalTracker #153034902
//

var startDate = p["start"];
var endDate = p["end"];
var site = p["site5"];
var store_name = p["store_name"];
var order_source = p["orderSource"];
var item_id = p["itemId"];
var version_id = p["versionId"];
var sku_id = p["sku_id"];
var show_tracking_numbers = p["show_tracking_numbers"];

count.push('order_id');


// The ship processor finds the shipdate, if any, for the order. This is only called sometimes. 
var shipProcessor = new SelectSQLBuilder();

shipProcessor.setSelect("select o.oid as order_id, COALESCE(osh.shipdate::DATE,null) as ship_date ");
shipProcessor.setFrom("from ecommerce.rsorder as o, ecommerce.ordershipment as osh ");
shipProcessor.setWhere("where osh.order_id = o.oid ");

if (notEmpty (site)) {
    if (site == 'All') { 
      // do nothing; let all results flow through
    } else {
        shipProcessor.appendWhere("o.site_id = " + site );
    }
}

// The outside subquery is only called when the user wants to see Amazon IDs. 
var outsideProcessor = new SelectSQLBuilder();

outsideProcessor.setSelect("select o.oid as order_id, na.amazon_id as amazon_order_id ");
outsideProcessor.setFrom("from ecommerce.rsorder as o, ecommerce.novica_identity as na ");
outsideProcessor.setWhere("where o.oid = na.source_id and na.sourceclass_id = 24 ");

if (notEmpty (site)) {
    if (site == 'All') { 
      // do nothing; let all results flow through
    } else {
        outsideProcessor.appendWhere("o.site_id = " + site );
    }
}

// The adjustment subquery finds all adjustments on the order, so they can be summed up later. 
var adjustmentProcessor = new SelectSQLBuilder();

adjustmentProcessor.setSelect("select o.oid as order_id, adj.amount as adj_amount ");
adjustmentProcessor.setFrom("from ecommerce.rsorder as o, ecommerce.rsadjustment as adj ");
adjustmentProcessor.setWhere("where o.oid = adj.order_id ");

if (notEmpty (site)) {
    if (site == 'All') { 
      // do nothing; let all results flow through
    } else {
        adjustmentProcessor.appendWhere("o.site_id = " + site );
    }
}

var sumString = '';

// First, create a subquery that finds all the valid paymentauthorizations throughout time, along with the minimum such auth_id and the order_id. 
payAuthProcessor = new SelectSQLBuilder();

payAuthProcessor.setSelect("SELECT MIN(payauth.authorization_id) OVER (PARTITION BY payauth.order_id) AS min_authorization_id, payauth.authorization_id ");
payAuthProcessor.appendSelect("payauth.order_id ");
payAuthProcessor.setFrom("FROM ecommerce.paymentauthorization payauth ");
payAuthProcessor.setWhere("WHERE payauth.payment_transaction_result_id = 1 AND payauth.payment_status_id IN (3,5,6)");

var payAuthString = payAuthProcessor.queryString();


// Add the payAuth results to the blank sumstring variable. 
sumString += "with pauth AS (" + payAuthString + ") ";


// Line Item Query 1: Find all regular (non-GTGM, non-recurring) line items, with their correct authorization_id and authdate. 
var regularItemProcessor = new SelectSQLBuilder();

regularItemProcessor.setSelect("SELECT oli.oid AS lineitem_id, pauth.min_authorization_id AS lineitem_authorization_id ");
regularItemProcessor.appendSelect("oli.order_id, sli.quantity AS run_count ");
regularItemProcessor.appendSelect("oli.quantity, oli.customerprice, (oli.quantity * oli.customerprice) AS lineitem_subtotal ");
regularItemProcessor.setFrom("FROM ecommerce.item item INNER JOIN ecommerce.productversion pversion USING (item_id) INNER JOIN ecommerce.rslineitem oli USING (productversion_id) INNER JOIN ecommerce.sitelineitem sli ON (oli.oid = sli.lineitem_id) INNER JOIN pauth USING (order_id) ");
regularItemProcessor.setWhere("WHERE item.itembitmask & 32 != 32 AND oli.lineitemtype_id IN (1,5) AND oli.subscription_payment_authorization_id IS NULL ");
regularItemProcessor.appendWhere("(sli.sourceclass_id IS NULL OR sli.sourceclass_id != 22) ");
regularItemProcessor.setGroupBy("GROUP BY oli.oid, pauth.min_authorization_id, oli.order_id, sli.quantity, oli.quantity, oli.customerprice ");

if (notEmpty(item_id)) {
	regularItemProcessor.appendWhere("item.item_id IN (" + item_id + ") ");
} 

if (notEmpty(version_id)) {
	regularItemProcessor.appendWhere("pversion.productversion_id IN (" + version_id + ") ");
} 

// Create a new string out of the regularItemProcessor subquery.  
var regularItemString = regularItemProcessor.queryString();


// Line Item Query 2: Using PayAuths, find all cart (checkbox) GTGMs and lay in the correct authorization_id and authdate for each. 

var cartGTGMProcessor = new SelectSQLBuilder();

cartGTGMProcessor.setSelect("SELECT oli.oid AS lineitem_id, pauth.min_authorization_id AS lineitem_authorization_id ");
cartGTGMProcessor.appendSelect("oli.order_id, sli.quantity AS run_count ");
cartGTGMProcessor.appendSelect("oli.quantity, oli.customerprice, (oli.quantity * oli.customerprice) AS lineitem_subtotal ");
cartGTGMProcessor.setFrom("FROM ecommerce.item item INNER JOIN ecommerce.productversion pversion USING (item_id) INNER JOIN ecommerce.rslineitem oli USING (productversion_id) INNER JOIN ecommerce.sitelineitem sli ON (oli.oid = sli.lineitem_id) INNER JOIN pauth USING (order_id) ");
cartGTGMProcessor.setWhere("WHERE item.itembitmask & 32 = 32 AND oli.lineitemtype_id IN (1,5) AND oli.subscription_payment_authorization_id IS NULL ");
cartGTGMProcessor.appendWhere("(sli.sourceclass_id IS NULL OR sli.sourceclass_id != 22) ");
cartGTGMProcessor.setGroupBy("GROUP BY oli.oid, pauth.min_authorization_id, oli.order_id, sli.quantity, oli.quantity, oli.customerprice ");

if (notEmpty(item_id)) {
	cartGTGMProcessor.appendWhere("item.item_id IN (" + item_id + ") ");
} 

if (notEmpty(version_id)) {
	cartGTGMProcessor.appendWhere("pversion.productversion_id IN (" + version_id + ") ");
} 

// Create a new string out of the cartGTGMProcessor subquery.  
var cartGTGMString = cartGTGMProcessor.queryString();


// Line Item Query 3: Using PayAuths, find all subscription / recurring GTGMs, and the correct authorization_id and authdate for each. 

var recurringGTGMProcessor = new SelectSQLBuilder();

recurringGTGMProcessor.setSelect("SELECT oli.oid AS lineitem_id, oli.subscription_payment_authorization_id AS lineitem_authorization_id ");
recurringGTGMProcessor.appendSelect("oli.order_id, sli.quantity AS run_count ");
recurringGTGMProcessor.appendSelect("oli.quantity, oli.customerprice, (oli.quantity * oli.customerprice) AS lineitem_subtotal ");
recurringGTGMProcessor.setFrom("FROM ecommerce.item item INNER JOIN ecommerce.productversion pversion USING (item_id) INNER JOIN ecommerce.rslineitem oli USING (productversion_id) INNER JOIN ecommerce.sitelineitem sli ON (oli.oid = sli.lineitem_id) INNER JOIN pauth USING (order_id) ");
recurringGTGMProcessor.setWhere("WHERE item.itembitmask & 32 = 32 AND oli.lineitemtype_id = 8 AND oli.subscription_payment_authorization_id IS NOT NULL ");
recurringGTGMProcessor.setGroupBy("GROUP BY oli.oid, oli.subscription_payment_authorization_id ");
recurringGTGMProcessor.appendGroupBy("oli.oid, oli.subscription_payment_authorization_id, oli.order_id, sli.quantity, oli.quantity, oli.customerprice ");

if (notEmpty(item_id)) {
	recurringGTGMProcessor.appendWhere("item.item_id IN (" + item_id + ") ");
}

if (notEmpty(version_id)) {
	recurringGTGMProcessor.appendWhere("pversion.productversion_id IN (" + version_id + ") ");
} 

// Create a new string out of the recurringGTGMProcessor subquery.  
var recurringGTGMString = recurringGTGMProcessor.queryString();


// The Pool query unites the results of the three line item subqueries.

sumString += " " + regularItemString + " UNION " + cartGTGMString + " UNION " + recurringGTGMString + " ";


// The PoolSum query takes the results of the Pool query and does a bit of math. 

var poolSumProcessor = new SelectSQLBuilder();

poolSumProcessor.setSelect("SELECT pool.lineitem_id, pool.lineitem_authorization_id, pool.order_id, o.email as email_address ");
poolSumProcessor.appendSelect("pool.run_count, pool.customerprice, pool.lineitem_subtotal ");
poolSumProcessor.setFrom("FROM ecommerce.paymentauthorization as pa RIGHT JOIN ( " + sumString + ") as pool ON pool.lineitem_authorization_id = pa.authorization_id ");
poolSumProcessor.appendFrom("ecommerce.rsorder as o ");
poolSumProcessor.setWhere("WHERE o.oid = pa.order_id ");
poolSumProcessor.setGroupBy("GROUP BY pool.lineitem_id, pool.lineitem_authorization_id, pa.authdate, pool.order_id, o.oid, o.email ");
poolSumProcessor.appendGroupBy("pool.run_count, pool.customerprice, pool.lineitem_subtotal ");


if (notEmpty(startDate)) {
   poolSumProcessor.appendWhere("pa.authdate >= '" + startDate + "' ");
} else {
   poolSumProcessor.appendWhere("pa.authdate::DATE >= date_trunc('month',now()::DATE) ");
}

if (notEmpty(endDate)) {
	poolSumProcessor.appendWhere("pa.authdate < '" + endDate + "'");
}


if (notEmpty(site)) {
    if ("ignoreAll" == site ) {
        // do nothing
    } else { 
        poolSumProcessor.appendSelect("site.name as site_name ");
        poolSumProcessor.appendFrom("ecommerce.site as site ");
        poolSumProcessor.appendWhere("o.site_id = site.site_id ");
        poolSumProcessor.appendGroupBy("site.name ");
    }
}


// This line is important to prevent division by 0 errors. 
poolSumProcessor.setPostquery("HAVING sum(pool.quantity) > 0 ");


// The main query ties it together. 
var sqlProcessor = new SelectSQLBuilder();

sqlProcessor.setSelect("SELECT pa.authdate as order_date, poolSum.order_id, o.email as email_address, pa.amount as order_total ");
sqlProcessor.appendSelect("pt.payment_transaction_result as payment_result, ps.payment_status, SUM(adj.adj_amount) as adjustment_amount, o.client_ip_address as customer_ip_address ");
sqlProcessor.appendSelect("si.name as site_name, os.order_source as order_source, outs.amazon_order_id ");
sqlProcessor.appendSelect("sku.sku_id, sku.name as sku_name ");
sqlProcessor.appendSelect("shipaddr.address1 as shipaddr1, shipaddr.address2 as shipaddr2, shipaddr.city as shipcity, shipaddr.state as shipst, shipaddr.zip as shipzip, shipaddr.country as shipcoun ");
sqlProcessor.appendSelect("billaddr.address1 as billaddr1, billaddr.address2 as billaddr2, billaddr.city as billcity, billaddr.state as billst, billaddr.zip as billzip, billaddr.country as billcoun ");
sqlProcessor.appendSelect("sopt.shippingoption as service ");
sqlProcessor.addCommonTableExpression("poolSum", poolSumProcessor);
sqlProcessor.addCommonTableExpression("adjustment", adjustmentProcessor);
sqlProcessor.setFrom("FROM ecommerce.rslineitem AS rsli RIGHT JOIN poolSum ON rsli.oid = poolSum.lineitem_id, ecommerce.paymentauthorization as pa ");
sqlProcessor.appendFrom("ecommerce.payment_transaction_result as pt, ecommerce.payment_status as ps ");
sqlProcessor.appendFrom("ecommerce.site as si, ecommerce.store as s, ecommerce.order_source as os ");
sqlProcessor.appendFrom("ecommerce.sku as sku, ecommerce.productversionsku as pvs, ecommerce.productversion as pv, ecommerce.item as item ");
sqlProcessor.appendFrom("ecommerce.rsaddress as billaddr, ecommerce.shippingoption as sopt ");
sqlProcessor.setWhere("WHERE pa.authorization_id = poolSum.lineitem_authorization_id AND o.oid = pa.order_id and o.store_id = s.store_id ");
sqlProcessor.appendWhere("o.site_id = si.site_id and o.order_source_id = os.order_source_id ");
sqlProcessor.appendWhere("pa.payment_transaction_result_id = pt.payment_transaction_result_id and pa.payment_status_id = ps.payment_status_id ");
sqlProcessor.appendWhere("pa.payment_transaction_result_id = 1 and pa.payment_status_id in (3,5,6) ");
sqlProcessor.appendWhere("o.billingaddress_id = billaddr.oid and o.shipping_option_id = sopt.shippingoption_id ");
sqlProcessor.appendWhere("rsli.order_id = o.oid and rsli.productversion_id = pv.productversion_id and pv.item_id = item.item_id and pv.productversion_id = pvs.productversion_id and pvs.sku_id = sku.sku_id ");
sqlProcessor.setGroupBy("group by pa.authdate, poolSum.order_id, o.oid, o.email, pa.amount, pt.payment_transaction_result, ps.payment_status, o.client_ip_address ");
sqlProcessor.appendGroupBy("si.name, os.order_source, outs.amazon_order_id, sku.sku_id, sku.name ");
sqlProcessor.appendGroupBy("shipaddr.address1, shipaddr.address2, shipaddr.city, shipaddr.state, shipaddr.zip, shipaddr.country ");
sqlProcessor.appendGroupBy("billaddr.address1, billaddr.address2, billaddr.city, billaddr.state, billaddr.zip, billaddr.country ");
sqlProcessor.appendGroupBy("sopt.shippingoption ");
sqlProcessor.setOrderBy("order by o.oid asc ");

if (notEmpty(startDate)) {
        sqlProcessor.appendWhere("pa.authdate >= '" + startDate + "'");
    } else {
        sqlProcessor.appendWhere("pa.authdate::DATE >= date_trunc('month',now()::DATE)");
    }
if (notEmpty(endDate)) {
        sqlProcessor.appendWhere("pa.authdate < '" + endDate + "'");
    }

if (notEmpty (site)) {
    if (site == 'All') { 
      // do nothing; let all results flow through
    } else {
        sqlProcessor.appendWhere("si.site_id = " + site );
    }
}

if (notEmpty (store_name)) {
    if ('Show All' == store_name) {
    //do nothing; let all values flow through
      } else {
        sqlProcessor.appendWhere("s.store_id = " + store_name );
	  }
}

if (notEmpty (order_source)) {
    sqlProcessor.appendWhere("os.order_source_id = " + order_source );
}

if (notEmpty (sku_id)) {
        sqlProcessor.appendWhere("sku.sku_id IN (" + sku_id + ") " );
}


if (notEmpty (version_id)) {
        sqlProcessor.appendWhere("rsli.productversion_id IN ( " + version_id + ") " );
}

if (notEmpty (item_id)) {
        sqlProcessor.appendWhere("item.item_id IN ( " + item_id + ") " );
}

if (notEmpty (show_tracking_numbers)) {
    sqlProcessor.appendSelect("ship.ship_date ");
    sqlProcessor.appendSelect("tr.trackingnumber as tracking_number ");
    sqlProcessor.appendFrom("ecommerce.rsorder as o LEFT OUTER JOIN ship ON ship.order_id = o.oid LEFT OUTER JOIN outs ON outs.order_id = o.oid LEFT OUTER JOIN ecommerce.rsaddress as shipaddr ON o.shippingaddress_id = shipaddr.oid LEFT OUTER JOIN adjustment as adj on o.oid = adj.order_id ");
    sqlProcessor.appendFrom("ecommerce.ordershipment as tr ");
    sqlProcessor.addCommonTableExpression("ship",shipProcessor);
    sqlProcessor.addCommonTableExpression("outs", outsideProcessor);
    sqlProcessor.appendWhere("tr.order_id = o.oid ");
    sqlProcessor.appendGroupBy("ship.ship_date, tr.trackingnumber ");
} else {
    sqlProcessor.appendFrom("ecommerce.rsorder as o LEFT OUTER JOIN outs ON outs.order_id = o.oid LEFT OUTER JOIN ecommerce.rsaddress as shipaddr ON o.shippingaddress_id = shipaddr.oid LEFT OUTER JOIN adjustment as adj on o.oid = adj.order_id ");
    sqlProcessor.addCommonTableExpression("outs", outsideProcessor);
    hide.push('tracking_number');
    hide.push('ship_date');
}
  
sql = sqlProcessor.queryString();