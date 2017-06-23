//
// Period Run Rate - DRAFT 
// Edited Catherine Warren, 2017-05-09 to 05-11 | JIRA RPT-661
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

minLineItemsProcessor = new SelectSQLBuilder();

minLineItemsProcessor.setSelect("select min(pa.authorization_id) as authorization_id, pa.order_id, 1 as min_lineitem ");
minLineItemsProcessor.setFrom("from ecommerce.paymentauthorization as pa, ecommerce.rslineitem as li ");
minLineItemsProcessor.setWhere("where pa.order_id = li.order_id and pa.payment_status_id IN (3, 5, 6) and pa.payment_transaction_result_id = 1 ");
minLineItemsProcessor.setGroupBy("group by pa.order_id ");
minLineItemsProcessor.setOrderBy("order by pa.order_id asc ");

if (notEmpty(startDate)) {
    minLineItemsProcessor.appendWhere("li.fulfillmentdate >= '" + startDate + "' ");
} 

if (notEmpty(endDate)) {
    minLineItemsProcessor.appendWhere("li.fulfillmentdate < '" + endDate + "' ");
}

payAuthProcessor = new SelectSQLBuilder();

payAuthProcessor.setSelect("select pa.authorization_id, pa.order_id, pa.authdate, pa.payment_method_id ");
payAuthProcessor.setFrom("from ecommerce.paymentauthorization as pa ");
payAuthProcessor.setWhere("where pa.payment_status_id IN (3, 5, 6) and pa.payment_transaction_result_id = 1 ");
payAuthProcessor.setGroupBy("group by pa.authorization_id, pa.order_id, pa.authdate, pa.payment_method_id ");
payAuthProcessor.setOrderBy("order by pa.authorization_id asc ");

//if (notEmpty(startDate)) {
//    payAuthProcessor.appendWhere("pa.authdate >= '" + startDate + "' ");
//} 

//if (notEmpty(endDate)) {
//    payAuthProcessor.appendWhere("pa.authdate < '" + endDate + "' ");
//}

var buyerProcessor = new SelectSQLBuilder();

buyerProcessor.setSelect("SELECT distinct pvsku.productversion_id, sc.buyer ");
buyerProcessor.setFrom("FROM ecommerce.productversionsku pvsku,ecommerce.skucategory AS sc ");
buyerProcessor.setWhere("WHERE pvsku.sku_id = sc.sku_id");

var poolProcessor = new SelectSQLBuilder();
poolProcessor.setSelect("SELECT pa.authorization_id, i.item_id, i.name AS item_name ");
poolProcessor.appendSelect("(CASE WHEN ((min.min_lineitem IS NOT NULL) OR (min.min_lineitem IS NULL AND li.subscription_id IS NOT NULL)) THEN sli.quantity ELSE 0 END) AS run_count ");
poolProcessor.appendSelect("sli.quantity as quantity, (li.customerprice * sli.quantity)::numeric(10,2) AS customer_price ");
poolProcessor.addCommonTableExpression("min", minLineItemsProcessor);
poolProcessor.addCommonTableExpression("paymentauths", payAuthProcessor);
poolProcessor.setFrom("FROM paymentauths AS pa LEFT OUTER JOIN min ON pa.authorization_id = min.authorization_id ");
poolProcessor.appendFrom("ecommerce.RSLineItem AS li, ecommerce.SiteLineItem AS sli, ecommerce.ProductVersion AS pv, ecommerce.Item AS i ");
poolProcessor.setWhere("WHERE li.productVersion_id = pv.productVersion_id ");
poolProcessor.appendWhere("li.lineItemType_id in (1,5,8) ");
poolProcessor.appendWhere("li.oid = sli.lineItem_id ");
poolProcessor.appendWhere("pv.item_id = i.item_id ");
poolProcessor.appendWhere("pa.order_id = li.order_id ");
poolProcessor.setGroupBy("GROUP BY pa.authorization_id, i.item_id, i.name, min.min_lineitem, li.subscription_id, li.customerprice, sli.quantity ");
poolProcessor.setOrderBy("ORDER BY sum(li.customerPrice * sli.quantity)::numeric(10,2) desc ");

