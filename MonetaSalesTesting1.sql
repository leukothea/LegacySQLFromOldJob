SELECT sku_id
 ,null::date as skuReorderDate 
 ,null::float as skuReorderAge 
 ,null::float as skuPrice 
 ,null::float as skuAverageCost 
 ,null::integer as skuSoldAsSingles 
 ,null::float as skuInitialCost 
 ,null::float as skuCurrentCost 
INTO 
 temporary table skucalc from 
 ecommerce.sku; 
 // Query returned successfully: 106897 rows affected, 77 ms execution time.

SELECT s.sku_id  
 ,max(ii.dateRecordAdded) as dra 
INTO 
 temporary table tempskudra 
FROM 
 ecommerce.SKU s 
 ,ecommerce.RSInventoryItem ii 
 ,ecommerce.ProductVersionSKU pvs 
WHERE 
 s.sku_id = ii.sku_id 
 and s.sku_id = pvs.sku_id and s.skuBitMask & 1 = 1 and ii.merchantPrice > 0 
GROUP BY 
 s.sku_id; 
// Query returned successfully: 76808 rows affected, 960 ms execution time.

SELECT s.sku_id 
 ,max(ii.merchantPrice) as price 
INTO 
 temporary table skuccost 
FROM 
 tempskudra as dra 
 ,ecommerce.SKU as s  
 ,ecommerce.RSInventoryItem as ii  
 ,ecommerce.ProductVersionSKU as pvs 
WHERE 
 s.sku_id = ii.sku_id 
 and s.sku_id = pvs.sku_id 
 and s.skuBitMask & 1 = 1 
 and dra.sku_id = ii.sku_id 
 and dra.dra = ii.dateRecordAdded and ii.merchantPrice > 0 
GROUP BY 
 s.sku_id; 
 // Query returned successfully: 74322 rows affected, 1010 ms execution time.

UPDATE 
 skucalc as sca 
SET 
 skuCurrentCost = scc.price  
FROM 
 skuccost as scc 
WHERE 
 scc.sku_id = sca.sku_id 
 and sca.skuCurrentCost is null; 
 // Query returned successfully: 74322 rows affected, 337 ms execution time.

SELECT 
 s.sku_id 
 ,max(ii.merchantPrice) as cost  
INTO 
 temporary table skuinitcost 
FROM 
 (SELECT 
  s.sku_id 
  ,min(ii.dateRecordAdded) as dra 
 FROM 
  ecommerce.SKU s 
  ,ecommerce.RSInventoryItem ii 
  ,ecommerce.ProductVersionSKU pvs 
 WHERE 
  s.sku_id = ii.sku_id 
  and s.sku_id = pvs.sku_id  
  and s.skuBitMask & 1 = 1  
  and ii.merchantPrice > 0 
 GROUP BY 
  s.sku_id 
 ) as dra 
 ,ecommerce.SKU as s 
 ,ecommerce.RSInventoryItem as ii 
 ,ecommerce.ProductVersionSKU as pvs 
WHERE 
 s.sku_id = ii.sku_id 
 and s.sku_id = pvs.sku_id 
 and s.skuBitMask & 1 = 1 
 and dra.sku_id = ii.sku_id 
 and dra.dra = ii.dateRecordAdded  
 and ii.merchantPrice > 0 
GROUP BY 
 s.sku_id; 
 // 74322 rows affected, 2137 ms execution time.

UPDATE 
 skucalc as sca 
SET 
 skuInitialCost = sic.cost  
FROM 
 skuinitcost as sic 
WHERE 
 sic.sku_id = sca.sku_id 
 and sca.skuInitialCost is null; 
 // Query returned successfully: 74322 rows affected, 290 ms execution time.

SELECT 
 pvsku.sku_id 
 ,count(*) as components 
INTO 
 temporary table skusas 
FROM 
 ecommerce.ProductVersionSKU as pvsku 
GROUP BY 
 sku_id; 
 // Query returned successfully: 97844 rows affected, 115 ms execution time.

UPDATE 
 skucalc as sca 
SET 
 skuSoldAsSingles = sas.components  
FROM 
 skusas as sas 
