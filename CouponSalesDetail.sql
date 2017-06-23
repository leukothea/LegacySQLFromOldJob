//
// Coupon Sales Detail Report
// Edited by Catherine Warren, 2015-07-27
//

var couponId = p["couponId"];
var sqlProcessor = new SelectSQLBuilder();

sqlProcessor.setSelect("select o.oid AS order_id, o.orderDate::DATE AS order_date, ptr.payment_transaction_result AS payment_result, pa.amount AS payment_amount, ps.payment_status AS payment_status");
sqlProcessor.setFrom("from ecommerce.RSOrder o,ecommerce.RSOrderCoupon co, ecommerce.rscoupon as c, ecommerce.PaymentAuthorization pa,ecommerce.payment_status ps,ecommerce.payment_transaction_result ptr");
sqlProcessor.setWhere("where o.oid = co.order_id and o.oid = pa.order_id and co.coupon_id = c.oid and co.order_id = pa.order_id and pa.payment_status_id = ps.payment_status_id and pa.payment_transaction_result_id = ptr.payment_transaction_result_id");
sqlProcessor.setOrderBy("order by o.orderDate");
sqlProcessor.appendWhere("c.code ILIKE '%" + couponId + "%' ");

sql = sqlProcessor.queryString();