//
// Moneta Sales Report - DRAFT WITH CHECKBOXES
// Taken from Moneta Sales Report and edited, Catherine Warren, 2015-11-19 to 2015-12-10 & on || JIRA RPT-192
//

var skuCategory1 = p["skuCategory1"];
var skuCategory2 = p["skuCategory2"];
var skuCategory3 = p["skuCategory3"];
var skuCategory4 = p["skuCategory4"];
var skuCategory5 = p["skuCategory5"];
var skuCategory6 = p["skuCategory6"];
var skuBuyer = p["buyer"];
var skuStatus = p["skuStatus"];
var skuName = p["sku_name"];
var partNumber = p["partNumber"];
var skuId = p["sku_id"];
var versionId = p["versionId"];
var skuFamilyVendor = p["skuFamilyVendor"];
var countryCode = p["countryOfOrigin"];
var salesMonth = p["salesMonth"];
var skuSupplierNames = p["skuSupplierNames"];
var orderSource = p["orderSource"];
var StoreCTGStore = p["Store-CTGStore"];
var StoreStandalone = p["Store-Standalone"];
var StoreGGShop = p["Store-GGShop"];
var StoreCoupaw = p["Store-Coupaw"];
var StoreDoggyloot = p["Store-Doggyloot"];

// BLOCK OF CODE TO HANDLE NEW STORE CHECKBOXES
var ids = "";

if (notEmpty(StoreCTGStore)) {
    if(ids.length > 0) {ids += ",";
                               }
    ids += "11";
}

if (notEmpty(StoreStandalone)) {
    if(ids.length > 0) {ids += ",";
                               }
    ids += "12";
}

if (notEmpty(StoreGGShop)) {
    if(ids.length > 0) {ids += ",";
                               }
    ids += "13";
}

if (notEmpty(StoreCoupaw)) {
    if(ids.length > 0) {ids += ",";
                               }
    ids += "14";
}

if (notEmpty(StoreDoggyloot)) {
    if(ids.length > 0) {ids += ",";
                               }
    ids += "15";
} else {
  ids = "11, 12, 13, 14, 15"
}


// END BLOCK FOR CHECKBOXES

if( skuCategory1 == "All" ){ skuCategory1 = ""; }
if( skuCategory2 == "All" ){ skuCategory2 = ""; }
if( skuCategory3 == "All" ){ skuCategory3 = ""; }
if( skuCategory4 == "All" ){ skuCategory4 = ""; }
if( skuCategory5 == "All" ){ skuCategory5 = ""; }
if( skuCategory6 == "All" ){ skuCategory6 = ""; }
if( countryCode == "All" ){ countryCode = ""; }

sql += "SELECT sku_id";
sql += " ,null::date as skuReorderDate ";
sql += " ,null::float as skuReorderAge ";
sql += " ,null::float as skuPrice ";
sql += " ,null::float as skuAverageCost ";
sql += " ,null::integer as skuSoldAsSingles ";
sql += " ,null::float as skuInitialCost ";
sql += " ,null::float as skuCurrentCost ";
sql += "INTO ";
sql += " temporary table skucalc from ";
sql += " ecommerce.sku; ";

sql += "SELECT s.sku_id  ";
sql += " ,max(ii.dateRecordAdded) as dra ";
sql += "INTO ";
sql += " temporary table tempskudra ";
sql += "FROM ";
sql += " ecommerce.SKU s ";
sql += " ,ecommerce.RSInventoryItem ii ";
sql += " ,ecommerce.ProductVersionSKU pvs ";
sql += "WHERE ";
sql += " s.sku_id = ii.sku_id ";
sql += " and s.sku_id = pvs.sku_id and s.skuBitMask & 1 = 1 and ii.merchantPrice > 0 ";
sql += "GROUP BY ";
sql += " s.sku_id; ";

sql += "SELECT s.sku_id ";
sql += " ,max(ii.merchantPrice) as price ";
sql += "INTO ";
sql += " temporary table skuccost ";
sql += "FROM ";
sql += " tempskudra as dra ";
sql += " ,ecommerce.SKU as s  ";
sql += " ,ecommerce.RSInventoryItem as ii  ";
sql += " ,ecommerce.ProductVersionSKU as pvs ";
sql += "WHERE ";
sql += " s.sku_id = ii.sku_id ";
sql += " and s.sku_id = pvs.sku_id ";
sql += " and s.skuBitMask & 1 = 1 ";
sql += " and dra.sku_id = ii.sku_id ";
sql += " and dra.dra = ii.dateRecordAdded and ii.merchantPrice > 0 ";
sql += "GROUP BY ";
sql += " s.sku_id; ";

sql += "UPDATE ";
sql += " skucalc as sca ";
sql += "SET ";
sql += " skuCurrentCost = scc.price  ";
sql += "FROM ";
sql += " skuccost as scc ";
sql += "WHERE ";
sql += " scc.sku_id = sca.sku_id ";
sql += " and sca.skuCurrentCost is null; ";

sql += "SELECT ";
sql += " s.sku_id ";
sql += " ,max(ii.merchantPrice) as cost  ";
sql += "INTO ";
sql += " temporary table skuinitcost ";
sql += "FROM ";
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
sql += "WHERE ";
sql += " s.sku_id = ii.sku_id ";
sql += " and s.sku_id = pvs.sku_id ";
sql += " and s.skuBitMask & 1 = 1 ";
sql += " and dra.sku_id = ii.sku_id ";
sql += " and dra.dra = ii.dateRecordAdded  ";
sql += " and ii.merchantPrice > 0 ";
sql += "GROUP BY ";
sql += " s.sku_id; ";

