//
// Wholesale Opencart - Gross Numbers
// Catherine Warren
// 2015-09-29 & 30
//


var year = p["wholesale_year"];
if(! notEmpty(year)){ year = "2";}
var sqlProcessor = new SelectSQLBuilder();

sum.push('total_sales');

sqlProcessor.setSelect("select YEAR(o.date_added) as 'year', MONTH(o.date_added) as 'month', MONTHNAME(o.date_added) as 'month_name', sum(op.price * op.quantity) as total_sales ");
sqlProcessor.setFrom("from opencart.order as o, opencart.order_product as op ");
sqlProcessor.setWhere("where o.order_id = op.order_id and (o.return_flag is null or o.return_flag = '') and not o.order_status_id = 18 ");

sqlProcessor.appendWhere("YEAR(o.date_added) like '%" + year + "'");
//sqlProcessor.appendWhere("MONTH(o.date_added) = " + month);

sqlProcessor.setGroupBy("group by YEAR(o.date_added), MONTH(o.date_added) ");
sqlProcessor.setOrderBy("order by year desc,month desc ");

sql = sqlProcessor.queryString();