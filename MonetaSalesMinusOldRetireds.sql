
-- Temp table skucalc. Updated by skucost, skuinitcost, skusas, skuprice, and skuac queries. After skucalc is populated by all those other queries, it's called from skuMain query. 
SELECT sku_id, null::date as skuReorderDate, null::float as skuReorderAge, null::float as skuPrice, null::float as skuAverageCost,null::integer as skuSoldAsSingles, null::float as skuInitialCost, null::float as skuCurrentCost
INTO temporary table skucalc 
from ecommerce.sku

-- Temp table tempskudra. Called from skucost query. 
SELECT s.sku_id, max(ii.dateRecordAdded) as dra
INTO temporary table tempskudra
FROM ecommerce.SKU s, ecommerce.RSInventoryItem ii, ecommerce.ProductVersionSKU pvs
WHERE s.sku_id = ii.sku_id
and s.sku_id = pvs.sku_id 
and s.skuBitMask & 1 = 1 
and ii.merchantPrice > 0
GROUP BY s.sku_id

-- Temp table skuccost
SELECT s.sku_id, max(ii.merchantPrice) as price 
INTO temporary table skuccost
FROM tempskudra as dra, ecommerce.SKU as s, ecommerce.RSInventoryItem as ii, ecommerce.ProductVersionSKU as pvs
WHERE s.sku_id = ii.sku_id
and s.sku_id = pvs.sku_id
and s.skuBitMask & 1 = 1
and dra.sku_id = ii.sku_id
and dra.dra = ii.dateRecordAdded and ii.merchantPrice > 0
GROUP BY s.sku_id

-- Update temp table skucalc; populate in the price from skucost where skucalc's "current cost" is null
UPDATE skucalc as sca
SET skuCurrentCost = scc.price 
FROM skuccost as scc
WHERE scc.sku_id = sca.sku_id
and sca.skuCurrentCost is null

-- Temp table skuinitcost
SELECT s.sku_id, max(ii.merchantPrice) as cost
INTO temporary table skuinitcost
FROM
(SELECT s.sku_id, min(ii.dateRecordAdded) as dra
    FROM ecommerce.SKU s, ecommerce.RSInventoryItem ii, ecommerce.ProductVersionSKU pvs
    WHERE s.sku_id = ii.sku_id
    and s.sku_id = pvs.sku_id
    and s.skuBitMask & 1 = 1
    and ii.merchantPrice > 0
    GROUP BY s.sku_id
) as dra, ecommerce.SKU as s, ecommerce.RSInventoryItem as ii, ecommerce.ProductVersionSKU as pvs
WHERE s.sku_id = ii.sku_id 
and s.sku_id = pvs.sku_id 
and s.skuBitMask & 1 = 1
and dra.sku_id = ii.sku_id
and dra.dra = ii.dateRecordAdded
and ii.merchantPrice > 0
GROUP BY s.sku_id

-- Update temp table skucalc; populate in the initial cost from skuinitcost where skucalc's "skuInitialCost" is null
UPDATE skucalc as sca
SET skuInitialCost = sic.cost
FROM skuinitcost as sic
WHERE sic.sku_id = sca.sku_id
and sca.skuInitialCost is null

-- Temp table skusas
SELECT pvsku.sku_id, count(*) as components
INTO temporary table skusas
FROM ecommerce.ProductVersionSKU as pvsku
GROUP BY sku_id

-- Update skucalc temp table; populate in "count" / components from skusas where skucalc's "skuSoldAsSingles" is null
UPDATE skucalc as sca
SET skuSoldAsSingles = sas.components
FROM skusas as sas
WHERE sas.sku_id = sca.sku_id
and sca.skuSoldAsSingles is null

-- Temp table skuprice
SELECT source_id as sku_id, min(customerprice) as price
INTO temporary table skuprice
FROM ecommerce.price
WHERE pricetype_id = 1
and sourceclass_id = 13
and customerprice > 0
GROUP BY source_id