sql += "UPDATE ";
sql += " skucalc as sca ";
sql += "SET ";
sql += " skuInitialCost = sic.cost  ";
sql += "FROM ";
sql += " skuinitcost as sic ";
sql += "WHERE ";
sql += " sic.sku_id = sca.sku_id ";
sql += " and sca.skuInitialCost is null; ";

sql += "SELECT ";
sql += " pvsku.sku_id ";
sql += " ,count(*) as components ";
sql += "INTO ";
sql += " temporary table skusas ";
sql += "FROM ";
sql += " ecommerce.ProductVersionSKU as pvsku ";
sql += "GROUP BY ";
sql += " sku_id; ";

sql += "UPDATE ";
sql += " skucalc as sca ";
sql += "SET ";
sql += " skuSoldAsSingles = sas.components  ";
sql += "FROM ";
sql += " skusas as sas ";
sql += "WHERE ";
sql += " sas.sku_id = sca.sku_id ";
sql += " and sca.skuSoldAsSingles is null; ";

sql += "SELECT ";
sql += " source_id as sku_id ";
sql += " ,min(customerprice) as price ";
sql += "INTO ";
sql += " temporary table skuprice ";
sql += "FROM ";
sql += " ecommerce.price ";
sql += "WHERE ";
sql += " pricetype_id = 1 ";
sql += " and sourceclass_id = 13  ";
sql += " and customerprice > 0 ";
sql += "GROUP BY ";
sql += " source_id; ";

sql += "UPDATE ";
sql += " skucalc as sca ";
sql += "SET ";
sql += " skuPrice = sp.price ";
sql += "FROM ";
sql += " skuprice as sp ";
sql += "WHERE ";
sql += " sp.sku_id = sca.sku_id ";
sql += " and sca.skuPrice is null; ";

sql += "SELECT ";
sql += " sku_id ";
sql += " ,sum(quantity * merchantPrice) / sum(quantity) as cost ";
sql += "INTO ";
sql += " temporary table skuac ";
sql += "FROM ";
sql += " ecommerce.RSInventoryItem ";
sql += "WHERE ";
sql += " quantity > 0 ";
sql += " and merchantPrice > 0  ";
sql += " and sku_id is not null ";
sql += "GROUP BY ";
sql += " sku_id; ";

sql += "UPDATE ";
sql += " skucalc as sca ";
sql += "SET ";
sql += " skuAverageCost = sac.cost ";
sql += "FROM ";
sql += " skuac as sac ";
sql += "WHERE ";
sql += " sac.sku_id = sca.sku_id ";
sql += " and sca.skuPrice is null; ";

    //Put a sku placeholder into temp table
sql += "SELECT ";
sql += " sku_id ";
sql += " ,null::timestamp as reorder_date ";
sql += "INTO ";
sql += " temporary table reorderage ";
sql += "FROM ";
sql += " ecommerce.sku; ";

    //Put the max receiving event date for each PO lineitem SKU into a temp table
sql += "SELECT ";
sql += " poli.sku_id,max(re.receiveddate) as reorder_date ";
sql += "INTO ";
sql += " temporary table retemp0 ";
sql += "FROM ";
sql += " ecommerce.purchaseorderlineitem poli ";
sql += " ,ecommerce.receivingevent as re  ";
sql += "WHERE ";
sql += " poli.poLineItem_id = re.poLineItem_id ";
sql += "GROUP BY ";
sql += " poli.sku_id; ";

    //update missing values reorderage temp table with retemp0 values
sql += "UPDATE ";
sql += " reorderage ";
sql += "SET ";
sql += " reorder_date = retemp0.reorder_date  ";
sql += "FROM ";
sql += " retemp0  ";
sql += "WHERE ";
sql += " reorderage.sku_id = retemp0.sku_id; ";

    //Put the max receiving event date for each RSinventoryitem SKU into a temp table
sql += "SELECT ";
sql += " rsii.sku_id as skuid ";
sql += " ,max(re.receiveddate) as redate ";
sql += "INTO ";
sql += " temporary table retemp1 ";
sql += "FROM ";
sql += " ecommerce.rsinventoryitem as rsii ";
sql += " ,ecommerce.receivingevent as re  ";
sql += "WHERE ";
sql += " rsii.receivingevent_id = re.receivingevent_id group by ";
sql += " rsii.sku_id; ";

    //update missing values in reorderage temp table with retemp1 values
sql += "UPDATE ";
sql += " reorderage ";
sql += "SET ";
sql += " reorder_date = redate ";
sql += "FROM ";
sql += " retemp1 ";
sql += "WHERE ";
sql += " sku_id = skuid ";
sql += " and reorder_date is null; ";

    //Put SKU initial launch date into a temp table
sql += "SELECT ";
sql += " sku_id as skuid ";
sql += " ,initialLaunchDate as redate ";
sql += "INTO ";
sql += " temporary table retemp4 ";
sql += "FROM ";
sql += " ecommerce.sku; ";

    //update missing values in reorderage temp table with retemp4 values
sql += "UPDATE ";
sql += " reorderage ";
sql += "SET ";
sql += " reorder_date = redate ";
sql += "FROM ";
sql += " retemp4 ";
sql += "WHERE ";
sql += " sku_id = skuid ";
sql += " and reorder_date is null; ";

    //Put SKU date record added into a temp table
sql += "SELECT ";
sql += " sku_id as skuid ";
sql += " ,daterecordadded as redate ";
sql += "INTO ";
sql += " temporary table retemp5 ";
sql += "FROM ";
sql += " ecommerce.sku; ";

    //update missing values in reorderage temp table with retemp5 values
