//
// Moneta Sales Report - DRAFT with Common Table Expressions
// Catherine Warren, 2016-05-03 through... ?
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
var storeId = p["store_id"];
var orderSource = p["orderSource"];

if( skuCategory1 == "All" ){ skuCategory1 = ""; }
if( skuCategory2 == "All" ){ skuCategory2 = ""; }
if( skuCategory3 == "All" ){ skuCategory3 = ""; }
if( skuCategory4 == "All" ){ skuCategory4 = ""; }
if( skuCategory5 == "All" ){ skuCategory5 = ""; }
if( skuCategory6 == "All" ){ skuCategory6 = ""; }
if( countryCode == "All" ){ countryCode = ""; }

//SUBQUERIES


// QUERY 18
var skuMain = new SelectSQLBuilder();

skuMain.setSelect("select ");
skuMain.setFrom("from ");
skuMain.setWhere("where ");
skuMain.setGroupBy("group by ");
skuMain.setOrderBy("order by ");



// QUERY 19
var versionDetails = new SelectSQLBuilder();

versionDetails.setSelect("select v.productVersion_id as versionId, v.item_id as versionFamilyId, v.itemStatus_id as versionStatusId, v.name as versionName, ist.itemStatus as versionStatus, i.name as versionFamilyName ");
versionDetails.setFrom("from ecommerce.ProductVersion as v, ecommerce.ItemStatus as ist, ecommerce.item as i ");
versionDetails.setWhere("where v.itemStatus_id = ist.itemStatus_id and v.item_id = i.item_id ");


// QUERY 20 
var pvskuid = new SelectSQLBuilder();

pvskuid.setSelect("select pvsku.productVersion_id::varchar || '-' || pvsku.sku_id::varchar as versionSkuId, pvsku.productVersion_id as versionId, pvsku.sku_id as skuId ");
pvskuid.setFrom("from ecommerce.ProductVersionSKU as pvsku ");
pvskuid.setWhere("where true ");


// QUERY 21
var versionsales = new SelectSQLBuilder();

versionsales.setSelect("select rsli.productVersion_id::varchar as versionId, extract( 'year' from rsli.fulfillmentDate) as year, sum(rsli.quantity) as units, sum(rsli.customerPrice * rsli.quantity) as revenue ");
versionsales.setFrom("from ecommerce.RSLineItem as rsli, ecommerce.RSOrder as o ");
versionsales.setWhere("where o.oid = rsli.order_id and rsli.fulfillmentDate >= '2015-01-01' and coalesce(rsli.lineItemType_id,1) in (1,5) and rsli.productVersion_id IS NOT NULL ");
versionsales.setGroupBy("group by rsli.productVersion_id::varchar, extract( 'year' from rsli.fulfillmentDate) ");
versionsales.setOrderBy("order by extract( 'year' from rsli.fulfillmentDate) DESC ");

if (notEmpty(storeId)) {
      versionsales.appendWhere("o.store_id = " + storeId);
}

if (notEmpty(orderSource)) {
      versionsales.appendWhere("o.order_source_id = " + orderSource);
}

// QUERY 22
var tempnext = new SelectSQLBuilder();

tempnext.setSelect("select ii.sku_id, sum(ii.quantity * ii.merchantPrice) / sum(ii.quantity) as cost ");
tempnext.setFrom("from ecommerce.RSInventoryItem as ii ");
tempnext.setWhere("where ii.quantity > 0 and ii.merchantPrice > 0 and ii.sku_id is not null ");
tempnext.setGroupBy("group by ii.sku_id ");


// QUERY 23
var versionAvgCost = new SelectSQLBuilder();

versionAvgCost.setSelect("select pvs.productVersion_id as versionId, sum(pvs.quantity * tn.cost) as cost");
versionAvgCost.addCommonTableExpression("tn", tempnext);
versionAvgCost.setFrom("from ecommerce.ProductVersionSKU as pvs LEFT OUTER JOIN tempnext as tn ON tn.sku_id = pvs.sku_id ");
versionAvgCost.setWhere("where true ");
versionAvgCost.setGroupBy("group by pvs.productVersion_id ");


// QUERY 24
var versionAvgPrice = new SelectSQLBuilder();

