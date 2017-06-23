//begin versionSkuRevenuePercentage
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

 