sql += "UPDATE ";
sql += " reorderage ";
sql += "SET ";
sql += " reorder_date = redate  ";
sql += "FROM ";
sql += " retemp5 ";
sql += "WHERE ";
sql += " sku_id = skuid ";
sql += " and reorder_date is null; ";

sql += "SELECT ";
sql += " sku_id ";
sql += " ,reorder_date::date as reorderDate ";
sql += " ,(now()::date - reorder_date::date)/365.0 as age ";
sql += "INTO  ";
sql += " temporary table skura  ";
sql += "FROM ";
sql += " reorderage; ";

sql += "UPDATE ";
sql += " skucalc as sca ";
sql += "SET ";
sql += " skuReorderDate = sra.reorderDate ";
sql += " ,skuReorderAge = sra.age ";
sql += "FROM ";
sql += " skura as sra ";
sql += "WHERE ";
sql += " sra.sku_id = sca.sku_id; ";

sql += "select ";
sql += " s.sku_id as skuId ";
sql += " ,sum(ii.quantity) as skuQuantity ";
sql += " ,min(ii.merchantPrice) as skuLowerOfCost ";
sql += " ,max(coalesce(ii.weight,0.0)) as skuWeight ";
sql += " ,string_agg(distinct sup.supplierName,'|') as skuSuppliers ";
sql += " INTO temporary table skudata ";
sql += "FROM ";
sql += " ecommerce.SKU as s ";
sql += " ,ecommerce.RSInventoryItem as ii  ";
sql += " ,ecommerce.Supplier sup ";
sql += "WHERE ";
sql += "        s.sku_id = ii.sku_id ";
sql += "        and ii.active=true ";
sql += "        and s.skuBitMask & 1 = 1 ";
sql += "        and ii.supplier_id = sup.supplier_id ";
sql += "group by ";
sql += "        s.sku_id; ";

sql += "select  ";
sql += " sku.item_id as skuFamilyId ";
sql += " ,i.name as skuFamilyName ";
sql += " ,i.itemStatus_id as skuFamilyStatusId  ";
sql += " ,istB.itemStatus as skuFamilyStatus ";
sql += " ,v.name as skuFamilyVendor ";
sql += " ,sku.sku_id as skuId ";
sql += " ,ist.itemStatus as skuStatus ";
sql += " ,CASE WHEN sku.skuBitMask & 1 = 1 THEN 1 ELSE 0 END as tracksInventory ";
sql += " ,sku.name as skuName ";
sql += " ,sku.partNumber as partnumber ";
sql += " ,sku.isoCountryCodeOfOrigin as countryCode ";
sql += " ,ist.itemStatus  ";
sql += " ,skucat.buyer as skuBuyer ";
sql += " ,skucat.skucategory1 ";
sql += " ,skucat.skucategory2 ";
sql += " ,skucat.skucategory3 ";
sql += " ,skucat.skucategory4 ";
sql += " ,skucat.skucategory5 ";
sql += " ,skucat.skucategory6 ";
sql += " ,sc.sku_class ";
sql += "INTO ";
sql += " temporary table skudetails ";
sql += "FROM ";
sql += " ecommerce.SKU as sku ";
sql += " left outer join ecommerce.skucategory skucat on skucat.sku_id = sku.sku_id ";
sql += " ,ecommerce.ItemStatus as ist ";
sql += " ,ecommerce.sku_class as sc  ";
sql += " ,ecommerce.Item i ";
sql += " ,ecommerce.ItemStatus istB ";
sql += " ,ecommerce.vendor v ";
sql += "WHERE ";
sql += " sku.itemStatus_id = ist.itemStatus_id ";
sql += " AND sku.sku_class_id = sc.sku_class_id ";
sql += " AND sku.item_id = i.item_id ";
sql += " AND i.itemStatus_id = istB.itemStatus_id  ";
sql += " AND v.vendor_id = i.vendor_id ";
sql += "ORDER BY ";
sql += " sku.item_id ";
sql += " ,sku.sku_id; ";

sql += "SELECT ";
sql += "    sku_id as skuId ";
sql += "    ,max(daterecordadded) as maxDate ";
sql += "INTO ";
sql += "    temporary table maxSkuDates ";
sql += "FROM ";
sql += "    ecommerce.RSInventoryItem as ii ";
sql += "GROUP BY ";
sql += "    sku_id; ";

sql += "SELECT ";
sql += "    sku_id as skuId ";
sql += "    ,sup.supplierName ";
sql += "INTO ";
sql += "    temporary table mostRecentSupplier ";
sql += "FROM ";
sql += "    maxSkuDates as msd ";
sql += "    ,ecommerce.RSInventoryItem as ii ";
sql += "    ,ecommerce.Supplier sup ";
sql += "WHERE ";
sql += "    msd.skuId = ii.sku_id ";
sql += "    AND msd.maxDate = ii.daterecordadded ";
sql += "    AND ii.supplier_id = sup.supplier_id ";
sql += " ORDER BY ";
sql += "    msd.skuId; ";

sql += "select  ";
sql += " sd.skuFamilyId ";
sql += " ,sd.skuFamilyName ";
sql += " ,sd.skuFamilyStatusId  ";
sql += " ,sd.skuFamilyStatus ";
sql += " ,sd.skuFamilyVendor ";
sql += " ,sd.skuId ";
sql += " ,sd.skuStatus ";
sql += " ,sd.tracksInventory ";
sql += " ,sd.skuName ";
sql += " ,sd.partnumber ";
sql += " ,sd.countryCode ";
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
sql += " ,skuc.skuAverageCost ";
sql += " ,skuc.skuSoldAsSingles ";
sql += " ,skuc.skuInitialCost ";
sql += " ,skuc.skuCurrentCost ";
sql += " ,mrs.supplierName ";
sql += "INTO temporary table skuMain ";
sql += "FROM  ";
sql += " skudetails sd  ";
sql += " left outer join skudata skud on sd.skuId = skud.skuId ";
sql += " left outer join skucalc skuc on sd.skuId = skuc.sku_id ";
sql += " left outer join mostRecentSupplier mrs on sd.skuId = mrs.skuId ";
sql += " WHERE true ";
sql += "ORDER BY ";
sql += " sd.skuFamilyId ";
sql += " ,sd.skuId; ";

