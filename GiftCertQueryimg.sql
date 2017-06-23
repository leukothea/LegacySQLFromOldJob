-- Gift Certificates by year issued

with rolledupview as (
	with detailedview as (
		select 
			gc.gift_certificate_id
			, gc.code AS coupon_code
			, gc.start_date::DATE as date_issued
			, EXTRACT(year from gc.start_date)::text as year_issued
			, gc.start_balance
			, (gc.start_balance - gc.current_balance) AS amount_claimed
			, gc.current_balance
			,btrim('http://fang.greatergood.net/pepe/viewer/report/gift_certificate_detail_report?couponId='|| trim(gc.code)) || '&output=html' AS subreporturl
		from 
			ecommerce.gift_certificate as gc 
		where 
			gc.gift_certificate_type_id = 1
			and gc.start_date < '2016-05-01'
		group by 
			gc.start_date
			, gc.gift_certificate_id
			, gc.code
			, gc.start_balance
			, gc.current_balance
	) select 
		detailedview.gift_certificate_id
		, detailedview.coupon_code
		, detailedview.year_issued
		, detailedview.start_balance
		, detailedview.amount_claimed
		, detailedview.current_balance
	from 
		detailedview
	where 
		true
	group by 
		detailedview.gift_certificate_id
		, detailedview.coupon_code
		, detailedview.year_issued
		, detailedview.start_balance
		, detailedview.amount_claimed
		, detailedview.current_balance
	order by 
		detailedview.year_issued
)
select 
	rolledupview.year_issued
	, sum(rolledupview.start_balance) as start_balance
	, sum(rolledupview.amount_claimed) as amount_claimed
	, sum(rolledupview.current_balance) as current_balance
from 
	rolledupview
where 
	true
group by 
	rolledupview.year_issued
order by 
	rolledupview.year_issued desc;


-- Start at code to find original gift certificate redemptions... 

with rsordercode as (
	select 
		o.oid as order_id
		, c.amountoff as amount_claimed
		, c.oid as coupon_id
	from 
		ecommerce.rsorder as o
		, ecommerce.rsordercoupon as oc
		, ecommerce.rscoupon as c
	where 
		o.oid = oc.order_id 
		and oc.coupon_id = c.oid 
		and c.gift_certificate_type_id = 1 
	group by 
		o.oid
		, c.amountoff
		, c.oid
)
select 
	c.oid as coupon_id
	, sum(rsordercode.amount_claimed) as gc_amount_claimed
from 
	ecommerce.rscoupon as c 
		LEFT OUTER JOIN rsordercode ON c.oid = rsordercode.coupon_id
	, ecommerce.rsorder as o
	, ecommerce.paymentauthorization as pa
where 
	rsordercode.order_id = o.oid 
	and o.oid = pa.order_id
	and pa.payment_status_id IN (3, 5, 6)
	and pa.payment_transaction_result_id = 1
	and c.oid != 8719
group by 
	c.oid;

-- New-style gift certificates issued more than 6 months ago

select 
	gc.gift_certificate_id
	, gc.code AS coupon_code
	, gc.start_date::DATE as date_issued
	, EXTRACT(year from gc.start_date)::text as year_issued
	, gc.start_balance
	, (gc.start_balance - gc.current_balance) AS amount_claimed
	, gc.current_balance
	,btrim('http://fang.greatergood.net/pepe/viewer/report/gift_certificate_detail_report?couponId='|| trim(gc.code)) || '&output=html' AS subreporturl
from 
	ecommerce.gift_certificate as gc 
where 
	gc.gift_certificate_type_id = 1
	and gc.start_date <= '2016-05-01'
group by 
	gc.start_date
	, gc.gift_certificate_id
	, gc.code
	, gc.start_balance
	, gc.current_balance;
