
  WITH cocp AS (  WITH cvc AS (  WITH csc AS (  WITH dra AS (SELECT s.sku_id ,max(ii.dateRecordAdded) as dra 
FROM ecommerce.SKU s ,ecommerce.RSInventoryItem ii ,ecommerce.ProductVersionSKU pvs 
WHERE s.sku_id = ii.sku_id and s.sku_id = pvs.sku_id and s.skuBitMask & 1 = 1 and ii.merchantPrice > 0 
 GROUP BY s.sku_id
 )
 SELECT s.sku_id ,max(ii.merchantPrice) as cost 
FROM ecommerce.SKU as s, ecommerce.ProductVersionSKU as pvs, ecommerce.RSInventoryItem as ii LEFT OUTER JOIN dra ON ii.sku_id = dra.sku_id 
WHERE s.sku_id = ii.sku_id and s.sku_id = pvs.sku_id and s.skuBitMask & 1 = 1 and dra.dra = ii.dateRecordAdded and ii.merchantPrice > 0 
GROUP BY s.sku_id
 )
 SELECT pvsku.productVersion_id as version_id, sum(pvsku.quantity * csc.cost) as cost
FROM ecommerce.productversionsku as pvsku LEFT OUTER JOIN csc ON pvsku.sku_id = csc.sku_id 
WHERE pvsku.sku_id = csc.sku_id 
Group By pvsku.productVersion_id
 )
 SELECT li.order_id as order_id, sum(cvc.cost) as cost 
FROM ecommerce.paymentauthorization as pa, ecommerce.rslineitem as li LEFT OUTER JOIN cvc ON li.productversion_id = cvc.version_id 
WHERE pa.order_id = li.order_id  and pa.payment_transaction_result_id = 1 and pa.payment_status_id in (3,5,6)  and pa.authDate >= now()::DATE - cast('0 day' as interval) and pa.authDate > now()::DATE
Group By li.order_id
 )
 , gtgm AS (select li.order_id,sum(li.customerPrice * li.quantity) as gtgm_total
from ecommerce.rslineitem as li,ecommerce.productversion as pv,ecommerce.item as i, ecommerce.paymentauthorization as pa 
where li.productversion_id = pv.productversion_id and pv.item_id = i.item_id and i.itembitmask & 32 = 32 and li.order_id = pa.order_id  and pa.payment_transaction_result_id = 1 and pa.payment_status_id in (3,5,6)  and pa.authDate >= now()::DATE - cast('0 day' as interval) and pa.authDate > now()::DATE
group by li.order_id
 )
 , ry AS (select li.order_id, sum(COALESCE(sli.quantity,0.00) * coalesce(df.royaltyFactor,0.00)) AS royalty 
from ecommerce.RSLineItem as li, ecommerce.SiteLineItem as sli, ecommerce.DonationFactor as df, ecommerce.PaymentAuthorization as pa, ecommerce.productversion as pv, ecommerce.item as i 
WHERE li.oid = sli.lineItem_id and sli.site_id = df.site_id and li.productversion_id = pv.productversion_id and pv.item_id = i.item_id and pa.order_id = li.order_id  and COALESCE(li.customerprice,0.00) >= df.minPrice and COALESCE(li.customerprice,0.00) < df.maxPrice  and i.itembitmask &2 != 2  and pa.authDate >= now()::DATE - cast('0 day' as interval) and pa.authDate > now()::DATE and pa.payment_transaction_result_id = 1 and pa.payment_status_id in (3,5,6)
group by li.order_id
 )
 select '' as sale_date,COALESCE(o.originCode,'No Origin Code') AS origin_code,count(distinct o.oid) AS order_count,sum(pa.amount) AS auth_amount,sum(coalesce(o.shippingcost,0.00)) as shipping ,sum(coalesce(gtgm.gtgm_total,0.00)) as gtgm_total, sum(coalesce(o.tax,0.00)) as sales_tax, sum(coalesce(ry.royalty,0.00)) as royalty ,sum(pa.amount) - sum(coalesce(o.shippingcost,0.00)) - sum(coalesce(gtgm.gtgm_total,0.00)) - sum(coalesce(o.tax,0.00)) - COALESCE(sum(ry.royalty),0.00) as adj_revenue,sum(cocp.cost) as cogs
from ecommerce.PaymentAuthorization as pa,ecommerce.RSOrder as o LEFT OUTER JOIN gtgm ON o.oid = gtgm.order_id LEFT OUTER JOIN cocp ON o.oid = cocp.order_id LEFT OUTER JOIN ry on o.oid = ry.order_id 
where pa.order_id = o.oid and pa.order_id = ry.order_id and pa.order_id = cocp.order_id and gtgm.order_id = pa.order_id  and pa.payment_transaction_result_id = 1 and pa.payment_status_id in (3,5,6) and pa.authDate >= now()::DATE - cast('0 day' as interval) and pa.authDate > now()::DATE
group by COALESCE(o.originCode,'No Origin Code')
order by auth_amount desc,COALESCE(o.originCode,'No Origin Code')
 