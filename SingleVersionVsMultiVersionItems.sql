-- Of the entire batch of non-retired items with at least one version, what percentage is single-version, and what percentage is multi-version? 

WITH query2 AS ( 
    select 
        count(*) as cnt
    from 
        ecommerce.item as i
        ,ecommerce.productversion as pv
    where 
        i.item_id = pv.item_id
        and i.itemstatus_id != 5
    group by 
        i.item_id,i.name
        having count(pv.item_id) = 1 
),query1 AS ( 
    select count(*) as cnt
    from 
        ecommerce.item as i
        ,ecommerce.productversion as pv
    where 
        i.item_id = pv.item_id
        and i.itemstatus_id != 5
    group by 
        i.item_id,i.name
    having 
        count(pv.item_id) > 1 
),query3 AS (
    select 
        count(*) as cnt 
    from 
        query1
),query4 as (
    select 
        count(*) as cnt 
    from 
        query2
)
select 
    query3.cnt
    ,100.0* query3.cnt/(query3.cnt+query4.cnt) as pcnt1
    ,query4.cnt
    ,100.0 *query4.cnt / (query3.cnt+query4.cnt) as pcnt2 
from 
    query3,query4