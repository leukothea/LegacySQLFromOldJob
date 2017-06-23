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

// QUERY 1: tempskudra (formerly query 2) - feeds into skucost

var tempskudra = new SelectSQLBuilder();

tempskudra.setSelect("select s.sku_id, max(ii.dateRecordAdded) as dra ");
tempskudra.setFrom("from ecommerce.SKU as s, ecommerce.RSInventoryItem as ii, ecommerce.ProductVersionSKU as pvs ");
tempskudra.setWhere("where s.sku_id = ii.sku_id and s.sku_id = pvs.sku_id and s.skuBitMask & 1 = 1 and ii.merchantPrice > 0 ");
tempskudra.setGroupBy("group by s.sku_id ");

// QUERY 2: skuccost, formerly query 3

var skuccost = new SelectSQLBuilder();

skuccost.setSelect("select s.sku_id, max(ii.merchantPrice) as price ");
skuccost.addCommonTableExpression("tempskudra", tempskudra);
skuccost.setFrom("from ecommerce.SKU as s LEFT OUTER JOIN tempskudra as tempskudra ON s.sku_id = tempskudra.sku_id, ecommerce.RSInventoryItem as ii, ecommerce.ProductVersionSKU as pvs ");
skuccost.setWhere("where s.sku_id = ii.sku_id and s.sku_id = pvs.sku_id and s.skuBitMask & 1 = 1 and tempskudra.sku_id = ii.sku_id");
skuccost.appendWhere("tempskudra.dra::DATE = ii.dateRecordAdded::DATE and ii.merchantPrice > 0 ");
skuccost.setGroupBy("group by s.sku_id ");


// QUERY 3: The previous version of skuinitcost (query 4) hid a secret subquery called dra

var dra = new SelectSQLBuilder();

dra.setSelect("select s.sku_id, min(ii.dateRecordAdded) as dra ");
dra.setFrom("from ecommerce.SKU as s, ecommerce.RSInventoryItem as ii, ecommerce.ProductVersionSKU as pvs ");
dra.setWhere("WHERE s.sku_id = ii.sku_id and s.sku_id = pvs.sku_id and s.skuBitMask & 1 = 1 and ii.merchantPrice > 0 ");
dra.setGroupBy("GROUP BY s.sku_id ");

// QUERY 4: skuinitcost

var skuinitcost = new SelectSQLBuilder();

skuinitcost.setSelect("select s.sku_id, max(ii.merchantPrice) as cost ");
skuinitcost.addCommonTableExpression("dra", dra);
skuinitcost.setFrom("from ecommerce.SKU as s LEFT OUTER JOIN dra as dra ON s.sku_id = dra.sku_id, ecommerce.RSInventoryItem as ii, ecommerce.ProductVersionSKU as pvs ");
skuinitcost.setWhere("where s.sku_id = ii.sku_id and s.sku_id = pvs.sku_id and s.skuBitMask & 1 = 1 and dra.dra::DATE = ii.dateRecordAdded::DATE and ii.merchantPrice > 0 ");
skuinitcost.setGroupBy("group by s.sku_id ");

// QUERY 5, skusas, is deprecated. It used to have a subquery itself, and be used to set the Is SKU Sold As Singles column, but per Julissa, that column is no longer needed

// QUERY 6, skuac (average cost), formerly query 7

var skuac = new SelectSQLBuilder();

skuac.setSelect("select ii.sku_id, sum(ii.quantity * ii.merchantPrice) / sum(ii.quantity) as cost ");
skuac.setFrom("from ecommerce.RSInventoryItem as ii ");
skuac.setWhere("where ii.quantity > 0 and ii.merchantPrice > 0 and ii.sku_id is not null");
skuac.setGroupBy("group by ii.sku_id");

// QUERY 7, skuprice, formerly query 6

var skuprice = new SelectSQLBuilder();

skuprice.setSelect("select pr.source_id as sku_id, min(pr.customerprice) as price ");
skuprice.setFrom("from ecommerce.price as pr ");
skuprice.setWhere("where pr.pricetype_id = 1 and pr.sourceclass_id = 13 and pr.customerprice > 0 ");
skuprice.setGroupBy("group by pr.source_id");

// QUERY 8: skucalc, formerly query 1

var skucalc = new SelectSQLBuilder();

