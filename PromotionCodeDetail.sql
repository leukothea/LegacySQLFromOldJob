//
// Promotion Code Detail Report
// Edited Catherine Warren, 2015-12-11, JIRA RPT-129
//

var startDate = p["start"];
var endDate = p["end"];
var promoId = p["promotionId"];
var code = p["promotionCode"];
var siteId = p["site2"];
var showOrderSource = p["showOrderSource"];

sum.push('sale_amount');

var sqlProcessor = new SelectSQLBuilder();

sqlProcessor.setSelect("select pa.authDate::DATE AS auth_date");
sqlProcessor.appendSelect("p.promotion_id as promotion_id, p.name AS promotion_name, COALESCE(p.promotionCode,'') AS code");
sqlProcessor.appendSelect("pa.amount AS sale_amount, p.promotion_cost ");
sqlProcessor.setFrom("from ecommerce.Promotion as p, ecommerce.OrderPromotion as op, ecommerce.PaymentAuthorization as pa ");
sqlProcessor.setWhere("where p.promotion_id = op.promotion_id and op.order_id = pa.order_id ");
sqlProcessor.appendWhere("pa.payment_transaction_result_id = 1 and pa.payment_status_id in (3,5,6) ");
sqlProcessor.setOrderBy("order by p.promotionCode,pa.authDate::DATE ");
if(notEmpty(promoId)) {
    sqlProcessor.appendWhere("p.promotion_id = " + promoId);
} else {
    if (code != null && !code.isEmpty()) {
       sqlProcessor.appendWhere("p.promotionCode ILIKE '" + code + "%'");
    } else {
       sqlProcessor.appendWhere("p.promotionCode is null");
    }
}
if (notEmpty(startDate)) {
    sqlProcessor.appendWhere("pa.authDate >= '" + startDate + "'");
}
if (notEmpty(endDate)) {
    sqlProcessor.appendWhere("pa.authDate < '" + endDate + "'");
}
if (notEmpty(siteId)) {
    sqlProcessor.appendFrom("ecommerce.rsorder as o");
    sqlProcessor.appendWhere("o.oid = pa.order_id and o.oid = op.order_id");
}
if (notEmpty(showOrderSource)) {
   sqlProcessor.appendSelect("st.name as store_name");
   sqlProcessor.appendSelect("os.order_source as order_source");
   if (notEmpty(siteId)) {
       //do nothing because rsorder reference is already added
   } else {
       sqlProcessor.appendFrom("ecommerce.rsorder as o");
       sqlProcessor.appendWhere("o.oid = pa.order_id and o.oid = op.order_id");
   }
   sqlProcessor.appendFrom("ecommerce.store st");
   sqlProcessor.appendFrom("ecommerce.order_source os");
   sqlProcessor.appendWhere("o.store_id = st.store_id");
   sqlProcessor.appendWhere("o.order_source_id = os.order_source_id");
   //sqlProcessor.appendGroupBy("s.name,os.order_source");
} else {
	hide.push("store_name");
	hide.push("order_source");
}
if ("ignoreAll" == siteId) {
	hide.push("site_name");
} else { // it's for a specific site or for all sites
   sqlProcessor.appendFrom("ecommerce.site s");
   sqlProcessor.appendWhere("o.site_id = s.site_id");
   sqlProcessor.appendSelect("COALESCE(s.name,'no name available') AS site_name");
   //sqlProcessor.appendGroupBy("COALESCE(s.name,'no name available')");
}
if ("showAll" != siteId && "ignoreAll" != siteId) {
   sqlProcessor.appendWhere("o.site_id = " + siteId);
}

sql = sqlProcessor.queryString();