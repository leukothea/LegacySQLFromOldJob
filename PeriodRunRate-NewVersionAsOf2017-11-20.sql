//
// Period Run Rate
// Edited Catherine Warren, 2017-09-11 | PivotalTracker #150989885
// Edited Catherine Warren, 2017-10-09 & 11 | PivotalTracker #151825707
// Edited Catherine Warren, 2017-10-30 to 11-16 | PivotalTracker #152246799
// Made into report of record, 2017-11-20
//

var itemId = p["itemId"];
var itemName = p["itemName"];
var versionName = p["versionName"];
var dayInterval = p["days"];
var startDate = p["start"];
var endDate = p["end"];
var showVersion = p["sv"];
var siteId = p["site"];
var vendorId = p["vendor"];
var buyerName = p["buyer"];
var isSpreadsheet = "SPREADSHEET" == p["outputType"];
var showOrderSource = p["showOrderSource"];
var period = p["period2"];

if (!siteId || "" == siteId){ siteId = "ignoreAll"; }

sum.push('run_count');
sum.push('customer_price');
weightedAverage['avg_unit_price']='run_count';

// We build a long string to find all the correct line items and their authorizations. 

var sumString = '';

// First, create a subquery that finds all the paymentauthorizations. 
payAuthProcessor = new SelectSQLBuilder();

payAuthProcessor.setSelect("SELECT MIN(payauth.authorization_id) OVER (PARTITION BY payauth.order_id) AS min_authorization_id, payauth.authorization_id ");
payAuthProcessor.appendSelect("payauth.order_id, payauth.authdate as order_date ");
payAuthProcessor.setFrom("FROM ecommerce.paymentauthorization payauth ");
payAuthProcessor.setWhere("WHERE payauth.payment_transaction_result_id = 1 AND payauth.payment_status_id IN (3,5,6)");

var payAuthString = payAuthProcessor.queryString();

sumString += "with pauth AS (" + payAuthString + ") ";


// The buyer subquery is in case the user wants to limit results by SKU buyer. Often, this subquery is not called. 
var buyerProcessor = new SelectSQLBuilder();

buyerProcessor.setSelect("SELECT distinct pvsku.productversion_id, sc.buyer ");
buyerProcessor.setFrom("FROM ecommerce.productversionsku pvsku,ecommerce.skucategory AS sc ");
buyerProcessor.setWhere("WHERE pvsku.sku_id = sc.sku_id");


// Line Item Query 1: Using PayAuths, find all regular non-GTGM cart line items and lay in the correct authorization_id and authdate for each. 

var regularItemProcessor = new SelectSQLBuilder();

regularItemProcessor.setSelect("SELECT oli.oid AS lineitem_id, min(pauth.authorization_id) AS lineitem_authorization_id, min(pauth.order_date) AS order_date ");
regularItemProcessor.appendSelect("oli.order_id, pversion.productversion_id as version_id, pversion.name AS version_name ");
regularItemProcessor.appendSelect("item.item_id, item.name as item_name, sli.quantity AS run_count ");
regularItemProcessor.appendSelect("oli.quantity, oli.customerprice, (oli.quantity * oli.customerprice) AS lineitem_subtotal ");
regularItemProcessor.setFrom("FROM ecommerce.item item INNER JOIN ecommerce.productversion pversion USING (item_id) INNER JOIN ecommerce.rslineitem oli USING (productversion_id) INNER JOIN ecommerce.sitelineitem sli ON (oli.oid = sli.lineitem_id) INNER JOIN pauth USING (order_id) ");
regularItemProcessor.setWhere("WHERE item.itembitmask & 32 != 32 AND oli.lineitemtype_id IN (1,5) AND oli.subscription_payment_authorization_id IS NULL ");
regularItemProcessor.appendWhere("(sli.sourceclass_id IS NULL OR sli.sourceclass_id != 22) ");
regularItemProcessor.setGroupBy("GROUP BY oli.oid, oli.order_id, pversion.productversion_id, pversion.name, item.item_id, item.name ");
regularItemProcessor.appendGroupBy("sli.quantity, oli.quantity, oli.customerprice ");

