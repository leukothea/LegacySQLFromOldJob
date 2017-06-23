//
// Period Run Rate - Sales Report
// Edited Catherine Warren, 2016-01-04, for JIRA RPT-195
// Made into the report of record, 2016-01-05
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

var buyerProcessor = new SelectSQLBuilder();

buyerProcessor.setSelect("select distinct pvsku.productversion_id,sc.buyer");
buyerProcessor.setFrom("from ecommerce.productversionsku pvsku,ecommerce.skucategory sc");
buyerProcessor.setWhere("where pvsku.sku_id = sc.sku_id");


var sqlProcessor = new SelectSQLBuilder();
sqlProcessor.setSelect("select i.item_id AS item_id,i.name AS item_name,sum(sli.quantity) AS run_count");
sqlProcessor.appendSelect("sum(li.customerPrice * sli.quantity)::numeric(10,2) AS customer_price");
sqlProcessor.appendSelect("(sum(li.customerPrice * sli.quantity) / sum(sli.quantity))::numeric(10,2) AS avg_unit_price");
//sqlProcessor.setFrom("from ecommerce.PaymentAuthorization pa,ecommerce.productversionsku pvsku,ecommerce.RSLineItem li,ecommerce.SiteLineItem sli,ecommerce.ProductVersion pv,ecommerce.Item i");
sqlProcessor.setFrom("from ecommerce.PaymentAuthorization pa,ecommerce.RSLineItem li,ecommerce.SiteLineItem sli,ecommerce.ProductVersion pv,ecommerce.Item i");
sqlProcessor.setWhere("where li.productVersion_id = pv.productVersion_id");
sqlProcessor.appendWhere("li.lineItemType_id in (1,5)");
sqlProcessor.appendWhere("li.oid = sli.lineItem_id");
sqlProcessor.appendWhere("pv.item_id = i.item_id");
sqlProcessor.appendWhere("pa.order_id = li.order_id");
sqlProcessor.appendWhere("pa.payment_transaction_result_id = 1 and pa.payment_status_id in (3,5,6,7)");
//sqlProcessor.appendWhere("pv.productversion_id = pvsku.productversion_id");
sqlProcessor.setHaving("having sum(sli.quantity) > 0");
sqlProcessor.setGroupBy("group by i.item_id,i.name");
sqlProcessor.setOrderBy("order by sum(sli.quantity) desc");

if (notEmpty(showOrderSource)) {
	sqlProcessor.appendSelect("st.name as store_name");
    sqlProcessor.appendSelect("os.order_source as order_source");
    sqlProcessor.appendFrom("ecommerce.rsorder o");
    sqlProcessor.appendFrom("ecommerce.store st");
    sqlProcessor.appendFrom("ecommerce.order_source os");
    sqlProcessor.appendWhere("o.oid = li.order_id");
    sqlProcessor.appendWhere("o.store_id = st.store_id");
    sqlProcessor.appendWhere("o.order_source_id = os.order_source_id");
    sqlProcessor.appendGroupBy("st.name,os.order_source");
} else {
	//sqlProcessor.appendSelect("'' as store_name");
    //sqlProcessor.appendSelect("'' as order_source");
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
        sqlProcessor.appendFrom("ecommerce.site s");
        sqlProcessor.appendWhere("s.site_id = sli.site_id");
    } else { // if the site id is all_ctg or all_std
    	if ("ignoreAll" == siteId ) {
          hide.push('site_name')
        } else if ( "showAll" == siteId ) { // it's for a specific site or for all sites
        	sqlProcessor.appendSelect("COALESCE(s.name,'no name available') AS site_name");
            sqlProcessor.appendGroupBy("COALESCE(s.name,'no name available')");
            sqlProcessor.appendFrom("ecommerce.site s");
            sqlProcessor.appendWhere("s.site_id = sli.site_id");
        } else {
        	sqlProcessor.appendSelect("COALESCE(s.name,'no name available') AS site_name");
            sqlProcessor.appendGroupBy("COALESCE(s.name,'no name available')");
            sqlProcessor.appendFrom("ecommerce.site s");
            sqlProcessor.appendWhere("s.site_id = sli.site_id");
            var negateString = "";
            if ("all_std" == siteId) {
            	negateString = "NOT";
            }
            sqlProcessor.appendWhere("sli.site_id  " + negateString + " IN (Select e.site_id from ecommerce.site as e , panacea.click_to_give as p where e.active = true and e.panaceasite_id = p.site_id )");
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
	sqlProcessor.appendSelect("pv.productversion_id as version_id,pv.name AS version_name");
    sqlProcessor.appendGroupBy("pv.productversion_id,pv.name");
} else {
	//sqlProcessor.appendSelect("'' as version_id,'' AS version_name");
    hide.push('version_id');
    hide.push('version_name');
}

if (notEmpty(versionName)) {
	sqlProcessor.appendWhere("pv.name ILIKE '" + versionName.replace("'", "''") + "%'");
}
if (notEmpty(buyerName)) {
	sqlProcessor.appendRelationToFromWithAlias(buyerProcessor, "bp");	
	sqlProcessor.appendWhere("bp.productversion_id = pv.productversion_id and bp.buyer ILIKE '" + buyerName.replace("'", "''") + "%'");
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
    sqlProcessor.appendWhere("pa.authDate >= now()::DATE - cast('" + dayInterval + " day' as interval) and pa.authDate < now()::DATE");
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