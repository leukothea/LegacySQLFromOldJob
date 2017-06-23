//
// Origin Code Auth Cogs Report 
// Edited Catherine Warren, 2015-12-10 to 11, RPT-179
//

var dayInterval = p["days2"];
var originCode = p["code"];
var startDate = p["start"];
var endDate = p["end"];
var showAuth = p["show"];
var site = p["site2"];
var platform = p["platform"];
var showOrderSource = p["showOrderSource"];

sum.push('order_count');
sum.push('auth_amount');
sum.push('gtgm_total');
sum.push('shipping');
sum.push('sales_tax');
sum.push('royalty');
sum.push('adj_revenue');
//sum.push('cogs');

var dateClause = "";
if (notEmpty(dayInterval)) {
	dateClause = dateClause + "pa.authDate >= now()::DATE - cast('" + dayInterval + " day' as interval)";
    if (dayInterval == 0) {
         dateClause = dateClause + " and pa.authDate > now()::DATE";
    } else {
         dateClause = dateClause + " and pa.authDate < now()::DATE";
    }
} else {
	// empty interval, so we are using only dates...
    if (notEmpty(startDate)) {
    	dateClause = dateClause + "pa.authDate >= '" + startDate + "'";
        if (notEmpty(endDate)) {
        	dateClause = dateClause + " and pa.authDate < '" + endDate + "'";
        }
    } else {
    	dateClause = dateClause + "pa.authDate >= date_trunc('month',now()::DATE)";
    }
}

var maxIIDateProcessor = new SelectSQLBuilder();

maxIIDateProcessor.setSelect("SELECT s.sku_id ,max(ii.dateRecordAdded) as dra ");
maxIIDateProcessor.setFrom("FROM ecommerce.SKU s ,ecommerce.RSInventoryItem ii ,ecommerce.ProductVersionSKU pvs ");
maxIIDateProcessor.setWhere("WHERE s.sku_id = ii.sku_id and s.sku_id = pvs.sku_id and s.skuBitMask & 1 = 1 and ii.merchantPrice > 0 ");
maxIIDateProcessor.setGroupBy(" GROUP BY s.sku_id");

var currentSkuCostProcessor = new SelectSQLBuilder();

currentSkuCostProcessor.setSelect("SELECT s.sku_id ,max(ii.merchantPrice) as cost ");
currentSkuCostProcessor.setFrom("FROM  ecommerce.SKU as s ,ecommerce.RSInventoryItem as ii ,ecommerce.ProductVersionSKU as pvs ");
currentSkuCostProcessor.appendRelationToFromWithAlias(maxIIDateProcessor, "dra");
currentSkuCostProcessor.setWhere("WHERE s.sku_id = ii.sku_id and s.sku_id = pvs.sku_id and s.skuBitMask & 1 = 1 and dra.sku_id = ii.sku_id and dra.dra = ii.dateRecordAdded and ii.merchantPrice > 0 ");
currentSkuCostProcessor.setGroupBy("GROUP BY s.sku_id");

var currentVersionCostProcessor = new SelectSQLBuilder();

currentVersionCostProcessor.setSelect("SELECT pvsku.productVersion_id as version_id, sum(pvsku.quantity * csc.cost) as cost");
currentVersionCostProcessor.setFrom("FROM ecommerce.productversionsku as pvsku");
currentVersionCostProcessor.appendRelationToFromWithAlias(currentSkuCostProcessor,"csc");
currentVersionCostProcessor.setWhere("WHERE pvsku.sku_id = csc.sku_id");
currentVersionCostProcessor.setGroupBy("Group By pvsku.productVersion_id");

var currentOrderCostProcessor = new SelectSQLBuilder();

currentOrderCostProcessor.setSelect("SELECT li.order_id as order_id, sum(cvc.cost) as cost");
currentOrderCostProcessor.setFrom("FROM ecommerce.rslineitem as li");
currentOrderCostProcessor.appendRelationToFromWithAlias(currentVersionCostProcessor,"cvc");
currentOrderCostProcessor.setWhere("WHERE li.productversion_id = cvc.version_id");
currentOrderCostProcessor.setGroupBy("Group By li.order_id");

var gtgmProcessor = new SelectSQLBuilder();
gtgmProcessor.setSelect("select li.order_id,sum(li.customerPrice * li.quantity) as gtgm_total");
gtgmProcessor.setFrom("from ecommerce.rslineitem as li,ecommerce.productversion as pv,ecommerce.item as i");
gtgmProcessor.setWhere("where li.productversion_id = pv.productversion_id and pv.item_id = i.item_id and i.itembitmask & 32 = 32");
gtgmProcessor.setGroupBy("group by li.order_id");

var royaltyProcessor = new SelectSQLBuilder();
royaltyProcessor.setSelect("select li.order_id, sum(COALESCE(sli.quantity,0.00) * coalesce(df.royaltyFactor,0.00)) AS royalty ");
royaltyProcessor.setFrom("from ecommerce.RSLineItem as li, ecommerce.SiteLineItem as sli, ecommerce.DonationFactor as df, ecommerce.PaymentAuthorization as pa, ecommerce.productversion as pv, ecommerce.item as i ");
royaltyProcessor.setWhere("where li.oid = sli.lineItem_id and sli.site_id = df.site_id and li.productversion_id = pv.productversion_id and pv.item_id = i.item_id and pa.order_id = li.order_id ");
royaltyProcessor.appendWhere("COALESCE(li.customerprice,0.00) >= df.minPrice and COALESCE(li.customerprice,0.00) < df.maxPrice ");
royaltyProcessor.appendWhere("i.itembitmask &2 != 2 ");
royaltyProcessor.appendWhere(dateClause.toString());
royaltyProcessor.appendWhere("pa.payment_transaction_result_id = 1 and pa.payment_status_id in (3,5,6)");
royaltyProcessor.setGroupBy("group by li.order_id");

