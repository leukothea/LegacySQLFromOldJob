//
// Moneta SKU Inventory Report
// Edited Catherine Warren, 2016-04-20 | JIRA RPT-318
//

var SkuCategory1 = p["skuCategory1"];
var SkuCategory2 = p["skuCategory2"];
var SkuCategory3 = p["skuCategory3"];
var SkuCategory4 = p["skuCategory4"];
var SkuCategory5 = p["skuCategory5"];
var SkuCategory6 = p["skuCategory6"];
var SkuStatus = p["skuStatus"];
var SkuBuyer = p["buyer"];
var SkuId = p["sku_id"];
var SkuName = p["sku_name"];
var countryCode = p["countryOfOrigin"];
var SkuFamilyVendor = p["skuFamilyVendor2"];
var SkuSupplierNames = p["skuSupplierNames"];

if( SkuCategory1 == "All" ){ SkuCategory1 = ""; }
if( SkuCategory2 == "All" ){ SkuCategory2 = ""; }
if( SkuCategory3 == "All" ){ SkuCategory3 = ""; }
if( SkuCategory4 == "All" ){ SkuCategory4 = ""; }
if( SkuCategory5 == "All" ){ SkuCategory5 = ""; }
if( SkuCategory6 == "All" ){ SkuCategory6 = ""; }
if( countryCode == "All" ){ countryCode = ""; }

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

sql += " SELECT ";
sql += " s.sku_id  ";
sql += " ,max(ii.dateRecordAdded) as dra ";
sql += " INTO ";
sql += " temporary table tempskudra ";
sql += " FROM ";
sql += " ecommerce.SKU s ";
sql += " ,ecommerce.RSInventoryItem ii ";
sql += " ,ecommerce.ProductVersionSKU pvs ";
sql += " WHERE ";
sql += " s.sku_id = ii.sku_id ";
sql += " and s.sku_id = pvs.sku_id and s.skuBitMask & 1 = 1 and ii.merchantPrice > 0 ";
sql += " GROUP BY ";
sql += " s.sku_id; ";

sql += " SELECT ";
sql += " s.sku_id ";
sql += " ,max(ii.merchantPrice) as price ";
sql += " INTO ";
sql += " temporary table skuccost ";
sql += " FROM ";
sql += " tempskudra as dra ";
sql += " ,ecommerce.SKU as s  ";
sql += " ,ecommerce.RSInventoryItem as ii  ";
sql += " ,ecommerce.ProductVersionSKU as pvs ";
sql += " WHERE ";
sql += " s.sku_id = ii.sku_id ";
sql += " and s.sku_id = pvs.sku_id ";
sql += " and s.skuBitMask & 1 = 1 ";
sql += " and dra.sku_id = ii.sku_id ";
sql += " and dra.dra = ii.dateRecordAdded and ii.merchantPrice > 0 ";
sql += " GROUP BY ";
sql += " s.sku_id; ";

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

sql += " SELECT ";
sql += " sku_id ";
sql += " ,sum(quantity * merchantPrice) / sum(quantity) as cost ";
sql += " INTO ";
sql += " temporary table skuac ";
sql += " FROM ";
sql += " ecommerce.RSInventoryItem ";
sql += " WHERE ";
sql += " quantity > 0 ";
sql += " and merchantPrice > 0  ";
sql += " and sku_id is not null ";
sql += " GROUP BY ";
sql += " sku_id; ";

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

//update missing values reorderage temp table with retemp0 values
sql += " UPDATE ";
sql += " reorderage ";
sql += " SET ";
sql += " reorder_date = retemp0.reorder_date  ";
sql += " FROM ";
sql += " retemp0  ";
sql += " WHERE ";
sql += " reorderage.sku_id = retemp0.sku_id; ";

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

//Put SKU initial launch date into a temp table
sql += " SELECT ";
sql += " sku_id as skuid ";
sql += " ,initialLaunchDate as redate ";
sql += " INTO ";
sql += " temporary table retemp4 ";
sql += " FROM ";
sql += " ecommerce.sku; ";

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

//Put SKU date record added into a temp table
sql += " SELECT ";
sql += " sku_id as skuid ";
sql += " ,daterecordadded as redate ";
sql += " INTO ";
sql += " temporary table retemp5 ";
sql += " FROM ";
sql += " ecommerce.sku; ";

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