WHERE 
 sas.sku_id = sca.sku_id 
 and sca.skuSoldAsSingles is null; 
 // Query returned successfully: 97844 rows affected, 336 ms execution time.

SELECT 
 source_id as sku_id 
 ,min(customerprice) as price 
INTO 
 temporary table skuprice 
FROM 
 ecommerce.price 
WHERE 
 pricetype_id = 1 
 and sourceclass_id = 13  
 and customerprice > 0 
GROUP BY 
 source_id; 
 // Query returned successfully: 11937 rows affected, 67 ms execution time.

UPDATE 
 skucalc as sca 
SET 
 skuPrice = sp.price 
FROM 
 skuprice as sp 
WHERE 
 sp.sku_id = sca.sku_id 
 and sca.skuPrice is null; 
 // Query returned successfully: 11934 rows affected, 205 ms execution time.

SELECT 
 sku_id 
 ,CASE WHEN (sum(quantity)) > 0 THEN sum(quantity * merchantPrice) / (sum(quantity)) ELSE avg(quantity * merchantPrice) END as cost
INTO 
 temporary table skuac 
FROM 
 ecommerce.RSInventoryItem 
WHERE 
 merchantPrice > 0  
 and sku_id is not null 
GROUP BY 
 sku_id; 
 // Query returned successfully: 27319 rows affected, 141 ms execution time.

UPDATE 
 skucalc as sca 
SET 
 skuAverageCost = sac.cost 
FROM 
 skuac as sac 
WHERE 
 sac.sku_id = sca.sku_id 
 and sca.skuPrice is null; 
 // Query returned successfully: 22936 rows affected, 148 ms execution time.

SELECT 
 sku_id 
 ,null::timestamp as reorder_date 
INTO 
 temporary table reorderage 
FROM 
 ecommerce.sku; 
 // Query returned successfully: 106897 rows affected, 64 ms execution time.

SELECT 
 poli.sku_id,max(re.receiveddate) as reorder_date 
INTO 
 temporary table retemp0 
FROM 
 ecommerce.purchaseorderlineitem poli 
 ,ecommerce.receivingevent as re  
WHERE 
 poli.poLineItem_id = re.poLineItem_id 
GROUP BY 
 poli.sku_id; 
 // Query returned successfully: 69483 rows affected, 485 ms execution time.

UPDATE 
 reorderage 
SET 
 reorder_date = retemp0.reorder_date  
FROM 
 retemp0  
WHERE 
 reorderage.sku_id = retemp0.sku_id; 
// Query returned successfully: 69483 rows affected, 323 ms execution time.

SELECT 
 rsii.sku_id as skuid 
 ,max(re.receiveddate) as redate 
INTO 
 temporary table retemp1 
FROM 
 ecommerce.rsinventoryitem as rsii 
 ,ecommerce.receivingevent as re  
WHERE 
 rsii.receivingevent_id = re.receivingevent_id group by 
 rsii.sku_id; 
 // Query returned successfully: 69348 rows affected, 523 ms execution time.

UPDATE 
 reorderage 
SET 
 reorder_date = redate 
FROM 
 retemp1 
WHERE 
 sku_id = skuid 
 and reorder_date is null; 
 // Query returned successfully: 69 rows affected, 80 ms execution time.

SELECT 
 sku_id as skuid 
 ,initialLaunchDate as redate 
INTO 
 temporary table retemp4 
FROM 
 ecommerce.sku; 
 // Query returned successfully: 106897 rows affected, 83 ms execution time.

UPDATE 
 reorderage 
SET 
 reorder_date = redate 
FROM 
 retemp4 
WHERE 
 sku_id = skuid 
 and reorder_date is null; 
 // Query returned successfully: 37345 rows affected, 132 ms execution time.

SELECT 
 sku_id as skuid 
 ,daterecordadded as redate 
INTO 
 temporary table retemp5 
FROM 
 ecommerce.sku; 
 // Query returned successfully: 106897 rows affected, 66 ms execution time.

UPDATE 
 reorderage 
SET 
 reorder_date = redate  
FROM 
 retemp5 