if (notEmpty(itemId)) {
	regularItemProcessor.appendWhere("item.item_id IN (" + itemId + ") ");
} else {
	if (notEmpty(vendorId)) {
    	regularItemProcessor.appendWhere("item.vendor_id = " + vendorId);
    }
    if (notEmpty(itemName)) {
		regularItemProcessor.appendWhere("item.name ILIKE '" + itemName.replace("'", "''") + "%' ");
    }
}

if(notEmpty(startDate)) { 
    regularItemProcessor.appendWhere("pauth.order_date >= '" + startDate + "' ");
} 

if(notEmpty(endDate)) { 
    regularItemProcessor.appendWhere("pauth.order_date < '" + endDate + "' ");
} 

if (notEmpty(showOrderSource)) {
	regularItemProcessor.appendSelect("st.name as store_name, os.order_source ");
    regularItemProcessor.appendFrom("ecommerce.rsorder as o, ecommerce.store as st, ecommerce.order_source as os ");
    regularItemProcessor.appendWhere("oli.order_id = o.oid and o.store_id = st.store_id and o.order_source_id = os.order_source_id ");
    regularItemProcessor.appendGroupBy("st.name, os.order_source ");
} 

if (notEmpty(siteId)) {
    if ("ignoreAll" == siteId ) {
        // do nothing
    } else { 
        regularItemProcessor.appendSelect("site.name as site_name ");
        regularItemProcessor.appendFrom("ecommerce.rsorder as ord, ecommerce.site as site ");
        regularItemProcessor.appendWhere("oli.order_id = ord.oid and ord.site_id = site.site_id ");
        regularItemProcessor.appendWhere("ord.site_id = " + siteId);
        regularItemProcessor.appendGroupBy("site.name ");
    }
}

if (notEmpty(period)) {
	if("day" == period) {
            regularItemProcessor.appendSelect("to_char(pauth.order_date,'yyyy-MM-DD') AS auth_period ");
            regularItemProcessor.appendGroupBy("to_char(pauth.order_date,'yyyy-MM-DD') ");
	} if("Month" == period) {
            regularItemProcessor.appendSelect("to_char(pauth.order_date,'yyyy-MM') AS auth_period ");
            regularItemProcessor.appendGroupBy("to_char(pauth.order_date,'yyyy-MM') ");
	} 
} else {
    regularItemProcessor.appendSelect(" '' AS auth_period ");
    regularItemProcessor.appendGroupBy("auth_period ");
}

if (notEmpty(buyerName)) {
	regularItemProcessor.appendRelationToFromWithAlias(buyerProcessor, "bp");	
	regularItemProcessor.appendWhere("bp.productversion_id = pversion.productversion_id AND bp.buyer ILIKE '" + buyerName.replace("'", "''") + "%' ");
}

var regularItemString = regularItemProcessor.queryString();


// Line Item Query 2: Using PayAuths, find all normal GTGMs and lay in the correct authorization_id and authdate for each. 

var cartGTGMProcessor = new SelectSQLBuilder();

cartGTGMProcessor.setSelect("SELECT oli.oid AS lineitem_id, min(pauth.authorization_id) AS lineitem_authorization_id, min(pauth.order_date) AS order_date ");
cartGTGMProcessor.appendSelect("oli.order_id, pversion.productversion_id as version_id, pversion.name AS version_name ");
cartGTGMProcessor.appendSelect("item.item_id, item.name as item_name, sli.quantity AS run_count ");
cartGTGMProcessor.appendSelect("oli.quantity, oli.customerprice, (oli.quantity * oli.customerprice) AS lineitem_subtotal ");
cartGTGMProcessor.setFrom("FROM ecommerce.item item INNER JOIN ecommerce.productversion pversion USING (item_id) INNER JOIN ecommerce.rslineitem oli USING (productversion_id) INNER JOIN ecommerce.sitelineitem sli ON (oli.oid = sli.lineitem_id) INNER JOIN pauth USING (order_id) ");
cartGTGMProcessor.setWhere("WHERE item.itembitmask & 32 = 32 AND oli.lineitemtype_id IN (1,5) AND oli.subscription_payment_authorization_id IS NULL ");
cartGTGMProcessor.appendWhere("(sli.sourceclass_id IS NULL OR sli.sourceclass_id != 22) ");
cartGTGMProcessor.setGroupBy("GROUP BY oli.oid, oli.order_id, pversion.productversion_id, pversion.name, item.item_id, item.name ");
cartGTGMProcessor.appendGroupBy("sli.quantity, oli.quantity, oli.customerprice ");

