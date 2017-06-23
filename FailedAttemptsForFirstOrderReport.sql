with first as (select o.oid as order_id, a.account_id, lower(COALESCE(a.email, o.email)) as email, (CASE WHEN o.oid = LEAST(o.oid) THEN 'true' ELSE 'false' END) as data
from ecommerce.rsorder as o, ecommerce.paymentauthorization as pa, pheme.account as a
where o.oid = pa.order_id and o.account_id = a.account_id
and pa.payment_status_id IN (3, 4, 5, 6) and pa.payment_transaction_result_id = 1
group by o.oid, a.account_id, o.email, a.email
order by o.oid asc)
select first.order_id, first.email, pa.authdate, first.data
from ecommerce.rsorder as o LEFT OUTER JOIN first ON o.oid = first.order_id, ecommerce.paymentauthorization as pa, ecommerce.rslineitem as rsli, ecommerce.productversion as pv, ecommerce.item as i
where o.oid = pa.order_id and o.oid = rsli.order_id and rsli.productversion_id = pv.productversion_id and pv.item_id = i.item_id and pa.payment_status_id IN (3, 4, 5, 6) and pa.payment_transaction_result_id = 1
and i.item_id = 34543
and first.data = 'true'
group by first.order_id, first.email, pa.authdate, first.data;

Total query runtime: 245219 ms.
268 rows retrieved.

with first as (with pool as (select o.oid as order_id, a.account_id, lower(COALESCE(a.email, o.email)) as email
from ecommerce.rsorder as o, ecommerce.paymentauthorization as pa, pheme.account as a
where o.oid = pa.order_id and o.account_id = a.account_id
and pa.payment_status_id IN (3, 4, 5, 6) and pa.payment_transaction_result_id = 1
group by o.oid, a.account_id, a.email, o.email
order by o.oid asc)
select pool.order_id, pool.email, pool.account_id, MIN(pool.order_id) OVER (PARTITION BY pool.account_id)
from ecommerce.rsorder as o LEFT OUTER JOIN pool ON o.oid = pool.order_id, ecommerce.paymentauthorization as pa
where o.oid = pa.order_id 
group by pool.order_id, o.oid, pool.email, pool.account_id)
select first.order_id, first.email, pa.authdate
from ecommerce.rsorder as o LEFT OUTER JOIN first ON o.oid = first.order_id, ecommerce.paymentauthorization as pa, ecommerce.rslineitem as rsli, ecommerce.productversion as pv, ecommerce.item as i
where o.oid = pa.order_id and o.oid = rsli.order_id and rsli.productversion_id = pv.productversion_id and pv.item_id = i.item_id and pa.payment_status_id IN (3, 4, 5, 6) and pa.payment_transaction_result_id = 1
and i.item_id = 34543
group by first.order_id, first.email, pa.authdate;

Total query runtime: 317750 ms.
268 rows retrieved.

with first as (select o.oid as order_id, lower(COALESCE(a.email, o.email)) as email, (CASE WHEN o.oid = MIN(o.oid) THEN true ELSE false END) as data
from ecommerce.rsorder as o, ecommerce.paymentauthorization as pa, pheme.account as a
where o.oid = pa.order_id and o.account_id = a.account_id
and pa.payment_status_id IN (3, 4, 5, 6) and pa.payment_transaction_result_id = 1
group by o.oid, o.email, a.email
order by o.oid asc)
select first.order_id, first.email, pa.authdate, first.data
from ecommerce.rsorder as o LEFT OUTER JOIN first ON o.oid = first.order_id, ecommerce.paymentauthorization as pa, ecommerce.rslineitem as rsli, ecommerce.productversion as pv, ecommerce.item as i
where o.oid = pa.order_id and o.oid = rsli.order_id and rsli.productversion_id = pv.productversion_id and pv.item_id = i.item_id and pa.payment_status_id IN (3, 4, 5, 6) and pa.payment_transaction_result_id = 1
and i.item_id = 34543
and first.data = 'true'
group by first.order_id, first.email, pa.authdate, first.data;

Total query runtime: 192860 ms.
268 rows retrieved.