if (notEmpty(showOrderSource)) {
	poolProcessor.appendSelect("st.name AS store_name ");
    poolProcessor.appendSelect("os.order_source AS order_source ");
    poolProcessor.appendFrom("ecommerce.rsorder AS o ");
    poolProcessor.appendFrom("ecommerce.store AS st ");
    poolProcessor.appendFrom("ecommerce.order_source AS os ");
    poolProcessor.appendWhere("o.oid = li.order_id ");
    poolProcessor.appendWhere("o.store_id = st.store_id ");
    poolProcessor.appendWhere("o.order_source_id = os.order_source_id ");
    poolProcessor.appendGroupBy("st.name, os.order_source ");
} else {
    hide.push('store_name');
    hide.push('order_source');
}

//handling Site options
/*if the siteId is empty, it refers to ALL sites... This means that we should not have any where criteria in SQL query.
  all_ctg  refers to ALL l click to gives
  all_std refers to All standalones
  none of this matters if we're searching by itemId
*/
if (notEmpty(siteId)) {
	if (siteId > 0 && siteId < 99999) {
    	poolProcessor.appendWhere("sli.site_id = " + siteId);
        poolProcessor.appendSelect("COALESCE(s.name,'no name available') AS site_name ");
        poolProcessor.appendGroupBy("COALESCE(s.name,'no name available') ");
        poolProcessor.appendFrom("ecommerce.site AS s ");
        poolProcessor.appendWhere("s.site_id = sli.site_id ");
    } else { // if the site id is all_ctg or all_std
    	if ("ignoreAll" == siteId ) {
          // do nothing
        } else if ( "showAll" == siteId ) { // it's for a specific site or for all sites
        	poolProcessor.appendSelect("COALESCE(s.name,'no name available') AS site_name ");
            poolProcessor.appendGroupBy("COALESCE(s.name,'no name available') ");
            poolProcessor.appendFrom("ecommerce.site AS s ");
            poolProcessor.appendWhere("s.site_id = sli.site_id ");
        } else {
        	poolProcessor.appendSelect("COALESCE(s.name,'no name available') AS site_name ");
            poolProcessor.appendGroupBy("COALESCE(s.name,'no name available') ");
            poolProcessor.appendFrom("ecommerce.site AS s ");
            poolProcessor.appendWhere("s.site_id = sli.site_id ");
            var negateString = "";
            if ("all_std" == siteId) {
            	negateString = "NOT";
            }
            poolProcessor.appendWhere("sli.site_id  " + negateString + " IN (SELECT e.site_id FROM ecommerce.site AS e, panacea.click_to_give AS p WHERE e.active = true AND e.panaceasite_id = p.site_id ) ");
        }
    }
}

if (notEmpty(itemId)) {
	poolProcessor.appendWhere("i.item_id IN (" + itemId + ") ");
} else {
	if (notEmpty(vendorId)) {
    	poolProcessor.appendWhere("i.vendor_id = " + vendorId);
    }
    if (notEmpty(itemName)) {
		poolProcessor.appendWhere("i.name ILIKE '" + itemName.replace("'", "''") + "%' ");
    }
}

if (notEmpty(showVersion)) {
	poolProcessor.appendSelect("pv.productversion_id AS version_id, pv.name AS version_name ");
    poolProcessor.appendGroupBy("pv.productversion_id, pv.name ");
} 

if (notEmpty(versionName)) {
	poolProcessor.appendWhere("pv.name ILIKE '" + versionName.replace("'", "''") + "%' ");
}
if (notEmpty(buyerName)) {
	poolProcessor.appendRelationToFromWithAlias(buyerProcessor, "bp");	
	poolProcessor.appendWhere("bp.productversion_id = pv.productversion_id AND bp.buyer ILIKE '" + buyerName.replace("'", "''") + "%' ");
}