skucalc.setSelect("select s.sku_id ");
skucalc.appendSelect("COALESCE(max(rcvd.receiveddate::DATE), s.initialLaunchDate::DATE, s.daterecordadded::DATE) AS skuReorderDate ");
skucalc.appendSelect("(abs(EXTRACT(DAY FROM COALESCE(MAX(rcvd.receiveddate), MAX(ii.daterecordadded), MAX(s.daterecordadded), MAX(s.initiallaunchdate)) - now())))/365 AS skuReorderAge ");
skucalc.appendSelect("(COALESCE(skuprice.price,0.00)) AS skuPrice ");
skucalc.appendSelect("(COALESCE(skuac.cost,0.00)) AS skuAverageCost ");
skucalc.appendSelect("(COALESCE(skuinitcost.cost,0.00)) AS skuInitialCost ");
skucalc.appendSelect("(COALESCE(skuccost.price,0.00)) AS skuCurrentCost ");
skucalc.addCommonTableExpression("skuprice", skuprice);
skucalc.addCommonTableExpression("skuac", skuac);
skucalc.addCommonTableExpression("skuccost", skuccost);
skucalc.addCommonTableExpression("skuinitcost", skuinitcost);
skucalc.setFrom("from ecommerce.sku as s LEFT OUTER JOIN skuccost ON s.sku_id = skuccost.sku_id LEFT OUTER JOIN skuinitcost ON s.sku_id = skuinitcost.sku_id LEFT OUTER JOIN skuac ON s.sku_id = skuac.sku_id LEFT OUTER JOIN skuprice ON s.sku_id = skuprice.sku_id ");
skucalc.appendFrom("ecommerce.rsinventoryitem as ii, ecommerce.receivingevent as rcvd ");
skucalc.setWhere("where ii.sku_id = s.sku_id and ii.receivingevent_id = rcvd.receivingevent_id ");
skucalc.setGroupBy("group by s.sku_id, skuccost.price, skuinitcost.cost, skuac.cost, skuprice.price ");

// QUERY 9: skudata, formerly query 14

var skudata = new SelectSQLBuilder();

skudata.setSelect("select s.sku_id as skuId, sum(ii.quantity) as skuQuantity, min(ii.merchantPrice) as skuLowerOfCost, max(coalesce(ii.weight,0.0)) as skuWeight ");
skudata.appendSelect("string_agg(distinct sup.supplierName,'|') as skuSuppliers ");
skudata.setFrom("from ecommerce.SKU as s, ecommerce.RSInventoryItem as ii, ecommerce.Supplier as sup ");
skudata.setWhere("where s.sku_id = ii.sku_id and ii.active = true and s.skuBitMask & 1 = 1 and ii.supplier_id = sup.supplier_id ");
skudata.setGroupBy("group by s.sku_id ");

// QUERY 10: skudetails, formerly query 15

var skudetails = new SelectSQLBuilder();

skudetails.setSelect("select sku.item_id as skuFamilyId, i.name as skuFamilyName, i.itemStatus_id as skuFamilyStatusId, istB.itemStatus as skuFamilyStatus ");
skudetails.appendSelect("v.name as skuFamilyVendor, sku.sku_id as skuId, ist.itemStatus as skuStatus ");
skudetails.appendSelect("CASE WHEN sku.skuBitMask & 1 = 1 THEN 1 ELSE 0 END as tracksInventory ");
skudetails.appendSelect("sku.name as skuName, sku.partNumber as partnumber, sku.isoCountryCodeOfOrigin as countryCode, ist.itemStatus, skucat.buyer as skuBuyer ");
skudetails.appendSelect("skucat.skucategory1, skucat.skucategory2, skucat.skucategory3, skucat.skucategory4, skucat.skucategory5, skucat.skucategory6, sc.sku_class ");
skudetails.setFrom("from ecommerce.SKU as sku LEFT OUTER JOIN ecommerce.skucategory as skucat on skucat.sku_id = sku.sku_id, ecommerce.ItemStatus as ist ");
skudetails.appendFrom("ecommerce.sku_class as sc, ecommerce.Item as i, ecommerce.ItemStatus as istB, ecommerce.vendor as v ");
skudetails.setWhere("where sku.itemStatus_id = ist.itemStatus_id AND sku.sku_class_id = sc.sku_class_id AND sku.item_id = i.item_id ");
skudetails.appendWhere("i.itemStatus_id = istB.itemStatus_id AND v.vendor_id = i.vendor_id ");
skudetails.setOrderBy("ORDER BY sku.item_id, sku.sku_id ");