with first as (select MIN(o.oid) as order_id, lower(COALESCE(a.email, o.email)) as email, pa.authdate as order_date, true as data
from ecommerce.rsorder as o, ecommerce.paymentauthorization as pa, pheme.account as a
where o.oid = pa.order_id and o.account_id = a.account_id
and pa.payment_status_id IN (3, 5, 6) and pa.payment_transaction_result_id = 1
group by o.oid, o.email, a.email, pa.authdate
order by o.oid asc)
select first.order_id, first.email, first.order_date
from ecommerce.rsorder as o LEFT OUTER JOIN first ON o.oid = first.order_id, ecommerce.paymentauthorization as pa, ecommerce.rslineitem as rsli, ecommerce.productversion as pv, ecommerce.item as i
where o.oid = pa.order_id and o.oid = rsli.order_id and rsli.productversion_id = pv.productversion_id and pv.item_id = i.item_id and pa.payment_status_id IN (3, 5, 6) and pa.payment_transaction_result_id = 1
and i.item_id = 34543
and first.data = 'true'
group by first.order_id, first.email, first.order_date, first.data;

Total query runtime: 173351 ms.
267 rows retrieved.


//May 12 attempts...

-- Executing query:
with itemorders AS (
    select
        rsli.order_id as order_id
    from 
        ecommerce.rslineitem rsli
        ,ecommerce.productversion pv
    where
        pv.item_id = 34543
        and pv.productversion_id = rsli.productversion_id    
),accountlist as ( select 
        lower(COALESCE(o.email, a.email)) as email
        ,o.account_id
    from 
        ecommerce.rsorder as o 
        ,pheme.account as a
        ,itemorders io
    where
        o.oid = io.order_id 
        and o.account_id = a.account_id
) select
    min(o.oid) as first_order_id
    ,al.email
    ,al.account_id
from
    accountlist as al
    ,itemorders as io
    ,ecommerce.rsorder as o
    ,pheme.account as a
    ,ecommerce.paymentauthorization as pa
where
    al.account_id = a.account_id 
    and o.account_id = a.account_id
    and o.oid = pa.order_id
    and o.oid = io.order_id
    and pa.payment_status_id IN (3, 4, 5, 6) and pa.payment_transaction_result_id = 1
group by
    o.oid
    ,al.email
    ,al.account_id
Total query runtime: 435 ms.
267 rows retrieved.


-- Executing query:
with itemorders AS (
    select
        rsli.order_id as order_id
    from 
        ecommerce.rslineitem rsli
        ,ecommerce.productversion pv
    where
        pv.item_id = 34543
        and pv.productversion_id = rsli.productversion_id    
),accountlist as ( select 
        lower(COALESCE(o.email, a.email)) as email
        ,o.account_id
    from 
        ecommerce.rsorder as o 
        ,pheme.account as a
        ,itemorders io
    where
        o.oid = io.order_id 
        and o.account_id = a.account_id
) select
    min(o.oid) as first_order_id
from
    accountlist as al
    ,ecommerce.rsorder as o
    ,pheme.account as a
    ,ecommerce.paymentauthorization as pa
where
    al.account_id = a.account_id 
    and o.account_id = a.account_id
    and o.oid = pa.order_id
    and pa.payment_status_id IN (3, 4, 5, 6) and pa.payment_transaction_result_id = 1
group by
    o.oid
    ,al.email
    ,al.account_id
INTERSECT 
    select 
	io.order_id
    from 
	itemorders as io
Total query runtime: 2934 ms.
267 rows retrieved.


-- Executing query:
with itemorders AS (
    select
        rsli.order_id as order_id
    from 
        ecommerce.rslineitem rsli
        ,ecommerce.productversion pv
    where
        pv.item_id = 34543
        and pv.productversion_id = rsli.productversion_id    
),accountlist as ( select 
	min(o.oid) as first_order_id
        ,lower(COALESCE(o.email, a.email)) as email
        ,o.account_id
    from 
        ecommerce.rsorder as o 
        ,pheme.account as a
        ,itemorders io
    where
        o.oid = io.order_id 
        and o.account_id = a.account_id
    group by o.email, a.email, o.account_id
) select
    al.first_order_id
    ,al.email
    ,al.account_id
from
    accountlist al
    ,ecommerce.rsorder as o
    ,pheme.account as a
where
    al.account_id = a.account_id 
    and o.account_id = a.account_id