WHERE 
 sku_id = skuid 
 and reorder_date is null; 
 // Query returned successfully: 14419 rows affected, 83 ms execution time.

SELECT 
 sku_id 
 ,reorder_date::date as reorderDate 
 ,(now()::date - reorder_date::date)/365.0 as age 
INTO  
 temporary table skura  
FROM 
 reorderage; 
 // Query returned successfully: 106897 rows affected, 151 ms execution time.

UPDATE 
 skucalc as sca 
SET 
 skuReorderDate = sra.reorderDate 
 ,skuReorderAge = sra.age 
FROM 
 skura as sra 
WHERE 
 sra.sku_id = sca.sku_id; 
 // Query returned successfully: 106897 rows affected, 578 ms execution time.

select 
 s.sku_id as skuId 
 ,sum(ii.quantity) as skuQuantity 
 ,min(ii.merchantPrice) as skuLowerOfCost 
 ,max(coalesce(ii.weight,0.0)) as skuWeight 
 ,string_agg(distinct sup.supplierName,'|') as skuSuppliers 
 INTO temporary table skudata 
FROM 
 ecommerce.SKU as s 
 ,ecommerce.RSInventoryItem as ii  
 ,ecommerce.Supplier sup 
WHERE 
        s.sku_id = ii.sku_id 
        and ii.active=true 
        and s.skuBitMask & 1 = 1 
        and ii.supplier_id = sup.supplier_id 
group by 
        s.sku_id; 
// Query returned successfully: 63265 rows affected, 632 ms execution time.

select  
 sku.item_id as skuFamilyId 
 ,i.name as skuFamilyName 
 ,i.itemStatus_id as skuFamilyStatusId  
 ,istB.itemStatus as skuFamilyStatus 
 ,v.name as skuFamilyVendor 
 ,sku.sku_id as skuId 
 ,ist.itemStatus as skuStatus 
 ,CASE WHEN sku.skuBitMask & 1 = 1 THEN 1 ELSE 0 END as tracksInventory 
 ,sku.name as skuName 
 ,sku.partNumber as partnumber 
 ,sku.isoCountryCodeOfOrigin as countryCode 
 ,ist.itemStatus  
 ,skucat.buyer as skuBuyer 
 ,skucat.skucategory1 
 ,skucat.skucategory2 
 ,skucat.skucategory3 
 ,skucat.skucategory4 
 ,skucat.skucategory5 
 ,skucat.skucategory6 
 ,sc.sku_class 
INTO 
 temporary table skudetails 
FROM 
 ecommerce.SKU as sku 
 left outer join ecommerce.skucategory skucat on skucat.sku_id = sku.sku_id 
 ,ecommerce.ItemStatus as ist 
 ,ecommerce.sku_class as sc  
 ,ecommerce.Item i 
 ,ecommerce.ItemStatus istB 
 ,ecommerce.vendor v 
WHERE 
 sku.itemStatus_id = ist.itemStatus_id 
 AND sku.sku_class_id = sc.sku_class_id 
 AND sku.item_id = i.item_id 
 AND i.itemStatus_id = istB.itemStatus_id  
 AND v.vendor_id = i.vendor_id 
 AND (sku.date_retired IS NULL OR sku.date_retired::DATE >= date_trunc('month',now()::DATE) - cast('5 years' as interval)) 
ORDER BY 
 sku.item_id 
 ,sku.sku_id; 
 // Query returned successfully: 81080 rows affected, 837 ms execution time.

SELECT 
    sku_id as skuId 
    ,max(daterecordadded) as maxDate 
INTO 
    temporary table maxSkuDates 
FROM 
    ecommerce.RSInventoryItem as ii 
GROUP BY 
    sku_id; 
// Query returned successfully: 90950 rows affected, 325 ms execution time.

SELECT 
    sku_id as skuId 
    ,sup.supplierName 
INTO 
    temporary table mostRecentSupplier 
FROM 
    maxSkuDates as msd 
    ,ecommerce.RSInventoryItem as ii 
    ,ecommerce.Supplier sup 
WHERE 
    msd.skuId = ii.sku_id 
    AND msd.maxDate = ii.daterecordadded 
    AND ii.supplier_id = sup.supplier_id 
 ORDER BY 
    msd.skuId; 
