// SKU-level Fulfillment query draft, 2017-01-11

with successfully_picked_skus as (
	select 
		fcpicker_id
		, pickstart
		, pickend
		, (pickend - pickstart)::time as picktime
		, fcskutracker_id
		, rsorder_id
		, sku_id
		, skulocation_id
		, quantity
		, productversionskuquantity
		, lineitemquantity
		, itemstate
		, aisle
		, bay
		, shelf
		, bin
		, description 
	from 
		fulfillmentcenter.fcskutracker
	where 
		itemstate & 512 = 512
), successfully_qced_skus as (
	select 
		fcqc_id
		, qcstart
		, qcend
		, (qcend - qcstart)::time as qctime
		, fcskutracker_id
		, rsorder_id
		, sku_id
		, skulocation_id
		, quantity
		, productversionskuquantity
		, lineitemquantity
		, itemstate
		, aisle
		, bay
		, shelf
		, bin
		, description
	from 
		fulfillmentcenter.fcskutracker
	where 
		itemstate & 1024 = 1024
), successfully_packed_skus as (
	select 
		fcpacker_id
		, packstart
		, packend
		, (packend - packstart)::time as packtime
		, fcskutracker_id
		, rsorder_id
		, sku_id
		, skulocation_id
		, quantity
		, productversionskuquantity
		, lineitemquantity
		, itemstate
		, aisle
		, bay
		, shelf
		, bin
		, description
	from 
		fulfillmentcenter.fcskutracker
	where 
		itemstate & 2048 = 2048
), 
picked_skus_that_failed_qc as (
	select 
		fcpicker_id
		, pickstart
		, pickend
		, fcskutracker_id
		, rsorder_id
		, sku_id 
		, quantity
		, fcqc_id
	from 
		fulfillmentcenter.fcskutracker
	where 
		itemstate & 61440 > 0
)

select 
	fcu.fcuser_id
	, fcu.username
	, fcu.fullname 
	, COALESCE(SUM(pick.quantity),0) as count_skus_picked
	, AVG(pick.picktime) as average_pick_time
	, COALESCE(COUNT DISTINCT(pick.sku_id),0) as unique_skus_picked
	, COALESCE(SUM(qc.quantity),0) as count_skus_qced
	, AVG(qc.qctime) as average_qc_time
	, COALESCE(SUM(pack.quantity),0) as count_skus_packed
	, AVG(pack.packtime) as average_pack_time
	, COALESCE(SUM(pickfail1.quantity),0) as count_skus_user_picked_that_later_failed_qc
	, COALESCE(SUM(pickfail2.quantity),0) as count_skus_user_qced_that_were_failing
from 
	fulfillmentcenter.fcuser as fcu LEFT OUTER JOIN successfully_picked_skus as pick ON fcu.fcuser_id = pick.fcpicker_id LEFT OUTER JOIN successfully_qced_skus as qc ON fcu.fcuser_id = qc.fcqc_id LEFT OUTER JOIN successfully_packed_skus as pack ON fcu.fcuser_id = pack.fcpacker_id LEFT OUTER JOIN picked_skus_that_failed_qc as pickfail1 ON fcu.fcuser_id = pickfail1.fcpicker_id LEFT OUTER JOIN picked_skus_that_failed_qc as pickfail2 ON fcu.fcuser_id = pickfail2.fcqc_id
	group by fcu.fcuser_id
	order by fcu.fcuser_id asc;