sql += " SELECT ";
sql += " sku_id ";
sql += " ,reorder_date::date as reorderDate ";
sql += " ,(now()::date - reorder_date::date)/365.0 as age ";
sql += " INTO  ";
sql += " temporary table skura  ";
sql += " FROM ";
sql += " reorderage; ";

sql += " UPDATE ";
sql += " skucalc as sca ";
sql += " SET ";
sql += " skuReorderDate = sra.reorderDate ";
sql += " ,skuReorderAge = sra.age ";
sql += " FROM ";
sql += " skura as sra ";
sql += " WHERE ";
sql += " sra.sku_id = sca.sku_id; ";

sql += " select ";
sql += " s.sku_id as skuId ";
sql += " ,sum(ii.quantity) as skuQuantity ";
sql += " ,min(ii.merchantPrice) as skuLowerOfCost ";
sql += " ,max(coalesce(ii.weight,0.0)) as skuWeight ";
sql += " ,string_agg(distinct sup.supplierName,'|') as skuSuppliers ";
sql += " ,s.partnumber as supplier_part_number ";
sql += " INTO temporary table skudata ";
sql += " FROM ";
sql += "  ecommerce.SKU as s ";
sql += " ,ecommerce.RSInventoryItem as ii  ";
sql += " ,ecommerce.Supplier sup ";
sql += " WHERE ";
sql += " s.sku_id = ii.sku_id ";
sql += " and ii.active=true ";
sql += " and s.skuBitMask & 1 = 1 ";
sql += " and ii.supplier_id = sup.supplier_id ";
sql += " group by ";
sql += " s.sku_id; ";

sql += " select  ";
sql += " sku.item_id as skuFamilyId ";
sql += " ,i.name as skuFamilyName ";
sql += " ,i.itemStatus_id as skuFamilyStatusId  ";
sql += " ,istB.itemStatus as skuFamilyStatus ";
sql += " ,v.name as skuFamilyVendor ";
sql += " ,sku.sku_id as skuId ";
sql += " ,ist.itemStatus as skuStatus ";
sql += " ,CASE WHEN sku.skuBitMask & 1 = 1 THEN 1 ELSE 0 END as tracksInventory ";
sql += " ,sku.name as skuName ";
sql += " ,sku.isoCountryCodeOfOrigin as countryCode ";
sql += " ,ist.itemStatus  ";
sql += " ,skucat.buyer as skuBuyer ";
sql += " ,sku.partnumber as partnumber ";
sql += " ,skucat.skucategory1 ";
sql += " ,skucat.skucategory2 ";
sql += " ,skucat.skucategory3 ";
sql += " ,skucat.skucategory4 ";
sql += " ,skucat.skucategory5 ";
sql += " ,skucat.skucategory6 ";
sql += " ,sc.sku_class ";
sql += " INTO ";
sql += " temporary table skudetails ";
sql += " FROM ";
sql += " ecommerce.SKU as sku ";
sql += " left outer join ecommerce.skucategory skucat on skucat.sku_id = sku.sku_id ";
sql += " ,ecommerce.ItemStatus as ist ";
sql += " ,ecommerce.sku_class as sc  ";
sql += " ,ecommerce.Item i ";
sql += " ,ecommerce.ItemStatus istB ";
sql += " ,ecommerce.vendor v ";
sql += " WHERE ";
sql += " sku.itemStatus_id = ist.itemStatus_id ";
sql += " AND sku.sku_class_id = sc.sku_class_id ";
sql += " AND sku.item_id = i.item_id ";
sql += " AND i.itemStatus_id = istB.itemStatus_id  ";
sql += " AND v.vendor_id = i.vendor_id ";
sql += " ORDER BY ";
sql += " sku.item_id ";
sql += " ,sku.sku_id; ";

sql += " SELECT ";
sql += "    sku_id as skuId ";
sql += "    ,max(daterecordadded) as maxDate ";
sql += " INTO ";
sql += "    temporary table maxSkuDates ";
sql += " FROM ";
sql += "    ecommerce.RSInventoryItem as ii ";
sql += " GROUP BY ";
sql += "    sku_id; ";

