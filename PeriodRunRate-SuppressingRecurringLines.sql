//
// Period Run Rate - DRAFT
// Edited Catherine Warren, 2017-05-15 | JIRA RPT-661
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

//var d = req.getStuff("WOW");
sum.push('run_count');
sum.push('customer_price');
weightedAverage['avg_unit_price']='run_count';

// First, a subquery to find the first / minimum payment authorization on the order. 
minLineItemsProcessor = new SelectSQLBuilder();

minLineItemsProcessor.setSelect("select min(pa.authorization_id) as authorization_id, pa.order_id, 1 as min_lineitem ");
minLineItemsProcessor.setFrom("from ecommerce.paymentauthorization as pa, ecommerce.rslineitem as li ");
minLineItemsProcessor.setWhere("where pa.order_id = li.order_id and pa.payment_status_id IN (3, 5, 6) and pa.payment_transaction_result_id = 1 ");
minLineItemsProcessor.setGroupBy("group by pa.order_id ");
minLineItemsProcessor.setOrderBy("order by pa.order_id asc ");

// Then, a subquery to find the buyer for each SKU. 
var buyerProcessor = new SelectSQLBuilder();

buyerProcessor.setSelect("SELECT distinct pvsku.productversion_id, sc.buyer");
buyerProcessor.setFrom("FROM ecommerce.productversionsku AS pvsku, ecommerce.skucategory AS sc");
buyerProcessor.setWhere("WHERE pvsku.sku_id = sc.sku_id");

// The main query. 
var sqlProcessor = new SelectSQLBuilder();
sqlProcessor.setSelect("SELECT i.item_id AS item_id, i.name AS item_name, (CASE WHEN min.min_lineitem IS NOT NULL THEN sli.quantity ELSE 0 END) AS run_count");
sqlProcessor.appendSelect("sum(li.customerPrice * sli.quantity)::numeric(10,2) AS customer_price");
sqlProcessor.appendSelect("(sum(li.customerPrice * sli.quantity) / sum(sli.quantity))::numeric(10,2) AS avg_unit_price");
sqlProcessor.addCommonTableExpression("min", minLineItemsProcessor);
sqlProcessor.setFrom("FROM ecommerce.paymentauthorization AS pa RIGHT JOIN min ON pa.authorization_id = min.authorization_id, ecommerce.RSLineItem AS li");
sqlProcessor.appendFrom("ecommerce.SiteLineItem AS sli, ecommerce.ProductVersion AS pv, ecommerce.Item AS i ");
sqlProcessor.setWhere("WHERE li.productVersion_id = pv.productVersion_id");
sqlProcessor.appendWhere("li.lineItemType_id in (1,5) AND li.subscription_id IS NULL");
sqlProcessor.appendWhere("li.oid = sli.lineItem_id");
sqlProcessor.appendWhere("pv.item_id = i.item_id");
sqlProcessor.appendWhere("pa.order_id = li.order_id");
// sqlProcessor.appendWhere("pa.payment_transaction_result_id = 1 AND pa.payment_status_id in (3,5,6,7)");
sqlProcessor.setHaving("HAVING (CASE WHEN min.min_lineitem IS NOT NULL THEN sli.quantity ELSE 0 END) > 0");
sqlProcessor.setGroupBy("GROUP BY i.item_id, i.name, min.min_lineitem, sli.quantity ");
sqlProcessor.setOrderBy("ORDER BY (CASE WHEN min.min_lineitem IS NOT NULL THEN sli.quantity ELSE 0 END) desc");

