//
// Orders by Promotion Report
// Catherine Warren, 2015-10-26
//

var startDate = p["start"];
var endDate = p["end"];
var promoId = p["promotionId"];
var code = p["promotionCode"];
var siteId = p["site2"];
var showOrderSource = p["showOrderSource"];

sum.push('sale_amount');

var sqlProcessor = new SelectSQLBuilder();

sqlProcessor.setSelect("select o.oid as order_id, pa.authDate::DATE AS order_date ");
sqlProcessor.appendSelect("pt.payment_transaction_result as payment_result, ps.payment_status, p.promotion_id, p.name AS promotion_name, COALESCE(p.promotionCode,'') AS code, pa.amount AS sale_amount, si.name as site_name ");
sqlProcessor.setFrom("from ecommerce.rsorder as o, ecommerce.promotion as p, ecommerce.OrderPromotion as op, ecommerce.PaymentAuthorization as pa, ecommerce.payment_transaction_result as pt, ecommerce.payment_status as ps, ecommerce.site as si ");
sqlProcessor.setWhere("where o.oid = pa.order_id and o.oid = op.order_id and p.promotion_id = op.promotion_id and op.order_id = pa.order_id and pa.payment_transaction_result_id = pt.payment_transaction_result_id and pa.payment_status_id = ps.payment_status_id and o.site_id = si.site_id ");
sqlProcessor.appendWhere("pa.payment_transaction_result_id = 1 and pa.payment_status_id in (3,4,5,6)");
sqlProcessor.setOrderBy("order by p.promotionCode, pa.authDate::DATE");
if(notEmpty(promoId)) {
    sqlProcessor.appendWhere("p.promotion_id = " + promoId);
} else {
    if (code != null && !code.isEmpty()) {
       sqlProcessor.appendWhere("p.promotionCode ILIKE '" + code + "'");
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
  	if("ignoreAll" == siteId) {
		} 
    else if("showAll" == siteId) {
		}  
    else {
		sqlProcessor.appendWhere("o.site_id = " + siteId);
    	}
    }

sql = sqlProcessor.queryString();