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

UPDATE 
 skucalc as sca 
SET 
 skuCurrentCost = scc.price  
FROM 
 skuccost as scc 
WHERE 
 scc.sku_id = sca.sku_id 
 and sca.skuCurrentCost is null; 

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

UPDATE 
 skucalc as sca 
SET 
 skuInitialCost = sic.cost  
FROM 
 skuinitcost as sic 
WHERE 
 sic.sku_id = sca.sku_id 
 and sca.skuInitialCost is null; 

SELECT 
 pvsku.sku_id 
 ,count(*) as components 
INTO 
 temporary table skusas 
FROM 
 ecommerce.ProductVersionSKU as pvsku 
GROUP BY 
 sku_id; 

UPDATE 
 skucalc as sca 
SET 
 skuSoldAsSingles = sas.components  
FROM 
 skusas as sas 
WHERE 
 sas.sku_id = sca.sku_id 
 and sca.skuSoldAsSingles is null; 

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

UPDATE 
 skucalc as sca 
SET 
 skuPrice = sp.price 
FROM 
 skuprice as sp 
WHERE 
 sp.sku_id = sca.sku_id 
 and sca.skuPrice is null; 

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

UPDATE 
 skucalc as sca 
SET 
 skuAverageCost = sac.cost 
FROM 
 skuac as sac 
WHERE 
 sac.sku_id = sca.sku_id 
 and sca.skuPrice is null; 

SELECT 
 sku_id 
 ,null::timestamp as reorder_date 
INTO 
 temporary table reorderage 
FROM 
 ecommerce.sku; 

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

UPDATE 
 reorderage 
SET 
 reorder_date = retemp0.reorder_date  
FROM 
 retemp0  
WHERE 
 reorderage.sku_id = retemp0.sku_id; 

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

UPDATE 
 reorderage 
SET 
 reorder_date = redate 
FROM 
 retemp1 
WHERE 
 sku_id = skuid 
 and reorder_date is null; 

SELECT 
 sku_id as skuid 
 ,initialLaunchDate as redate 
INTO 
 temporary table retemp4 
FROM 
 ecommerce.sku; 

UPDATE 
 reorderage 
SET 
 reorder_date = redate 
FROM 
 retemp4 
WHERE 
 sku_id = skuid 
 and reorder_date is null; 

SELECT 
 sku_id as skuid 
 ,daterecordadded as redate 
INTO 
 temporary table retemp5 
FROM 
 ecommerce.sku; 

UPDATE 
 reorderage 
SET 
 reorder_date = redate  
FROM 
 retemp5 
WHERE 
 sku_id = skuid 
 and reorder_date is null; 

SELECT 
 sku_id 
 ,reorder_date::date as reorderDate 
 ,(now()::date - reorder_date::date)/365.0 as age 
INTO  
 temporary table skura  
FROM 
 reorderage; 

UPDATE 
 skucalc as sca 
SET 
 skuReorderDate = sra.reorderDate 
 ,skuReorderAge = sra.age 
FROM 
 skura as sra 
WHERE 
 sra.sku_id = sca.sku_id; 

select 
 s.sku_id as skuId 
 ,sum(ii.quantity) as skuQuantity 
 ,min(ii.merchantPrice) as skuLowerOfCost 
 ,max(coalesce(ii.weight,0.0)) as skuWeight 
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
ORDER BY 
 sku.item_id 
 ,sku.sku_id; 

// TEST: select * from skudetails where skuId IN (36955, 82813);
// gives two rows. 
// So, these SKUs have not fallen out of the data yet. Onward! 


SELECT 
    sku_id as skuId 
    ,max(daterecordadded) as maxDate 
INTO 
    temporary table maxSkuDates 
FROM 
    ecommerce.RSInventoryItem as ii 
GROUP BY 
    sku_id; 

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

// TEST TWO: select * from skuMain where skuId IN (36955, 82813);
// gives two rows.  
// So, these SKUs have not fallen out of the data yet. Onward! 


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

select  
 pvsku.productVersion_id::varchar || '-' || pvsku.sku_id::varchar as versionSkuId 
 ,pvsku.productVersion_id as versionId 
 ,pvsku.sku_id as skuId  
INTO 
 temporary table pvskuid 