// QUERY 11: maxskudates, formerly query 16

var maxSkuDates = new SelectSQLBuilder();

maxSkuDates.setSelect("select ii.sku_id as skuId, max(ii.daterecordadded)::DATE as maxDate ");
maxSkuDates.setFrom("from ecommerce.RSInventoryItem as ii  ");
maxSkuDates.setGroupBy("group by ii.sku_id ");


// QUERY 12: mostrecentsupplier, formerly query 17

var mostrecentsupplier = new SelectSQLBuilder();

mostrecentsupplier.setSelect("select maxSkuDates.skuid as skuId, sup.supplierName ");
mostrecentsupplier.addCommonTableExpression("maxSkuDates", maxSkuDates);
mostrecentsupplier.setFrom("from ecommerce.sku as s RIGHT JOIN maxSkuDates as maxSkuDates ON s.sku_id = maxSkuDates.skuid ");
mostrecentsupplier.appendFrom("ecommerce.RSInventoryItem as ii, ecommerce.Supplier as sup ");
mostrecentsupplier.setWhere("where maxSkuDates.skuId = ii.sku_id AND maxSkuDates.maxDate::DATE = ii.daterecordadded::DATE AND ii.supplier_id = sup.supplier_id ");
mostrecentsupplier.setOrderBy("ORDER BY maxSkuDates.skuId ");


// QUERY 13, skuMain, formerly query 18
var skuMain = new SelectSQLBuilder();

skuMain.setSelect("select skudetails.skuFamilyId, skudetails.skuFamilyName, skudetails.skuFamilyStatusId, skudetails.skuFamilyStatus, skudetails.skuFamilyVendor, skudetails.skuId, skudetails.skuStatus, skudetails.tracksInventory ");
skuMain.appendSelect("skudetails.skuName, skudetails.partnumber, skudetails.countryCode, skudetails.skuBuyer, skudetails.skucategory1, skudetails.skucategory2, skudetails.skucategory3, skudetails.skucategory4, skudetails.skucategory5, skudetails.skucategory6 ");
skuMain.appendSelect("skudetails.sku_class, skudata.skuQuantity, skudata.skuLowerOfCost, skudata.skuWeight, skudata.skuSuppliers, skucalc.skuReorderDate, skucalc.skuReorderAge, skucalc.skuPrice, skucalc.skuAverageCost ");
skuMain.appendSelect("skucalc.skuInitialCost, skucalc.skuCurrentCost, mostrecentsupplier.supplierName ");
skuMain.addCommonTableExpression("skucalc", skucalc);
skuMain.addCommonTableExpression("skudata", skudata);
skuMain.addCommonTableExpression("skudetails", skudetails);
skuMain.addCommonTableExpression("mostrecentsupplier", mostrecentsupplier);
skuMain.setFrom("from ecommerce.sku as s LEFT OUTER JOIN skucalc AS skucalc ON s.sku_id = skucalc.sku_id LEFT OUTER JOIN skudetails as skudetails ON s.sku_id = skudetails.skuId LEFT OUTER JOIN skudata ON s.sku_id = skudata.skuid LEFT OUTER JOIN mostrecentsupplier as mostrecentsupplier ON s.sku_id = mostrecentsupplier.skuId ");
skuMain.setWhere("where true");
skuMain.setOrderBy("order by skudetails.skuFamilyId, skudetails.skuId "); 


// QUERY 14: versionDetails, formerly query 19
var versionDetails = new SelectSQLBuilder();

versionDetails.setSelect("select v.productVersion_id as versionId, v.item_id as versionFamilyId, v.itemStatus_id as versionStatusId, v.name as versionName, ist.itemStatus as versionStatus, i.name as versionFamilyName ");
versionDetails.setFrom("from ecommerce.ProductVersion as v, ecommerce.ItemStatus as ist, ecommerce.item as i ");
versionDetails.setWhere("where v.itemStatus_id = ist.itemStatus_id and v.item_id = i.item_id ");


// QUERY 15, pvskuid, formerly query 20
//var pvskuid = new SelectSQLBuilder();

//pvskuid.setSelect("select pvsku.productVersion_id::varchar || '-' || pvsku.sku_id::varchar as versionSkuId, pvsku.productVersion_id as versionId, pvsku.sku_id as skuId ");
//pvskuid.setFrom("from ecommerce.ProductVersionSKU as pvsku ");
//pvskuid.setWhere("where true ");