group by
    al.first_order_id
    ,al.email
    ,al.account_id
INTERSECT
	select io.order_id as first_order_id
	,al.email
	,al.account_id
	from itemorders as io
	,accountlist as al
	where io.order_id = al.first_order_id
Total query runtime: 83 ms.
260 rows retrieved.


-- Executing query:
with itemorders AS (
    select
        rsli.order_id as order_id
    from 
        ecommerce.rslineitem rsli
        ,ecommerce.productversion pv
    where
        pv.item_id = 34543
        and pv.productversion_id = rsli.productversion_id    
),accountlist as ( select 
	min(o.oid) OVER (PARTITION BY o.account_id order by o.oid asc) as first_order_id
        ,lower(COALESCE(o.email, a.email)) as email
        ,o.account_id
    from 
        ecommerce.rsorder as o 
        ,pheme.account as a
        ,itemorders io
    where
        o.oid = io.order_id 
        and o.account_id = a.account_id
    group by o.oid, o.email, a.email, o.account_id
) select
    al.first_order_id
    ,al.email
    ,al.account_id
from
    accountlist al
    ,ecommerce.rsorder as o
    ,pheme.account as a
where
    al.account_id = a.account_id 
    and o.account_id = a.account_id
group by
    al.first_order_id
    ,al.email
    ,al.account_id
INTERSECT
	select io.order_id as first_order_id
	,al.email
	,al.account_id
	from itemorders as io
	,accountlist as al
	where io.order_id = al.first_order_id
Total query runtime: 152 ms.
260 rows retrieved.

-- Executing query:
with itemorders AS (
    select
        rsli.order_id as order_id
    from 
        ecommerce.rslineitem rsli
        ,ecommerce.productversion pv
    where
        pv.item_id = 34543
        and pv.productversion_id = rsli.productversion_id    
),accountlist as ( select 
	min(o.oid) OVER (PARTITION BY o.account_id order by o.oid asc) as first_order_id
        ,lower(COALESCE(o.email, a.email)) as email
        ,o.account_id
    from 
        ecommerce.rsorder as o 
        ,pheme.account as a
        ,itemorders io
    where
        o.oid = io.order_id 
        and o.account_id = a.account_id
    group by o.oid, o.email, a.email, o.account_id
) select
    al.first_order_id
    ,al.email
    ,al.account_id
from
    accountlist as al
    ,itemorders as io
    ,ecommerce.rsorder as o
    ,pheme.account as a
where
    al.account_id = a.account_id 
    and o.account_id = a.account_id
    and o.oid = io.order_id
group by
    al.first_order_id
    ,al.email
    ,al.account_id

Total query runtime: 67 ms.
260 rows retrieved.

-- Executing query:
with itemorders AS (
    select
        rsli.order_id as order_id
    from 
        ecommerce.rslineitem rsli
        ,ecommerce.productversion pv
    where
        pv.item_id = 34543
        and pv.productversion_id = rsli.productversion_id    
),accountlist as ( select 
	min(o.oid) OVER (PARTITION BY o.account_id order by o.oid asc) as first_order_id
        ,lower(COALESCE(o.email, a.email)) as email
        ,o.account_id
    from 
        ecommerce.rsorder as o 
        ,pheme.account as a
        ,itemorders io
    where
        o.oid = io.order_id 
        and o.account_id = a.account_id
    group by o.oid, o.email, a.email, o.account_id
) select
    al.first_order_id
    ,al.email
    ,al.account_id
from
    accountlist as al
    ,itemorders as io
    ,ecommerce.rsorder as o
    ,pheme.account as a
    ,ecommerce.paymentauthorization as pa
where
    al.account_id = a.account_id 
    and o.account_id = a.account_id
    and o.oid = io.order_id
    and o.oid = pa.order_id
    and pa.payment_status_id IN (3, 4, 5, 6) 
    and pa.payment_transaction_result_id = 1
group by
    al.first_order_id
    ,al.email
    ,al.account_id

Total query runtime: 66 ms.
256 rows retrieved.