versionAvgPrice.setSelect("select rsli.productVersion_id as versionId, sum(rsli.customerPrice/rsli.quantity) / sum(rsli.quantity) as price ");
versionAvgPrice.setFrom("from ecommerce.RSLineItem");
versionAvgPrice.setWhere("where rsli.fulfillmentDate is not null and rsli.fulfillmentDate > '2015-01-01' and rsli.quantity > 0 ");
versionAvgPrice.setGroupBy("group by rsli.productVersion_id");



// QUERY 25
var vCurrentPrice = new SelectSQLBuilder();

vCurrentPrice.setSelect("select distinct pv.productVersion_id as versionId, COALESCE(p1.customerPrice,p2.customerPrice) as price, p1.active ");
vCurrentPrice.setFrom("from ecommerce.ProductVersion as pv LEFT OUTER JOIN ecommerce.Price as p1 ON pv.productVersion_id = p1.source_id AND p1.sourceclass_id = 9 AND p1.priceType_id = 1 AND (p1.active = TRUE OR p1.active IS NULL) LEFT OUTER JOIN ecommerce.Price as p2 ON pv.item_id = p2.source_id AND p2.sourceclass_id = 5 AND p2.priceType_id = 1 AND (p2.active = TRUE OR p2.active IS NULL) ");
vCurrentPrice.setWhere("where true ");


// QUERY 26
var versionFirstDateSold = new SelectSQLBuilder();

versionFirstDateSold.setSelect("select rsli.productVersion_id as versionId, min(to_char(rsli.fulfillmentDate,'yyyymmdd')::int) as firstDateSold ");
versionFirstDateSold.setFrom("from ecommerce.RSLineItem as rsli ");
versionFirstDateSold.setWhere("where rsli.lineItemType_id = 1 and rsli.fulfillmentDate is not null ");
versionFirstDateSold.setGroupBy("group by rsli.productVersion_id ");


// QUERY 27
var last14 = new SelectSQLBuilder();

last14.setSelect("select rsli.productVersion_id as versionId, sum(rsli.customerPrice * rsli.quantity) as revenue, sum(rsli.quantity) as units ");
last14.setFrom("from ecommerce.RSLineItem as rsli, ecommerce.RSOrder as o ");
last14.setWhere("where COALESCE(rsli.lineItemType_id,1) in (1,5) and o.oid = rsli.order_id and rsli.fulfillmentDate >= now() - interval '14 days' ");
last14.setGroupBy("group by rsli.productVersion_id ");

if (notEmpty(storeId)) {
      last14.appendWhere("o.store_id = " + storeId);
}

if (notEmpty(orderSource)) {
      last14.appendWhere("o.order_source_id = " + orderSource); 
}

// QUERY 28
var last30 = new SelectSQLBuilder();

last30.setSelect("select rsli.productVersion_id as versionId, sum(rsli.customerPrice * rsli.quantity) as revenue, sum(rsli.quantity) as units ");
last30.setFrom("from ecommerce.RSLineItem as rsli, ecommerce.RSOrder as o ");
last30.setWhere("where COALESCE(rsli.lineItemType_id,1) in (1,5) and o.oid = rsli.order_id and rsli.fulfillmentDate >= now() - interval '30 days' ");
last30.setGroupBy("group by rsli.productVersion_id ");

if (notEmpty(storeId)) {
      last30.appendWhere("o.store_id = " + storeId);
}

if (notEmpty(orderSource)) {
      last30.appendWhere("o.order_source_id = " + orderSource); 
}


// QUERY 29
var last90 = new SelectSQLBuilder();

last90.setSelect("select rsli.productVersion_id as versionId, sum(rsli.customerPrice * rsli.quantity) as revenue, sum(rsli.quantity) as units ");
last90.setFrom("from ecommerce.RSLineItem as rsli, ecommerce.RSOrder as o ");
last90.setWhere("where COALESCE(rsli.lineItemType_id,1) in (1,5) and o.oid = rsli.order_id and rsli.fulfillmentDate >= now() - interval '90 days' ");
last90.setGroupBy("group by rsli.productVersion_id ");

if (notEmpty(storeId)) {
      last90.appendWhere("o.store_id = " + storeId);
}