// QUERY 16: versionsales (also aliased in other iterations as vs2016), formerly query 21
var versionsales = new SelectSQLBuilder();

versionsales.setSelect("select rsli.productVersion_id as versionId, extract( 'year' from rsli.fulfillmentDate) as year, sum(rsli.quantity) as units, sum(rsli.customerPrice * rsli.quantity) as revenue ");
versionsales.setFrom("from ecommerce.RSLineItem as rsli, ecommerce.RSOrder as o ");
versionsales.setWhere("where o.oid = rsli.order_id and rsli.fulfillmentDate >= '2015-01-01' and coalesce(rsli.lineItemType_id,1) in (1,5) and rsli.productVersion_id IS NOT NULL ");
versionsales.setGroupBy("group by rsli.productVersion_id, extract( 'year' from rsli.fulfillmentDate) ");
versionsales.setOrderBy("order by extract( 'year' from rsli.fulfillmentDate) DESC ");

if (notEmpty(storeId)) {
      versionsales.appendWhere("o.store_id = " + storeId);
}

if (notEmpty(orderSource)) {
      versionsales.appendWhere("o.order_source_id = " + orderSource);
}

// QUERY 17, formerly query 22
var tempnext = new SelectSQLBuilder();

tempnext.setSelect("select ii.sku_id, sum(ii.quantity * ii.merchantPrice) / sum(ii.quantity) as cost ");
tempnext.setFrom("from ecommerce.RSInventoryItem as ii ");
tempnext.setWhere("where ii.quantity > 0 and ii.merchantPrice > 0 and ii.sku_id is not null ");
tempnext.setGroupBy("group by ii.sku_id ");


// QUERY 18: vac (formerly versionAvgCost), formerly query 23
var vac = new SelectSQLBuilder();

vac.setSelect("select pvs.productVersion_id as versionId, sum(pvs.quantity * tempnext.cost) as cost");
vac.addCommonTableExpression("tempnext", tempnext);
vac.setFrom("from ecommerce.ProductVersionSKU as pvs LEFT OUTER JOIN tempnext as tempnext ON tempnext.sku_id = pvs.sku_id ");
vac.setWhere("where true ");
vac.setGroupBy("group by pvs.productVersion_id ");


// QUERY 19: vap (formerly versionAvgPrice), formerly query 24
var vap = new SelectSQLBuilder();

vap.setSelect("select rsli.productVersion_id as versionId, sum(rsli.customerPrice/rsli.quantity) / sum(rsli.quantity) as price ");
vap.setFrom("from ecommerce.RSLineItem as rsli");
vap.setWhere("where rsli.fulfillmentDate is not null and rsli.fulfillmentDate > '2015-01-01' and rsli.quantity > 0 ");
vap.setGroupBy("group by rsli.productVersion_id");



// QUERY 20: vcp (formerly vCurrentPrice), formerly query 25
var vcp = new SelectSQLBuilder();

vcp.setSelect("select distinct pv.productVersion_id as versionId, COALESCE(p1.customerPrice,p2.customerPrice) as price, p1.active ");
vcp.setFrom("from ecommerce.ProductVersion as pv LEFT OUTER JOIN ecommerce.Price as p1 ON pv.productVersion_id = p1.source_id AND p1.sourceclass_id = 9 AND p1.priceType_id = 1 AND (p1.active = TRUE OR p1.active IS NULL) LEFT OUTER JOIN ecommerce.Price as p2 ON pv.item_id = p2.source_id AND p2.sourceclass_id = 5 AND p2.priceType_id = 1 AND (p2.active = TRUE OR p2.active IS NULL) ");
vcp.setWhere("where true ");


// QUERY 21: vfds (formerly versionFirstDateSold), formerly query 26
var vfds = new SelectSQLBuilder();

vfds.setSelect("select rsli.productVersion_id as versionId, min(to_char(rsli.fulfillmentDate,'yyyymmdd')::int) as firstDateSold ");
vfds.setFrom("from ecommerce.RSLineItem as rsli ");
vfds.setWhere("where rsli.lineItemType_id = 1 and rsli.fulfillmentDate is not null ");
vfds.setGroupBy("group by rsli.productVersion_id ");


// QUERY 22, last14, formerly query 27
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

// QUERY 23, formerly query 28
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


// QUERY 24, formerly query 29
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

// QUERY 25, formerly query 30
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



// QUERY 26, formerly query 31
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
// QUERY 26, formerly query 33
var versionSkuQuantity = new SelectSQLBuilder();

