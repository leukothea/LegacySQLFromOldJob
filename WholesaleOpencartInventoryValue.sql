//
// Wholesale Opencart - Inventory Value
// Catherine Warren
// 2015-10-01
// Revised 2015-10-10 to add column for bads
// Revising 2015-10-23 to add column for Total Sold
//

var year = p["wholesale_year"];
if(! notEmpty(year)){ year = "2";}

var lineItemProcessor = new SelectSQLBuilder();

lineItemProcessor.setSelect("select sum(pov.vendor_cost * op.quantity) as ws_returns_for_restock, o.date_added as sales_date ");
lineItemProcessor.setFrom("from opencart.order_product as op, opencart.`order` as o, opencart.product_option_value as pov ");
lineItemProcessor.setWhere("where op.order_id = o.order_id and op.model2 = pov.model and o.return_flag = 'YES' and op.restocked = 'YES' and not o.order_status_id = 18 ");
lineItemProcessor.appendWhere("YEAR(o.date_added) like '%" + year + "'");
lineItemProcessor.setGroupBy("group by YEAR(o.date_added), MONTH(o.date_added) ");
lineItemProcessor.setOrderBy("order by YEAR(o.date_added) desc, MONTH(o.date_added) desc ");

var badsProcessor = new SelectSQLBuilder();

badsProcessor.setSelect("select sum(b.qty * pov2.vendor_cost) as ws_bads, b.timestamp as bads_date ");
badsProcessor.setFrom("from opencart.bads as b, opencart.product_option_value as pov2 ");
badsProcessor.setWhere("where b.product_id = pov2.product_option_value_id ");
badsProcessor.appendWhere("YEAR(b.timestamp) like '%" + year + "'");
badsProcessor.setGroupBy("group by YEAR(b.timestamp), MONTH(b.timestamp) ");
badsProcessor.setOrderBy("order by YEAR(b.timestamp) desc, MONTH(b.timestamp) desc ");

var sqlProcessor = new SelectSQLBuilder();

sqlProcessor.setSelect("select si.id as ws_inventory_start_id, si.amount as ws_inventory_amount, si.timestamp as ws_timestamp, si.adjustment as ws_inventory_adjustment, sum(pop.qty_received * pop.cost) as ws_total_received ");
sqlProcessor.setFrom("from opencart.start_inventory as si, opencart.purchase_orders_products as pop ");
sqlProcessor.setWhere("where YEAR(si.timestamp) = YEAR(pop.date_received) and MONTH(si.timestamp) = MONTH(pop.date_received) ");

sqlProcessor.appendWhere("YEAR(si.timestamp) like '%" + year + "'");
sqlProcessor.appendWhere("YEAR(pop.date_received) like '%" + year + "'");

sqlProcessor.appendSelect("sales.ws_returns_for_restock ");
sqlProcessor.appendRelationToFromWithAlias(lineItemProcessor, "sales");
sqlProcessor.appendWhere("YEAR(si.timestamp) = YEAR(sales_date) ");
sqlProcessor.appendWhere("MONTH(si.timestamp) = MONTH(sales_date) ");

sqlProcessor.appendSelect("ws_bads.ws_bads ");
sqlProcessor.appendRelationToFromWithAlias(badsProcessor, "ws_bads");
sqlProcessor.appendWhere("YEAR(si.timestamp) = YEAR(bads_date) ");
sqlProcessor.appendWhere("MONTH(si.timestamp) = MONTH(bads_date) ");

sqlProcessor.setGroupBy("group by YEAR(si.timestamp), MONTH(si.timestamp) ");
sqlProcessor.setOrderBy("order by YEAR(si.timestamp) desc, MONTH(si.timestamp) desc ");

average.push('ws_inventory_amount');
average.push('ws_inventory_adjustment');
average.push('ws_total_received');
average.push('ws_returns_for_restock');
average.push('ws_bads');

sql = sqlProcessor.queryString();