if (notEmpty(orderSource)) {
      last90.appendWhere("o.order_source_id = " + orderSource); 
}

// QUERY 30
var last180 = new SelectSQLBuilder();

last180.setSelect("select rsli.productVersion_id as versionId, sum(rsli.customerPrice * rsli.quantity) as revenue, sum(rsli.quantity) as units ");
last180.setFrom("from ecommerce.RSLineItem as rsli, ecommerce.RSOrder as o ");
last180.setWhere("where COALESCE(rsli.lineItemType_id,1) in (1,5) and o.oid = rsli.order_id and rsli.fulfillmentDate >= now() - interval '180 days' ");
last180.setGroupBy("group by rsli.productVersion_id ");

if (notEmpty(storeId)) {
      last180.appendWhere("o.store_id = " + storeId);
}

if (notEmpty(orderSource)) {
      last180.appendWhere("o.order_source_id = " + orderSource); 
}



// QUERY 31
var last365 = new SelectSQLBuilder();

last365.setSelect("select rsli.productVersion_id as versionId, sum(rsli.customerPrice * rsli.quantity) as revenue, sum(rsli.quantity) as units ");
last365.setFrom("from ecommerce.RSLineItem as rsli, ecommerce.RSOrder as o ");
last365.setWhere("where COALESCE(rsli.lineItemType_id,1) in (1,5) and o.oid = rsli.order_id and rsli.fulfillmentDate >= now() - interval '365 days' ");
last365.setGroupBy("group by rsli.productVersion_id ");

if (notEmpty(storeId)) {
      last365.appendWhere("o.store_id = " + storeId);
}

if (notEmpty(orderSource)) {
      last365.appendWhere("o.order_source_id = " + orderSource); 
}


// QUERY 32 is deprecated
// QUERY 33
var versionSkuQuantity = new SelectSQLBuilder();

versionSkuQuantity.setSelect("pvs.productVersion_id as versionId, pvs.sku_id as skuId, pvs.quantity ");
versionSkuQuantity.setFrom("from ecommerce.ProductVersionSKU as pvs ");
versionSkuQuantity.setWhere("where true ");


// QUERY 35
var VersionWeightedAveragePrice = new SelectSQLBuilder();

VersionWeightedAveragePrice.setSelect("select rsli.productVersion_id as versionId, sum(rsli.customerPrice/rsli.quantity) / sum(rsli.quantity) as price ");
VersionWeightedAveragePrice.setFrom("from ecommerce.RSLineItem as rsli");
VersionWeightedAveragePrice.setWhere("where rsli.fulfillmentDate is not null and rsli.fulfillmentDate >= '2015-01-01' and rsli.quantity > 0 ");
VersionWeightedAveragePrice.setGroupBy("group by rsli.productVersion_id HAVING sum(rsli.quantity) > 0 ");



// QUERY 36
var Singles = new SelectSQLBuilder();

Singles.setSelect("select pvsku.productVersion_id ");
Singles.setFrom("from ecommerce.ProductVersionSKU as pvsku ");
Singles.setWhere("where true ");
Singles.setGroupBy("group by productVersion_id HAVING count(*) = 1 ");


// QUERY 37
var SingleVersionPrice = new SelectSQLBuilder();

SingleVersionPrice.setSelect("select vwap.versionId as versionId, vwap.price ");
SingleVersionPrice.addCommonTableExpression("vwap", VersionWeightedAveragePrice);
SingleVersionPrice.addCommonTableExpression("s", Singles);
SingleVersionPrice.setFrom("from ecommerce.productversion as pv LEFT OUTER JOIN VersionWeightedAveragePrice as vwap ON vwap.versionId = pv.productversion_id LEFT OUTER JOIN Singles as s ON pv.productversion_id = s.productversion_id ");
SingleVersionPrice.setWhere("where true ");


// QUERY 38
var TMP_SKU_PRICE = new SelectSQLBuilder();