if (notEmpty(itemId)) {
	cartGTGMProcessor.appendWhere("item.item_id IN (" + itemId + ") ");
} else {
	if (notEmpty(vendorId)) {
    	cartGTGMProcessor.appendWhere("item.vendor_id = " + vendorId);
    }
    if (notEmpty(itemName)) {
		cartGTGMProcessor.appendWhere("item.name ILIKE '" + itemName.replace("'", "''") + "%' ");
    }
}

if(notEmpty(startDate)) { 
    cartGTGMProcessor.appendWhere("pauth.order_date >= '" + startDate + "' ");
} 

if(notEmpty(endDate)) { 
    cartGTGMProcessor.appendWhere("pauth.order_date < '" + endDate + "' ");
} 

if (notEmpty(showOrderSource)) {
	cartGTGMProcessor.appendSelect("st.name as store_name, os.order_source ");
    cartGTGMProcessor.appendFrom("ecommerce.rsorder as o, ecommerce.store as st, ecommerce.order_source as os ");
    cartGTGMProcessor.appendWhere("oli.order_id = o.oid and o.store_id = st.store_id and o.order_source_id = os.order_source_id ");
    cartGTGMProcessor.appendGroupBy("st.name, os.order_source ");
} 

if (notEmpty(siteId)) {
    if ("ignoreAll" == siteId ) {
        // do nothing
    } else { 
        cartGTGMProcessor.appendSelect("site.name as site_name ");
        cartGTGMProcessor.appendFrom("ecommerce.rsorder as ord, ecommerce.site as site ");
        cartGTGMProcessor.appendWhere("oli.order_id = ord.oid and ord.site_id = site.site_id ");
        cartGTGMProcessor.appendWhere("ord.site_id = " + siteId);
        cartGTGMProcessor.appendGroupBy("site.name ");
    }
}

if (notEmpty(period)) {
	if("day" == period) {
            cartGTGMProcessor.appendSelect("to_char(pauth.order_date,'yyyy-MM-DD') AS auth_period ");
            cartGTGMProcessor.appendGroupBy("to_char(pauth.order_date,'yyyy-MM-DD') ");
	} if("Month" == period) {
            cartGTGMProcessor.appendSelect("to_char(pauth.order_date,'yyyy-MM') AS auth_period ");
            cartGTGMProcessor.appendGroupBy("to_char(pauth.order_date,'yyyy-MM') ");
	} 
} else {
    cartGTGMProcessor.appendSelect(" '' AS auth_period ");
    cartGTGMProcessor.appendGroupBy("auth_period ");
}

if (notEmpty(buyerName)) {
	cartGTGMProcessor.appendRelationToFromWithAlias(buyerProcessor, "bp");	
	cartGTGMProcessor.appendWhere("bp.productversion_id = pversion.productversion_id AND bp.buyer ILIKE '" + buyerName.replace("'", "''") + "%' ");
}

var cartGTGMString = cartGTGMProcessor.queryString();


// Line Item Query 3: Using PayAuths, find all subscription / recurring GTGMs, and the correct authorization_id and authdate for each. 

var recurringGTGMProcessor = new SelectSQLBuilder();

recurringGTGMProcessor.setSelect("SELECT oli.oid AS lineitem_id, oli.subscription_payment_authorization_id AS lineitem_authorization_id, pauth.order_date ");
recurringGTGMProcessor.appendSelect("oli.order_id, pversion.productversion_id as version_id, pversion.name AS version_name ");
recurringGTGMProcessor.appendSelect("item.item_id, item.name as item_name, sli.quantity AS run_count ");
recurringGTGMProcessor.appendSelect("oli.quantity, oli.customerprice, (oli.quantity * oli.customerprice) AS lineitem_subtotal ");
recurringGTGMProcessor.setFrom("FROM ecommerce.item item INNER JOIN ecommerce.productversion pversion USING (item_id) INNER JOIN ecommerce.rslineitem oli USING (productversion_id) INNER JOIN ecommerce.sitelineitem sli ON (oli.oid = sli.lineitem_id) INNER JOIN pauth USING (order_id) ");
recurringGTGMProcessor.setWhere("WHERE item.itembitmask & 32 = 32 AND oli.lineitemtype_id = 8 AND oli.subscription_payment_authorization_id IS NOT NULL ");
recurringGTGMProcessor.setGroupBy("GROUP BY oli.oid, oli.subscription_payment_authorization_id, pauth.order_date ");
recurringGTGMProcessor.appendGroupBy("oli.order_id, pversion.productversion_id, pversion.name, item.item_id, item.name ");
recurringGTGMProcessor.appendGroupBy("sli.quantity, oli.quantity, oli.customerprice ");