versionSkuQuantity.setSelect("select pvs.productVersion_id as versionId, pvs.sku_id as skuId, pvs.quantity ");
versionSkuQuantity.setFrom("from ecommerce.ProductVersionSKU as pvs ");
versionSkuQuantity.setWhere("where true ");

// QUERY 27, versionMonthSales, formerly query 34. Only called if the Order Month input is selected. 

if(notEmpty(salesMonth)){
var versionMonthSales = new SelectSQLBuilder(); 

versionMonthSales.setSelect("select rsli.productVersion_id as versionId, to_char(rsli.fulfillmentDate,'yyyy-MM') as month, sum(rsli.quantity) as units, sum(rsli.quantity * rsli.customerPrice) as revenue ");
versionMonthSales.setFrom("from ecommerce.RSLineItem as rsli, ecommerce.RSOrder as o ");
versionMonthSales.setWhere("where o.oid = rsli.order_id and coalesce(rsli.lineItemType_id,1) in (1,5) and rsli.fulfillmentDate is not null ");
versionMonthSales.appendWhere("rsli.fulfillmentDate >= '" + salesMonth + "-01' ");
versionMonthSales.appendWhere("to_char(rsli.fulfillmentDate,'yyyy-MM') = '" + salesMonth + "' ");
versionMonthSales.setGroupBy("group by versionId, month ");
}

// QUERY 27: vwap (formerly VersionWeightedAveragePrice), formerly query 35
var vwap = new SelectSQLBuilder();

vwap.setSelect("select rsli.productVersion_id as versionId, sum(rsli.customerPrice/rsli.quantity) / sum(rsli.quantity) as price ");
vwap.setFrom("from ecommerce.RSLineItem as rsli ");
vwap.setWhere("where rsli.fulfillmentDate is not null and rsli.fulfillmentDate >= '2015-01-01' and rsli.quantity > 0 ");
vwap.setGroupBy("group by rsli.productVersion_id HAVING sum(rsli.quantity) > 0 ");


// QUERY 28: singles (formerly s), formerly query 36
var singles = new SelectSQLBuilder();

singles.setSelect("select pvsku.productVersion_id ");
singles.setFrom("from ecommerce.ProductVersionSKU as pvsku ");
singles.setWhere("where true ");
singles.setGroupBy("group by productVersion_id HAVING count(*) = 1 ");


// QUERY 29: svp (formerly singleVersionPrice, SingleVersionPrice), formerly query 37
var svp = new SelectSQLBuilder();

svp.setSelect("select vwap.versionId as versionId, vwap.price ");
svp.addCommonTableExpression("vwap", vwap);
svp.addCommonTableExpression("singles", singles);
svp.setFrom("from ecommerce.productversion as pv LEFT OUTER JOIN vwap as vwap ON vwap.versionId = pv.productversion_id RIGHT JOIN singles as singles ON pv.productversion_id = singles.productversion_id ");
svp.setWhere("where true ");


// QUERY 30: tmp_sku1 (formerly TMP_SKU_PRICE): query 1 (this one takes care of any SKU-level prices), formerly query 38
var tmp_sku1 = new SelectSQLBuilder();

tmp_sku1.setSelect("select pvsku.sku_id as skuId, pr.customerprice as customerprice ");
tmp_sku1.setFrom("from ecommerce.price as pr, ecommerce.ProductVersionSKU as pvsku ");
tmp_sku1.setWhere("where pvsku.sku_id = pr.source_id and pvsku.quantity > 0 and pr.pricetype_id = 1 AND pr.sourceclass_id = 13 ");
tmp_sku1.setGroupBy("group by pvsku.sku_id, pr.pricetype_id, pr.sourceclass_id, pr.customerprice ");

// QUERY 31: new added table tmp_sku2 (this one is for everything else)
var tmp_sku2 = new SelectSQLBuilder();

tmp_sku2.setSelect("select pvsku.sku_id as skuId ");
tmp_sku2.appendSelect("avg(svp.price / pvsku.quantity) as customerprice ");
tmp_sku2.addCommonTableExpression("svp", svp);
tmp_sku2.setFrom("from ecommerce.ProductVersionSKU as pvsku LEFT OUTER JOIN svp as svp ON pvsku.productversion_id = svp.versionId ");
tmp_sku2.setWhere("where pvsku.quantity > 0 ");
tmp_sku2.setGroupBy("group by pvsku.sku_id, svp.price, pvsku.quantity ");


