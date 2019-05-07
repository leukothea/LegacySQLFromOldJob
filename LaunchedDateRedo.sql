WITH Q1 AS (
select 
    o11.oid, true as to_exclude 
from 
    ecommerce.rsorder as o11
    ,ecommerce.promotion as p11
    ,ecommerce.orderpromotion as op11
    ,ecommerce.promotionaction as pact11 
where 
    o11.oid = op11.order_id 
    and op11.promotion_id = p11.promotion_id 
    and p11.promotion_id = pact11.promotion_id 
    and pact11.inputparam IN ('SHIPPING_PRICE', 'SHIPPING_DISCOUNT')
)  
select 
    o1.oid as order_id
    ,o1.shippingcost
    ,o1.shippingcost AS shipping_price 
from 
    ecommerce.rsorder as o1 LEFT OUTER JOIN Q1 q ON o1.oid = q.oid
    ,ecommerce.paymentauthorization as pa 
where 
    o1.oid = pa.order_id 
    and pa.payment_transaction_result_id = 1 
    and pa.payment_status_id IN (3, 5, 6) 
    and NOT q.to_exclude = true
    and pa.authDate >= now()::DATE - cast('1 day' as interval) 
    and pa.authDate < now()::DATE
group by o1.oid, o1.shippingcost


WITH Q as (
    SELECT 
        DISTINCT * 
    FROM ( 
        select 
            item_id
            , item_name
            , item_status
            , site_name
            , vendor
            , min(launch_date) as launch_date 
        from ( 
            select 
                i.item_id
                , i.name as item_name
                , st.itemstatus as item_status
                , s.name as site_name
                , v.name as vendor
                , MIN(CAST(sh.date_record_added as DATE)) as launch_date
                , true as to_exclude
            from 
                ecommerce.item as i
                , ecommerce.site as s
                , ecommerce.itemstatus as st
                , ecommerce.vendor as v
                , ecommerce.source_product_status_history as sh 
            where 
                i.item_id = sh.source_id 
                and i.itemstatus_id = st.itemstatus_id 
                and i.primary_site_id = s.site_id 
                and i.vendor_id = v.vendor_id 
                and sh.sourceclass_id = 5 
                and sh.previous_itemstatus_id IN (2, 3, 4) 
                and sh.new_itemstatus_id = 0  
                and sh.date_record_added >= '06/01/2015' 
                and v.vendor_id = '94' 
                and i.itembitmask & 256 != 256  
                and i.name NOT LIKE 'FP - %' 
            GROUP BY item_id, item_name, item_status, site_name, vendor 
            ) as bq
        group by 
            item_id, item_name, item_status, site_name, vendor 
        UNION 

        select 
            distinct i.item_id
            , i.name
            , st.itemstatus as item_status
            , s.name as site_name
            , v.name as vendor
            , MIN(CAST(pv.initiallaunchdate as DATE)) as launch_date 
        from 
            ecommerce.item as i
            , ecommerce.itemstatus as st
            , ecommerce.productversion as pv
            , ecommerce.site as s
            , ecommerce.vendor as v 
            LEFT OUTER JOIN bq ON bq.item_id = i.item_id
        where 
            i.item_id = pv.item_id 
            and i.itemstatus_id = st.itemstatus_id 
            and i.primary_site_id = s.site_id 
            and i.vendor_id = v.vendor_id  
            and NOT bq.to_exclude = true
            and pv.initiallaunchdate >= '06/01/2015' 
            and v.vendor_id = '94' 
            and i.itembitmask & 256 != 256  
            and i.name NOT LIKE 'FP - %' 
        group by 
            i.item_id
            , i.name
            , st.itemstatus
            , s.name
            , v.name
            , pv.initiallaunchdate 
          ) 
zzzz ) 

SELECT 
    q.item_id
    , q.item_name
    , q.item_status
    , q.site_name
    , q.vendor, MIN(q.launch_date) as launch_date 
FROM 
    Q 
where 
    q.item_id = q.item_id 
    and q.launch_date >= '06/01/2015' 
GROUP BY 
    q.item_id
    , q.item_name
    , q.item_status
    , q.site_name
    , q.vendor 

