//
// Origin Code Auth Report
// Revised by Catherine Warren, 2015-11-03 to 13
//

var dayInterval = p["days2"];
var originCode = p["origin_code"];
var startDate = p["start"];
var endDate = p["end"];
var showAuth = p["show"];
var site = p["site2"];
var platform = p["platform"];
var showOrderSource = p["showOrderSource"];
var showVersion = p["sv"];

sum.push('order_count');
sum.push('auth_amount');
sum.push('gtgm_total');
sum.push('order_shipping_amount');
//sum.push('nopromo_order_shipping_price');
sum.push('promo_shipping_price');
sum.push('promo_shipping_discount');
sum.push('summed_shipping_price');
sum.push('sales_tax');
sum.push('royalty');
sum.push('adj_revenue');

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

var noShipSubProcessor = new SelectSQLBuilder();
noShipSubProcessor.setSelect ("select o11.oid, true as to_exclude ");
noShipSubProcessor.setFrom ("from ecommerce.rsorder as o11, ecommerce.promotion as p11, ecommerce.orderpromotion as op11, ecommerce.promotionaction as pact11, ecommerce.paymentauthorization as pa ");
noShipSubProcessor.setWhere ("where o11.oid = pa.order_id and o11.oid = op11.order_id and op11.promotion_id = p11.promotion_id and p11.promotion_id = pact11.promotion_id and pa.payment_transaction_result_id = 1 and pa.payment_status_id IN (3, 5, 6) and pact11.inputparam ILIKE 'SHIPPING%' ");
noShipSubProcessor.appendWhere(dateClause);
noShipSubProcessor.setGroupBy ("group by o11.oid ");

var noShipPromoProcessor = new SelectSQLBuilder();
// Subquery to show orders that are missing a shipping promotion. 
noShipPromoProcessor.setSelect ("select o1.oid as order_id, o1.shippingcost, o1.shippingcost AS shipping_price ");
noShipPromoProcessor.setFrom ("from ecommerce.rsorder as o1 LEFT OUTER JOIN q ON o1.oid = q.oid, ecommerce.paymentauthorization as pa ");
noShipPromoProcessor.addCommonTableExpression("q",noShipSubProcessor);
noShipPromoProcessor.setWhere ("where o1.oid = pa.order_id and pa.payment_transaction_result_id = 1 and pa.payment_status_id IN (3, 5, 6) " );
noShipPromoProcessor.appendWhere(dateClause);
noShipPromoProcessor.setGroupBy ("group by o1.oid, o1.shippingcost ");

var shippingPriceProcessor = new SelectSQLBuilder();
// Subquery to show orders that have a SHIPPING_PRICE promotion. 
shippingPriceProcessor.setSelect ("select o2.oid as order_id, adj.promotion_id , o2.shippingcost, pact.inputparam, pact.amount, sum(pact.amount) AS shipping_price ");
shippingPriceProcessor.setFrom ("from ecommerce.rsorder as o2, ecommerce.orderpromotion as op, ecommerce.rsadjustment as adj, ecommerce.promotion as p, ecommerce.promotionaction as pact, ecommerce.paymentauthorization as pa ");
shippingPriceProcessor.setWhere ("where o2.oid = adj.order_id and o2.oid = op.order_id and op.promotion_id = p.promotion_id and p.promotion_id = pact.promotion_id and o2.oid = pa.order_id and pa.payment_transaction_result_id = 1 and pa.payment_status_id IN (3, 5, 6) and pact.inputparam = 'SHIPPING_PRICE' ");
shippingPriceProcessor.appendWhere(dateClause);
shippingPriceProcessor.setGroupBy ("group by o2.oid, adj.promotion_id, o2.shippingcost, pact.inputparam, pact.amount ");

var shippingDiscountProcessor = new SelectSQLBuilder();
// Subquery to show orders that have a SHIPPING_DISCOUNT promotion. 
shippingDiscountProcessor.setSelect ("select o3.oid as order_id, adj.promotion_id , o3.shippingcost, -(adj.amount) AS shipping_price ");
shippingDiscountProcessor.setFrom ("from ecommerce.rsorder as o3, ecommerce.orderpromotion as op, ecommerce.rsadjustment as adj, ecommerce.promotion as p, ecommerce.promotionaction as pact, ecommerce.paymentauthorization as pa ");
shippingDiscountProcessor.setWhere ("where o3.oid = adj.order_id and o3.oid = op.order_id and op.promotion_id = p.promotion_id and p.promotion_id = pact.promotion_id and o3.oid = pa.order_id and pa.payment_transaction_result_id = 1 and pa.payment_status_id IN (3, 5, 6) and adj.adjustment_type_id = 6 and pact.inputparam = 'SHIPPING_DISCOUNT' ");
shippingDiscountProcessor.appendWhere(dateClause);
shippingDiscountProcessor.setGroupBy ("group by o3.oid, adj.promotion_id, o3.shippingcost, adj.amount ");