// QUERY 32: minskuprice (formerly mSKUPRICE, msp), formerly query 39
var minskuprice = new SelectSQLBuilder();

minskuprice.setSelect("select s.sku_id ");
minskuprice.appendSelect("COALESCE(tmp_sku1.customerprice,(min(tmp_sku2.customerprice))) as price ");
minskuprice.addCommonTableExpression("tmp_sku1", tmp_sku1);
minskuprice.addCommonTableExpression("tmp_sku2", tmp_sku2);
minskuprice.setFrom("from ecommerce.sku as s LEFT OUTER JOIN tmp_sku1 as tmp_sku1 ON s.sku_id = tmp_sku1.skuId LEFT OUTER JOIN tmp_sku2 as tmp_sku2 ON s.sku_id = tmp_sku2.skuId ");
minskuprice.setWhere("where true ");
minskuprice.setGroupBy("group by s.sku_id, tmp_sku1.customerprice ");


// QUERY 33: versionPrice (formerly VERSION_PRICE), formerly query 40
var versionPrice = new SelectSQLBuilder();

versionPrice.setSelect("select pvsku.productVersion_id as versionId, sum(coalesce(minskuprice.price,0) * pvsku.quantity ) as price ");
versionPrice.addCommonTableExpression("minskuprice", minskuprice);
versionPrice.setFrom("from ecommerce.productversionsku as pvsku INNER JOIN minskuprice as minskuprice ON pvsku.sku_id = minskuprice.sku_id ");
versionPrice.setWhere("where true ");
versionPrice.setGroupBy("group by pvsku.productversion_id ");

// QUERY 34: vsrp (formerly versionSkuRevPercentage), formerly query 41
var vsrp = new SelectSQLBuilder();

vsrp.setSelect("select pvsku.productVersion_id as versionId, pvsku.sku_id as skuId ");
vsrp.appendSelect("avg(CASE WHEN versionPrice.price > 0 THEN (versionPrice.price * pvsku.quantity) / versionPrice.price ELSE 0 END) as percentage ");
vsrp.addCommonTableExpression("versionPrice", versionPrice);
vsrp.setFrom("from ecommerce.ProductVersionSKU as pvsku INNER JOIN versionPrice as versionPrice ON pvsku.productVersion_id = versionPrice.versionId ");
vsrp.setWhere("where true");
vsrp.setGroupBy("group by pvsku.productVersion_id, pvsku.sku_id ");

// QUERY 35: new query vsppp (formerly VersionSalePopPickPricing), formerly not on the list
var vsppp = new SelectSQLBuilder();

vsppp.setSelect("select pv.productversion_id as versionId, COALESCE(pr1.customerprice, 0.00) as recommended_sale_price, COALESCE(pr2.customerprice, 0.00) as recommended_pop_pick_price ");
vsppp.setFrom("from ecommerce.productversion as pv, ecommerce.item as i, ecommerce.price as pr1, ecommerce.price as pr2 ");
vsppp.setWhere("where pv.item_id = i.item_id ");
vsppp.appendWhere("i.item_id = pr1.source_id and pr1.sourceclass_id = 5 and pr1.pricetype_id = 5 and i.item_id = pr2.source_id and pr2.sourceclass_id = 5 and pr2.pricetype_id = 6 ");


// QUERY 36, versionData, formerly query 42
var versionData = new SelectSQLBuilder();