if (notEmpty(itemId)) {
	recurringGTGMProcessor.appendWhere("item.item_id IN (" + itemId + ") ");
} else {
	if (notEmpty(vendorId)) {
    	recurringGTGMProcessor.appendWhere("item.vendor_id = " + vendorId);
    }
    if (notEmpty(itemName)) {
		recurringGTGMProcessor.appendWhere("item.name ILIKE '" + itemName.replace("'", "''") + "%' ");
    }
}

if(notEmpty(startDate)) { 
    recurringGTGMProcessor.appendWhere("pauth.order_date >= '" + startDate + "' ");
} 

if(notEmpty(endDate)) { 
    recurringGTGMProcessor.appendWhere("pauth.order_date < '" + endDate + "' ");
} 

if (notEmpty(showOrderSource)) {
	recurringGTGMProcessor.appendSelect("st.name as store_name, os.order_source ");
    recurringGTGMProcessor.appendFrom("ecommerce.rsorder as o, ecommerce.store as st, ecommerce.order_source as os ");
    recurringGTGMProcessor.appendWhere("oli.order_id = o.oid and o.store_id = st.store_id and o.order_source_id = os.order_source_id ");
    recurringGTGMProcessor.appendGroupBy("st.name, os.order_source ");
} 

if (notEmpty(siteId)) {
    if ("ignoreAll" == siteId ) {
        // do nothing
    } else { 
        recurringGTGMProcessor.appendSelect("site.name as site_name ");
        recurringGTGMProcessor.appendFrom("ecommerce.rsorder as ord, ecommerce.site as site ");
        recurringGTGMProcessor.appendWhere("oli.order_id = ord.oid and ord.site_id = site.site_id ");
        recurringGTGMProcessor.appendWhere("ord.site_id = " + siteId);
        recurringGTGMProcessor.appendGroupBy("site.name ");
    }
}

if (notEmpty(period)) {
	if("day" == period) {
            recurringGTGMProcessor.appendSelect("to_char(pauth.order_date,'yyyy-MM-DD') AS auth_period ");
            recurringGTGMProcessor.appendGroupBy("to_char(pauth.order_date,'yyyy-MM-DD') ");
	} if("Month" == period) {
            recurringGTGMProcessor.appendSelect("to_char(pauth.order_date,'yyyy-MM') AS auth_period ");
            recurringGTGMProcessor.appendGroupBy("to_char(pauth.order_date,'yyyy-MM') ");
	} 
} else {
    recurringGTGMProcessor.appendSelect(" '' AS auth_period ");
    recurringGTGMProcessor.appendGroupBy("auth_period ");
}

if (notEmpty(buyerName)) {
	recurringGTGMProcessor.appendRelationToFromWithAlias(buyerProcessor, "bp");	
	recurringGTGMProcessor.appendWhere("bp.productversion_id = pversion.productversion_id AND bp.buyer ILIKE '" + buyerName.replace("'", "''") + "%' ");
}

var recurringGTGMString = recurringGTGMProcessor.queryString();


// The Pool query unites the results of the three line item subqueries.

sumString += " " + regularItemString + " UNION " + cartGTGMString + " UNION " + recurringGTGMString + " ";

// The PoolSum query takes the results of the Pool query and does a bit of math. 

var poolSumProcessor = new SelectSQLBuilder();