sql += "select  ";
sql += " v.productVersion_id as versionId ";
sql += " ,v.item_id as versionFamilyId ";
sql += " ,v.itemStatus_id versionStatusId ";
sql += " ,v.name as versionName ";
sql += " ,ist.itemStatus as versionStatus  ";
sql += " ,i.name as versionFamilyName ";
sql += "INTO ";
sql += " temporary table versionDetails ";
sql += "FROM  ";
sql += " ecommerce.ProductVersion v  ";
sql += " ,ecommerce.ItemStatus ist  ";
sql += " ,ecommerce.item i ";
sql += "WHERE  ";
sql += " v.itemStatus_id = ist.itemStatus_id ";
sql += " and v.item_id = i.item_id; ";

sql += "select  ";
sql += " pvsku.productVersion_id::varchar || '-' || pvsku.sku_id::varchar as versionSkuId ";
sql += " ,pvsku.productVersion_id as versionId ";
sql += " ,pvsku.sku_id as skuId  ";
sql += "INTO ";
sql += " temporary table pvskuid ";
sql += "FROM ";
sql += " ecommerce.ProductVersionSKU as pvsku ";
sql += " ,ecommerce.rslineitem as li ";
sql += " ,ecommerce.rsorder as o ";
sql += "WHERE ";
sql += " pvsku.productVersion_id = li.productversion_id ";
sql += " and li.order_id = o.oid ";
sql += " and o.store_id IN (" + ids + ");";

sql += "SELECT  ";
sql += " productVersion_id::varchar as versionId ";
sql += " ,extract( 'year' from fulfillmentDate) as year ";
sql += " ,sum(quantity) as units ";
sql += " ,sum(customerPrice * quantity) as revenue  ";
sql += "INTO ";
sql += " temporary table versionSales ";
sql += "FROM ";
sql += " ecommerce.RSLineItem ";
sql += " ,ecommerce.RSOrder o ";
sql += " WHERE ";
sql += " o.oid = order_id ";
sql += " and fulfillmentDate >= '2010-01-01' ";
sql += "and o.store_id IN (" + ids + ")";

if(notEmpty(orderSource)){
	sql += " and o.order_source_id = " + orderSource + " ";
}
sql += " and coalesce(lineItemType_id,1) in (1,5)  ";
sql += " and productVersion_id is not null  ";
sql += "GROUP BY  ";
sql += " productVersion_id::varchar  ";
sql += " ,extract( 'year' from fulfillmentDate)  ";
sql += "ORDER BY  ";
sql += " extract( 'year' from fulfillmentDate) DESC ; ";

sql += "select  ";
sql += " sku_id  ";
sql += " ,sum(quantity * merchantPrice) / sum(quantity) as cost  ";
sql += "into  ";
sql += " temporary table tempnext  ";
sql += "from  ";
sql += " ecommerce.RSInventoryItem  ";
sql += "where  ";
sql += " quantity > 0  ";
sql += " and merchantPrice > 0   ";
sql += " and sku_id is not null  ";
sql += "group by  ";
sql += " sku_id; ";

sql += "select  ";
sql += " pvs.productVersion_id as versionId ";
sql += " ,sum(pvs.quantity * tn.cost) as cost ";
sql += "into ";
sql += " temporary table versionAvgCost ";
sql += "from  ";
sql += " ecommerce.ProductVersionSKU as pvs ";
sql += " ,tempnext as tn  ";
sql += "where  ";
sql += " tn.sku_id = pvs.sku_id  ";
sql += "group by  ";
sql += " pvs.productVersion_id; ";

sql += "select  ";
sql += " productVersion_id as versionId ";
sql += " ,sum(customerPrice/quantity) / sum(quantity) as price  ";
sql += "into ";
sql += " temporary table versionAvgPrice ";
sql += "from  ";
sql += " ecommerce.RSLineItem  ";
sql += "where  ";
sql += " fulfillmentDate is not null  ";
sql += " and fulfillmentDate > '2009-12-31 23:59:59'  ";
sql += " and quantity > 0  ";
sql += "group by  ";
sql += " productVersion_id; ";

sql += " select distinct ";
sql += "	pv.productVersion_id as versionId ";
sql += "	,COALESCE(p1.customerPrice,p2.customerPrice) as price ";
sql += "    ,p1.active "
sql += " INTO temporary table vCurrentPrice ";
sql += " FROM ";
sql += "	ecommerce.ProductVersion as pv ";
sql += "	LEFT OUTER JOIN ecommerce.Price as p1 ";
sql += "		ON pv.productVersion_id = p1.source_id ";
sql += "		AND p1.sourceclass_id = 9 ";
sql += "		AND p1.priceType_id = 1 ";
sql += "	LEFT OUTER JOIN ecommerce.Price as p2 ";
sql += "		ON pv.item_id = p2.source_id ";
sql += "		AND p2.sourceclass_id = 5 ";
sql += "		AND p2.priceType_id = 1; ";