versionData.setSelect("select versionDetails.versionId, versionDetails.versionFamilyId, ist.itemstatus as versionFamilyStatus, versionDetails.versionFamilyName, versionDetails.versionStatusId, versionDetails.versionStatus, versionDetails.versionName ");
versionData.appendSelect("versionsales.units as units2016, versionsales.revenue as rev2016 ");
versionData.appendSelect("vac.cost as versionAverageCost, vap.price as versionAveragePrice, vcp.price as currentPrice, vsppp.recommended_sale_price, vsppp.recommended_pop_pick_price ");
versionData.appendSelect("vfds.firstDateSold, last14.units as last14units, last14.revenue as last14rev, last30.units as last30units, last30.revenue as last30rev ");
versionData.appendSelect("last90.units as last90units, last90.revenue as last90rev, last180.units as last180units, last180.revenue as last180rev, last365.units as last365units, last365.revenue as last365rev ");
versionData.addCommonTableExpression("versionDetails", versionDetails);
versionData.addCommonTableExpression("versionsales", versionsales);
versionData.addCommonTableExpression("vac", vac);
versionData.addCommonTableExpression("vap", vap);
versionData.addCommonTableExpression("vcp", vcp);
versionData.addCommonTableExpression("vsppp", vsppp);
versionData.addCommonTableExpression("vfds", vfds);
versionData.addCommonTableExpression("last14", last14);
versionData.addCommonTableExpression("last30", last30);
versionData.addCommonTableExpression("last90", last90);
versionData.addCommonTableExpression("last180", last180);
versionData.addCommonTableExpression("last365", last365);
versionData.setFrom("from ecommerce.productversion as pv LEFT OUTER JOIN versionDetails as versionDetails ON pv.productversion_id = versionDetails.versionId LEFT OUTER JOIN versionsales AS versionsales on pv.productversion_id::integer = versionsales.versionId::integer and versionsales.year::varchar = '2016' LEFT OUTER JOIN vac as vac on pv.productversion_id::integer = vac.versionId::integer LEFT OUTER JOIN vap as vap on pv.productversion_id::integer = vap.versionId::integer LEFT OUTER JOIN vcp as vcp on pv.productversion_id::integer = vcp.versionId::integer LEFT OUTER JOIN vsppp as vsppp on pv.productversion_id::integer = vsppp.versionId::integer LEFT OUTER JOIN vfds as vfds on pv.productversion_id::integer = vfds.versionId::integer LEFT OUTER JOIN last14 as last14 on pv.productversion_id::integer = last14.versionId::integer LEFT OUTER JOIN last30 as last30 on pv.productversion_id::integer = last30.versionId::integer LEFT OUTER JOIN last90 as last90 on pv.productversion_id::integer = last90.versionId::integer LEFT OUTER JOIN last180 as last180 on pv.productversion_id::integer = last180.versionId::integer LEFT OUTER JOIN last365 as last365 on pv.productversion_id::integer = last365.versionId::integer ");
versionData.appendFrom("ecommerce.item as i, ecommerce.itemstatus as ist ");
versionData.setWhere("where i.item_id = pv.item_id and versionDetails.versionFamilyId = i.item_id and i.itemStatus_id = ist.itemstatus_id ");
versionData.setOrderBy("order by versionDetails.versionId asc");

//MAIN QUERY = QUERY 37, formerly query 43
var sqlProcessor = new SelectSQLBuilder();

sqlProcessor.setSelect("select DISTINCT vsid.productversion_id as version_id, vsid.sku_id as sku_id, versionSkuQuantity.quantity AS versionSkuQuantity, vsrp.percentage AS skuRevenuePercentage ");
sqlProcessor.appendSelect("versionData.versionFamilyId, versionData.versionFamilyName, versionData.versionFamilyStatus, versionData.versionStatusId, versionData.versionStatus, versionData.versionName as version_name ");
sqlProcessor.appendSelect("versionData.units2016, versionData.rev2016 ");
sqlProcessor.appendSelect("versionData.versionAverageCost, versionData.versionAveragePrice, versionData.currentPrice, versionData.recommended_sale_price, versionData.recommended_pop_pick_price ");
sqlProcessor.appendSelect("versionData.firstDateSold, versionData.last14units, versionData.last14rev, versionData.last30units, versionData.last30rev, versionData.last90units, versionData.last90rev, versionData.last180units, versionData.last180rev, versionData.last365units, versionData.last365rev ");
sqlProcessor.appendSelect("skuMain.skuFamilyId, skuMain.skuFamilyName, skuMain.skuFamilyStatusId, skuMain.skuFamilyStatus, skuMain.skuFamilyVendor, skuMain.skuStatus, skuMain.tracksInventory, skuMain.skuName as sku_name ");
sqlProcessor.appendSelect("skuMain.partnumber, skuMain.countryCode as country_code, skuMain.skuBuyer, skuMain.skucategory1, skuMain.skucategory2, skuMain.skucategory3, skuMain.skucategory4, skuMain.skucategory5, skuMain.skucategory6 ");
sqlProcessor.appendSelect("skuMain.sku_class, skuMain.skuQuantity, skuMain.skuLowerOfCost, skuMain.skuWeight, skuMain.skuSuppliers, skuMain.skuReorderDate, skuMain.skuReorderAge, skuMain.skuPrice, skuMain.skuAverageCost ");
sqlProcessor.appendSelect("skuMain.skuInitialCost, skuMain.skuCurrentCost, skuMain.supplierName as supplier_name ");
sqlProcessor.addCommonTableExpression("versionSkuQuantity", versionSkuQuantity);
sqlProcessor.addCommonTableExpression("vsrp", vsrp);
sqlProcessor.addCommonTableExpression("versionData", versionData);
sqlProcessor.addCommonTableExpression("skuMain", skuMain);
sqlProcessor.setFrom("from ecommerce.productversionsku as vsid LEFT OUTER JOIN skuMain as skuMain ON vsid.sku_id = skuMain.skuId LEFT OUTER JOIN versionData as versionData ON versionData.versionId = vsid.productversion_id LEFT OUTER JOIN versionSkuQuantity as versionSkuQuantity ON vsid.productversion_id = versionSkuQuantity.versionId AND vsid.sku_id = versionSkuQuantity.skuId LEFT OUTER JOIN vsrp as vsrp ON vsid.productversion_id = vsrp.versionId ");
sqlProcessor.setWhere("where vsid.sku_id = vsrp.skuId ");
sqlProcessor.setOrderBy("order by vsid.productversion_id, vsid.sku_id ");

