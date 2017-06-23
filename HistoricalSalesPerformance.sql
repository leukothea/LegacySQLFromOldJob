//
// Historical Sales Performance - Sales Report
// Revised Catherine Warren 2016-12-14 | JIRA RPT-196
//

var startDate = p["start"];
//sum.push('run_count');
//weightedAverage['avg_unit_price']='run_count';

var sqlProcessor = new SelectSQLBuilder();

sqlProcessor.setSelect("SELECT authdd.weekday_abv AS day_of_week");
sqlProcessor.appendSelect("to_char(authdd.system_date::DATE,'YYYY/MM/DD') AS sale_date");
sqlProcessor.appendSelect("1-ABS(SIGN(authdd.julian_day_num - to_char(now(), 'j')::INT)) AS is_today");
sqlProcessor.appendSelect("count(*) as sale_count");
sqlProcessor.appendSelect("sum(osf.payment_amount) as sale_amount");
sqlProcessor.setFrom("FROM (sales_data_mart.order_sales_fact osf INNER JOIN dimension.date_dim authdd ON osf.date_key = authdd.julian_day_num) INNER JOIN sales_data_mart.order_dim odim ON osf.order_key = odim.order_key");
sqlProcessor.setWhere("WHERE authdd.system_date::DATE >= ('" + startDate + "'::DATE - interval '1 year')::DATE");
sqlProcessor.appendWhere("authdd.system_date::DATE > now()::DATE - interval '32 days'");
sqlProcessor.setGroupBy("GROUP BY authdd.weekday_abv");
sqlProcessor.appendGroupBy("to_char(authdd.system_date::DATE,'YYYY/MM/DD')");
sqlProcessor.appendGroupBy("1-ABS(SIGN(authdd.julian_day_num - to_char(now(), 'j')::INT))");
sqlProcessor.setOrderBy("ORDER BY sum(osf.payment_amount) desc");

sql = sqlProcessor.queryString();

