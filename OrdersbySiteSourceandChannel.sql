//
// Orders by Site, Source, and Channel
// Catherine Warren, 2015-09-21
// 

var startDate = p["start"];
var endDate = p["end"];
var site = p["site4"];
var store_name = p["store_name"];
var order_source = p["orderSource"];
var show_tracking_numbers = p["show_tracking_numbers"];

var sqlProcessor = new SelectSQLBuilder();

sqlProcessor.setSelect("select o.oid as order_id, pa.authdate as auth_date, pt.payment_transaction_result as payment_result, ps.payment_status, si.name as site_name, s.name as store_name, os.order_source as order_source, na.amazon_id as amazon_order_id, na.novica_id as novica_order_id, osh.shipdate as ship_date ");
sqlProcessor.setFrom("from ecommerce.rsorder as o, ecommerce.paymentauthorization as pa, ecommerce.payment_transaction_result as pt, ecommerce.payment_status as ps , ecommerce.site as si, ecommerce.store as s, ecommerce.order_source as os, ecommerce.novica_identity as na, ecommerce.ordershipment as osh ");
sqlProcessor.setWhere("where o.oid = pa.order_id and o.store_id = s.store_id and o.site_id = si.site_id and o.order_source_id = os.order_source_id and pa.payment_transaction_result_id = pt.payment_transaction_result_id and pa.payment_status_id = ps.payment_status_id and na.source_id = o.oid and osh.order_id = o.oid and na.sourceclass_id = 24 and pa.payment_transaction_result_id = 1 and pa.payment_status_id in (3,4,5,6) ");
sqlProcessor.setOrderBy("order by o.oid desc ");

if (notEmpty(startDate)) {
        sqlProcessor.appendWhere("pa.authDate >= '" + startDate + "'");
    } else {
        sqlProcessor.appendWhere("pa.authDate::DATE >= date_trunc('month',now()::DATE)");
    }
if (notEmpty(endDate)) {
        sqlProcessor.appendWhere("pa.authDate < '" + endDate + "'");
    }

if (notEmpty (site)) {
        sqlProcessor.appendWhere("si.site_id = " + site );
}

if (notEmpty (store_name)) {
        sqlProcessor.appendWhere("s.store_id = " + store_name );
}

if (notEmpty (order_source)) {
        sqlProcessor.appendWhere("os.order_source_id = " + order_source );
}

if (notEmpty (show_tracking_numbers)) {
        sqlProcessor.appendSelect("tr.trackingnumber as tracking_number ");
        sqlProcessor.appendFrom("ecommerce.ordershipment as tr ");
        sqlProcessor.appendWhere("tr.order_id = o.oid ");
}

else {
    		hide.push('tracking_number');
		}

sql = sqlProcessor.queryString();