if(notEmpty(salesMonth)) {
    sqlProcessor.appendSelect("versionMonthSales.month as salesMonth, versionMonthSales.units as salesMonthUnits, versionMonthSales.revenue as salesMonthRevenue ");
    sqlProcessor.addCommonTableExpression("versionMonthSales", versionMonthSales);
    sqlProcessor.appendFrom("ecommerce.productversionsku as pvsku LEFT OUTER JOIN versionMonthSales as versionMonthSales ON pvsku.productVersion_id = versionMonthSales.versionId AND versionMonthSales.month = '" + salesMonth + "' ");
    sqlProcessor.appendWhere("pvsku.productVersion_id = vsid.productVersion_id ");
} else {
    sqlProcessor.appendSelect(" '' as salesMonth, 0 as salesMonthUnits, 0 as salesMonthRevenue ");
}

if(notEmpty(countryCode)){
     sqlProcessor.appendWhere("skuMain.countryCode = '" + countryCode + "' ");
}

if(notEmpty(skuId)){
     sqlProcessor.appendWhere("skuMain.skuId = " + skuId );
}

if(notEmpty(versionId)){
     sqlProcessor.appendWhere("versionData.versionId = " + versionId );
}

if(notEmpty(skuStatus)){
     sqlProcessor.appendWhere("skuMain.skuStatus ILIKE '%" + skuStatus + "%' ");
}

if(notEmpty(skuCategory1)){
     sqlProcessor.appendWhere("skuMain.skuCategory1 ILIKE '%" + skuCategory1 + "%' ");
}

if(notEmpty(skuCategory2)){
     sqlProcessor.appendWhere("skuMain.skuCategory2 ILIKE '%" + skuCategory2 + "%' ");
}

if(notEmpty(skuCategory3)){
     sqlProcessor.appendWhere("skuMain.skuCategory3 ILIKE '%" + skuCategory3 + "%' ");
}

if(notEmpty(skuCategory4)){
     sqlProcessor.appendWhere("skuMain.skuCategory4 ILIKE '%" + skuCategory4 + "%' ");
}

if(notEmpty(skuCategory5)){
     sqlProcessor.appendWhere("skuMain.skuCategory5 ILIKE '%" + skuCategory5 + "%' ");
}

if(notEmpty(skuCategory6)){
     sqlProcessor.appendWhere("skuMain.skuCategory6 ILIKE '%" + skuCategory6 + "%' ");
}

if(notEmpty(skuBuyer)){
     sqlProcessor.appendWhere("skuMain.skuBuyer ILIKE '%" + skuBuyer + "%' ");
}

if(notEmpty(partNumber)){
     sqlProcessor.appendWhere("skuMain.skuPartNumber ILIKE '%" + partNumber + "%' ");
}

if(notEmpty(skuName)){
     sqlProcessor.appendWhere("skuMain.skuName ILIKE '%" + skuName + "%' ");
}

if(notEmpty(skuFamilyVendor)){
     sqlProcessor.appendWhere("skuMain.skuFamilyVendor ILIKE '%" + skuFamilyVendor + "%' ");
}

if(notEmpty(skuSupplierNames)){
     sqlProcessor.appendWhere("skuMain.skuSuppliers ILIKE '%" + skuSupplierNames + "%' "); 
}

sql = sqlProcessor.queryString();