-- Update temp table skucalc; populate in price from skuprice where skucalc's "skuPrice" is null
UPDATE skucalc as sca
SET skuPrice = sp.price
FROM skuprice as sp
WHERE sp.sku_id = sca.sku_id
and sca.skuPrice is null

-- Temp table skuac
SELECT sku_id, sum(quantity * merchantPrice) / sum(quantity) as cost
INTO temporary table skuac
FROM ecommerce.RSInventoryItem 
WHERE quantity > 0
and merchantPrice > 0
and sku_id is not null
GROUP BY sku_id

-- Update skucalc temp table; populate in cost from skuac where skucalc's "skuPrice" is null
UPDATE skucalc as sca
SET skuAverageCost = sac.cost
FROM skuac as sac
WHERE sac.sku_id = sca.sku_id
and sca.skuPrice is null

-- Put a sku placeholder into temp table reorderage. Updated by retemp0, retemp1, retemp4, and retemp5 queries. After it's populated, it's called from skura query. 
SELECT sku_id, null::timestamp as reorder_date
INTO temporary table reorderage
FROM ecommerce.sku

-- Put the max receiving event date for each PO lineitem SKU into temp table retemp0
SELECT poli.sku_id, max(re.receiveddate) as reorder_date
INTO temporary table retemp0
FROM ecommerce.purchaseorderlineitem poli, ecommerce.receivingevent as re
WHERE poli.poLineItem_id = re.poLineItem_id
GROUP BY poli.sku_id

-- update missing values reorderage temp table with retemp0 values
UPDATE reorderage
SET reorder_date = retemp0.reorder_date
FROM retemp0
WHERE reorderage.sku_id = retemp0.sku_id

-- Put the max receiving event date for each RSinventoryitem SKU into temp table retemp1
SELECT rsii.sku_id as skuid, max(re.receiveddate) as redate
INTO temporary table retemp1
FROM ecommerce.rsinventoryitem as rsii, ecommerce.receivingevent as re
WHERE rsii.receivingevent_id = re.receivingevent_id 
group by rsii.sku_id

-- update missing values in reorderage temp table with retemp1 values
UPDATE reorderage
SET reorder_date = redate
FROM retemp1
WHERE sku_id = skuid
and reorder_date is null

-- Put SKU initial launch date into temp table retemp4
SELECT sku_id as skuid, initialLaunchDate as redate
INTO temporary table retemp4
FROM ecommerce.sku

-- update missing values in reorderage temp table with retemp4 values
UPDATE reorderage
SET reorder_date = redate
FROM retemp4
WHERE sku_id = skuid
and reorder_date is null

-- Put SKU date record added into temp table retemp5
SELECT sku_id as skuid, daterecordadded as redate
INTO temporary table retemp5
FROM ecommerce.sku

-- update missing values in reorderage temp table with retemp5 values
UPDATE reorderage
SET reorder_date = redate
FROM retemp5
WHERE sku_id = skuid
and reorder_date is null

-- Temp table skura. Used to update skucalc. 
SELECT sku_id, reorder_date::date as reorderDate, (now()::date - reorder_date::date)/365.0 as age
INTO temporary table skura
FROM reorderage

-- Update skucalc temp table
UPDATE skucalc as sca
SET skuReorderDate = sra.reorderDate, skuReorderAge = sra.age
FROM skura as sra
WHERE sra.sku_id = sca.sku_id

-- Temp table skudata. Called from skuMain. 
select s.sku_id as skuId, sum(ii.quantity) as skuQuantity, min(ii.merchantPrice) as skuLowerOfCost, max(coalesce(ii.weight,0.0)) as skuWeight, string_agg(distinct sup.supplierName,'|') as skuSuppliers
INTO temporary table skudata
FROM ecommerce.SKU as s, ecommerce.RSInventoryItem as ii, ecommerce.Supplier sup
WHERE s.sku_id = ii.sku_id
and ii.active=true
and s.skuBitMask & 1 = 1
and ii.supplier_id = sup.supplier_id
group by s.sku_id