FROM 
 ecommerce.ProductVersionSKU as pvsku 
 ,ecommerce.rslineitem as li 
 ,ecommerce.rsorder as o 
WHERE 
 pvsku.productVersion_id = li.productversion_id 
 and li.order_id = o.oid; 

// select * from pvskuid where skuId IN (36955, 82813);
// AHA, this gives no result. Perhaps the data has fallen out at this point! But, let us go onward to see if another, later table comes back to update this one. 

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

select  
 sku_id  
 ,sum(quantity * merchantPrice) / sum(quantity) as cost  
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

SELECT  
 pvs.productVersion_id as versionId  
 ,pvs.sku_id as skuId  
 ,pvs.quantity  
INTO 
 temporary table versionSkuQuantity 
FROM  
 ecommerce.ProductVersionSKU as pvs; 

SELECT  
 productVersion_id as versionId 
 ,sum(customerPrice/quantity) / sum(quantity) as price  
INTO  
 temporary table versionWeightedAveragePrice  
FROM  
 ecommerce.RSLineItem  
WHERE  
 fulfillmentDate is not null  
 and fulfillmentDate >= '2014-01-01'  
 and quantity > 0  
GROUP BY  
 productVersion_id  
HAVING  
 sum(quantity) > 0; 

SELECT  
 pvsku.productVersion_id  
INTO  
 temporary table Singles  
FROM  
 ecommerce.ProductVersionSKU as pvsku  
GROUP BY  
 productVersion_id  
HAVING count(*) = 1; 

SELECT  
 vwap.versionId as versionId 
 ,vwap.price  
INTO  
 temporary table SingleVersionPrice  
FROM  
 VersionWeightedAveragePrice as vwap  
 ,Singles as s  
WHERE  
 s.productVersion_id = vwap.versionId; 

SELECT  
 pvsku.sku_id as skuId 
 ,avg(svp.price / pvsku.quantity) as price  
INTO 
 temporary table TMP_SKU_PRICE  
FROM  
 SingleVersionPrice as svp  
 ,Singles as s  
 ,ecommerce.ProductVersionSKU as pvsku  
WHERE  
 svp.versionId = s.productVersion_id  
 and pvsku.productVersion_id = s.productVersion_id  
 and pvsku.quantity > 0  
GROUP BY  
 pvsku.sku_id; 

INSERT INTO TMP_SKU_PRICE (skuId,price)  
 SELECT 
  source_id as skuId 
  ,customerprice  
 FROM  
  ecommerce.price  
 WHERE  
  pricetype_id = 1  
  and sourceclass_id = 13; 

SELECT  
 skuId 
 ,min(price) as price  
INTO  
 temporary table mSKUPRICE  
FROM  
 TMP_SKU_PRICE  
WHERE  
 price > 0  
GROUP BY  
 skuId; 

SELECT  
 pvsku.productVersion_id as versionId 
 ,sum(coalesce(sp.price,0) * pvsku.quantity ) as price  
INTO  
 temporary table VERSION_PRICE  
FROM  
 mSKUPRICE as sp 
 ,ecommerce.productversionsku as pvsku  
WHERE  
 pvsku.sku_id = sp.skuId  
GROUP BY  
 productversion_id;  

 // testing again: select * from VERSION_PRICE where versionId IN (55848, 79476);
 // Nope, these versions are not in the data at this point. 

SELECT 
 pvsku.productVersion_id as versionId 
 ,pvsku.sku_id as skuId 
 ,avg(CASE WHEN vp.price > 0 THEN (sp.price * pvsku.quantity) / vp.price ELSE 0 END) as percentage 
INTO  
 temporary table versionSkuRevPercentage  
FROM 
 ecommerce.ProductVersionSKU as pvsku 
 ,VERSION_PRICE as vp 
 ,mSKUPRICE as sp 
WHERE 
 pvsku.productVersion_id = vp.versionId 
 and pvsku.sku_id = sp.skuId 
GROUP BY 
 pvsku.productVersion_id 
 ,pvsku.sku_id;  

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
 ,vac.cost as versionAverageCost 
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
ORDER BY 
 vd.versionId; 

// THIS QUERY IS TAKING FOREVER TO RUN. 
// testing again: select * from VERSION_PRICE where versionId IN (55848, 79476);

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
 ,vsid.skuId 