-- Executing query:
with itemorders AS (
    select
        rsli.order_id as order_id
    from 
        ecommerce.rslineitem rsli
        ,ecommerce.productversion pv
    where
        pv.item_id = 34543
        and pv.productversion_id = rsli.productversion_id    
),accountlist as ( select 
	min(o.oid) OVER (PARTITION BY o.account_id order by o.oid asc) as first_order_id
        ,lower(COALESCE(o.email, a.email)) as email
        ,o.account_id
    from 
        ecommerce.rsorder as o 
        ,pheme.account as a
    where
        o.account_id = a.account_id
    group by o.oid, o.email, a.email, o.account_id
) select
    al.first_order_id
    ,al.email
    ,al.account_id
from
    accountlist as al
    ,itemorders as io
    ,ecommerce.rsorder as o
    ,pheme.account as a
    ,ecommerce.paymentauthorization as pa
where
    al.account_id = a.account_id 
    and o.account_id = a.account_id
    and o.oid = io.order_id
    and o.oid = pa.order_id
    and pa.payment_status_id IN (3, 4, 5, 6) 
    and pa.payment_transaction_result_id = 1
group by
    al.first_order_id
    ,al.email
    ,al.account_id
order by al.email asc

Total query runtime: 134800 ms.
256 rows retrieved.

-- Executing query:
with itemorders AS (
    select
        rsli.order_id as order_id
    from 
        ecommerce.rslineitem rsli
        ,ecommerce.productversion pv
    where
        pv.item_id = 34543
        and pv.productversion_id = rsli.productversion_id    
),accountlist as ( select 
	min(o.oid) OVER (PARTITION BY o.account_id order by o.oid asc) as first_order_id
        ,lower(COALESCE(o.email, a.email)) as email
        ,o.account_id
    from 
        ecommerce.rsorder as o 
        ,pheme.account as a
    where
        o.account_id = a.account_id
    group by o.oid, o.email, a.email, o.account_id
) select
    al.first_order_id
    ,al.email
    ,al.account_id
from
    accountlist as al
    ,ecommerce.rsorder as o RIGHT JOIN itemorders as io ON o.oid = io.order_id
    ,pheme.account as a
    ,ecommerce.paymentauthorization as pa
where
    al.account_id = a.account_id 
    and o.account_id = a.account_id
    and o.oid = io.order_id
    and o.oid = pa.order_id
    and pa.payment_status_id IN (3, 4, 5, 6) 
    and pa.payment_transaction_result_id = 1
group by
    al.first_order_id
    ,al.email
    ,al.account_id
order by al.email asc

Total query runtime: 105826 ms.
256 rows retrieved.

-- Executing query:
with itemorders AS (
    select
        rsli.order_id as order_id
    from 
        ecommerce.rslineitem rsli
        ,ecommerce.productversion pv
    where
        pv.item_id = 34543
        and pv.productversion_id = rsli.productversion_id    
),accountlist as ( select 
	min(o.oid) OVER (PARTITION BY o.account_id order by o.oid asc) as first_order_id
        ,lower(COALESCE(o.email, a.email)) as email
        ,o.account_id
    from 
        ecommerce.rsorder as o 
        ,pheme.account as a
    where
        o.account_id = a.account_id
    group by o.oid, o.email, a.email, o.account_id
) select
    al.first_order_id
    ,al.email
    ,al.account_id
from
    accountlist as al 
    ,ecommerce.rsorder as o RIGHT JOIN itemorders as io ON o.oid = io.order_id
    ,pheme.account as a
    ,ecommerce.paymentauthorization as pa
where
    al.account_id = a.account_id 
    and o.account_id = a.account_id
    and o.oid = pa.order_id
    and pa.payment_status_id IN (3, 4, 5, 6) 
    and pa.payment_transaction_result_id = 1
group by
    al.first_order_id
    ,al.email
    ,al.account_id
order by al.email asc

Total query runtime: 134163 ms.
256 rows retrieved.

with accountlist as ( select 
    min(o.oid) OVER (PARTITION BY o.account_id order by o.oid asc) as first_order_id
        ,lower(COALESCE(o.email, a.email)) as email
        ,o.account_id
    from 
        ecommerce.rsorder as o 
        ,pheme.account as a
    where
        o.account_id = a.account_id
    group by o.oid, o.email, a.email, o.account_id
) select
    al.first_order_id
    ,al.email
    ,al.account_id