sql += "SELECT  ";
sql += " rsli.productVersion_id as versionId ";
sql += " ,min(to_char(rsli.fulfillmentDate,'yyyymmdd')::int) as firstDateSold  ";
sql += "INTO ";
sql += " temporary table versionFirstDateSold ";
sql += "FROM  ";
sql += " ecommerce.RSLineItem as rsli  ";
sql += "WHERE  ";
sql += " rsli.lineItemType_id = 1  ";
sql += " and rsli.fulfillmentDate is not null  ";
sql += "GROUP BY  ";
sql += " rsli.productVersion_id; ";

sql += "SELECT  ";
sql += " rsli.productVersion_id as versionId ";
sql += " ,sum(rsli.customerPrice * rsli.quantity) as revenue ";
sql += " ,sum(rsli.quantity) as units ";
sql += "INTO ";
sql += " temporary table last14   ";
sql += "FROM  ";
sql += " ecommerce.RSLineItem rsli  ";
sql += " ,ecommerce.rsorder o "
sql += "WHERE  ";
sql += " coalesce(rsli.lineItemType_id,1) in (1,5)  ";
sql += " and o.oid = rsli.order_id ";
sql += "and o.store_id IN (" + ids + ")";
  
if(notEmpty(orderSource)){
	sql += " and o.order_source_id = " + orderSource + " ";
}
sql += " and rsli.fulfillmentDate >= now() - interval '14 days'  ";
sql += "GROUP BY  ";
sql += " rsli.productVersion_id; ";

sql += "SELECT  ";
sql += " rsli.productVersion_id as versionId ";
sql += " ,sum(rsli.customerPrice * rsli.quantity) as revenue ";
sql += " ,sum(rsli.quantity) as units  ";
sql += "INTO ";
sql += " temporary table last30 ";
sql += "FROM  ";
sql += " ecommerce.RSLineItem rsli  ";
sql += " ,ecommerce.RSOrder o ";
sql += "WHERE  ";
sql += " coalesce(rsli.lineItemType_id,1) in (1,5)  ";
sql += " and o.oid = rsli.order_id ";
sql += "and o.store_id IN (" + ids + ")";
  
if(notEmpty(orderSource)){
	sql += " and o.order_source_id = " + orderSource + " ";
}
sql += " and rsli.fulfillmentDate >= now() - interval '30 days'  ";
sql += "GROUP BY  ";
sql += " rsli.productVersion_id; ";

sql += "SELECT  ";
sql += " rsli.productVersion_id as versionId ";
sql += " ,sum(rsli.customerPrice * rsli.quantity) as revenue ";
sql += " ,sum(rsli.quantity) as units  ";
sql += "INTO ";
sql += " temporary table last90 ";
sql += "FROM  ";
sql += " ecommerce.RSLineItem rsli  ";
sql += " ,ecommerce.RSOrder o ";
sql += "WHERE  ";
sql += " coalesce(rsli.lineItemType_id,1) in (1,5)  ";
sql += " and o.oid = rsli.order_id ";
sql += "and o.store_id IN (" + ids + ")";

if(notEmpty(orderSource)){
	sql += " and o.order_source_id = " + orderSource + " ";
}
sql += " and rsli.fulfillmentDate >= now()::date - interval '90 days'  ";
sql += "GROUP BY  ";
sql += " rsli.productVersion_id; ";

sql += "SELECT  ";
sql += " rsli.productVersion_id as versionId ";
sql += " ,sum(rsli.customerPrice * rsli.quantity) as revenue ";
sql += " ,sum(rsli.quantity) as units ";
sql += "INTO ";
sql += " temporary table last180 ";
sql += "FROM  ";
sql += " ecommerce.RSLineItem as rsli  ";
sql += " ,ecommerce.RSOrder o ";
sql += "WHERE  ";
sql += " coalesce(rsli.lineItemType_id,1) in (1,5)  ";
sql += " and o.oid = rsli.order_id ";
sql += "and o.store_id IN (" + ids + ")";

if(notEmpty(orderSource)){
	sql += " and o.order_source_id = " + orderSource + " ";
}
sql += " and rsli.fulfillmentDate >= now() - interval '180 days' ";
sql += "GROUP BY  ";
sql += " rsli.productVersion_id; ";

sql += "SELECT  ";
sql += " rsli.productVersion_id as versionId ";
sql += " ,sum(rsli.customerPrice * rsli.quantity) as revenue ";
sql += " ,sum(rsli.quantity) as units  ";
sql += "INTO ";
sql += " temporary table last365 ";
sql += "FROM  ";
sql += " ecommerce.RSLineItem as rsli  ";
sql += " ,ecommerce.RSOrder o ";
sql += "WHERE  ";
sql += " coalesce(rsli.lineItemType_id,1) in (1,5)  ";
sql += " and o.oid = rsli.order_id ";
sql += "and o.store_id IN (" + ids + ")";
  
if(notEmpty(orderSource)){
	sql += " and o.order_source_id = " + orderSource + " ";
}
  
sql += " and rsli.fulfillmentDate >= now() - interval '365 days'  ";
sql += "GROUP BY  ";
sql += " rsli.productVersion_id; ";

sql += "SELECT ";
sql += " rsli.productVersion_id as versionId ";
sql += " ,sum(rsli.quantity) as units ";
sql += " ,sum(rsli.quantity * rsli.customerPrice) as revenue  ";
sql += "INTO ";
sql += " temporary table lastSixWeeks ";
sql += "FROM  ";
sql += " ecommerce.RSLineItem as rsli  ";
sql += " ,ecommerce.RSOrder o ";
sql += "WHERE  ";
sql += " coalesce(rsli.lineItemType_id,1) in (1,5)  ";
sql += " and o.oid = rsli.order_id ";
sql += "and o.store_id IN (" + ids + ")";

