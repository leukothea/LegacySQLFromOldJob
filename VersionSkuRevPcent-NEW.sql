// (1)
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

// (2) 
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

// (3) 
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

// (4) 
UPDATE 
 skucalc as sca 
SET 
 skuCurrentCost = scc.price  
FROM 
 skuccost as scc 
WHERE 
 scc.sku_id = sca.sku_id 
 and sca.skuCurrentCost is null; 

// (5) 
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

// (6) 
UPDATE 
 skucalc as sca 
SET 
 skuInitialCost = sic.cost  
FROM 
 skuinitcost as sic 
WHERE 
 sic.sku_id = sca.sku_id 
 and sca.skuInitialCost is null; 

// (7) 
SELECT 
 pvsku.sku_id 
 ,count(*) as components 
INTO 
 temporary table skusas 
FROM 
 ecommerce.ProductVersionSKU as pvsku 
GROUP BY 
 sku_id; 

// (8) 
UPDATE 
 skucalc as sca 
SET 
 skuSoldAsSingles = sas.components  
FROM 
 skusas as sas 
WHERE 
 sas.sku_id = sca.sku_id 
 and sca.skuSoldAsSingles is null; 

// skipped 2 queries here

// (9) 
SELECT 
 sku_id 
 ,sum(quantity * merchantPrice) / sum(quantity) as cost 
INTO 
 temporary table skuac 
FROM 
 ecommerce.RSInventoryItem 
WHERE 
 quantity > 0 
 and merchantPrice > 0  
 and sku_id is not null 
GROUP BY 
 sku_id; 

// (10)
UPDATE 
 skucalc as sca 
SET 
 skuAverageCost = sac.cost 
FROM 
 skuac as sac 
WHERE 
 sac.sku_id = sca.sku_id 
 and sca.skuPrice is null; 

// skipped some daterecordadded queries here 

// (11) 
select 
 s.sku_id as skuId 
 ,sum(ii.quantity) as skuQuantity 
 ,min(ii.merchantPrice) as skuLowerOfCost 
 ,max(coalesce(ii.weight,0.0)) as skuWeight 
 // skipped a line here
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

// (12)
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

// skipped another daterecordadded query
// edited the below query to remove references to queries I took out. 

// (13) skuMain
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
// took out a line here
 ,skuc.skuReorderDate 
 ,skuc.skuReorderAge 
 ,skuc.skuPrice 
 ,skuc.skuAverageCost 
 ,skuc.skuSoldAsSingles 
 ,skuc.skuInitialCost 
 ,skuc.skuCurrentCost 
INTO temporary table skuMain 
FROM  
 skudetails sd  
 left outer join skudata skud on sd.skuId = skud.skuId 
 left outer join skucalc skuc on sd.skuId = skuc.sku_id 
 WHERE true 
ORDER BY 
 sd.skuFamilyId 
 ,sd.skuId; 

// (14) versionAvgCost
select 
 pvs.productVersion_id as versionId
 ,sum(pvs.quantity * sm.skuAverageCost) as cost
into
 temporary table versionAvgCost
from 
 ecommerce.ProductVersionSKU as pvs
 ,skuMain as sm  
where 
 sm.skuId = pvs.sku_id 
group by 
 pvs.productVersion_id;

// so far so good... 

// At this point we have made these temptables: 
// (1) skucalc
// (2) tempskudra (date record added)
// (3) skuccost (enough to just use this one? No)
// (4) UPDATE skucalc using skuccost values. 
// (5) skuinitcost (for the SKU s initial inventoryrecord cost)
// (6) UPDATE skucalc using skuinitcost values. 
// (7) skusas (count of SKUs in the version?)
// (8) UPDATE skucalc using skusas data (if there is just one SKU in the version, the quantity 1 goes in)
// (9) skuac of each SKU s average cost: sum(quantity * merchantPrice) / sum(quantity) as cost
// (10) update skucalc set sku average cost from table skuac
// (11) skudata (assembling a new temptable with minimum SKU cost data)
// (12) skudetails (assembling a lot of SKU level data from regular ecommerce database)
// (13) skuMain (assembling data about SKUs from the previous temptables). Provides sm.skuAverageCost and sm.skuCurrentCost 
// (14) versionAvgCost (from ProductVersionSKU and SKUMain s skuAverageCost)


// I think I need a new temptable to sum up the version s associated SKU costs. 