// Query returned successfully: 86222 rows affected, 500 ms execution time.

select  
 sd.skuFamilyId 
 ,sd.skuFamilyName 
 ,sd.skuFamilyStatusId  
 ,sd.skuFamilyStatus 
 ,sd.skuFamilyVendor 
 ,sd.skuId 
 ,sd.skuStatus 
 ,sd.tracksInventory 
 ,sd.skuName 
 ,sd.partnumber 
 ,sd.countryCode 
 ,sd.skuBuyer 
 ,sd.skucategory1 
 ,sd.skucategory2 
 ,sd.skucategory3 
 ,sd.skucategory4 
 ,sd.skucategory5 
 ,sd.skucategory6 
 ,sd.sku_class 
 ,skud.skuQuantity 
 ,skud.skuLowerOfCost 
 ,skud.skuWeight 
 ,skud.skuSuppliers 
 ,skuc.skuReorderDate 
 ,skuc.skuReorderAge 
 ,skuc.skuPrice 
 ,skuc.skuAverageCost 
 ,skuc.skuSoldAsSingles 
 ,skuc.skuInitialCost 
 ,skuc.skuCurrentCost 
 ,mrs.supplierName 
INTO temporary table skuMain 
FROM  
 skudetails sd  
 left outer join skudata skud on sd.skuId = skud.skuId 
 left outer join skucalc skuc on sd.skuId = skuc.sku_id 
 left outer join mostRecentSupplier mrs on sd.skuId = mrs.skuId 
 WHERE true 
ORDER BY 
 sd.skuFamilyId 
 ,sd.skuId; 
 // Query returned successfully: 81101 rows affected, 951 ms execution time.

select  
 v.productVersion_id as versionId 
 ,v.item_id as versionFamilyId 
 ,v.itemStatus_id versionStatusId 
 ,v.name as versionName 
 ,ist.itemStatus as versionStatus  
 ,i.name as versionFamilyName 
INTO 
 temporary table versionDetails 
FROM  
 ecommerce.ProductVersion v  
 ,ecommerce.ItemStatus ist  
 ,ecommerce.item i 
WHERE  
 v.itemStatus_id = ist.itemStatus_id 
 and v.item_id = i.item_id; 
 // Query returned successfully: 107178 rows affected, 252 ms execution time.

select  
 pvsku.productVersion_id::varchar || '-' || pvsku.sku_id::varchar as versionSkuId 
 ,pvsku.productVersion_id as versionId 
 ,pvsku.sku_id as skuId  
into 
 temporary table pvskuid 
from  
 ecommerce.ProductVersionSKU as pvsku; 
 // Query returned successfully: 112364 rows affected, 114 ms execution time.

SELECT  
 productVersion_id::varchar as versionId 
 ,extract( 'year' from fulfillmentDate) as year 
 ,sum(quantity) as units 
 ,sum(customerPrice * quantity) as revenue  
INTO 
 temporary table versionSales 
FROM 
 ecommerce.RSLineItem 
 ,ecommerce.RSOrder o 
 WHERE 
 o.oid = order_id 
 and fulfillmentDate >= '2014-01-01' 
 and coalesce(lineItemType_id,1) in (1,5)  
 and productVersion_id is not null  
GROUP BY  
 productVersion_id::varchar  
 ,extract( 'year' from fulfillmentDate)  
ORDER BY  
 extract( 'year' from fulfillmentDate) DESC ; 
 // Query returned successfully: 81742 rows affected, 83059 ms execution time.

select  
 sku_id  
 ,CASE WHEN (sum(quantity)) > 0 THEN sum(quantity * merchantPrice) / sum(quantity) ELSE avg(quantity * merchantPrice) END as cost
into  
 temporary table tempnext  
from  
 ecommerce.RSInventoryItem  
where  
 quantity > 0  
 and merchantPrice > 0   
 and sku_id is not null  
group by  
 sku_id; 
 // Query returned successfully: 27319 rows affected, 132 ms execution time.