if(notEmpty(orderSource)){
	sql += " and o.order_source_id = " + orderSource + " ";
}
sql += " and rsli.fulfillmentDate >= now() - interval '42 days'  ";
sql += "GROUP BY  ";
sql += " rsli.productVersion_id;  ";

sql += "SELECT  ";
sql += " pvs.productVersion_id as versionId  ";
sql += " ,pvs.sku_id as skuId  ";
sql += " ,pvs.quantity  ";
sql += "INTO ";
sql += " temporary table versionSkuQuantity ";
sql += "FROM  ";
sql += " ecommerce.ProductVersionSKU as pvs; ";

if(notEmpty(salesMonth)){
	sql += "SELECT ";
	sql += " rsli.productVersion_id as versionId ";
	sql += " ,to_char(rsli.fulfillmentDate,'yyyy-MM') as month ";
	sql += " ,sum(rsli.quantity) as units  ";
	sql += " ,sum(rsli.quantity * rsli.customerPrice) as revenue  ";
	sql += "INTO ";
	sql += " temporary table versionMonthSales ";
	sql += "FROM  ";
	sql += " ecommerce.RSLineItem as rsli ";
	sql += " ,ecommerce.RSOrder o ";
	sql += "WHERE  ";
	sql += " o.oid = rsli.order_id ";
	sql += " and o.store_id IN (" + ids + ") ";
    
	if(notEmpty(orderSource)){
		sql += " and o.order_source_id = " + orderSource + " ";
	}
	sql += " and rsli.fulfillmentDate >= '" + salesMonth + "-01' ";
	sql += " and to_char(rsli.fulfillmentDate,'yyyy-MM') = '" + salesMonth + "' " ;
	sql += " and coalesce(rsli.lineItemType_id,1) in (1,5)  ";
	sql += " and rsli.fulfillmentDate is not null  ";
	sql += "GROUP BY  ";
	sql += " versionId ";
	sql += " ,month; ";
}

//begin versionSkuRevenuePercentage
sql += "SELECT  ";
sql += " productVersion_id as versionId ";
sql += " ,sum(customerPrice/quantity) / sum(quantity) as price  ";
sql += "INTO  ";
sql += " temporary table versionWeightedAveragePrice  ";
sql += "FROM  ";
sql += " ecommerce.RSLineItem  ";
sql += "WHERE  ";
sql += " fulfillmentDate is not null  ";
sql += " and fulfillmentDate >= '2010-01-01'  ";
sql += " and quantity > 0  ";
sql += "GROUP BY  ";
sql += " productVersion_id  ";
sql += "HAVING  ";
sql += " sum(quantity) > 0; ";

sql += "SELECT  ";
sql += " pvsku.productVersion_id  ";
sql += "INTO  ";
sql += " temporary table Singles  ";
sql += "FROM  ";
sql += " ecommerce.ProductVersionSKU as pvsku  ";
sql += "GROUP BY  ";
sql += " productVersion_id  ";
sql += "HAVING count(*) = 1; ";

sql += "SELECT  ";
sql += " vwap.versionId as versionId ";
sql += " ,vwap.price  ";
sql += "INTO  ";
sql += " temporary table SingleVersionPrice  ";
sql += "FROM  ";
sql += " VersionWeightedAveragePrice as vwap  ";
sql += " ,Singles as s  ";
sql += "WHERE  ";
sql += " s.productVersion_id = vwap.versionId; ";

sql += "SELECT  ";
sql += " pvsku.sku_id as skuId ";
sql += " ,avg(svp.price / pvsku.quantity) as price  ";
sql += "INTO ";
sql += " temporary table TMP_SKU_PRICE  ";
sql += "FROM  ";
sql += " SingleVersionPrice as svp  ";
sql += " ,Singles as s  ";
sql += " ,ecommerce.ProductVersionSKU as pvsku  ";
sql += "WHERE  ";
sql += " svp.versionId = s.productVersion_id  ";
sql += " and pvsku.productVersion_id = s.productVersion_id  ";
sql += " and pvsku.quantity > 0  ";
sql += "GROUP BY  ";
sql += " pvsku.sku_id; ";

sql += "INSERT INTO TMP_SKU_PRICE (skuId,price)  ";
sql += " SELECT ";
sql += "  source_id as skuId ";
sql += "  ,customerprice  ";
sql += " FROM  ";
sql += "  ecommerce.price  ";
sql += " WHERE  ";
sql += "  pricetype_id = 1  ";
sql += "  and sourceclass_id = 13; ";

sql += "SELECT  ";
sql += " skuId ";
sql += " ,min(price) as price  ";
sql += "INTO  ";
sql += " temporary table mSKUPRICE  ";
sql += "FROM  ";
sql += " TMP_SKU_PRICE  ";
sql += "WHERE  ";
sql += " price > 0  ";
sql += "GROUP BY  ";
sql += " skuId; ";

sql += "SELECT  ";
sql += " pvsku.productVersion_id as versionId ";
sql += " ,sum(coalesce(sp.price,0) * pvsku.quantity ) as price  ";
sql += "INTO  ";
sql += " temporary table VERSION_PRICE  ";
sql += "FROM  ";
sql += " mSKUPRICE as sp ";
sql += " ,ecommerce.productversionsku as pvsku  ";
sql += "WHERE  ";
sql += " pvsku.sku_id = sp.skuId  ";
sql += "GROUP BY  ";
sql += " productversion_id;  ";

