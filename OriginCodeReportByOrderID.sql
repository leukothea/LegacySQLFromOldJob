// 
// Origin Code Report by Order ID
// In Progress by Catherine Warren, 2015-07-14
// 

var order_id = p["order_id"];


var sqlProcessor = new SelectSQLBuilder();

sqlProcessor.setSelect("select o.oid as order_id, st.name as store_name, si.name as site_name, o.origincode as origin_code, o.linkshare_site_id, o.client_ip_address, s.order_source, pt.payment_transaction_result as payment_result, ps.payment_status, pa.authdate as auth_date ");
sqlProcessor.setFrom("from ecommerce.rsorder as o, ecommerce.store as st, ecommerce.site as si, ecommerce.paymentauthorization as pa, ecommerce.payment_transaction_result as pt, ecommerce.payment_status as ps, ecommerce.order_source as s ");
sqlProcessor.setWhere("where o.oid = pa.order_id and o.store_id = st.store_id and o.site_id = si.site_id and o.order_source_id = s.order_source_id and pa.payment_transaction_result_id = pt.payment_transaction_result_id and pa.payment_status_id = ps.payment_status_id and pa.payment_transaction_result_id = 1 ");

if (notEmpty (order_id)) {
  sqlProcessor.appendWhere ("o.oid IN (" + order_id  + ")" );
}

sqlProcessor.setOrderBy("order by o.oid ");

sql = sqlProcessor.queryString();