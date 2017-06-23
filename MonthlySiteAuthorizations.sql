//
// Monthly Site Authorizations Report
// Edited Catherine Warren, 2016-01-04 - JIRA RPT-203
//

var year = p["siteAuthYear"];
if(! notEmpty(year)){ year = "2";}
var sqlProcessor = new SelectSQLBuilder();

sum.push('ths');
sum.push('trs');
sum.push('bcs');
sum.push('ars');
sum.push('chs');
sum.push('ms');
sum.push('prs');
sum.push('ggf');
sum.push('vet');
sum.push('aut');
sum.push('lit');
sum.push('hfl');
sum.push('dbs');
sum.push('alz');
sum.push('jg');
sum.push('ck');
sum.push('sb');
sum.push('total_sales');

sqlProcessor.setSelect("select to_char(pa.authdate::DATE,'YYYY-MM') as month");
sqlProcessor.appendSelect("cast(SUM(pa.amount * (1 - ABS(SIGN(ma.site_id - 220)))) AS numeric(9,2)) as ths");
sqlProcessor.appendSelect("cast(SUM(pa.amount * (1 - ABS(SIGN(ma.site_id - 221)))) AS numeric(9,2)) as trs");
sqlProcessor.appendSelect("cast(SUM(pa.amount * (1 - ABS(SIGN(ma.site_id - 224)))) AS numeric(9,2)) as bcs");
sqlProcessor.appendSelect("cast(SUM(pa.amount * (1 - ABS(SIGN(ma.site_id - 310)))) AS numeric(9,2)) as ars");
sqlProcessor.appendSelect("cast(SUM(pa.amount * (1 - ABS(SIGN(ma.site_id - 314)))) AS numeric(9,2)) as chs");
sqlProcessor.appendSelect("cast(SUM(pa.amount * (1 - ABS(SIGN(ma.site_id - 342)))) AS numeric(9,2)) as ms");
sqlProcessor.appendSelect("cast(SUM(pa.amount * (1 - ABS(SIGN(ma.site_id - 343)))) AS numeric(9,2)) as prs");
sqlProcessor.appendSelect("cast(SUM(pa.amount * (1 - ABS(SIGN(ma.site_id - 344)))) AS numeric(9,2)) as ggf");
sqlProcessor.appendSelect("cast(SUM(pa.amount * (1 - ABS(SIGN(ma.site_id - 345)))) AS numeric(9,2)) as vet");
sqlProcessor.appendSelect("cast(SUM(pa.amount * (1 - ABS(SIGN(ma.site_id - 346)))) AS numeric(9,2)) as aut");
sqlProcessor.appendSelect("cast(SUM(pa.amount * (1 - ABS(SIGN(ma.site_id - 2001)))) AS numeric(9,2)) as lit");
sqlProcessor.appendSelect("cast(SUM(pa.amount * (1 - ABS(SIGN(ma.site_id - 347)))) AS numeric(9,2)) as hfl");
sqlProcessor.appendSelect("cast(SUM(pa.amount * (1 - ABS(SIGN(ma.site_id - 348)))) AS numeric(9,2)) as dbs");
sqlProcessor.appendSelect("cast(SUM(pa.amount * (1 - ABS(SIGN(ma.site_id - 349)))) AS numeric(9,2)) as alz");
sqlProcessor.appendSelect("cast(SUM(pa.amount * (1 - ABS(SIGN(ma.site_id - 350)))) AS numeric(9,2)) as jg");
sqlProcessor.appendSelect("cast(SUM(pa.amount * (1 - ABS(SIGN(ma.site_id - 351)))) AS numeric(9,2)) as ck");
sqlProcessor.appendSelect("cast(SUM(pa.amount * (1 - ABS(SIGN(ma.site_id - 352)))) AS numeric(9,2)) as sb");
sqlProcessor.appendSelect("cast(SUM(pa.amount) AS numeric(10,2)) as total_sales");
sqlProcessor.setFrom("from ecommerce.rsorder as o,ecommerce.paymentauthorization as pa, ecommerce.merchantaccount as ma,ecommerce.site as s");
sqlProcessor.setWhere("where o.oid = pa.order_id and pa.merchantaccount_id = ma.merchantaccount_id and ma.site_id = s.site_id");
switch (year) {
    case "1":
        sqlProcessor.appendWhere("pa.authdate >= now() - cast('1 year' as interval)");
        break;
    case "2":
        sqlProcessor.appendWhere("pa.authdate >= date_trunc('month',now()::DATE) - cast('2 year' as interval)");
        break;
    case "10":
        sqlProcessor.appendWhere("pa.authdate >= date_trunc('month',now()::DATE) - cast('10 year' as interval)");
        break;
    default:
        sqlProcessor.appendWhere("date_part('year',pa.authdate) = " + year);
}
sqlProcessor.appendWhere("pa.payment_transaction_result_id = 1 and pa.payment_status_id in (3,5,6)");
sqlProcessor.setGroupBy("group by to_char(pa.authdate::DATE,'YYYY-MM')");
sqlProcessor.setOrderBy("order by to_char(pa.authdate::DATE,'YYYY-MM')");

sql = sqlProcessor.queryString();