-- Temp table skudetails. Called from skuMain. 
select sku.item_id as skuFamilyId, i.name as skuFamilyName, i.itemStatus_id as skuFamilyStatusId, istB.itemStatus as skuFamilyStatus, v.name as skuFamilyVendor, sku.sku_id as skuId, ist.itemStatus as skuStatus, CASE WHEN sku.skuBitMask & 1 = 1 THEN 1 ELSE 0 END as tracksInventory, sku.name as skuName, sku.partNumber as partnumber, sku.isoCountryCodeOfOrigin as countryCode, ist.itemStatus, skucat.buyer as skuBuyer, skucat.skucategory1, skucat.skucategory2, skucat.skucategory3, skucat.skucategory4, skucat.skucategory5, skucat.skucategory6, sc.sku_class
INTO temporary table skudetails
FROM ecommerce.SKU as sku
left outer join ecommerce.skucategory skucat 
    on skucat.sku_id = sku.sku_id, ecommerce.ItemStatus as ist, ecommerce.sku_class as sc, ecommerce.Item i, ecommerce.ItemStatus istB, ecommerce.vendor v
WHERE sku.itemStatus_id = ist.itemStatus_id
AND sku.sku_class_id = sc.sku_class_id
AND sku.item_id = i.item_id
AND i.itemStatus_id = istB.itemStatus_id
AND v.vendor_id = i.vendor_id
AND (sku.date_retired IS NULL OR sku.date_retired::DATE >= date_trunc('month',now()::DATE) - cast('5 years' as interval))
ORDER BY sku.item_id, sku.sku_id

-- Temp table maxSkuDates. Called from mostRecentSupplier.
SELECT sku_id as skuId, max(daterecordadded) as maxDate
INTO temporary table maxSkuDates
FROM ecommerce.RSInventoryItem as ii
GROUP BY sku_id

-- Temp table mostRecentSupplier. Called from skuMain. 
SELECT sku_id as skuId, sup.supplierName
INTO temporary table mostRecentSupplier
FROM maxSkuDates as msd, ecommerce.RSInventoryItem as ii, ecommerce.Supplier sup
WHERE msd.skuId = ii.sku_id
AND msd.maxDate = ii.daterecordadded
AND ii.supplier_id = sup.supplier_id
ORDER BY msd.skuId

-- Temp table skuMain. Called from main query. 
select sd.skuFamilyId, sd.skuFamilyName, sd.skuFamilyStatusId, sd.skuFamilyStatus, sd.skuFamilyVendor, sd.skuId, sd.skuStatus, sd.tracksInventory, sd.skuName, sd.partnumber, sd.countryCode, sd.skuBuyer, sd.skucategory1, sd.skucategory2, sd.skucategory3, sd.skucategory4, sd.skucategory5, sd.skucategory6, sd.sku_class, skud.skuQuantity, skud.skuLowerOfCost, skud.skuWeight, skud.skuSuppliers,skuc.skuReorderDate, skuc.skuReorderAge, skuc.skuPrice, skuc.skuAverageCost, skuc.skuSoldAsSingles, skuc.skuInitialCost, skuc.skuCurrentCost, mrs.supplierName
INTO temporary table skuMain
FROM skudetails sd
left outer join skudata skud 
    on sd.skuId = skud.skuId
left outer join skucalc skuc 
    on sd.skuId = skuc.sku_id
left outer join mostRecentSupplier mrs 
    on sd.skuId = mrs.skuId
WHERE true
ORDER BY sd.skuFamilyId, sd.skuId

-- Temp table versionDetails. Called from versionData query. 
select v.productVersion_id as versionId, v.item_id as versionFamilyId, v.itemStatus_id versionStatusId, v.name as versionName, ist.itemStatus as versionStatus, i.name as versionFamilyName
INTO temporary table versionDetails
FROM ecommerce.ProductVersion v, ecommerce.ItemStatus ist, ecommerce.item i
WHERE v.itemStatus_id = ist.itemStatus_id
and v.item_id = i.item_id