SELECT 
pvsku.productversion_id as versionId
 ,pvsku.sku_id as skuId
 // (CASE WHEN vp.price > 0 THEN (sp.price * pvsku.quantity) / vp.price ELSE 0 END) as percentage
 ,avg(CASE WHEN sm.skuSoldAsSingles = 1 THEN sm.skuCurrentCost / vAvgCost.cost ELSE / (sm.skuSoldAsSingles * s.skuCurrentCost) / vAvgCost.cost END) as percentage

 // (sm.skuCurrentCost / vAvgCost.cost) as percentage
FROM 
ecommerce.ProductVersionSKU as pvsku
,versionAvgCost as vAvgCost 
,skuMain as sm 
WHERE
pvsku.productversion_id = vAvgCost.versionId
and sm.skuId = pvsku.sku_id 
GROUP BY pvsku.productversion_id, pvsku.sku_id
ORDER BY pvsku.productversion_id ASC;

// This version is just for sleuthing. 

SELECT 
pvsku.productversion_id as versionId
 ,pvsku.sku_id as skuId
 ,sm.skuSoldAsSingles
 ,sm.skuCurrentCost
 ,sm.skuAverageCost
 ,vAvgCost.cost
 ,avg(CASE WHEN vAvgCost is NOT NULL THEN (sm.skuSoldAsSingles * sm.skuCurrentCost) / vAvgCost.cost ELSE 0 END) as percentage
FROM 
ecommerce.ProductVersionSKU as pvsku
,versionAvgCost as vAvgCost 
,skuMain as sm 
WHERE
pvsku.productversion_id = vAvgCost.versionId
and sm.skuId = pvsku.sku_id 
GROUP BY pvsku.productversion_id, pvsku.sku_id, sm.skuSoldAsSingles, sm.skuCurrentCost, sm.skuAverageCost, vAvgCost.cost
ORDER BY pvsku.productversion_id ASC;

// The above query does result in correctly summed version average costs for versions with multiple of the same SKU. Example: version 128594. 
// And for versions with multiple different SKUs. Examples: version 129484
// But, some of the values were false 0s. 

// Another attempt: 

SELECT 
pvsku.productversion_id as versionId
 ,pvsku.sku_id as skuId
 ,sm.skuSoldAsSingles
 ,sm.skuCurrentCost
 ,sm.skuAverageCost
 ,vAvgCost.cost
 ,avg(CASE WHEN ((sm.skuSoldAsSingles * sm.skuCurrentCost) / vAvgCost.cost) BETWEEN 0 and 1 THEN ((sm.skuSoldAsSingles * sm.skuCurrentCost) / vAvgCost.cost) ELSE 0 END) as percentage
FROM 
ecommerce.ProductVersionSKU as pvsku
,versionAvgCost as vAvgCost 
,skuMain as sm 
WHERE
pvsku.productversion_id = vAvgCost.versionId
and sm.skuId = pvsku.sku_id 
GROUP BY pvsku.productversion_id, pvsku.sku_id, sm.skuSoldAsSingles, sm.skuCurrentCost, sm.skuAverageCost, vAvgCost.cost
ORDER BY pvsku.productversion_id ASC;

// This one looked better : all the percentage cells had a value. Problem: Some versions that were composed of multiples of the same SKU showed weird numbers. 
// Example: 129343, which had skuSoldAsSingles = 2, skuCurrentCost = 1, skuAverageCost = 1, version cost = 3, and a percentage of 2/3. 

// I need to get away from the sm.skuSoldAsSingles information, which is not helping here. I think productversionsku quantity is where to go next. 


SELECT 
pvsku.productversion_id as versionId
 ,pvsku.sku_id as skuId
 ,pvsku.quantity
 ,sm.skuCurrentCost
 ,sm.skuAverageCost
 ,vAvgCost.cost
 ,avg(CASE WHEN ((pvsku.quantity * sm.skuCurrentCost) / vAvgCost.cost) BETWEEN 0 and 1 THEN ((pvsku.quantity * sm.skuCurrentCost) / vAvgCost.cost) ELSE 0 END) as percentage
 INTO temporary table versionSkuRevPercentage
FROM 
ecommerce.ProductVersionSKU as pvsku
,versionAvgCost as vAvgCost 
,skuMain as sm 
WHERE
pvsku.productversion_id = vAvgCost.versionId
and sm.skuId = pvsku.sku_id 
GROUP BY pvsku.productversion_id, pvsku.sku_id, pvsku.quantity, sm.skuCurrentCost, sm.skuAverageCost, vAvgCost.cost
ORDER BY pvsku.productversion_id ASC;




 