select  
 pvs.productVersion_id as versionId 
 ,sum(pvs.quantity * tn.cost) as cost 
into 
 temporary table versionAvgCost 
from  
 ecommerce.ProductVersionSKU as pvs 
 ,tempnext as tn  
where  
 tn.sku_id = pvs.sku_id  
group by  
 pvs.productVersion_id; 
 // Query returned successfully: 33053 rows affected, 150 ms execution time.

select  
 productVersion_id as versionId 
 ,sum(customerPrice/quantity) / sum(quantity) as price  
into 
 temporary table versionAvgPrice 
from  
 ecommerce.RSLineItem  
where  
 fulfillmentDate is not null  
 and fulfillmentDate > '2014-01-01'  
 and quantity > 0  
group by  
 productVersion_id; 
 // Query returned successfully: 48439 rows affected, 8484 ms execution time.

 select distinct 
  pv.productVersion_id as versionId 
  ,COALESCE(p1.customerPrice,p2.customerPrice) as price 
    ,p1.active 
 INTO temporary table vCurrentPrice 
 FROM 
	ecommerce.ProductVersion as pv 
	LEFT OUTER JOIN ecommerce.Price as p1 
		ON pv.productVersion_id = p1.source_id 
		AND p1.sourceclass_id = 9 
		AND p1.priceType_id = 1 
            AND (p1.active = TRUE OR p1.active IS NULL) 
	LEFT OUTER JOIN ecommerce.Price as p2 
		ON pv.item_id = p2.source_id 
		AND p2.sourceclass_id = 5 
		AND p2.priceType_id = 1 
            AND (p2.active = TRUE OR p2.active IS NULL); 
// Query returned successfully: 107180 rows affected, 382 ms execution time.

SELECT  
 rsli.productVersion_id as versionId 
 ,min(to_char(rsli.fulfillmentDate,'yyyymmdd')::int) as firstDateSold  
INTO 
 temporary table versionFirstDateSold 
FROM  
 ecommerce.RSLineItem as rsli  
WHERE  
 rsli.lineItemType_id = 1  
 and rsli.fulfillmentDate is not null  
GROUP BY  
 rsli.productVersion_id; 
 // Query returned successfully: 87758 rows affected, 24510 ms execution time.

SELECT  
 rsli.productVersion_id as versionId 
 ,sum(rsli.customerPrice * rsli.quantity) as revenue 
 ,sum(rsli.quantity) as units 
INTO 
 temporary table last14   
FROM  
 ecommerce.RSLineItem rsli  
 ,ecommerce.rsorder o 
WHERE  
 coalesce(rsli.lineItemType_id,1) in (1,5)  
 and o.oid = rsli.order_id 
 and rsli.fulfillmentDate >= now() - interval '14 days'  
GROUP BY  
 rsli.productVersion_id; 
// Query returned successfully: 350 rows affected, 32 ms execution time.

SELECT  
 rsli.productVersion_id as versionId 
 ,sum(rsli.customerPrice * rsli.quantity) as revenue 
 ,sum(rsli.quantity) as units  
INTO 
 temporary table last30 
FROM  
 ecommerce.RSLineItem rsli  
 ,ecommerce.RSOrder o 
WHERE  
 coalesce(rsli.lineItemType_id,1) in (1,5)  
 and o.oid = rsli.order_id 
 and rsli.fulfillmentDate >= now() - interval '30 days'  
GROUP BY  
 rsli.productVersion_id; 
 // Query returned successfully: 12354 rows affected, 1166 ms execution time.

SELECT  
 rsli.productVersion_id as versionId 
 ,sum(rsli.customerPrice * rsli.quantity) as revenue 
 ,sum(rsli.quantity) as units  
INTO 
 temporary table last90 
FROM  
 ecommerce.RSLineItem rsli  
 ,ecommerce.RSOrder o 
WHERE  
 coalesce(rsli.lineItemType_id,1) in (1,5)  
 and o.oid = rsli.order_id 
 and rsli.fulfillmentDate >= now()::date - interval '90 days'  
GROUP BY  
 rsli.productVersion_id; 
 // Query returned successfully: 28800 rows affected, 7207 ms execution time.

