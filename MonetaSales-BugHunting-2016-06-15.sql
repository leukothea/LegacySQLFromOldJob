select pvs.productVersion_id as versionId, pvs.sku_id as skuId, pvs.quantity 
into temporary table versionSkuQuantity
from ecommerce.ProductVersionSKU as pvs 
where true

Query returned successfully: 119604 rows affected, 65 ms execution time.

select rsli.productVersion_id as versionId, sum(rsli.customerPrice/rsli.quantity) / sum(rsli.quantity) as price
into temporary table vwap 
from ecommerce.RSLineItem as rsli 
where rsli.fulfillmentDate is not null and rsli.fulfillmentDate >= '2015-01-01' and rsli.quantity > 0 
group by rsli.productVersion_id HAVING sum(rsli.quantity) > 0

Query returned successfully: 47592 rows affected, 6164 ms execution time.

select pvsku.productVersion_id 
into temporary table singles
from ecommerce.ProductVersionSKU as pvsku 
where true 
group by productVersion_id HAVING count(*) = 1

Query returned successfully: 108666 rows affected, 117 ms execution time.





Query returned successfully: 108666 rows affected, 165 ms execution time.



TMP SKU PRICE is the culprit!!!!

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



select pr.source_id as sku_id, pr.customerprice
from ecommerce.price as pr
where 
and (pr.pricetype_id = 1 and pr.sourceclass_id = 13)