if (notEmpty(showOrderSource)) {
	sqlProcessor.appendSelect("st.name AS store_name");
    sqlProcessor.appendSelect("os.order_source AS order_source");
    sqlProcessor.appendFrom("ecommerce.rsorder AS o");
    sqlProcessor.appendFrom("ecommerce.store AS st");
    sqlProcessor.appendFrom("ecommerce.order_source AS os");
    sqlProcessor.appendWhere("o.oid = li.order_id");
    sqlProcessor.appendWhere("o.store_id = st.store_id");
    sqlProcessor.appendWhere("o.order_source_id = os.order_source_id");
    sqlProcessor.appendGroupBy("st.name, os.order_source");
} else {
	sqlProcessor.appendSelect("'' AS store_name");
    sqlProcessor.appendSelect("'' AS order_source");
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
    	sqlProcessor.appendWhere("sli.site_id = " + siteId);
        sqlProcessor.appendSelect("COALESCE(s.name,'no name available') AS site_name");
        sqlProcessor.appendGroupBy("COALESCE(s.name,'no name available')");
        sqlProcessor.appendFrom("ecommerce.site AS s");
        sqlProcessor.appendWhere("s.site_id = sli.site_id");
    } else { // if the site id is all_ctg or all_std
    	if ("ignoreAll" == siteId ) {
          hide.push('site_name')
        } else if ( "showAll" == siteId ) { // it's for a specific site or for all sites
        	sqlProcessor.appendSelect("COALESCE(s.name,'no name available') AS site_name");
            sqlProcessor.appendGroupBy("COALESCE(s.name,'no name available')");
            sqlProcessor.appendFrom("ecommerce.site AS s");
            sqlProcessor.appendWhere("s.site_id = sli.site_id");
        } else {
        	sqlProcessor.appendSelect("COALESCE(s.name,'no name available') AS site_name");
            sqlProcessor.appendGroupBy("COALESCE(s.name,'no name available')");
            sqlProcessor.appendFrom("ecommerce.site AS s");
            sqlProcessor.appendWhere("s.site_id = sli.site_id");
            var negateString = "";
            if ("all_std" == siteId) {
            	negateString = "NOT";
            }
            sqlProcessor.appendWhere("sli.site_id  " + negateString + " IN (SELECT e.site_id FROM ecommerce.site AS e, panacea.click_to_give AS p WHERE e.active = true AND e.panaceasite_id = p.site_id )");
        }
    }
}
if (notEmpty(itemId)) {
	sqlProcessor.appendWhere("i.item_id = " + itemId);
} else {
	if (notEmpty(vendorId)) {
    	sqlProcessor.appendWhere("i.vendor_id = " + vendorId);
    }
    if (notEmpty(itemName)) {
		sqlProcessor.appendWhere("i.name ILIKE '" + itemName.replace("'", "''") + "%'");
    }
}
if (notEmpty(showVersion)) {
	sqlProcessor.appendSelect("pv.productversion_id AS version_id, pv.name AS version_name");
    sqlProcessor.appendGroupBy("pv.productversion_id, pv.name");
} else {
	sqlProcessor.appendSelect("'' as version_id, '' AS version_name");
    hide.push('version_id');
    hide.push('version_name');
}

if (notEmpty(versionName)) {
	sqlProcessor.appendWhere("pv.name ILIKE '" + versionName.replace("'", "''") + "%'");
}
if (notEmpty(buyerName)) {
	sqlProcessor.appendRelationToFromWithAlias(buyerProcessor, "bp");	
	sqlProcessor.appendWhere("bp.productversion_id = pv.productversion_id AND bp.buyer ILIKE '" + buyerName.replace("'", "''") + "%'");
}

if (isEmpty(dayInterval)) {
   	if (notEmpty(startDate)) {
       	sqlProcessor.appendWhere("pa.authDate >= '" + startDate + "'");
    } else {
       	sqlProcessor.appendWhere("pa.authDate::DATE >= date_trunc('month',now()::DATE)");
    }
    if (notEmpty(endDate)) {
		sqlProcessor.appendWhere("pa.authDate < '" + endDate + "'");
    }
} else if ("current" == dayInterval) {
    sqlProcessor.appendWhere("pa.authDate >= now()::DATE");
} else {
    sqlProcessor.appendWhere("pa.authDate >= now()::DATE - cast('" + dayInterval + " day' AS interval) AND pa.authDate < now()::DATE");
}

if (notEmpty(period)) {
	if("day" == period) {
            sqlProcessor.appendSelect("to_char(pa.authDate,'yyyy-MM-DD') AS auth_period ");
            sqlProcessor.appendGroupBy("to_char(pa.authDate,'yyyy-MM-DD') ");
            sqlProcessor.appendOrderBy("to_char(pa.authDate,'yyyy-MM-DD') ");
	} if("Month" == period) {
            sqlProcessor.appendSelect("to_char(pa.authDate,'yyyy-MM') AS auth_period ");
            sqlProcessor.appendGroupBy("to_char(pa.authDate,'yyyy-MM') ");
            sqlProcessor.appendOrderBy("to_char(pa.authDate,'yyyy-MM') ");
	} 
} else {
    sqlProcessor.appendSelect(" '' AS auth_period ");
    sqlProcessor.appendGroupBy("auth_period ");
    sqlProcessor.appendOrderBy("auth_period ");
}

sql = sqlProcessor.queryString();