poolSumProcessor.setSelect("SELECT pool.version_id, pool.version_name ");
poolSumProcessor.appendSelect("pool.item_id, pool.item_name, pool.run_count ");
poolSumProcessor.appendSelect("pool.customerprice ,(sum(pool.customerprice * pool.quantity) / sum(pool.quantity))::numeric(10,2) AS avg_unit_price ");
poolSumProcessor.setFrom("FROM ( " + sumString + ") as pool ");
poolSumProcessor.setGroupBy("GROUP BY pool.lineitem_id, pool.lineitem_authorization_id, pool.order_date ");
poolSumProcessor.appendGroupBy("pool.version_id, pool.version_name, pool.item_id, pool.item_name, pool.run_count, pool.customerprice ");

if (notEmpty(showOrderSource)) {
	poolSumProcessor.appendSelect("pool.store_name ");
    poolSumProcessor.appendSelect("pool.order_source ");
    poolSumProcessor.appendGroupBy("pool.store_name, pool.order_source ");
} 

if (isEmpty(dayInterval)) {
   	if (notEmpty(startDate)) {
       	poolSumProcessor.appendWhere("pool.order_Date >= '" + startDate + "' ");
    } else {
       	poolSumProcessor.appendWhere("pool.order_date::DATE >= date_trunc('month',now()::DATE) ");
    }
    if (notEmpty(endDate)) {
		poolSumProcessor.appendWhere("pool.order_Date < '" + endDate + "'");
    }
} else if ("current" == dayInterval) {
    poolSumProcessor.appendWhere("pool.order_date >= now()::DATE ");
} else {
    poolSumProcessor.appendWhere("pool.order_date >= now()::DATE - cast('" + dayInterval + " day' AS interval) AND pool.authDate < now()::DATE ");
}

if (notEmpty(siteId)) {
    if ("ignoreAll" == siteId ) {
        // do nothing
    } else { 
        poolSumProcessor.appendSelect("pool.site_name ");
        poolSumProcessor.appendGroupBy("pool.site_name ");
    }
}


if (notEmpty(period)) {
	poolSumProcessor.appendSelect("pool.auth_period ");
    poolSumProcessor.appendGroupBy("pool.auth_period ");
} else {
    poolSumProcessor.appendSelect(" ''::text AS auth_period ");
}

// This line is important to prevent division by 0 errors. 
poolSumProcessor.setPostquery("HAVING sum(pool.quantity) > 0 ");


// Finally, the main query draws from PoolSum to sum up the run count and customer price.
var sqlProcessor = new SelectSQLBuilder();

sqlProcessor.setSelect("select poolSum.item_id, poolSum.item_name, sum(poolSum.run_count) as run_count, sum(poolSum.customerprice) as customer_price ");
sqlProcessor.appendSelect("(CASE WHEN sum(poolSum.run_count) > 0 THEN (sum(poolSum.customerprice) / sum(poolSum.run_count)) ELSE 0 END) as avg_unit_price ");
sqlProcessor.appendSelect("poolSum.auth_period ");
sqlProcessor.setFrom("from poolSum ");
sqlProcessor.addCommonTableExpression("poolSum", poolSumProcessor);
sqlProcessor.setWhere("where true ");
sqlProcessor.setGroupBy("GROUP BY poolSum.item_id, poolSum.item_name, poolSum.auth_period ");
sqlProcessor.setOrderBy("order by poolSum.auth_period desc ");

if (notEmpty(showOrderSource)) {
	sqlProcessor.appendSelect("poolSum.store_name ");
    sqlProcessor.appendSelect("poolSum.order_source ");
    sqlProcessor.appendGroupBy("poolSum.store_name, poolSum.order_source ");
} else {
    hide.push('store_name');
    hide.push('order_source');
}

if (notEmpty(siteId)) {
    if ("ignoreAll" == siteId ) {
        hide.push('site_name'); 
    } else { 
        sqlProcessor.appendSelect("poolSum.site_name ");
        sqlProcessor.appendGroupBy("poolSum.site_name ");
    }
}

if (notEmpty(showVersion)) {
    sqlProcessor.appendSelect("poolSum.version_id, poolSum.version_name ");
    sqlProcessor.appendGroupBy("poolSum.version_id, poolSum.version_name ");
} else {
    hide.push('version_id');
    hide.push('version_name');
}

sql = sqlProcessor.queryString();