-- Temp table pvskuid. Called from main query. 
select pvsku.productVersion_id::varchar || '-' || pvsku.sku_id::varchar as versionSkuId, pvsku.productVersion_id as versionId, pvsku.sku_id as skuId
into temporary table pvskuid
from ecommerce.ProductVersionSKU as pvsku

-- Temp table versionSales. Called from versionData query. 
SELECT productVersion_id::varchar as versionId, extract( 'year' from fulfillmentDate) as year, sum(quantity) as units, sum(customerPrice * quantity) as revenue
INTO temporary table versionSales
FROM ecommerce.RSLineItem, ecommerce.RSOrder o
WHERE o.oid = order_id
and fulfillmentDate >= '2010-01-01'

if(notEmpty(storeId)){
	sql += " and o.store_id = " + storeId + " ";
}
if(notEmpty(orderSource)){
	sql += " and o.order_source_id = " + orderSource + " ";
}

and coalesce(lineItemType_id,1) in (1,5)
and productVersion_id is not null
GROUP BY productVersion_id::varchar, extract( 'year' from fulfillmentDate)
ORDER BY extract( 'year' from fulfillmentDate) DESC

-- Temp table tempnext. Called from versionAvgCost.
select sku_id, sum(quantity * merchantPrice) / sum(quantity) as cost
into temporary table tempnext
from ecommerce.RSInventoryItem
where quantity > 0
and merchantPrice > 0
and sku_id is not null
group by sku_id

-- Temp table versionAvgCost. Called from versionData. 
select pvs.productVersion_id as versionId, sum(pvs.quantity * tn.cost) as cost
into temporary table versionAvgCost
from ecommerce.ProductVersionSKU as pvs, tempnext as tn
where tn.sku_id = pvs.sku_id
group by pvs.productVersion_id

-- Temp table versionAvgPrice. Called from versionData.
select productVersion_id as versionId, sum(customerPrice/quantity) / sum(quantity) as price
into temporary table versionAvgPrice
from ecommerce.RSLineItem
where fulfillmentDate is not null
and fulfillmentDate > '2009-12-31 23:59:59'
and quantity > 0
group by productVersion_id

-- Temp table vCurrentPrice. Called from versionData.
select distinct pv.productVersion_id as versionId, COALESCE(p1.customerPrice,p2.customerPrice) as price
INTO temporary table vCurrentPrice
FROM ecommerce.ProductVersion as pv
LEFT OUTER JOIN ecommerce.Price as p1
    ON pv.productVersion_id = p1.source_id
    AND p1.sourceclass_id = 9
    AND p1.priceType_id = 1
LEFT OUTER JOIN ecommerce.Price as p2
    ON pv.item_id = p2.source_id
    AND p2.sourceclass_id = 5
    AND p2.priceType_id = 1

-- Temp table versionFirstDateSold. Called from versionData.
SELECT rsli.productVersion_id as versionId, min(to_char(rsli.fulfillmentDate,'yyyymmdd')::int) as firstDateSold
INTO temporary table versionFirstDateSold
FROM ecommerce.RSLineItem as rsli
WHERE rsli.lineItemType_id = 1
and rsli.fulfillmentDate is not null 
GROUP BY rsli.productVersion_id

-- Temp table last14. Called from versionData. 
SELECT rsli.productVersion_id as versionId, sum(rsli.customerPrice * rsli.quantity) as revenue, sum(rsli.quantity) as units
INTO temporary table last14
FROM ecommerce.RSLineItem rsli, ecommerce.rsorder o
WHERE coalesce(rsli.lineItemType_id,1) in (1,5) 
and o.oid = rsli.order_id

if(notEmpty(storeId)){
	and o.store_id = " + storeId + "
}
if(notEmpty(orderSource)){
	 and o.order_source_id = " + orderSource + "
}

and rsli.fulfillmentDate >= now() - interval '14 days'
GROUP BY rsli.productVersion_id