SELECT  
 rsli.productVersion_id as versionId 
 ,sum(rsli.customerPrice * rsli.quantity) as revenue 
 ,sum(rsli.quantity) as units 
INTO 
 temporary table last180 
FROM  
 ecommerce.RSLineItem as rsli  
 ,ecommerce.RSOrder o 
WHERE  
 coalesce(rsli.lineItemType_id,1) in (1,5)  
 and o.oid = rsli.order_id 
 and rsli.fulfillmentDate >= now() - interval '180 days' 
GROUP BY  
 rsli.productVersion_id; 
 // Query returned successfully: 34209 rows affected, 11898 ms execution time.

SELECT  
 rsli.productVersion_id as versionId 
 ,sum(rsli.customerPrice * rsli.quantity) as revenue 
 ,sum(rsli.quantity) as units  
INTO 
 temporary table last365 
FROM  
 ecommerce.RSLineItem as rsli  
 ,ecommerce.RSOrder o 
WHERE  
 coalesce(rsli.lineItemType_id,1) in (1,5)  
 and o.oid = rsli.order_id 
 and rsli.fulfillmentDate >= now() - interval '365 days'  
GROUP BY  
 rsli.productVersion_id; 
 // Query returned successfully: 40069 rows affected, 19944 ms execution time.

SELECT  
 pvs.productVersion_id as versionId  
 ,pvs.sku_id as skuId  
 ,pvs.quantity  
INTO 
 temporary table versionSkuQuantity 
FROM  
 ecommerce.ProductVersionSKU as pvs; 
 // Query returned successfully: 112364 rows affected, 66 ms execution time.

SELECT 
pvsku.productversion_id as versionId 
 ,pvsku.sku_id as skuId 
 ,pvsku.quantity 
 ,sm.skuCurrentCost 
 ,sm.skuAverageCost 
 ,vAvgCost.cost 
  ,avg(CASE WHEN vAvgCost.cost = 0 THEN 0 WHEN ((pvsku.quantity * sm.skuCurrentCost) / vAvgCost.cost) BETWEEN 0 and 1 THEN ((pvsku.quantity * sm.skuCurrentCost) / vAvgCost.cost) ELSE 0 END) as percentage
  INTO temporary table versionSkuRevPercentage 
FROM 
ecommerce.ProductVersionSKU as pvsku 
,versionAvgCost as vAvgCost 
,skuMain as sm 
WHERE 
pvsku.productversion_id = vAvgCost.versionId 
and sm.skuId = pvsku.sku_id 
GROUP BY pvsku.productversion_id, pvsku.sku_id, pvsku.quantity, sm.skuCurrentCost, sm.skuAverageCost, vAvgCost.cost; 
// Query returned successfully: 35962 rows affected, 467 ms execution time.

SELECT 
 vd.versionId 
 ,vd.versionFamilyId 
 ,ist.itemstatus as versionFamilyStatus   
 ,vd.versionFamilyName 
 ,vd.versionStatusId 
 ,vd.versionStatus 
 ,vd.versionName 
 ,vs2016.units as units2016 
 ,vs2016.revenue as rev2016 
 ,avg(vac.cost) as versionAverageCost 
 ,vap.price as versionAveragePrice 
 ,vcp.price as currentPrice 
 ,vfds.firstDateSold 
 ,last14.units as last14units 
 ,last14.revenue as last14rev 
 ,last30.units as last30units 
 ,last30.revenue as last30rev 
 ,last90.units as last90units 
 ,last90.revenue as last90rev 
 ,last180.units as last180units 
 ,last180.revenue as last180rev 
 ,last365.units as last365units 
 ,last365.revenue as last365rev 
INTO 
 temporary table versionData  
