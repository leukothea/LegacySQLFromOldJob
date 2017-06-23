//
// Promotion Performance Report
// Taken from Promotion Code Report. Edited by Catherine Warren, 2015-11-18, to include promotions that don't have a code (RPT-184)
// Edited Catherine Warren, 2015-11-23, to replace "No Promotion Code" in output with a blank cell.
// Edited Catherine Warren, 2015-11-25, JIRA RPT-188
// Edited Catherine Warren, 2015-11-30, JIRA RPT-190
//

var startDate = p["start"];
var endDate = p["end"];
var siteId = p["site2"];
var period = p["period"];
var choose_promocode_or_not = p["choose_promocode_or_not"];

sum.push('number_redeemed');
sum.push('code_total');
sum.push('order_total');

var sqlProcessor = new SelectSQLBuilder();

if (notEmpty(period)) {
	if("day" == period) {
            sqlProcessor.setSelect("select to_char(pa.authDate,'yyyy-MM-DD') AS auth_period ");
            sqlProcessor.setGroupBy("group by to_char(pa.authDate,'yyyy-MM-DD') ");
            sqlProcessor.setOrderBy("order by to_char(pa.authDate,'yyyy-MM-DD') ");
	} if("Month" == period) {
            sqlProcessor.setSelect("select to_char(pa.authDate,'yyyy-MM') AS auth_period ");
            sqlProcessor.setGroupBy("group by to_char(pa.authDate,'yyyy-MM') ");
            sqlProcessor.setOrderBy("order by to_char(pa.authDate,'yyyy-MM') ");
	} 
} else {
    sqlProcessor.setSelect("select '' AS auth_period ");
    sqlProcessor.setGroupBy("group by auth_period ");
    sqlProcessor.setOrderBy("order by auth_period ");
}

sqlProcessor.appendSelect("p.promotion_id, p.name AS promotion_name, COALESCE(p.promotionCode,' ') as code, COALESCE(p.promotion_cost,0.00) AS promotion_cost ");
sqlProcessor.appendSelect("count(*) AS number_redeemed, count(*) * COALESCE(p.promotion_cost,0.00) AS code_total, sum(coalesce(pa.amount,0.00)) AS order_total, (sum(coalesce(pa.amount,0.00)) / count(*)) as promo_avg_order_total ");
sqlProcessor.setFrom("from ecommerce.Promotion as p, ecommerce.OrderPromotion as op, ecommerce.PaymentAuthorization as pa ");
sqlProcessor.setWhere("where op.order_id = pa.order_id");
sqlProcessor.appendWhere("p.promotion_id = op.promotion_id");
sqlProcessor.appendWhere("pa.payment_transaction_result_id = 1 and pa.payment_status_id in (3,5,6)");

if (notEmpty(startDate)) {
    sqlProcessor.appendWhere("pa.authDate >= '" + startDate + "'");
}

if (notEmpty(endDate)) {
   sqlProcessor.appendWhere("pa.authDate < '" + endDate + "'");
}

if("ignoreAll" == siteId) {

} else if("showAll" == siteId) {

} else if (notEmpty(siteId)) {
    sqlProcessor.appendFrom("ecommerce.rsorder as o");
    sqlProcessor.appendWhere("o.oid = pa.order_id and o.oid = op.order_id");
    sqlProcessor.appendWhere("o.site_id = " + siteId);
}

if (choose_promocode_or_not == "AllPromotions") {
    sqlProcessor.appendOrderBy("COALESCE(p.promotionCode, ' ') ");
    sqlProcessor.appendGroupBy("p.promotionCode ");
} if (choose_promocode_or_not == "PromotionsWithCode") {
    sqlProcessor.appendWhere("p.promotionCode IS NOT NULL ");
    sqlProcessor.appendOrderBy("p.promotionCode ");
    sqlProcessor.appendGroupBy("p.promotionCode ");
} if (choose_promocode_or_not == "PromotionsWithNoCode") {
    sqlProcessor.appendWhere("p.promotionCode IS NULL ");
    sqlProcessor.appendOrderBy("p.promotionCode ");
    sqlProcessor.appendGroupBy("p.promotionCode ");
}

sqlProcessor.appendGroupBy("p.promotion_id, p.name, COALESCE(p.promotion_cost,0.00), COALESCE(p.promotion_cost,0)");


sql = sqlProcessor.queryString();