-- Temp table last30. Called from versionData. 
SELECT rsli.productVersion_id as versionId, sum(rsli.customerPrice * rsli.quantity) as revenue, sum(rsli.quantity) as units
INTO temporary table last30
FROM ecommerce.RSLineItem rsli, ecommerce.RSOrder o
WHERE coalesce(rsli.lineItemType_id,1) in (1,5)
and o.oid = rsli.order_id 

if(notEmpty(storeId)){
	and o.store_id = " + storeId + "
}

if(notEmpty(orderSource)){
	and o.order_source_id = " + orderSource + "
}

and rsli.fulfillmentDate >= now() - interval '30 days' 
GROUP BY rsli.productVersion_id

-- Temp table last90. Called from versionData. 
SELECT rsli.productVersion_id as versionId, sum(rsli.customerPrice * rsli.quantity) as revenue, sum(rsli.quantity) as units
INTO temporary table last90
FROM ecommerce.RSLineItem rsli, ecommerce.RSOrder o
WHERE coalesce(rsli.lineItemType_id,1) in (1,5)
and o.oid = rsli.order_id

if(notEmpty(storeId)){
	and o.store_id = " + storeId + "
}
if(notEmpty(orderSource)){
	and o.order_source_id = " + orderSource + "
}

and rsli.fulfillmentDate >= now()::date - interval '90 days'
GROUP BY rsli.productVersion_id

-- Temp table last180. Called from versionData. 
SELECT rsli.productVersion_id as versionId, sum(rsli.customerPrice * rsli.quantity) as revenue, sum(rsli.quantity) as units
INTO temporary table last180
FROM ecommerce.RSLineItem as rsli, ecommerce.RSOrder o
WHERE coalesce(rsli.lineItemType_id,1) in (1,5) and o.oid = rsli.order_id

if(notEmpty(storeId)){
	and o.store_id = " + storeId + "
}

if(notEmpty(orderSource)){
	and o.order_source_id = " + orderSource + "
}

and rsli.fulfillmentDate >= now() - interval '180 days'
GROUP BY rsli.productVersion_id

-- Temp table last365. Called from versionData.
SELECT rsli.productVersion_id as versionId, sum(rsli.customerPrice * rsli.quantity) as revenue, sum(rsli.quantity) as units
INTO temporary table last365
FROM ecommerce.RSLineItem as rsli, ecommerce.RSOrder o
WHERE coalesce(rsli.lineItemType_id,1) in (1,5)
and o.oid = rsli.order_id

if(notEmpty(storeId)){
	and o.store_id = " + storeId + "
}
if(notEmpty(orderSource)){
	and o.order_source_id = " + orderSource + "
}

and rsli.fulfillmentDate >= now() - interval '365 days'
GROUP BY rsli.productVersion_id

-- Temp table lastSixWeeks. Called from versionData. 
SELECT rsli.productVersion_id as versionId, sum(rsli.quantity) as units, sum(rsli.quantity * rsli.customerPrice) as revenue
INTO temporary table lastSixWeeks
FROM ecommerce.RSLineItem as rsli, ecommerce.RSOrder o
WHERE coalesce(rsli.lineItemType_id,1) in (1,5)
and o.oid = rsli.order_id

if(notEmpty(storeId)){
	and o.store_id = " + storeId + "
}
if(notEmpty(orderSource)){
	and o.order_source_id = " + orderSource + "
}

and rsli.fulfillmentDate >= now() - interval '42 days'
GROUP BY rsli.productVersion_id

-- Temp table versionSkuQuantity. Called from main query. 
SELECT pvs.productVersion_id as versionId, pvs.sku_id as skuId, pvs.quantity
INTO temporary table versionSkuQuantity
FROM ecommerce.ProductVersionSKU as pvs