TMP_SKU_PRICE.setSelect("select (CASE WHEN (pr.pricetype_id = 1 AND pr.sourceclass_id = 13) THEN pr.source_id ELSE pvsku.sku_id END) as skuId ");
TMP_SKU_PRICE.appendSelect("(CASE WHEN (pr.pricetype_id = 1 AND pr.sourceclass_id = 13) THEN pr.customerprice ELSE avg(svp.price / pvsku.quantity) END) as customerprice ");
TMP_SKU_PRICE.addCommonTableExpression("s", Singles);
TMP_SKU_PRICE.addCommonTableExpression("svp", SingleVersionPrice);
TMP_SKU_PRICE.setFrom("from ecommerce.price as pr, ecommerce.ProductVersionSKU as pvsku LEFT OUTER JOIN Singles as s ON pvsku.productVersion_id = s.productVersion_id LEFT OUTER JOIN SingleVersionPrice as svp ON pvsku.productversion_id = svp.versionId ");
TMP_SKU_PRICE.setWhere("where pvsku.quantity > 0 ");
TMP_SKU_PRICE.setGroupBy("group by skuId, pr.pricetype_id, pr.sourceclass_id, pr.customerprice ");

// QUERY 39
var mSKUPRICE = new SelectSQLBuilder();

mSKUPRICE.setSelect("select skuId, min(customerprice) as price ");
mSKUPRICE.setFrom("from TMP_SKU_PRICE ");
mSKUPRICE.setWhere("where customerprice > 0 ");
mSKUPRICE.setGroupBy("group by skuId ");


// QUERY 40
var VERSION_PRICE = new SelectSQLBuilder();

VERSION_PRICE.setSelect("select pvsku.productVersion_id as versionId, sum(coalesce(sp.price,0) * pvsku.quantity ) as price ");
VERSION_PRICE.addCommonTableExpression("sp", mSKUPRICE);
VERSION_PRICE.setFrom("from ecommerce.productversionsku as pvsku INNER JOIN mSKUPRICE as sp ON pvsku.sku_id = sp.skuId ");
VERSION_PRICE.setWhere("where true ");
VERSION_PRICE.setGroupBy("group by productversion_id ");

// QUERY 41
var versionSkuRevPercentage = new SelectSQLBuilder();

versionSkuRevPercentage.setSelect("select pvsku.productVersion_id as versionId, pvsku.sku_id as skuId ");
versionSkuRevPercentage.appendSelect("avg(CASE WHEN vp.price > 0 THEN (sp.price * pvsku.quantity) / vp.price ELSE 0 END) as percentage ");
versionSkuRevPercentage.addCommonTableExpression("vp", VERSION_PRICE);
versionSkuRevPercentage.addCommonTableExpression("sp", mSKUPRICE);
versionSkuRevPercentage.setFrom("from ecommerce.ProductVersionSKU as pvsku INNER JOIN VERSION_PRICE as vp ON pvsku.productVersion_id = vp.versionId INNER JOIN mSKUPRICE as sp ON pvsku.sku_id = sp.skuId ");
versionSkuRevPercentage.setWhere("where true");
versionSkuRevPercentage.setGroupBy("group by pvsku.productVersion_id, pvsku.sku_id ");

// QUERY ??
var VersionSalePopPickPricing = new SelectSQLBuilder();

VersionSalePopPickPricing.setSelect("select pv.productversion_id as versionId, COALESCE(pr1.customerprice, 0.00) as recommended_sale_price, COALESCE(pr2.customerprice, 0.00) as recommended_pop_pick_price ");
VersionSalePopPickPricing.setFrom("from ecommerce.productversion as pv, ecommerce.item as i, ecommerce.price as pr1, ecommerce.price as pr2 ");
VersionSalePopPickPricing.setWhere("where pv.item_id = i.item_id ");
VersionSalePopPickPricing.appendWhere("i.item_id = pr1.source_id and pr1.sourceclass_id = 5 and pr1.pricetype_id = 5 and i.item_id = pr2.source_id and pr2.sourceclass_id = 5 and pr2.pricetype_id = 6 ");


// QUERY 42
var versionData = new SelectSQLBuilder();

