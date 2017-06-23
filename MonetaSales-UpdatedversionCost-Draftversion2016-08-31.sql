****
MonetaSales-UpdatedVersionCost, sql version with the "updated version cost" part STRIPPED OUT so I can QA it. 

To-do on this file: 
1) Determine which columns show the incorrect SKU cost. -- ANSWER: SCurCost
2) Determine which query pulls those costs. -- ANSWER: 
3) And which subqueries pull those costs. 
4) ??
5) Profit! 

****


 
  WITH versionSkuQuantity AS (select pvs.productVersion_id as versionId, pvs.sku_id as skuId, pvs.quantity 
from ecommerce.ProductVersionSKU as pvs 
where true 
 )
 , versionData AS (  WITH versionDetails AS (select v.productVersion_id as versionId, v.item_id as versionFamilyId, v.itemStatus_id as versionStatusId, v.name as versionName, ist.itemStatus as versionStatus, i.name as versionFamilyName 
from ecommerce.ProductVersion as v, ecommerce.ItemStatus as ist, ecommerce.item as i 
where v.itemStatus_id = ist.itemStatus_id and v.item_id = i.item_id 
 )
 , versionsales AS (select rsli.productVersion_id as versionId, extract( 'year' from rsli.fulfillmentDate) as year, sum(rsli.quantity) as units, sum(rsli.customerPrice * rsli.quantity) as revenue 
from ecommerce.RSLineItem as rsli, ecommerce.RSOrder as o 
where o.oid = rsli.order_id and rsli.fulfillmentDate >= '2015-01-01' and coalesce(rsli.lineItemType_id,1) in (1,5) and rsli.productVersion_id IS NOT NULL 
group by rsli.productVersion_id, extract( 'year' from rsli.fulfillmentDate) 
order by extract( 'year' from rsli.fulfillmentDate) DESC 
 )
 , vac AS (  WITH tempnext AS (select ii.sku_id, sum(ii.quantity * ii.merchantPrice) / sum(ii.quantity) as cost 
from ecommerce.RSInventoryItem as ii 
where ii.quantity > 0 and ii.merchantPrice > 0 and ii.sku_id is not null 
group by ii.sku_id 
 )
 select pvs.productVersion_id as versionId, sum(pvs.quantity * tempnext.cost) as cost
from ecommerce.ProductVersionSKU as pvs LEFT OUTER JOIN tempnext as tempnext ON tempnext.sku_id = pvs.sku_id 
where true 
group by pvs.productVersion_id 
 )
 , vap AS (select rsli.productVersion_id as versionId, sum(rsli.customerPrice/rsli.quantity) / sum(rsli.quantity) as price 
from ecommerce.RSLineItem as rsli
where rsli.fulfillmentDate is not null and rsli.fulfillmentDate > '2015-01-01' and rsli.quantity > 0 
group by rsli.productVersion_id
 )
 , vcp AS (select distinct pv.productVersion_id as versionId, COALESCE(p1.customerPrice,p2.customerPrice) as price, p1.active 
from ecommerce.ProductVersion as pv LEFT OUTER JOIN ecommerce.Price as p1 ON pv.productVersion_id = p1.source_id AND p1.sourceclass_id = 9 AND p1.priceType_id = 1 AND (p1.active = TRUE OR p1.active IS NULL) LEFT OUTER JOIN ecommerce.Price as p2 ON pv.item_id = p2.source_id AND p2.sourceclass_id = 5 AND p2.priceType_id = 1 AND (p2.active = TRUE OR p2.active IS NULL) 
where true 
 )
 , vsppp AS (select pv.productversion_id as versionId, COALESCE(pr1.customerprice, 0.00) as recommended_sale_price, COALESCE(pr2.customerprice, 0.00) as recommended_pop_pick_price 
from ecommerce.productversion as pv, ecommerce.item as i, ecommerce.price as pr1, ecommerce.price as pr2 
where pv.item_id = i.item_id  and i.item_id = pr1.source_id and pr1.sourceclass_id = 5 and pr1.pricetype_id = 5 and i.item_id = pr2.source_id and pr2.sourceclass_id = 5 and pr2.pricetype_id = 6 
 )
 , vfds AS (select rsli.productVersion_id as versionId, min(to_char(rsli.fulfillmentDate,'yyyymmdd')::int) as firstDateSold 
from ecommerce.RSLineItem as rsli 
where rsli.lineItemType_id = 1 and rsli.fulfillmentDate is not null 
group by rsli.productVersion_id 
 )
 , last14 AS (select rsli.productVersion_id as versionId, sum(rsli.customerPrice * rsli.quantity) as revenue, sum(rsli.quantity) as units 
from ecommerce.RSLineItem as rsli, ecommerce.RSOrder as o 
where COALESCE(rsli.lineItemType_id,1) in (1,5) and o.oid = rsli.order_id and rsli.fulfillmentDate >= now() - interval '14 days' 
group by rsli.productVersion_id 
 )
 , last30 AS (select rsli.productVersion_id as versionId, sum(rsli.customerPrice * rsli.quantity) as revenue, sum(rsli.quantity) as units 
from ecommerce.RSLineItem as rsli, ecommerce.RSOrder as o 
where COALESCE(rsli.lineItemType_id,1) in (1,5) and o.oid = rsli.order_id and rsli.fulfillmentDate >= now() - interval '30 days' 
group by rsli.productVersion_id 
 )
 , last90 AS (select rsli.productVersion_id as versionId, sum(rsli.customerPrice * rsli.quantity) as revenue, sum(rsli.quantity) as units 
from ecommerce.RSLineItem as rsli, ecommerce.RSOrder as o 
where COALESCE(rsli.lineItemType_id,1) in (1,5) and o.oid = rsli.order_id and rsli.fulfillmentDate >= now() - interval '90 days' 
group by rsli.productVersion_id 
 )
 , last180 AS (select rsli.productVersion_id as versionId, sum(rsli.customerPrice * rsli.quantity) as revenue, sum(rsli.quantity) as units 
from ecommerce.RSLineItem as rsli, ecommerce.RSOrder as o 
where COALESCE(rsli.lineItemType_id,1) in (1,5) and o.oid = rsli.order_id and rsli.fulfillmentDate >= now() - interval '180 days' 
group by rsli.productVersion_id 
 )
 , last365 AS (select rsli.productVersion_id as versionId, sum(rsli.customerPrice * rsli.quantity) as revenue, sum(rsli.quantity) as units 
from ecommerce.RSLineItem as rsli, ecommerce.RSOrder as o 
where COALESCE(rsli.lineItemType_id,1) in (1,5) and o.oid = rsli.order_id and rsli.fulfillmentDate >= now() - interval '365 days' 
group by rsli.productVersion_id 
 )
 select versionDetails.versionId, versionDetails.versionFamilyId, ist.itemstatus as versionFamilyStatus, versionDetails.versionFamilyName, versionDetails.versionStatusId, versionDetails.versionStatus, versionDetails.versionName ,versionsales.units as units2016, versionsales.revenue as rev2016 ,vac.cost as versionAverageCost, vap.price as versionAveragePrice, vcp.price as currentPrice, vsppp.recommended_sale_price, vsppp.recommended_pop_pick_price ,vfds.firstDateSold, last14.units as last14units, last14.revenue as last14rev, last30.units as last30units, last30.revenue as last30rev ,last90.units as last90units, last90.revenue as last90rev, last180.units as last180units, last180.revenue as last180rev, last365.units as last365units, last365.revenue as last365rev 
from ecommerce.productversion as pv LEFT OUTER JOIN versionDetails as versionDetails ON pv.productversion_id = versionDetails.versionId LEFT OUTER JOIN versionsales AS versionsales on pv.productversion_id::integer = versionsales.versionId::integer and versionsales.year::varchar = '2016' LEFT OUTER JOIN vac as vac on pv.productversion_id::integer = vac.versionId::integer LEFT OUTER JOIN vap as vap on pv.productversion_id::integer = vap.versionId::integer LEFT OUTER JOIN vcp as vcp on pv.productversion_id::integer = vcp.versionId::integer LEFT OUTER JOIN vsppp as vsppp on pv.productversion_id::integer = vsppp.versionId::integer LEFT OUTER JOIN vfds as vfds on pv.productversion_id::integer = vfds.versionId::integer LEFT OUTER JOIN last14 as last14 on pv.productversion_id::integer = last14.versionId::integer LEFT OUTER JOIN last30 as last30 on pv.productversion_id::integer = last30.versionId::integer LEFT OUTER JOIN last90 as last90 on pv.productversion_id::integer = last90.versionId::integer LEFT OUTER JOIN last180 as last180 on pv.productversion_id::integer = last180.versionId::integer LEFT OUTER JOIN last365 as last365 on pv.productversion_id::integer = last365.versionId::integer ,ecommerce.item as i, ecommerce.itemstatus as ist 
where i.item_id = pv.item_id and versionDetails.versionFamilyId = i.item_id and i.itemStatus_id = ist.itemstatus_id 
order by versionDetails.versionId asc
 )
 , skuMain AS (  WITH skucalc AS (  WITH skuprice AS (select pr.source_id as sku_id, min(pr.customerprice) as price 
from ecommerce.price as pr 
where pr.pricetype_id = 1 and pr.sourceclass_id = 13 and pr.customerprice > 0 
group by pr.source_id
 )
 , skuac AS (select ii.sku_id, sum(ii.quantity * ii.merchantPrice) / sum(ii.quantity) as cost 
from ecommerce.RSInventoryItem as ii 
where ii.quantity > 0 and ii.merchantPrice > 0 and ii.sku_id is not null
group by ii.sku_id
 )
 , skuccost AS (  WITH tempskudra AS (select s.sku_id, max(ii.dateRecordAdded) as dra 
from ecommerce.SKU as s, ecommerce.RSInventoryItem as ii, ecommerce.ProductVersionSKU as pvs 
where s.sku_id = ii.sku_id and s.sku_id = pvs.sku_id and s.skuBitMask & 1 = 1 and ii.merchantPrice > 0 
group by s.sku_id 
 )
 select s.sku_id, max(ii.merchantPrice) as price 
from ecommerce.SKU as s LEFT OUTER JOIN tempskudra as tempskudra ON s.sku_id = tempskudra.sku_id, ecommerce.RSInventoryItem as ii, ecommerce.ProductVersionSKU as pvs 
where s.sku_id = ii.sku_id and s.sku_id = pvs.sku_id and s.skuBitMask & 1 = 1 and tempskudra.sku_id = ii.sku_id and tempskudra.dra::DATE = ii.dateRecordAdded::DATE and ii.merchantPrice > 0 
group by s.sku_id 
 )
 , skuinitcost AS (  WITH dra AS (select s.sku_id, min(ii.dateRecordAdded) as dra 
from ecommerce.SKU as s, ecommerce.RSInventoryItem as ii, ecommerce.ProductVersionSKU as pvs 
WHERE s.sku_id = ii.sku_id and s.sku_id = pvs.sku_id and s.skuBitMask & 1 = 1 and ii.merchantPrice > 0 
GROUP BY s.sku_id 
 )
 select s.sku_id, max(ii.merchantPrice) as cost 
from ecommerce.SKU as s LEFT OUTER JOIN dra as dra ON s.sku_id = dra.sku_id, ecommerce.RSInventoryItem as ii, ecommerce.ProductVersionSKU as pvs 
where s.sku_id = ii.sku_id and s.sku_id = pvs.sku_id and s.skuBitMask & 1 = 1 and dra.dra::DATE = ii.dateRecordAdded::DATE and ii.merchantPrice > 0 
group by s.sku_id 
 )
 select s.sku_id ,COALESCE(max(rcvd.receiveddate::DATE), s.initialLaunchDate::DATE, s.daterecordadded::DATE) AS skuReorderDate ,(abs(EXTRACT(DAY FROM COALESCE(MAX(rcvd.receiveddate), MAX(ii.daterecordadded), MAX(s.daterecordadded), MAX(s.initiallaunchdate)) - now())))/365 AS skuReorderAge ,(COALESCE(skuprice.price,0.00)) AS skuPrice ,(COALESCE(skuac.cost,0.00)) AS skuAverageCost ,(COALESCE(skuinitcost.cost,0.00)) AS skuInitialCost ,(COALESCE(skuccost.price,0.00)) AS skuCurrentCost 
from ecommerce.sku as s LEFT OUTER JOIN skuccost ON s.sku_id = skuccost.sku_id LEFT OUTER JOIN skuinitcost ON s.sku_id = skuinitcost.sku_id LEFT OUTER JOIN skuac ON s.sku_id = skuac.sku_id LEFT OUTER JOIN skuprice ON s.sku_id = skuprice.sku_id ,ecommerce.rsinventoryitem as ii, ecommerce.receivingevent as rcvd 
where ii.sku_id = s.sku_id and ii.receivingevent_id = rcvd.receivingevent_id 
group by s.sku_id, skuccost.price, skuinitcost.cost, skuac.cost, skuprice.price 
 )
 , skudata AS (select s.sku_id as skuId, sum(ii.quantity) as skuQuantity, min(ii.merchantPrice) as skuLowerOfCost, max(coalesce(ii.weight,0.0)) as skuWeight ,string_agg(distinct sup.supplierName,'|') as skuSuppliers 
from ecommerce.SKU as s, ecommerce.RSInventoryItem as ii, ecommerce.Supplier as sup 
where s.sku_id = ii.sku_id and ii.active = true and s.skuBitMask & 1 = 1 and ii.supplier_id = sup.supplier_id 
group by s.sku_id 
 )
 , skudetails AS (select sku.item_id as skuFamilyId, i.name as skuFamilyName, i.itemStatus_id as skuFamilyStatusId, istB.itemStatus as skuFamilyStatus ,v.name as skuFamilyVendor, sku.sku_id as skuId, ist.itemStatus as skuStatus ,CASE WHEN sku.skuBitMask & 1 = 1 THEN 1 ELSE 0 END as tracksInventory ,sku.name as skuName, sku.partNumber as partnumber, sku.isoCountryCodeOfOrigin as countryCode, ist.itemStatus, skucat.buyer as skuBuyer ,skucat.skucategory1, skucat.skucategory2, skucat.skucategory3, skucat.skucategory4, skucat.skucategory5, skucat.skucategory6, sc.sku_class 
from ecommerce.SKU as sku LEFT OUTER JOIN ecommerce.skucategory as skucat on skucat.sku_id = sku.sku_id, ecommerce.ItemStatus as ist ,ecommerce.sku_class as sc, ecommerce.Item as i, ecommerce.ItemStatus as istB, ecommerce.vendor as v 
where sku.itemStatus_id = ist.itemStatus_id AND sku.sku_class_id = sc.sku_class_id AND sku.item_id = i.item_id  and i.itemStatus_id = istB.itemStatus_id AND v.vendor_id = i.vendor_id  and (sku.date_retired IS NULL OR sku.date_retired::DATE >= date_trunc('month',now()::DATE) - cast('5 years' as interval)) 
ORDER BY sku.item_id, sku.sku_id 
 )
 , mostrecentsupplier AS (  WITH maxSkuDates AS (select ii.sku_id as skuId, max(ii.daterecordadded)::DATE as maxDate 
from ecommerce.RSInventoryItem as ii  
group by ii.sku_id 
 )
 select maxSkuDates.skuid as skuId, sup.supplierName 
from ecommerce.sku as s RIGHT JOIN maxSkuDates as maxSkuDates ON s.sku_id = maxSkuDates.skuid ,ecommerce.RSInventoryItem as ii, ecommerce.Supplier as sup 
where maxSkuDates.skuId = ii.sku_id AND maxSkuDates.maxDate::DATE = ii.daterecordadded::DATE AND ii.supplier_id = sup.supplier_id 
ORDER BY maxSkuDates.skuId 
 )
 select skudetails.skuFamilyId, skudetails.skuFamilyName, skudetails.skuFamilyStatusId, skudetails.skuFamilyStatus, skudetails.skuFamilyVendor, skudetails.skuId, skudetails.skuStatus, skudetails.tracksInventory ,skudetails.skuName, skudetails.partnumber, skudetails.countryCode, skudetails.skuBuyer, skudetails.skucategory1, skudetails.skucategory2, skudetails.skucategory3, skudetails.skucategory4, skudetails.skucategory5, skudetails.skucategory6 ,skudetails.sku_class, skudata.skuQuantity, skudata.skuLowerOfCost, skudata.skuWeight, skudata.skuSuppliers, skucalc.skuReorderDate, skucalc.skuReorderAge, skucalc.skuPrice, skucalc.skuAverageCost ,skucalc.skuInitialCost, skucalc.skuCurrentCost, mostrecentsupplier.supplierName 
from ecommerce.sku as s LEFT OUTER JOIN skucalc AS skucalc ON s.sku_id = skucalc.sku_id LEFT OUTER JOIN skudetails as skudetails ON s.sku_id = skudetails.skuId LEFT OUTER JOIN skudata ON s.sku_id = skudata.skuid LEFT OUTER JOIN mostrecentsupplier as mostrecentsupplier ON s.sku_id = mostrecentsupplier.skuId 
where true
order by skudetails.skuFamilyId, skudetails.skuId 
 )
 select DISTINCT vsid.productversion_id as version_id, vsid.sku_id as sku_id, versionSkuQuantity.quantity AS versionSkuQuantity, '0' as skuRevenuePercentage ,versionData.versionFamilyId, versionData.versionFamilyName, versionData.versionFamilyStatus, versionData.versionStatusId, versionData.versionStatus, versionData.versionName as version_name ,versionData.units2016, versionData.rev2016 ,versionData.versionAverageCost, versionData.versionAveragePrice, versionData.currentPrice, versionData.recommended_sale_price, versionData.recommended_pop_pick_price ,versionData.firstDateSold, versionData.last14units, versionData.last14rev, versionData.last30units, versionData.last30rev, versionData.last90units, versionData.last90rev, versionData.last180units, versionData.last180rev, versionData.last365units, versionData.last365rev ,skuMain.skuFamilyId, skuMain.skuFamilyName, skuMain.skuFamilyStatusId, skuMain.skuFamilyStatus, skuMain.skuFamilyVendor, skuMain.skuStatus, skuMain.tracksInventory, skuMain.skuName as sku_name ,skuMain.partnumber, skuMain.countryCode as country_code, skuMain.skuBuyer, skuMain.skucategory1, skuMain.skucategory2, skuMain.skucategory3, skuMain.skucategory4, skuMain.skucategory5, skuMain.skucategory6 ,skuMain.sku_class, skuMain.skuQuantity, skuMain.skuLowerOfCost, skuMain.skuWeight, skuMain.skuSuppliers, skuMain.skuReorderDate, skuMain.skuReorderAge, skuMain.skuPrice, skuMain.skuAverageCost ,skuMain.skuInitialCost, skuMain.skuCurrentCost, skuMain.supplierName as supplier_name , '' as salesMonth, 0 as salesMonthUnits, 0 as salesMonthRevenue 
from ecommerce.productversionsku as vsid LEFT OUTER JOIN skuMain as skuMain ON vsid.sku_id = skuMain.skuId LEFT OUTER JOIN versionData as versionData ON versionData.versionId = vsid.productversion_id LEFT OUTER JOIN versionSkuQuantity as versionSkuQuantity ON vsid.productversion_id = versionSkuQuantity.versionId AND vsid.sku_id = versionSkuQuantity.skuId 
where true  and skuMain.skuId = 31317
order by vsid.productversion_id, vsid.sku_id 
 