if(notEmpty(salesMonth)){
	-- Temp table versionMonthSales. Called from main query, if applicable. 
    SELECT rsli.productVersion_id as versionId, to_char(rsli.fulfillmentDate,'yyyy-MM') as month, sum(rsli.quantity) as units, sum(rsli.quantity * rsli.customerPrice) as revenue
    INTO temporary table versionMonthSales
    FROM ecommerce.RSLineItem as rsli, ecommerce.RSOrder o
    WHERE o.oid = rsli.order_id

	if(notEmpty(storeId)){
		and o.store_id = " + storeId + "
	}
	if(notEmpty(orderSource)){
		and o.order_source_id = " + orderSource + "
	}

	and rsli.fulfillmentDate >= '" + salesMonth + "-01'
    and to_char(rsli.fulfillmentDate,'yyyy-MM') = '" + salesMonth + "'
	and coalesce(rsli.lineItemType_id,1) in (1,5)
    and rsli.fulfillmentDate is not null
    GROUP BY versionId, month
}

--begin versionSkuRevenuePercentage
-- Temp table versionWeightedAveragePrice. Called from SingleVersionPrice. 
SELECT productVersion_id as versionId, sum(customerPrice/quantity) / sum(quantity) as price
INTO temporary table versionWeightedAveragePrice
FROM ecommerce.RSLineItem
WHERE fulfillmentDate is not null
and fulfillmentDate >= '2010-01-01'
and quantity > 0
GROUP BY productVersion_id
HAVING sum(quantity) > 0

-- Temp table Singles. Called from both SingleVersionPrice and TMP_SKU_PRICE. 
SELECT pvsku.productVersion_id
INTO temporary table Singles
FROM ecommerce.ProductVersionSKU as pvsku
GROUP BY productVersion_id
HAVING count(*) = 1

-- Temp table SingleVersionPrice. Called from TEMP_SKU_PRICE. 
SELECT vwap.versionId as versionId, vwap.price
INTO temporary table SingleVersionPrice
FROM VersionWeightedAveragePrice as vwap, Singles as s
WHERE s.productVersion_id = vwap.versionId

-- Temp table TMP_SKU_PRICE. Called from mSKUPRICE. 
SELECT pvsku.sku_id as skuId, avg(svp.price / pvsku.quantity) as price
INTO temporary table TMP_SKU_PRICE
FROM SingleVersionPrice as svp, Singles as s, ecommerce.ProductVersionSKU as pvsku
WHERE svp.versionId = s.productVersion_id
and pvsku.productVersion_id = s.productVersion_id
and pvsku.quantity > 0
GROUP BY pvsku.sku_id

-- UPDATE TMP_SKU_PRICE table
INSERT INTO TMP_SKU_PRICE (skuId,price)
SELECT source_id as skuId, customerprice
FROM ecommerce.price
WHERE pricetype_id = 1
and sourceclass_id = 13

-- Temp table mSKUPRICE. Called from both VERSIONPRICE and versionSkuRevPercentage.
SELECT skuId, min(price) as price
INTO temporary table mSKUPRICE
FROM TMP_SKU_PRICE
WHERE price > 0
GROUP BY skuId

-- Temp table VERSION_PRICE. Called from versionSkuRevPercentage.
SELECT pvsku.productVersion_id as versionId, sum(coalesce(sp.price,0) * pvsku.quantity ) as price
INTO temporary table VERSION_PRICE
FROM mSKUPRICE as sp, ecommerce.productversionsku as pvsku
WHERE pvsku.sku_id = sp.skuId
GROUP BY productversion_id

-- Temp table versionSkuRevPercentage. Called from main query. 
SELECT pvsku.productVersion_id as versionId, pvsku.sku_id as skuId, avg(CASE WHEN vp.price > 0 THEN (sp.price * pvsku.quantity) / vp.price ELSE 0 END) as percentage
INTO temporary table versionSkuRevPercentage
FROM ecommerce.ProductVersionSKU as pvsku, VERSION_PRICE as vp, mSKUPRICE as sp
WHERE pvsku.productVersion_id = vp.versionId
and pvsku.sku_id = sp.skuId
GROUP BY pvsku.productVersion_id, pvsku.sku_id