sql += " SELECT ";
sql += "    sku_id as skuId ";
sql += "    ,sup.supplierName ";
sql += " INTO ";
sql += "    temporary table mostRecentSupplier ";
sql += " FROM ";
sql += "    maxSkuDates as msd ";
sql += "    ,ecommerce.RSInventoryItem as ii ";
sql += "    ,ecommerce.Supplier sup ";
sql += " WHERE ";
sql += "    msd.skuId = ii.sku_id ";
sql += "    AND msd.maxDate = ii.daterecordadded ";
sql += "    AND ii.supplier_id = sup.supplier_id ";
sql += " ORDER BY ";
sql += "    msd.skuId; ";

sql += " select distinct ";
sql += " sd.skuFamilyId ";
sql += " ,sd.skuFamilyName ";
sql += " ,sd.skuFamilyStatusId  ";
sql += " ,sd.skuFamilyStatus ";
sql += " ,sd.skuFamilyVendor ";
sql += " ,sd.skuId as sku_id";
sql += " ,sd.skuStatus ";
sql += " ,sd.tracksInventory ";
sql += " ,sd.skuName as sku_name";
sql += " ,sd.partnumber as partnumber";
sql += " ,sd.countryCode as country_code";
sql += " ,sd.skuBuyer ";
sql += " ,sd.skucategory1 ";
sql += " ,sd.skucategory2 ";
sql += " ,sd.skucategory3 ";
sql += " ,sd.skucategory4 ";
sql += " ,sd.skucategory5 ";
sql += " ,sd.skucategory6 ";
sql += " ,sd.sku_class ";
sql += " ,skud.skuQuantity ";
sql += " ,skud.skuLowerOfCost ";
sql += " ,skud.skuWeight ";
sql += " ,skud.skuSuppliers ";
sql += " ,skuc.skuReorderDate ";
sql += " ,skuc.skuReorderAge ";
sql += " ,skuc.skuPrice ";
sql += " ,skuc.skuAverageCost as skuWeightedAverageCost ";
sql += " ,skuc.skuSoldAsSingles ";
sql += " ,skuc.skuInitialCost ";
sql += " ,skuc.skuCurrentCost ";
sql += " ,mrs.supplierName ";
sql += " FROM  ";
sql += " skudetails sd  ";
sql += " left outer join skudata skud on sd.skuId = skud.skuId ";
sql += " left outer join skucalc skuc on sd.skuId = skuc.sku_id ";
sql += " left outer join mostRecentSupplier mrs on sd.skuId = mrs.skuId ";
sql += " WHERE true ";

if( notEmpty(countryCode)){
    sql += " AND sd.countryCode = '" + countryCode + "' ";
}
if( notEmpty(SkuId)){
    sql += " AND sd.skuId = " + SkuId + " ";
}
if( notEmpty(SkuStatus)){
    sql += " AND sd.skuStatus ILIKE '%" + SkuStatus + "%' ";
}
if( notEmpty(SkuCategory1)){
    sql += " AND sd.skuCategory1 ILIKE '%" + SkuCategory1 + "%' ";
}
if( notEmpty(SkuCategory2)){
    sql += " AND sd.skuCategory2 ILIKE '%" + SkuCategory2 + "%' ";
}
if( notEmpty(SkuCategory3)){
    sql += " AND sd.skuCategory3 ILIKE '%" + SkuCategory3 + "%' ";
}
if( notEmpty(SkuCategory4)){
    sql += " AND sd.skuCategory4 ILIKE '%" + SkuCategory4 + "%' ";
}
if( notEmpty(SkuCategory5)){
    sql += " AND sd.skuCategory5 ILIKE '%" + SkuCategory5 + "%' ";
}
if( notEmpty(SkuCategory6)){
    sql += " AND sd.skuCategory6 ILIKE '%" + SkuCategory6 + "%' ";
}
if( notEmpty(SkuBuyer)){
    sql += " AND sd.skuBuyer ILIKE '%" + SkuBuyer + "%' ";
}

if( notEmpty(SkuName)){
    sql += " AND sd.skuName ILIKE '%" + SkuName + "%' ";
}
if( notEmpty(SkuFamilyVendor)){
    sql += " AND sd.skuFamilyVendor ILIKE '%" + SkuFamilyVendor + "%' ";
}
if( notEmpty(SkuSupplierNames)){
    sql += " AND skud.skuSuppliers ILIKE '%" + SkuSupplierNames + "%' ";
}

sql += " ORDER BY ";
sql += " sd.skuFamilyId ";
sql += " ,sd.skuId";