if (isEmpty(dayInterval)) {
   	if (notEmpty(startDate)) {
       	poolProcessor.appendWhere("pa.authDate >= '" + startDate + "' ");
    } else {
       	poolProcessor.appendWhere("pa.authDate::DATE >= date_trunc('month',now()::DATE) ");
    }
    if (notEmpty(endDate)) {
		poolProcessor.appendWhere("pa.authDate < '" + endDate + "'");
    }
} else if ("current" == dayInterval) {
    poolProcessor.appendWhere("pa.authDate >= now()::DATE ");
} else {
    poolProcessor.appendWhere("pa.authDate >= now()::DATE - cast('" + dayInterval + " day' AS interval) AND pa.authDate < now()::DATE ");
}

if (notEmpty(period)) {
	if("day" == period) {
            poolProcessor.appendSelect("to_char(pa.authDate,'yyyy-MM-DD') AS auth_period ");
            poolProcessor.appendGroupBy("to_char(pa.authDate,'yyyy-MM-DD') ");
            poolProcessor.appendOrderBy("to_char(pa.authDate,'yyyy-MM-DD') ");
	} if("Month" == period) {
            poolProcessor.appendSelect("to_char(pa.authDate,'yyyy-MM') AS auth_period ");
            poolProcessor.appendGroupBy("to_char(pa.authDate,'yyyy-MM') ");
            poolProcessor.appendOrderBy("to_char(pa.authDate,'yyyy-MM') ");
	} 
} else {
    poolProcessor.appendSelect(" '' AS auth_period ");
    poolProcessor.appendGroupBy("auth_period ");
    poolProcessor.appendOrderBy("auth_period ");
}

var poolSumProcessor = new SelectSQLBuilder();

poolSumProcessor.setSelect("SELECT pool.item_id, pool.item_name, pool.run_count, pool.customer_price ");
poolSumProcessor.appendSelect("(sum(pool.customer_price * pool.quantity) / sum(pool.quantity))::numeric(10,2) AS avg_unit_price ");
poolSumProcessor.setFrom("FROM pool ");
poolSumProcessor.addCommonTableExpression("pool", poolProcessor);
poolSumProcessor.setWhere("WHERE true ");
poolSumProcessor.setGroupBy("GROUP BY pool.authorization_id, pool.item_id, pool.item_name, pool.run_count, pool.customer_price, pool.quantity, pool.auth_period ");
poolSumProcessor.setPostquery("HAVING pool.run_count > 0 ");

if (notEmpty(showOrderSource)) {
	poolSumProcessor.appendSelect("pool.store_name ");
    poolSumProcessor.appendSelect("pool.order_source ");
    poolSumProcessor.appendGroupBy("pool.store_name, pool.order_source ");
} 

if (notEmpty(siteId)) {
    if ("ignoreAll" == siteId ) {
        // do nothing
    } else { 
        poolSumProcessor.appendSelect("pool.site_name ");
        poolSumProcessor.appendGroupBy("pool.site_name ");
    }
}

if (notEmpty(showVersion)) {
	poolSumProcessor.appendSelect("pool.version_id, pool.version_name ");
    poolSumProcessor.appendGroupBy("pool.version_id, pool.version_name ");
} 

if (notEmpty(period)) {
	poolSumProcessor.appendSelect("pool.auth_period ");
} else {
    poolSumProcessor.appendSelect(" ''::text AS auth_period ");
}

var sqlProcessor = new SelectSQLBuilder();

sqlProcessor.setSelect("select poolSum.item_id, poolSum.item_name, sum(poolSum.run_count) as run_count, sum(poolSum.customer_price) as customer_price, (sum(poolSum.customer_price) / sum(poolSum.run_count)) as avg_unit_price, poolSum.auth_period ");
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