-- Version Data temp table. Calls many other queries to build itself. Then, it is called from main query. 
SELECT vd.versionId, vd.versionFamilyId, ist.itemstatus as versionFamilyStatus, vd.versionFamilyName, vd.versionStatusId, vd.versionStatus, vd.versionName, vs2010.units as units2010, vs2010.revenue as rev2010, vs2011.units as units2011, vs2011.revenue as rev2011, vs2012.units as units2012, vs2012.revenue as rev2012, vs2013.units as units2013, vs2013.revenue as rev2013, vs2014.units as units2014, vs2014.revenue as rev2014, vs2015.units as units2015, vs2015.revenue as rev2015, vac.cost as versionAverageCost, vap.price as versionAveragePrice, vcp.price as currentPrice, vfds.firstDateSold, last14.units as last14units, last14.revenue as last14rev, last30.units as last30units, last30.revenue as last30rev, last90.units as last90units, last90.revenue as last90rev, last180.units as last180units, last180.revenue as last180rev, last365.units as last365units, last365.revenue as last365rev, lastSixWeeks.units as lastSixWksUnits, lastSixWeeks.revenue as lastSixWksRev
INTO temporary table versionData
FROM versionDetails vd
left outer join versionsales vs2010 
    on vd.versionId::integer = vs2010.versionId::integer 
    and vs2010.year::varchar = '2010'
left outer join versionsales vs2011 
    on vd.versionId::integer = vs2011.versionId::integer 
    and vs2011.year::varchar = '2011'
left outer join versionsales vs2012 
    on vd.versionId::integer = vs2012.versionId::integer 
    and vs2012.year::varchar = '2012'
left outer join versionsales vs2013 
    on vd.versionId::integer = vs2013.versionId::integer 
    and vs2013.year::varchar = '2013'
left outer join versionsales vs2014 
    on vd.versionId::integer = vs2014.versionId::integer 
    and vs2014.year::varchar = '2014'
left outer join versionsales vs2015 
    on vd.versionId::integer = vs2015.versionId::integer 
    and vs2015.year::varchar = '2015'
left outer join versionAvgCost vac 
    on vd.versionId::integer = vac.versionId::integer
left outer join versionAvgPrice vap 
    on vd.versionId::integer = vap.versionId::integer
left outer join vCurrentPrice vcp 
    on vd.versionId::integer = vcp.versionId::integer
left outer join versionFirstDateSold vfds 
    on vd.versionId::integer = vfds.versionId::integer
left outer join last14 
    on vd.versionId::integer = last14.versionId::integer
left outer join last30 
    on vd.versionId::integer = last30.versionId::integer
left outer join last90 
    on vd.versionId::integer = last90.versionId::integer
left outer join last180 
    on vd.versionId::integer = last180.versionId::integer
left outer join last365 
    on vd.versionId::integer = last365.versionId::integer
left outer join lastSixWeeks 
    on vd.versionId::integer = lastSixWeeks.versionId::integer
, ecommerce.item i, ecommerce.itemstatus ist
WHERE vd.versionFamilyId = i.item_id
AND i.itemStatus_id = ist.itemstatus_id
ORDER BY vd.versionId