var sqlProcessor = new SelectSQLBuilder();

if (notEmpty(showAuth)) {
	sqlProcessor.setSelect("select pa.authDate::DATE as sale_date,COALESCE(o.originCode,'No Origin Code') AS origin_code");
} else {
  hide.push('sale_date');
  sqlProcessor.setSelect("select '' as sale_date,COALESCE(o.originCode,'No Origin Code') AS origin_code");
}
sqlProcessor.appendSelect("count(distinct o.oid) AS order_count,sum(pa.amount) AS auth_amount,sum(coalesce(o.shippingcost,0.00)) as shipping ");
sqlProcessor.appendSelect("sum(coalesce(gtgm.gtgm_total,0.00)) as gtgm_total, sum(coalesce(o.tax,0.00)) as sales_tax, sum(coalesce(ry.royalty,0.00)) as royalty ");
sqlProcessor.appendSelect("sum(pa.amount) - sum(coalesce(o.shippingcost,0.00)) - sum(coalesce(gtgm.gtgm_total,0.00)) - sum(coalesce(o.tax,0.00)) - COALESCE(sum(ry.royalty),0.00) as adj_revenue");
sqlProcessor.appendSelect("sum(cocp.cost) as cogs");
//sqlProcessor.appendSelect("'sales.do?method=originCodeDetail&code=' || COALESCE(o.originCode,'No Origin Code') || '&start=' || '" + startDate + "' || '&end=' || '" + endDate + "' || '&days=' || '" + dayInterval + "' || '&show=' || '" + showAuth + "' AS subreporturl");
sqlProcessor.setFrom("from ecommerce.PaymentAuthorization as pa");
sqlProcessor.appendFrom("ecommerce.RSOrder as o LEFT OUTER JOIN (" + gtgmProcessor.queryString() + ") gtgm ON o.oid = gtgm.order_id LEFT OUTER JOIN (" + currentOrderCostProcessor.queryString() + ") cocp ON o.oid = cocp.order_id LEFT OUTER JOIN ry on ry.order_id = o.oid ");
sqlProcessor.addCommonTableExpression("ry", royaltyProcessor);
sqlProcessor.setWhere("where pa.order_id = o.oid and pa.order_id = ry.order_id");
sqlProcessor.appendWhere("pa.payment_transaction_result_id = 1 and pa.payment_status_id in (3,5,6)");
sqlProcessor.appendWhere(dateClause);

if (notEmpty(originCode)) {
    sqlProcessor.appendWhere("o.originCode ILIKE '" + originCode + "%'");
}
if ("m" == platform) {
    sqlProcessor.appendWhere("o.client_ip_address in ('54.215.150.37','54.241.179.159','54.215.150.33','54.215.148.134','54.208.37.246','54.236.100.183','54.208.57.30','54.208.37.89','54.154.19.105','54.154.18.247','54.172.227.126','54.174.197.243','54.67.78.16','54.67.110.97','54.246.211.85','54.246.211.102','54.229.31.168','54.229.72.158','54.64.130.216','54.64.71.56')");
} else if ("d" == platform) {
    sqlProcessor.appendWhere("o.client_ip_address not in ('54.215.150.37','54.241.179.159','54.215.150.33','54.215.148.134','54.208.37.246','54.236.100.183','54.208.57.30','54.208.37.89','54.154.19.105','54.154.18.247','54.172.227.126','54.174.197.243','54.67.78.16','54.67.110.97','54.246.211.85','54.246.211.102','54.229.31.168','54.229.72.158','54.64.130.216','54.64.71.56')");
}

if (notEmpty(showAuth)) {
    sqlProcessor.setGroupBy("group by pa.authDate::DATE,COALESCE(o.originCode,'No Origin Code')");
    sqlProcessor.setOrderBy("order by pa.authDate::DATE,auth_amount desc,COALESCE(o.originCode,'No Origin Code')");
} else {
    sqlProcessor.setGroupBy("group by COALESCE(o.originCode,'No Origin Code')");
    sqlProcessor.setOrderBy("order by auth_amount desc,COALESCE(o.originCode,'No Origin Code')");
}

if (notEmpty(showOrderSource)) {
    sqlProcessor.appendSelect("st.name as store_name");
    sqlProcessor.appendSelect("os.order_source as order_source");
    sqlProcessor.appendFrom("ecommerce.store st");
    sqlProcessor.appendFrom("ecommerce.order_source os");
    sqlProcessor.appendWhere("o.store_id = st.store_id");
    sqlProcessor.appendWhere("o.order_source_id = os.order_source_id");
    sqlProcessor.appendGroupBy("st.name,os.order_source");
} else {
  hide.push('store_name');
  hide.push('order_source');
}

if ("ignoreAll" == site) {
	hide.push('site_name');
} else { // it's for a specific site or for all sites
    sqlProcessor.appendFrom("ecommerce.site s");
    sqlProcessor.appendWhere("o.site_id = s.site_id");
    sqlProcessor.appendSelect("COALESCE(s.name,'no name available') AS site_name");
    sqlProcessor.appendGroupBy("COALESCE(s.name,'no name available')");
}

if ("showAll" != site && "ignoreAll" != site) {
    sqlProcessor.appendWhere("s.site_id = " + site);
}
        
sql = sqlProcessor.queryString();