from
    accountlist as al
    ,ecommerce.rsorder as o
    ,ecommerce.rslineitem as rsli
    ,ecommerce.productversion as pv
    ,pheme.account as a
    ,ecommerce.paymentauthorization as pa
where
    al.account_id = a.account_id 
    and o.account_id = a.account_id
    and o.oid = pa.order_id
    and pa.payment_status_id IN (3, 4, 5, 6) 
    and pa.payment_transaction_result_id = 1
    and o.oid = rsli.order_id
    and rsli.productversion_id = pv.productversion_id
    and pv.item_id = 34543
group by
    al.first_order_id
    ,al.email
    ,al.account_id
order by al.email asc

Total query runtime: 132245 ms.
256 rows retrieved.





-- Executing query:
with itemorders AS (
    select
        rsli.order_id as order_id
    from 
        ecommerce.rslineitem rsli
        ,ecommerce.productversion pv
    where
        pv.item_id = 34543
        and pv.productversion_id = rsli.productversion_id    
),accountlist as ( select 
    min(o.oid) OVER (PARTITION BY o.account_id order by o.oid asc) as first_order_id
        ,lower(COALESCE(o.email, a.email)) as email
        ,o.account_id
    from 
        ecommerce.rsorder as o 
        ,pheme.account as a
        ,itemorders io
    where
        o.oid = io.order_id 
        and o.account_id = a.account_id
    group by o.oid, o.email, a.email, o.account_id
) select
    al.first_order_id
    ,al.email
    ,al.account_id
from
    accountlist as al
    ,itemorders as io
    ,ecommerce.rsorder as o
    ,pheme.account as a
    ,ecommerce.paymentauthorization as pa
where
    al.account_id = a.account_id 
    and o.account_id = a.account_id
    and o.oid = io.order_id
    and o.oid = pa.order_id
    and pa.payment_status_id IN (3, 4, 5, 6) 
    and pa.payment_transaction_result_id = 1
group by
    al.first_order_id
    ,al.email
    ,al.account_id
order by al.email asc

Total query runtime: 80 ms.
256 rows retrieved.



with itemorders AS (
    select
        rsli.order_id as order_id
    from 
        ecommerce.rslineitem rsli
        ,ecommerce.productversion pv
    where
        pv.item_id = 34543
        and pv.productversion_id = rsli.productversion_id    
),accountlist as ( select 
    min(o.oid) OVER (PARTITION BY o.account_id order by o.oid asc) as first_order_id
        ,lower(COALESCE(o.email, a.email)) as email
        ,o.account_id
    from 
        ecommerce.rsorder as o 
        ,pheme.account as a
        ,itemorders io
    where
        o.oid = io.order_id 
        and o.account_id = a.account_id
    group by o.oid, o.email, a.email, o.account_id
) select
    al.first_order_id
    ,al.email
    ,al.account_id
from
    accountlist as al
    ,ecommerce.rsorder as o RIGHT JOIN itemorders as io ON o.oid = io.order_id 
    ,pheme.account as a
    ,ecommerce.paymentauthorization as pa
where
    al.account_id = a.account_id 
    and o.account_id = a.account_id
    and o.oid = pa.order_id
    and pa.payment_status_id IN (3, 4, 5, 6) 
    and pa.payment_transaction_result_id = 1
group by
    al.first_order_id
    ,al.email
    ,al.account_id
order by al.email asc

Total query runtime: 182 ms.
256 rows retrieved.

with pool as (with accountlist as ( select 
    min(o.oid) OVER (PARTITION BY o.account_id order by o.oid asc) as first_order_id
        ,lower(COALESCE(o.email, a.email)) as email
        ,o.account_id
    from 
        ecommerce.rsorder as o 
        ,pheme.account as a
    where
        o.account_id = a.account_id
    group by o.oid, o.email, a.email, o.account_id
) select
    al.first_order_id
    ,al.email
    ,al.account_id
from
    accountlist as al
    ,ecommerce.rsorder as o
    ,pheme.account as a
    ,ecommerce.paymentauthorization as pa
where
    al.account_id = a.account_id 
    and o.account_id = a.account_id
    and o.oid = pa.order_id
    and pa.payment_status_id IN (3, 4, 5, 6) 
    and pa.payment_transaction_result_id = 1
group by
    al.first_order_id
    ,al.email
    ,al.account_id
order by al.email asc)
select pool.first_order_id, pool.email, pool.account_id
    from 
        ecommerce.rslineitem as rsli LEFT JOIN pool ON rsli.order_id = pool.first_order_id
        ,ecommerce.productversion as pv
    where
        pv.item_id = 34543
        and pv.productversion_id = rsli.productversion_id;