sql += "SELECT ";
sql += " pvsku.productVersion_id as versionId ";
sql += " ,pvsku.sku_id as skuId ";
sql += " ,avg(CASE WHEN vp.price > 0 THEN (sp.price * pvsku.quantity) / vp.price ELSE 0 END) as percentage ";
sql += "INTO  ";
sql += " temporary table versionSkuRevPercentage  ";
sql += "FROM ";
sql += " ecommerce.ProductVersionSKU as pvsku ";
sql += " ,VERSION_PRICE as vp ";
sql += " ,mSKUPRICE as sp ";
sql += "WHERE ";
sql += " pvsku.productVersion_id = vp.versionId ";
sql += " and pvsku.sku_id = sp.skuId ";
sql += "GROUP BY ";
sql += " pvsku.productVersion_id ";
sql += " ,pvsku.sku_id;  ";

sql += "SELECT ";
sql += " vd.versionId ";
sql += " ,vd.versionFamilyId ";
sql += " ,ist.itemstatus as versionFamilyStatus   ";
sql += " ,vd.versionFamilyName ";
sql += " ,vd.versionStatusId ";
sql += " ,vd.versionStatus ";
sql += " ,vd.versionName ";
sql += " ,vs2010.units as units2010 ";
sql += " ,vs2010.revenue as rev2010 ";
sql += " ,vs2011.units as units2011 ";
sql += " ,vs2011.revenue as rev2011 ";
sql += " ,vs2012.units as units2012 ";
sql += " ,vs2012.revenue as rev2012 ";
sql += " ,vs2013.units as units2013 ";
sql += " ,vs2013.revenue as rev2013 ";
sql += " ,vs2014.units as units2014 ";
sql += " ,vs2014.revenue as rev2014 ";
sql += " ,vs2015.units as units2015 ";
sql += " ,vs2015.revenue as rev2015 ";
sql += " ,vac.cost as versionAverageCost ";
sql += " ,vap.price as versionAveragePrice ";
sql += " ,vcp.price as currentPrice ";
sql += " ,vfds.firstDateSold ";
sql += " ,last14.units as last14units ";
sql += " ,last14.revenue as last14rev ";
sql += " ,last30.units as last30units ";
sql += " ,last30.revenue as last30rev ";
sql += " ,last90.units as last90units ";
sql += " ,last90.revenue as last90rev ";
sql += " ,last180.units as last180units ";
sql += " ,last180.revenue as last180rev ";
sql += " ,last365.units as last365units ";
sql += " ,last365.revenue as last365rev ";
sql += " ,lastSixWeeks.units as lastSixWksUnits ";
sql += " ,lastSixWeeks.revenue as lastSixWksRev ";
sql += "INTO ";
sql += " temporary table versionData  ";
sql += "FROM ";
sql += " versionDetails vd ";
sql += " left outer join versionsales vs2010 on vd.versionId::integer = vs2010.versionId::integer and vs2010.year::varchar = '2010'  ";
sql += " left outer join versionsales vs2011 on vd.versionId::integer = vs2011.versionId::integer and vs2011.year::varchar = '2011'  ";
sql += " left outer join versionsales vs2012 on vd.versionId::integer = vs2012.versionId::integer and vs2012.year::varchar = '2012'  ";
sql += " left outer join versionsales vs2013 on vd.versionId::integer = vs2013.versionId::integer and vs2013.year::varchar = '2013'  ";
sql += " left outer join versionsales vs2014 on vd.versionId::integer = vs2014.versionId::integer and vs2014.year::varchar = '2014'  ";
sql += " left outer join versionsales vs2015 on vd.versionId::integer = vs2015.versionId::integer and vs2015.year::varchar = '2015'  ";
sql += " left outer join versionAvgCost vac on vd.versionId::integer = vac.versionId::integer ";
sql += " left outer join versionAvgPrice vap on vd.versionId::integer = vap.versionId::integer ";
sql += " left outer join vCurrentPrice vcp on vd.versionId::integer = vcp.versionId::integer ";
sql += " left outer join versionFirstDateSold vfds on vd.versionId::integer = vfds.versionId::integer ";
sql += " left outer join last14 on vd.versionId::integer = last14.versionId::integer ";
sql += " left outer join last30 on vd.versionId::integer = last30.versionId::integer ";
sql += " left outer join last90 on vd.versionId::integer = last90.versionId::integer ";
sql += " left outer join last180 on vd.versionId::integer = last180.versionId::integer ";
sql += " left outer join last365 on vd.versionId::integer = last365.versionId::integer ";
sql += " left outer join lastSixWeeks on vd.versionId::integer = lastSixWeeks.versionId::integer ";
sql += " , ecommerce.item i ";
sql += " , ecommerce.itemstatus ist ";
sql += "WHERE vd.versionFamilyId = i.item_id  ";
sql += "  AND i.itemStatus_id = ist.itemstatus_id  ";
sql += "  AND vcp.active != false "
sql += "ORDER BY ";
sql += " vd.versionId;  ";

