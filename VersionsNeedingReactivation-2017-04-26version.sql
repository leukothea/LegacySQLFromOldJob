// 
// Versions Needing Reactivation
// Catherine Warren, 2016-06-07 | JIRA RPT-386
// Edited Catherine Warren, 2017-04-25&26 | JIRA RPT-655
// 

var disallow_familypet_items = p['disallow_familypet_items'];

count.push('VID');

// First, make a Common Table Expression to find all SKU IDs that are hooked up to a version. 

var groupedProcessor = new SelectSQLBuilder();

groupedProcessor.setSelect("select pvs.sku_id ");
groupedProcessor.setFrom("from ecommerce.productversionsku as pvs ");

// Then, make a query that will refer to the grouped SKU query, finding only Active, positive-quantity SKUs that are hooked up once-and-only-once to a version that is Inactive or Retired. 
// CharityUSA items only, and no promotional ones (based on Promo in the name). Finding only the SKUs that are hooked up to one-and-only-one version ensures that we will not be 
// overwhelmed with promotional version clutter, as we would otherwise be when looking for Retired versions. 

var sql1Processor = new SelectSQLBuilder();

sql1Processor.setSelect("select distinct s.sku_id, s.name as sku_name, sts.itemstatus as skuStatus, sum(ii.quantity) as total_quantity ");
sql1Processor.appendSelect("pv.productversion_id as version_id, pv.name as version_name, pstat.itemstatus as versionStatus ");
sql1Processor.appendSelect("i.item_id, i.name as item_name, its.itemstatus as item_status ");
sql1Processor.setFrom("from ecommerce.item as i, ecommerce.itemstatus as its, ecommerce.itemstatus as sts, ecommerce.itemstatus as pstat ");
sql1Processor.addCommonTableExpression("grouped", groupedProcessor);
sql1Processor.appendFrom("ecommerce.productversion as pv, ecommerce.productversionsku as pvs, ecommerce.sku as s, ecommerce.rsinventoryitem as ii, grouped ");
sql1Processor.setWhere("where i.item_id = pv.item_id and i.itemstatus_id = its.itemstatus_id and pv.productversion_id = pvs.productversion_id ");
sql1Processor.appendWhere("pv.itemstatus_id = pstat.itemstatus_id and pvs.sku_id = s.sku_id and s.itemstatus_id = sts.itemstatus_id and s.sku_id = ii.sku_id and s.sku_id = grouped.sku_id and s.skubitmask &1 = 1 and s.skubitmask &8 != 8");
sql1Processor.appendWhere("s.itemstatus_id = 0 and i.itemstatus_id in (0,1,5,8) and pv.itemstatus_id IN (1,5) and pv.initiallaunchdate is not null ");
sql1Processor.appendWhere("pv.productversion_id not in (select pvs.productversion_id from ecommerce.productversionsku as pvs,ecommerce.sku as s where pvs.sku_id = s.sku_id and s.itemstatus_id in (1,5,8)) ");
sql1Processor.appendWhere("pv.name NOT ILIKE '%Promo%' and i.vendor_id = 83 ");
sql1Processor.setGroupBy("group by s.sku_id, s.name, sts.itemstatus, pv.productversion_id, pv.name, pvs.quantity, pstat.itemstatus, i.item_id, i.name, its.itemstatus having (count(grouped.sku_id) = 1 and sum(ii.quantity) >= pvs.quantity) ");

// Then, make another query to find all CharityUSA active, positive-quantity SKUs that are attached to an inactive version. This query does not include retired versions, because
// they are already handled in sql1. If we included them here, we would be overwhelmed with promotional version clutter. Also suppress SKUs that are hooked up to versions that are
// also hooked up to a SKU that is Inactive, Retired, Canceled, or has Material Failure, since those verisons cannot be reactivated. 
// Also suppress SKUs 41267 and 35449, because those are chains. 

var sql2Processor = new SelectSQLBuilder();

sql2Processor.setSelect("select distinct s.sku_id, s.name as sku_name, sts.itemstatus as skuStatus, sum(ii.quantity) as total_quantity ");
sql2Processor.appendSelect("pv.productversion_id as version_id, pv.name as version_name, pstat.itemstatus as versionStatus ");
sql2Processor.appendSelect("i.item_id, i.name as item_name, its.itemstatus as item_status ");
sql2Processor.setFrom("from ecommerce.item as i, ecommerce.itemstatus as its, ecommerce.itemstatus as sts, ecommerce.itemstatus as pstat ");
sql2Processor.appendFrom("ecommerce.productversion as pv, ecommerce.productversionsku as pvs, ecommerce.sku as s, ecommerce.rsinventoryitem as ii ");
sql2Processor.setWhere("where i.item_id = pv.item_id and i.itemstatus_id = its.itemstatus_id and pv.productversion_id = pvs.productversion_id ");
sql2Processor.appendWhere("pv.itemstatus_id = pstat.itemstatus_id and pvs.sku_id = s.sku_id and s.itemstatus_id = sts.itemstatus_id and s.sku_id = ii.sku_id ");
sql2Processor.appendWhere("s.skubitmask &1 = 1 and s.skubitmask &8 != 8 and s.itemstatus_id = 0 and i.itemstatus_id in (0,1,5,8) and pv.itemstatus_id IN (1) and pv.initiallaunchdate is not null ");
sql2Processor.appendWhere("pv.productversion_id not in (select pvs.productversion_id from ecommerce.productversionsku as pvs,ecommerce.sku as s where pvs.sku_id = s.sku_id and s.itemstatus_id in (1,5,7,8)) ");
sql2Processor.appendWhere("pv.name NOT ILIKE '%Promo%' and i.vendor_id = 83 and s.sku_id NOT IN (41267, 35449) ");
sql2Processor.setGroupBy("group by s.sku_id, s.name, sts.itemstatus, pv.productversion_id, pv.name, pvs.quantity, pstat.itemstatus, i.item_id, i.name, its.itemstatus having sum(ii.quantity) >= pvs.quantity");

if (notEmpty(disallow_familypet_items)) {
    sql1Processor.appendWhere("pv.name NOT ILIKE 'FP%' ");
    sql2Processor.appendWhere("pv.name NOT ILIKE 'FP%' ");
}

// Finally, create query strings for both sql1 and sql2, join them, and query distinct records from them to find all the SKUs whose versions / items need to be reactivated. 

var sql1 = sql1Processor.queryString();

var sql2 = sql2Processor.queryString();

var sql = "SELECT DISTINCT * FROM (( " + sql1 + ") UNION (" + sql2 + " )) zzzz ORDER BY zzzz.total_quantity desc"