var gtgmProcessor = new SelectSQLBuilder();
gtgmProcessor.setSelect("select li.order_id, sum(li.customerPrice * li.quantity) as gtgm_total ");
gtgmProcessor.setFrom("from ecommerce.rslineitem as li, ecommerce.productversion as pv, ecommerce.item as i, ecommerce.PaymentAuthorization as pa, ecommerce.rsorder as o4 ");
gtgmProcessor.setWhere("where li.order_id = o4.oid and li.productversion_id = pv.productversion_id and pv.item_id = i.item_id and i.itembitmask & 32 = 32 and pa.order_id = li.order_id ");
gtgmProcessor.appendWhere(dateClause);
gtgmProcessor.appendWhere("pa.payment_transaction_result_id = 1 and pa.payment_status_id in (3,5,6) ");
gtgmProcessor.setGroupBy("group by li.order_id ");

var royaltyProcessor = new SelectSQLBuilder();
royaltyProcessor.setSelect("select li.order_id, sum(COALESCE(sli.quantity,0.00) * coalesce(df.royaltyFactor,0.00)) AS royalty ");
royaltyProcessor.setFrom("from ecommerce.RSLineItem as li, ecommerce.SiteLineItem as sli, ecommerce.DonationFactor as df, ecommerce.PaymentAuthorization as pa, ecommerce.productversion as pv, ecommerce.item as i ");
royaltyProcessor.setWhere("where li.oid = sli.lineItem_id and sli.site_id = df.site_id and li.productversion_id = pv.productversion_id and pv.item_id = i.item_id and pa.order_id = li.order_id ");
royaltyProcessor.appendWhere("COALESCE(li.customerprice,0.00) >= df.minPrice and COALESCE(li.customerprice,0.00) < df.maxPrice ");
royaltyProcessor.appendWhere("i.itembitmask &2 != 2 ");
royaltyProcessor.appendWhere(dateClause);
royaltyProcessor.appendWhere("pa.payment_transaction_result_id = 1 and pa.payment_status_id in (3,5,6)");
royaltyProcessor.setGroupBy("group by li.order_id");

var sqlProcessor = new SelectSQLBuilder();

if (notEmpty(showAuth)) {
	sqlProcessor.setSelect("select pa.authDate::DATE as sale_date,COALESCE(o.originCode,'No Origin Code') AS origin_code");
} else {
  hide.push('sale_date');
  sqlProcessor.setSelect("select '' as sale_date,COALESCE(o.originCode,'No Origin Code') AS origin_code");
}
sqlProcessor.appendSelect("count(distinct o.oid) AS order_count, sum(pa.amount) AS auth_amount, sum(coalesce(shippingPrice.shipping_price,noShipPromo.shipping_price)) as order_shipping_amount, sum(coalesce(shippingDiscount.shipping_price,0.00)) as promo_shipping_discount, (sum(coalesce(shippingPrice.shipping_price,noShipPromo.shipping_price)) + sum(coalesce(shippingDiscount.shipping_price,0.00))) as summed_shipping_price ");
sqlProcessor.appendSelect("sum(coalesce(gtgm.gtgm_total,0.00)) as gtgm_total, sum(coalesce(o.tax,0.00)) as sales_tax, COALESCE(sum(ry.royalty),0.00) as royalty ");
sqlProcessor.appendSelect("sum(pa.amount) - (sum(coalesce(noShipPromo.shipping_price,shippingPrice.shipping_price)) + sum(coalesce(shippingDiscount.shipping_price,0.00))) - sum(coalesce(gtgm.gtgm_total,0.00)) - sum(coalesce(o.tax,0.00)) - COALESCE(sum(ry.royalty),0.00) as adj_revenue ");
//sqlProcessor.appendSelect("'sales.do?method=originCodeDetail&code=' || COALESCE(o.originCode,'No Origin Code') || '&start=' || '" + startDate + "' || '&end=' || '" + endDate + "' || '&days=' || '" + dayInterval + "' || '&show=' || '" + showAuth + "' AS subreporturl");
sqlProcessor.setFrom("from ecommerce.PaymentAuthorization as pa");
sqlProcessor.addCommonTableExpression("ry",royaltyProcessor);
sqlProcessor.addCommonTableExpression("gtgm",gtgmProcessor);
sqlProcessor.addCommonTableExpression("noShipPromo",noShipPromoProcessor);
sqlProcessor.addCommonTableExpression("shippingPrice",shippingPriceProcessor);
sqlProcessor.addCommonTableExpression("shippingDiscount",shippingDiscountProcessor);
sqlProcessor.appendFrom("ecommerce.RSOrder as o LEFT OUTER JOIN gtgm ON o.oid = gtgm.order_id LEFT OUTER JOIN noShipPromo ON o.oid = noShipPromo.order_id LEFT OUTER JOIN shippingPrice ON o.oid = shippingPrice.order_id LEFT OUTER JOIN shippingDiscount ON o.oid = shippingDiscount.order_id LEFT OUTER JOIN ry ON o.oid = ry.order_id ");
sqlProcessor.setWhere("where pa.order_id = o.oid ");
sqlProcessor.appendWhere("pa.payment_transaction_result_id = 1 and pa.payment_status_id in (3,5,6) ");
sqlProcessor.appendWhere(dateClause);