FROM 
 versionDetails vd 
 left outer join versionsales vs2016 on vd.versionId::integer = vs2016.versionId::integer and vs2016.year::varchar = '2016'  
 left outer join versionAvgCost vac on vd.versionId::integer = vac.versionId::integer 
 left outer join versionAvgPrice vap on vd.versionId::integer = vap.versionId::integer 
 left outer join vCurrentPrice vcp on vd.versionId::integer = vcp.versionId::integer 
 left outer join versionFirstDateSold vfds on vd.versionId::integer = vfds.versionId::integer 
 left outer join last14 on vd.versionId::integer = last14.versionId::integer 
 left outer join last30 on vd.versionId::integer = last30.versionId::integer 
 left outer join last90 on vd.versionId::integer = last90.versionId::integer 
 left outer join last180 on vd.versionId::integer = last180.versionId::integer 
 left outer join last365 on vd.versionId::integer = last365.versionId::integer 
 , ecommerce.item i 
 , ecommerce.itemstatus ist 
WHERE vd.versionFamilyId = i.item_id  
  AND i.itemStatus_id = ist.itemstatus_id  
GROUP BY
  vd.versionId, vd.versionFamilyId, ist.itemstatus, vd.versionFamilyName, vd.versionStatusId, vd.versionStatus, vd.versionName, vs2016.units, vs2016.revenue, vap.price, vcp.price, vfds.firstDateSold, last14.units, last14.revenue, last30.units, last30.revenue, last90.units, last90.revenue, last180.units, last180.revenue, last365.units, last365.revenue
ORDER BY 
 vd.versionId;  
 // Query returned successfully: 107180 rows affected, 1445 ms execution time.  <-- NOT ANYMORE

SELECT DISTINCT 
 vsid.versionId as version_id
 ,vsid.skuId as sku_id
 ,vsq.quantity AS versionSkuQuantity 
 ,vsrp.percentage AS skuRevenuePercentage 
 ,vd.versionFamilyId 
 ,vd.versionFamilyName 
 ,vd.versionFamilyStatus 
 ,vd.versionStatusId 
 ,vd.versionStatus 
 ,vd.versionName as version_name
 ,vd.units2016 
 ,vd.rev2016 
 ,vd.versionAverageCost 
 ,vd.versionAveragePrice 
 ,vd.currentPrice 
 ,vd.firstDateSold 
 ,vd.last14units 
 ,vd.last14rev 
 ,vd.last30units 
 ,vd.last30rev 
 ,vd.last90units 
 ,vd.last90rev 
 ,vd.last180units 
 ,vd.last180rev 
 ,vd.last365units 
 ,vd.last365rev 
 ,sm.skuFamilyId 
 ,sm.skuFamilyName 
 ,sm.skuFamilyStatusId 
 ,sm.skuFamilyStatus 
 ,sm.skuFamilyVendor 
 ,sm.skuStatus 
 ,sm.tracksInventory 
 ,sm.skuName as sku_name
 ,sm.partnumber 
 ,sm.countryCode as country_code
 ,sm.skuBuyer 
 ,sm.skucategory1 
 ,sm.skucategory2 
 ,sm.skucategory3 
 ,sm.skucategory4 
 ,sm.skucategory5 
 ,sm.skucategory6 
 ,sm.sku_class 
 ,sm.skuQuantity 
 ,sm.skuLowerOfCost 
 ,sm.skuWeight 
 ,sm.skuSuppliers 
 ,sm.skuReorderDate 
 ,sm.skuReorderAge 
 ,sm.skuPrice 
 ,sm.skuAverageCost 
 ,sm.skuSoldAsSingles 
 ,sm.skuInitialCost 
 ,sm.skuCurrentCost 
 ,sm.supplierName as supplier_name 
 ,'' as salesMonth,0 as salesMonthUnits,0 as salesMonthRevenue 
 ,vd.versionFamilyStatus 
FROM 
 pvskuid vsid 
 LEFT OUTER JOIN versionSkuQuantity vsq ON vsid.versionId = vsq.versionId AND vsid.skuId = vsq.skuId 
 LEFT OUTER JOIN versionSkuRevPercentage vsrp ON vsid.versionId = vsrp.versionId AND vsid.skuId = vsrp.skuId 
 ,versionData vd 
 ,skuMain sm 
WHERE ( vsid.versionId = vd.versionId AND vsid.skuId = sm.skuId ) 

 ORDER BY 
 vsid.versionId 
 ,vsid.skuId;
// Total query runtime: 41927 ms. 86987 rows retrieved.