versionData.setSelect("select vd.versionId, vd.versionFamilyId, ist.itemstatus as versionFamilyStatus, vd.versionFamilyName, vd.versionStatusId, vd.versionStatus, vd.versionName ");
versionData.appendSelect("vs2016.units as units2016, vs2016.revenue as rev2016 ");
versionData.appendSelect("vac.cost as versionAverageCost, vap.price as versionAveragePrice, vcp.price as currentPrice, vspp.recommended_sale_price, vspp.recommended_pop_pick_price ");
versionData.appendSelect("vfds.firstDateSold, last14.units as last14units, last14.revenue as last14rev, last30.units as last30units, last30.revenue as last30rev ");
versionData.appendSelect("last90.units as last90units, last90.revenue as last90rev, last180.units as last180units, last180.revenue as last180rev, last365.units as last365units, last365.revenue as last365rev ");
versionData.addCommonTableExpression("vs2016", versionsales);
versionData.addCommonTableExpression("vac", versionAvgCost);
versionData.addCommonTableExpression("vap", versionAvgPrice);
versionData.addCommonTableExpression("vcp", vCurrentPrice);
versionData.addCommonTableExpression("vspp", VersionSalePopPickPricing);
versionData.addCommonTableExpression("vfds", versionFirstDateSold);
versionData.addCommonTableExpression("last14", last14);
versionData.addCommonTableExpression("last30", last30);
versionData.addCommonTableExpression("last90", last90);
versionData.addCommonTableExpression("last180", last180);
versionData.addCommonTableExpression("last365", last365);
versionData.setFrom("from versionDetails as vd LEFT OUTER JOIN versionsales as vs2016 on vd.versionId::integer = vs2016.versionId::integer and vs2016.year::varchar = '2016' LEFT OUTER JOIN versionAvgCost as vac on vd.versionId::integer = vac.versionId::integer LEFT OUTER JOIN versionAvgPrice as vap on vd.versionId::integer = vap.versionId::integer LEFT OUTER JOIN vCurrentPrice as vcp on vd.versionId::integer = vcp.versionId::integer LEFT OUTER JOIN VersionSalePopPickPricing as vspp on vd.versionId::integer = vspp.versionId::integer LEFT OUTER JOIN versionFirstDateSold as vfds on vd.versionId::integer = vfds.versionId::integer LEFT OUTER JOIN last14 as last14 on vd.versionId::integer = last14.versionId::integer LEFT OUTER JOIN last30 as last 30 on vd.versionId::integer = last30.versionId::integer LEFT OUTER JOIN last90 as last90 on vd.versionId::integer = last90.versionId::integer LEFT OUTER JOIN last180 as last180 on vd.versionId::integer = last180.versionId::integer LEFT OUTER JOIN last365 as last365 on vd.versionId::integer = last365.versionId::integer ");
versionData.appendFrom("ecommerce.item as i, ecommerce.itemstatus as ist ");
versionData.setWhere("where vd.versionFamilyId = i.item_id and i.itemStatus_id = ist.itemstatus_id ");
versionData.setOrderBy("order by vd.versionId asc");

//MAIN QUERY = QUERY 43
var sqlProcessor = new SelectSQLBuilder();