if (notEmpty(originCode)) {
    sqlProcessor.appendWhere("o.originCode ILIKE '%" + originCode + "%'");
}
if ("m" == platform) {
    sqlProcessor.appendWhere("o.client_ip_address in ('54.215.150.37','54.241.179.159','54.215.150.33','54.215.148.134','54.208.37.246','54.236.100.183','54.208.57.30','54.208.37.89','54.154.19.105','54.154.18.247','54.172.227.126','54.174.197.243','54.67.78.16','54.67.110.97','54.246.211.85','54.246.211.102','54.229.31.168','54.229.72.158','54.64.130.216','54.64.71.56')");
} else if ("d" == platform) {
    sqlProcessor.appendWhere("o.client_ip_address not in ('54.215.150.37','54.241.179.159','54.215.150.33','54.215.148.134','54.208.37.246','54.236.100.183','54.208.57.30','54.208.37.89','54.154.19.105','54.154.18.247','54.172.227.126','54.174.197.243','54.67.78.16','54.67.110.97','54.246.211.85','54.246.211.102','54.229.31.168','54.229.72.158','54.64.130.216','54.64.71.56')");
}

if (notEmpty(showAuth)) {
    sqlProcessor.setGroupBy("group by pa.authDate::DATE,COALESCE(o.originCode,'No Origin Code'), coalesce((noShipPromo.shipping_price + shippingPrice.shipping_price + shippingDiscount.shipping_price),0.00) ");
    sqlProcessor.setOrderBy("order by pa.authDate::DATE,auth_amount desc,COALESCE(o.originCode,'No Origin Code') ");
} else {
    sqlProcessor.setGroupBy("group by COALESCE(o.originCode,'No Origin Code'), coalesce((noShipPromo.shipping_price + shippingPrice.shipping_price + shippingDiscount.shipping_price),0.00) ");
    sqlProcessor.setOrderBy("order by auth_amount desc,COALESCE(o.originCode,'No Origin Code') ");
}

if (notEmpty(showOrderSource)) {
    sqlProcessor.appendSelect("st.name as store_name ");
    sqlProcessor.appendSelect("os.order_source as order_source ");
    sqlProcessor.appendFrom("ecommerce.store as st ");
    sqlProcessor.appendFrom("ecommerce.order_source as os ");
    sqlProcessor.appendWhere("o.store_id = st.store_id ");
    sqlProcessor.appendWhere("o.order_source_id = os.order_source_id ");
    sqlProcessor.appendGroupBy("st.name, os.order_source ");
} else {
  hide.push('store_name');
  hide.push('order_source');
}

if ("ignoreAll" == site) {
	hide.push('site_name');
} else { // it's for a specific site or for all sites
    sqlProcessor.appendFrom("ecommerce.site as s ");
    sqlProcessor.appendWhere("o.site_id = s.site_id ");
    sqlProcessor.appendSelect("COALESCE(s.name, 'no name available') AS site_name ");
    sqlProcessor.appendGroupBy("COALESCE(s.name, 'no name available') ");
}

if ("showAll" != site && "ignoreAll" != site) {
    sqlProcessor.appendWhere("s.site_id = " + site);
}

if (notEmpty(showVersion)) {
    sqlProcessor.appendSelect("i.item_id, i.name as item_name, pv.productversion_id as version_id, pv.name AS version_name, count(li.productversion_id) as total_sold ");
    sqlProcessor.appendFrom("ecommerce.item as i, ecommerce.productversion as pv, ecommerce.rslineitem as li ");
    sqlProcessor.appendWhere("o.oid = li.order_id and li.productversion_id = pv.productversion_id and pv.item_id = i.item_id ");
    sqlProcessor.appendGroupBy("i.item_id, i.name, pv.productversion_id, pv.name ");
    hide.push('order_count');
    hide.push('auth_amount');
    hide.push('gtgm_total');
    hide.push('shipping');
    hide.push('sales_tax');
    hide.push('royalty');
    hide.push('adj_revenue');
} else {
    hide.push('item_id');
    hide.push('item_name');
    hide.push('version_id');
    hide.push('version_name');
    hide.push('total_sold');
}
        
sql = sqlProcessor.queryString();