sql += "SELECT DISTINCT ";
sql += " vsid.versionId as version_id";
sql += " ,vsid.skuId as sku_id";
sql += " ,vsq.quantity AS versionSkuQuantity ";
sql += " ,vsrp.percentage AS skuRevenuePercentage ";
sql += " ,vd.versionFamilyId ";
sql += " ,vd.versionFamilyName ";
sql += " ,vd.versionFamilyStatus ";
sql += " ,vd.versionStatusId ";
sql += " ,vd.versionStatus ";
sql += " ,vd.versionName as version_name";
sql += " ,vd.units2010 ";
sql += " ,vd.rev2010 ";
sql += " ,vd.units2011 ";
sql += " ,vd.rev2011 ";
sql += " ,vd.units2012 ";
sql += " ,vd.rev2012 ";
sql += " ,vd.units2013 ";
sql += " ,vd.rev2013 ";
sql += " ,vd.units2014 ";
sql += " ,vd.rev2014 ";
sql += " ,vd.units2015 ";
sql += " ,vd.rev2015 ";
sql += " ,vd.versionAverageCost ";
sql += " ,vd.versionAveragePrice ";
sql += " ,vd.currentPrice ";
sql += " ,vd.firstDateSold ";
sql += " ,vd.last14units ";
sql += " ,vd.last14rev ";
sql += " ,vd.last30units ";
sql += " ,vd.last30rev ";
sql += " ,vd.last90units ";
sql += " ,vd.last90rev ";
sql += " ,vd.last180units ";
sql += " ,vd.last180rev ";
sql += " ,vd.last365units ";
sql += " ,vd.last365rev ";
sql += " ,vd.lastSixWksUnits ";
sql += " ,vd.lastSixWksRev ";
sql += " ,sm.skuFamilyId ";
sql += " ,sm.skuFamilyName ";
sql += " ,sm.skuFamilyStatusId ";
sql += " ,sm.skuFamilyStatus ";
sql += " ,sm.skuFamilyVendor ";
sql += " ,sm.skuStatus ";
sql += " ,sm.tracksInventory ";
sql += " ,sm.skuName as sku_name";
sql += " ,sm.partnumber ";
sql += " ,sm.countryCode as country_code";
sql += " ,sm.skuBuyer ";
sql += " ,sm.skucategory1 ";
sql += " ,sm.skucategory2 ";
sql += " ,sm.skucategory3 ";
sql += " ,sm.skucategory4 ";
sql += " ,sm.skucategory5 ";
sql += " ,sm.skucategory6 ";
sql += " ,sm.sku_class ";
sql += " ,sm.skuQuantity ";
sql += " ,sm.skuLowerOfCost ";
sql += " ,sm.skuWeight ";
sql += " ,sm.skuSuppliers ";
sql += " ,sm.skuReorderDate ";
sql += " ,sm.skuReorderAge ";
sql += " ,sm.skuPrice ";
sql += " ,sm.skuAverageCost ";
sql += " ,sm.skuSoldAsSingles ";
sql += " ,sm.skuInitialCost ";
sql += " ,sm.skuCurrentCost ";
sql += " ,sm.supplierName as supplier_name ";

if(notEmpty(salesMonth)){
       sql += " ,vms.month as salesMonth,vms.units as salesMonthUnits,vms.revenue as salesMonthRevenue ";
} else {
       sql += " ,'' as salesMonth,0 as salesMonthUnits,0 as salesMonthRevenue ";
}

sql += " ,vd.versionFamilyStatus ";
sql += "FROM ";
sql += " pvskuid vsid ";
sql += " LEFT OUTER JOIN versionSkuQuantity vsq ON vsid.versionId = vsq.versionId AND vsid.skuId = vsq.skuId ";
sql += " LEFT OUTER JOIN versionSkuRevPercentage vsrp ON vsid.versionId = vsrp.versionId AND vsid.skuId = vsrp.skuId ";

if(notEmpty(salesMonth)){
    sql += " LEFT OUTER JOIN versionMonthSales vms ON vsid.versionId = vms.versionId AND vms.month = '" + salesMonth + "' ";
}

sql += " ,versionData vd ";
sql += " ,skuMain sm ";
sql += "WHERE ( vsid.versionId = vd.versionId AND vsid.skuId = sm.skuId ) ";

if(notEmpty(countryCode)){
    sql += " and sm.countryCode = '" + countryCode + "' ";
}
if(notEmpty(skuId)){
    sql += " and sm.skuId = " + skuId;
}
if(notEmpty(versionId)){
    sql += " and vd.versionId = " + versionId;
}
if(notEmpty(skuStatus)){
    sql += " and sm.skuStatus ILIKE '%" + skuStatus + "%' ";
}
if(notEmpty(skuCategory1)){
    sql += " and sm.skuCategory1 ILIKE '%" + skuCategory1 + "%' ";
}
if(notEmpty(skuCategory2)){
    sql += " and sm.skuCategory2 ILIKE '%" + skuCategory2 + "%' ";
}
if(notEmpty(skuCategory3)){
    sql += " and sm.skuCategory3 ILIKE '%" + skuCategory3 + "%' ";
}
if(notEmpty(skuCategory4)){
    sql += " and sm.skuCategory4 ILIKE '%" + skuCategory4 + "%' ";
}
if(notEmpty(skuCategory5)){
    sql += " and sm.skuCategory5 ILIKE '%" + skuCategory5 + "%' ";
}
if(notEmpty(skuCategory6)){
    sql += " and sm.skuCategory6 ILIKE '%" + skuCategory6 + "%' ";
}
if(notEmpty(skuBuyer)){
    sql += " and sm.skuBuyer ILIKE '%" + skuBuyer + "%' ";
}
if(notEmpty(partNumber)){
	sql += " and sm.skuPartNumber ILIKE '%" + partNumber + "%' ";
}
if(notEmpty(skuName)){
	sql += " and sm.skuName ILIKE '%" + skuName + "%' ";
}
if(notEmpty(skuFamilyVendor)){
    sql += " and sm.skuFamilyVendor ILIKE '%" + skuFamilyVendor + "%' ";
}
if(notEmpty(skuSupplierNames)){
    sql += " and sm.skuSuppliers ILIKE '%" + skuSupplierNames + "%' ";
}

sql += " ORDER BY ";
sql += " vsid.versionId ";
sql += " ,vsid.skuId ";