sqlProcessor.setSelect("select DISTINCT vsid.versionId as version_id, vsid.skuId as sku_id, vsq.quantity AS versionSkuQuantity, vsrp.percentage AS skuRevenuePercentage ");
sqlProcessor.appendSelect("vd.versionFamilyId, vd.versionFamilyName, vd.versionFamilyStatus, vd.versionStatusId, vd.versionStatus, vd.versionName as version_name ");
sqlProcessor.appendSelect("vd.units2016, vd.rev2016 ");
sqlProcessor.appendSelect("vd.versionAverageCost, vd.versionAveragePrice, vd.currentPricevd.currentPrice, vd.recommended_sale_price, vd.recommended_pop_pick_price ");
sqlProcessor.appendSelect("vd.firstDateSold, vd.last14units, vd.last14rev, vd.last30units, vd.last30rev, vd.last90units, vd.last90rev, vd.last180units, vd.last180rev, vd.last365units, vd.last365rev ");
sqlProcessor.appendSelect("sm.skuFamilyId, sm.skuFamilyName, sm.skuFamilyStatusId, sm.skuFamilyStatus, sm.skuFamilyVendor, sm.skuStatus, sm.tracksInventory, sm.skuName as sku_name ");
sqlProcessor.appendSelect("sm.partnumber, sm.countryCode as country_code, sm.skuBuyer, sm.skucategory1, sm.skucategory2, sm.skucategory3, sm.skucategory4, sm.skucategory5, sm.skucategory6 ");
sqlProcessor.appendSelect("sm.sku_class, sm.skuQuantity, sm.skuLowerOfCost, sm.skuWeight, sm.skuSuppliers, sm.skuReorderDate, sm.skuReorderAge, sm.skuPrice, sm.skuAverageCost ");
sqlProcessor.appendSelect("sm.skuSoldAsSingles, sm.skuInitialCost, sm.skuCurrentCost, sm.supplierName as supplier_name ");
sqlProcessor.addCommonTableExpression("vsq", versionSkuQuantity);
sqlProcessor.addCommonTableExpression("vsrp", versionSkuRevPercentage);
sqlProcessor.addCommonTableExpression("vd", versionData);
sqlProcessor.setFrom("from pvskuid as vsid LEFT OUTER JOIN skuMain ON vsid.skuId = sm.skuId LEFT OUTER JOIN versionData as vd ON vd.versionId = vsid.versionId LEFT OUTER JOIN versionSkuQuantity as vsq ON vsid.versionId = vsq.versionId AND vsid.skuId = vsq.skuId LEFT OUTER JOIN versionSkuRevPercentage as vsrp ON vsid.versionId = vsrp.versionId ");
sqlProcessor.setWhere("where vsid.skuId = vsrp.skuId ");
sqlProcessor.setOrderBy("order by vsid.versionId, vsid.skuId ");

if(notEmpty(salesMonth)) {
    sqlProcessor.appendSelect("vms.month as salesMonth, vms.units as salesMonthUnits, vms.revenue as salesMonthRevenue ");
} else {
    sqlProcessor.appendSelect(" '' as salesMonth, 0 as salesMonthUnits, 0 as salesMonthRevenue ");
}

if(notEmpty(countryCode)){
     sqlProcessor.appendWhere("sm.countryCode = '" + countryCode + "' ");
}

if(notEmpty(skuId)){
     sqlProcessor.appendWhere("sm.skuId = " + skuId );
}

if(notEmpty(versionId)){
     sqlProcessor.appendWhere("vd.versionId = " + versionId );
}

if(notEmpty(skuStatus)){
     sqlProcessor.appendWhere("sm.skuStatus ILIKE '%" + skuStatus + "%' ");
}

if(notEmpty(skuCategory1)){
     sqlProcessor.appendWhere("sm.skuCategory1 ILIKE '%" + skuCategory1 + "%' ");
}

if(notEmpty(skuCategory2)){
     sqlProcessor.appendWhere("sm.skuCategory2 ILIKE '%" + skuCategory2 + "%' ");
}

if(notEmpty(skuCategory3)){
     sqlProcessor.appendWhere("sm.skuCategory3 ILIKE '%" + skuCategory3 + "%' ");
}

if(notEmpty(skuCategory4)){
     sqlProcessor.appendWhere("sm.skuCategory4 ILIKE '%" + skuCategory4 + "%' ");
}

if(notEmpty(skuCategory5)){
     sqlProcessor.appendWhere("sm.skuCategory5 ILIKE '%" + skuCategory5 + "%' ");
}

if(notEmpty(skuCategory6)){
     sqlProcessor.appendWhere("sm.skuCategory6 ILIKE '%" + skuCategory6 + "%' ");
}

if(notEmpty(skuBuyer)){
     sqlProcessor.appendWhere("sm.skuBuyer ILIKE '%" + skuBuyer + "%' ");
}

if(notEmpty(partNumber)){
     sqlProcessor.appendWhere("sm.skuPartNumber ILIKE '%" + partNumber + "%' ");
}

if(notEmpty(skuName)){
     sqlProcessor.appendWhere("sm.skuName ILIKE '%" + skuName + "%' ");
}

if(notEmpty(skuFamilyVendor)){
     sqlProcessor.appendWhere("sm.skuFamilyVendor ILIKE '%" + skuFamilyVendor + "%' ");
}

if(notEmpty(skuSupplierNames)){
     sqlProcessor.appendWhere("sm.skuSuppliers ILIKE '%" + skuSupplierNames + "%' "); 
}

sql = sqlProcessor.queryString();