Total query runtime: 1259209 ms.
405 rows retrieved.

with pool as (with accountlist as ( select 
    min(o.oid) OVER (PARTITION BY o.account_id order by o.oid asc) as first_order_id
        ,lower(COALESCE(o.email, a.email)) as email
        ,o.account_id
    from 
        ecommerce.rsorder as o 
        ,pheme.account as a
    where
        o.account_id = a.account_id
    group by o.oid, o.email, a.email, o.account_id
) select
    al.first_order_id
    ,al.email
    ,al.account_id
from
    accountlist as al
    ,ecommerce.rsorder as o
    ,pheme.account as a
    ,ecommerce.paymentauthorization as pa
where
    al.account_id = a.account_id 
    and o.account_id = a.account_id
    and o.oid = pa.order_id
    and pa.payment_status_id IN (3, 4, 5, 6) 
    and pa.payment_transaction_result_id = 1
group by
    al.first_order_id
    ,al.email
    ,al.account_id
order by al.email asc)
select distinct pool.first_order_id, pool.email, pool.account_id
    from 
        ecommerce.rslineitem as rsli LEFT JOIN pool ON rsli.order_id = pool.first_order_id
        ,ecommerce.productversion as pv
    where
        pv.item_id = 34543
        and pv.productversion_id = rsli.productversion_id
        and pool.email is not null;
Total query runtime: 1210969 ms.
106 rows retrieved.

// THIS IS WHAT I WANT! , but it takes WAY too long! :P

with pool as (with accountlist as ( select 
    min(o.oid) OVER (PARTITION BY o.account_id order by o.oid asc) as order_id
        ,lower(COALESCE(o.email, a.email)) as email
        ,o.account_id
    from 
        ecommerce.rsorder as o 
        ,pheme.account as a
    where
        o.account_id = a.account_id
    group by o.oid, o.email, a.email, o.account_id
) select
    al.order_id
    ,al.email
    ,al.account_id
from
    accountlist as al
    ,ecommerce.rsorder as o
    ,pheme.account as a
    ,ecommerce.paymentauthorization as pa
where
    al.account_id = a.account_id 
    and o.account_id = a.account_id
    and o.oid = pa.order_id
    and pa.payment_status_id IN (3, 4, 5, 6) 
    and pa.payment_transaction_result_id = 1
group by
    al.order_id
    ,al.email
    ,al.account_id
order by al.email asc),

itemorders as (
select distinct o.oid as order_id, COALESCE(o.email, a.email), o.account_id
    from 
    ecommerce.rsorder as o
    , pheme.account as a
        , ecommerce.rslineitem as rsli 
        ,ecommerce.productversion as pv
    where
        o.oid = rsli.order_id
        and o.account_id = a.account_id
        and pv.productversion_id = rsli.productversion_id
        and pv.item_id = 34543) 

select 
pool.order_id
    ,pool.email
    ,pool.account_id
     from pool INNER JOIN itemorders as io USING (order_id);

// takes about 22 minutes. 


with itemorders as (select distinct o.oid as order_id, COALESCE(o.email, a.email) as email, o.account_id
    from 
    ecommerce.rsorder as o
    , pheme.account as a
        , ecommerce.rslineitem as rsli 
        ,ecommerce.productversion as pv
    where
        o.oid = rsli.order_id
        and o.account_id = a.account_id
        and pv.productversion_id = rsli.productversion_id
        and pv.item_id = 34543)
select io.order_id, io.email, io.account_id, (CASE WHEN io.order_id = MIN(o.oid) OVER (partition by o.account_id order by o.oid asc) THEN true ELSE false END) as data
from ecommerce.rsorder as o RIGHT JOIN itemorders as io ON o.oid = io.order_id
order by io.email asc;

// ought to work, but gives bad results. Too many orders show as true, when they should be false. 

