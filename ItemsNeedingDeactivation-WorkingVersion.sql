// 
// Items Needing Deactivation 
// Catherine Warren, 2016-06-14 | JIRA RPT-392
// 

var sumProcessor = new SelectSQLBuilder();

count.push('item_id');

sumProcessor.setSelect("select ii.sku_id, COALESCE(sum(ii.quantity),0) as quantity ");
sumProcessor.setFrom("from ecommerce.sku as s, ecommerce.rsinventoryitem as ii ");
sumProcessor.setWhere("where ii.sku_id = s.sku_id");
sumProcessor.setGroupBy("group by ii.sku_id ");

var skudataProcessor = new SelectSQLBuilder();

skudataProcessor.setSelect("select s.item_id, sum(sum.quantity) as quantity ");
skudataProcessor.addCommonTableExpression("sum",sumProcessor);
skudataProcessor.setFrom("from ecommerce.sku as s LEFT OUTER JOIN sum ON s.sku_id = sum.sku_id ");
skudataProcessor.setWhere("where s.skubitmask & 1 = 1 ");
skudataProcessor.setGroupBy("group by s.item_id having sum(sum.quantity) = 0 ");

var sqlProcessor = new SelectSQLBuilder();

sqlProcessor.setSelect("select distinct i.item_id, i.name as item_name, st.itemstatus as item_status, skudata.quantity ");
sqlProcessor.addCommonTableExpression("skudata",skudataProcessor);
sqlProcessor.setFrom("from ecommerce.item as i LEFT OUTER JOIN skudata ON i.item_id = skudata.item_id, ecommerce.itemstatus as st ");
sqlProcessor.setWhere("where i.itemstatus_id = st.itemstatus_id and i.itemstatus_id = 0 and skudata.quantity = 0 and i.itembitmask & 32 != 32 and i.itembitmask & 256 != 256 and i.name NOT ILIKE 'Extra Donation%' ");
sqlProcessor.setOrderBy("order by i.item_id asc ");

sql = sqlProcessor.queryString();