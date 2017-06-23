// 
// Number of Customers Report
// Just what it says on the tin! 
// Catherine Warren, 2015-12-10, just for fun
// 

var sqlProcessor = new SelectSQLBuilder();

sqlProcessor.setSelect("select count(distinct a.account_id) as data ");
sqlProcessor.setFrom("from pheme.account as a, ecommerce.rsorder as o, ecommerce.paymentauthorization as pa ");
sqlProcessor.setWhere("where a.account_id = o.account_id and o.oid = pa.order_id and pa.payment_transaction_result_id = 1 and pa.payment_status_id in (3, 4, 5) ");

sql = sqlProcessor.queryString();