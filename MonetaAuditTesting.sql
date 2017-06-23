sql += " ,skuc.skuAverageCost as skuWeightedAverageCost ";

sql += " left outer join skucalc skuc on sd.skuId = skuc.sku_id "


sql += " SELECT ";
sql += " sku_id ";
sql += " ,null::date as skuReorderDate ";
sql += " ,null::float as skuReorderAge ";
sql += " ,null::float as skuPrice ";
sql += " ,null::float as skuAverageCost ";
sql += " ,null::integer as skuSoldAsSingles ";
sql += " ,null::float as skuInitialCost ";
sql += " ,null::float as skuCurrentCost ";
sql += " INTO ";
sql += " temporary table skucalc from ";
sql += " ecommerce.sku; ";

sql += " UPDATE ";
sql += " skucalc as sca ";
sql += " SET ";
sql += " skuCurrentCost = scc.price  ";
sql += " FROM ";
sql += " skuccost as scc ";
sql += " WHERE ";
sql += " scc.sku_id = sca.sku_id ";
sql += " and sca.skuCurrentCost is null; ";

sql += " SELECT ";
sql += " s.sku_id ";
sql += " ,max(ii.merchantPrice) as cost  ";
sql += " INTO ";
sql += " temporary table skuinitcost ";
sql += " FROM ";
sql += " (SELECT ";
sql += "  s.sku_id ";
sql += "  ,min(ii.dateRecordAdded) as dra ";
sql += " FROM ";
sql += "  ecommerce.SKU s ";
sql += "  ,ecommerce.RSInventoryItem ii ";
sql += "  ,ecommerce.ProductVersionSKU pvs ";
sql += " WHERE ";
sql += "  s.sku_id = ii.sku_id ";
sql += "  and s.sku_id = pvs.sku_id  ";
sql += "  and s.skuBitMask & 1 = 1  ";
sql += "  and ii.merchantPrice > 0 ";
sql += " GROUP BY ";
sql += "  s.sku_id ";
sql += " ) as dra ";
sql += " ,ecommerce.SKU as s ";
sql += " ,ecommerce.RSInventoryItem as ii ";
sql += " ,ecommerce.ProductVersionSKU as pvs ";
sql += " WHERE ";
sql += " s.sku_id = ii.sku_id ";
sql += " and s.sku_id = pvs.sku_id ";
sql += " and s.skuBitMask & 1 = 1 ";
sql += " and dra.sku_id = ii.sku_id ";
sql += " and dra.dra = ii.dateRecordAdded  ";
sql += " and ii.merchantPrice > 0 ";
sql += " GROUP BY ";
sql += " s.sku_id; ";

sql += " UPDATE ";
sql += " skucalc as sca ";
sql += " SET ";
sql += " skuInitialCost = sic.cost  ";
sql += " FROM ";
sql += " skuinitcost as sic ";
sql += " WHERE ";
sql += " sic.sku_id = sca.sku_id ";
sql += " and sca.skuInitialCost is null; ";

sql += " SELECT ";
sql += " pvsku.sku_id ";
sql += " ,count(*) as components ";
sql += " INTO ";
sql += " temporary table skusas ";
sql += " FROM ";
sql += " ecommerce.ProductVersionSKU as pvsku ";
sql += " GROUP BY ";
sql += " sku_id; ";

sql += " UPDATE ";
sql += " skucalc as sca ";
sql += " SET ";
sql += " skuSoldAsSingles = sas.components  ";
sql += " FROM ";
sql += " skusas as sas ";
sql += " WHERE ";
sql += " sas.sku_id = sca.sku_id ";
sql += " and sca.skuSoldAsSingles is null; ";

sql += " SELECT ";
sql += " source_id as sku_id ";
sql += " ,min(customerprice) as price ";
sql += " INTO ";
sql += " temporary table skuprice ";
sql += " FROM ";
sql += " ecommerce.price ";
sql += " WHERE ";
sql += " pricetype_id = 1 ";
sql += " and sourceclass_id = 13  ";
sql += " and customerprice > 0 ";
sql += " GROUP BY ";
sql += " source_id; ";

sql += " UPDATE ";
sql += " skucalc as sca ";
sql += " SET ";
sql += " skuPrice = sp.price ";
sql += " FROM ";
sql += " skuprice as sp ";
sql += " WHERE ";
sql += " sp.sku_id = sca.sku_id ";
sql += " and sca.skuPrice is null; ";