-- MAIN QUERY. Calls skuMain, pvskuid, versionSkuQuantity, versionMonthSales (if applicable), versionSkuRevPercentage, and versionData.
SELECT DISTINCT vsid.versionId as version_id, vsid.skuId as sku_id, vsq.quantity AS versionSkuQuantity, vsrp.percentage AS skuRevenuePercentage, vd.versionFamilyId, vd.versionFamilyName, vd.versionFamilyStatus, vd.versionStatusId, vd.versionStatus, vd.versionName as version_name, vd.units2010, vd.rev2010, vd.units2011, vd.rev2011, vd.units2012, vd.rev2012, vd.units2013, vd.rev2013, vd.units2014, vd.rev2014, vd.units2015, vd.rev2015, vd.versionAverageCost, vd.versionAveragePrice, vd.currentPrice, vd.firstDateSold, vd.last14units, vd.last14rev, vd.last30units, vd.last30rev, vd.last90units, vd.last90rev, vd.last180units, vd.last180rev, vd.last365units, vd.last365rev, vd.lastSixWksUnits, vd.lastSixWksRev, sm.skuFamilyId, sm.skuFamilyName, sm.skuFamilyStatusId, sm.skuFamilyStatus, sm.skuFamilyVendor, sm.skuStatus, sm.tracksInventory, sm.skuName as sku_name, sm.partnumber, sm.countryCode as country_code, sm.skuBuyer, sm.skucategory1, sm.skucategory2, sm.skucategory3, sm.skucategory4, sm.skucategory5, sm.skucategory6, sm.sku_class, sm.skuQuantity, sm.skuLowerOfCost, sm.skuWeight, sm.skuSuppliers, sm.skuReorderDate, sm.skuReorderAge, sm.skuPrice, sm.skuAverageCost, sm.skuSoldAsSingles, sm.skuInitialCost, sm.skuCurrentCost, sm.supplierName as supplier_name
if(notEmpty(salesMonth)){
       vms.month as salesMonth, vms.units as salesMonthUnits, vms.revenue as salesMonthRevenue
} else {
        ,'' as salesMonth, 0 as salesMonthUnits, 0 as salesMonthRevenue
}

, vd.versionFamilyStatus

FROM pvskuid vsid
LEFT OUTER JOIN versionSkuQuantity vsq 
    ON vsid.versionId = vsq.versionId 
    AND vsid.skuId = vsq.skuId
LEFT OUTER JOIN versionSkuRevPercentage vsrp 
    ON vsid.versionId = vsrp.versionId 
    AND vsid.skuId = vsrp.skuId

if(notEmpty(salesMonth)){
    LEFT OUTER JOIN versionMonthSales vms 
        ON vsid.versionId = vms.versionId 
        AND vms.month = '" + salesMonth + "'
}

, versionData vd, skuMain sm
WHERE ( vsid.versionId = vd.versionId AND vsid.skuId = sm.skuId

if(notEmpty(countryCode)){
    and sm.countryCode = '" + countryCode + "'
}
if(notEmpty(skuId)){
    and sm.skuId =  + skuId
}
if(notEmpty(versionId)){
    and vd.versionId =  + versionId
}
if(notEmpty(skuStatus)){
    and sm.skuStatus ILIKE '% + skuStatus + %' 
}
if(notEmpty(skuCategory1)){
    and sm.skuCategory1 ILIKE '% + skuCategory1 + "%' 
}
if(notEmpty(skuCategory2)){
    and sm.skuCategory2 ILIKE '% + skuCategory2 + %' 
}
if(notEmpty(skuCategory3)){
    and sm.skuCategory3 ILIKE '% + skuCategory3 + %' 
}
if(notEmpty(skuCategory4)){
    and sm.skuCategory4 ILIKE '% + skuCategory4 + %' 
}
if(notEmpty(skuCategory5)){
    and sm.skuCategory5 ILIKE '% + skuCategory5 + %' 
}
if(notEmpty(skuCategory6)){
    and sm.skuCategory6 ILIKE '% + skuCategory6 + %'
}
if(notEmpty(skuBuyer)){
    and sm.skuBuyer ILIKE '% + skuBuyer + %'
}
if(notEmpty(partNumber)){
	and sm.skuPartNumber ILIKE '% + partNumber + %'
}
if(notEmpty(skuName)){
	and sm.skuName ILIKE '% + skuName + %'
}
if(notEmpty(skuFamilyVendor)){
    and sm.skuFamilyVendor ILIKE '% + skuFamilyVendor + %'
}
if(notEmpty(skuSupplierNames)){
    and sm.skuSuppliers ILIKE '% + skuSupplierNames + %'
}

ORDER BY vsid.versionId, vsid.skuId