sql += " UPDATE ";
sql += " skucalc as sca ";
sql += " SET ";
sql += " skuAverageCost = sac.cost ";
sql += " FROM ";
sql += " skuac as sac ";
sql += " WHERE ";
sql += " sac.sku_id = sca.sku_id ";
sql += " and sca.skuAverageCost is null; ";





//Put a sku placeholder into temp table
sql += " SELECT ";
sql += " sku_id ";
sql += " ,null::timestamp as reorder_date ";
sql += " INTO ";
sql += " temporary table reorderage ";
sql += " FROM ";
sql += " ecommerce.sku; ";
// Query returned successfully: 110944 rows affected, 68 ms execution time.

//Put the max receiving event date for each PO lineitem SKU into a temp table
sql += " SELECT ";
sql += " poli.sku_id,max(re.receiveddate) as reorder_date ";
sql += " INTO ";
sql += " temporary table retemp0 ";
sql += " FROM ";
sql += " ecommerce.purchaseorderlineitem poli ";
sql += " ,ecommerce.receivingevent as re  ";
sql += " WHERE ";
sql += " poli.poLineItem_id = re.poLineItem_id ";
sql += " GROUP BY ";
sql += " poli.sku_id; ";
// Query returned successfully: 72798 rows affected, 386 ms execution time.

//update missing values reorderage temp table with retemp0 values
sql += " UPDATE ";
sql += " reorderage ";
sql += " SET ";
sql += " reorder_date = retemp0.reorder_date  ";
sql += " FROM ";
sql += " retemp0  ";
sql += " WHERE ";
sql += " reorderage.sku_id = retemp0.sku_id; ";
// Query returned successfully: 72798 rows affected, 260 ms execution time.

//Put the max receiving event date for each RSinventoryitem SKU into a temp table
sql += " SELECT ";
sql += " rsii.sku_id as skuid ";
sql += " ,max(re.receiveddate) as redate ";
sql += " INTO ";
sql += " temporary table retemp1 ";
sql += " FROM ";
sql += " ecommerce.rsinventoryitem as rsii ";
sql += " ,ecommerce.receivingevent as re  ";
sql += " WHERE ";
sql += " rsii.receivingevent_id = re.receivingevent_id group by ";
sql += " rsii.sku_id; ";
// Query returned successfully: 72663 rows affected, 433 ms execution time.

//update missing values in reorderage temp table with retemp1 values
sql += " UPDATE ";
sql += " reorderage ";
sql += " SET ";
sql += " reorder_date = redate ";
sql += " FROM ";
sql += " retemp1 ";
sql += " WHERE ";
sql += " sku_id = skuid ";
sql += " and reorder_date is null; ";
// Query returned successfully: 69 rows affected, 82 ms execution time.

//Put SKU initial launch date into a temp table
sql += " SELECT ";
sql += " sku_id as skuid ";
sql += " ,initialLaunchDate as redate ";
sql += " INTO ";
sql += " temporary table retemp4 ";
sql += " FROM ";
sql += " ecommerce.sku; ";
// Query returned successfully: 110944 rows affected, 83 ms execution time.


//update missing values in reorderage temp table with retemp4 values
sql += " UPDATE ";
sql += " reorderage ";
sql += " SET ";
sql += " reorder_date = redate ";
sql += " FROM ";
sql += " retemp4 ";
sql += " WHERE ";
sql += " sku_id = skuid ";
sql += " and reorder_date is null; ";
// Query returned successfully: 38077 rows affected, 133 ms execution time.

//Put SKU date record added into a temp table
sql += " SELECT ";
sql += " sku_id as skuid ";
sql += " ,daterecordadded as redate ";
sql += " INTO ";
sql += " temporary table retemp5 ";
sql += " FROM ";
sql += " ecommerce.sku; ";
// Query returned successfully: 110944 rows affected, 66 ms execution time.

//update missing values in reorderage temp table with retemp5 values
sql += " UPDATE ";
sql += " reorderage ";
sql += " SET ";
sql += " reorder_date = redate  ";
sql += " FROM ";
sql += " retemp5 ";
sql += " WHERE ";
sql += " sku_id = skuid ";
sql += " and reorder_date is null; ";
// Query returned successfully: 14674 rows affected, 83 ms execution time.

sql += " SELECT ";
sql += " sku_id ";
sql += " ,reorder_date::date as reorderDate ";
sql += " ,(now()::date - reorder_date::date)/365.0 as age ";
sql += " INTO  ";
sql += " temporary table skura  ";
sql += " FROM ";
sql += " reorderage; ";
// Query returned successfully: 110944 rows affected, 184 ms execution time.

"reorderage" now has 110,944 rows. Each SKU is represented once and only once. 





