// DRAFT -- this version gives a false high number for picked / QCed / packed SKUs. Looks like it's taking the picked SKU total and squaring it, then adding it again, to get the total it's reporting. Rolling back in favor of the one with the sub-sub-query and the sub-query to sum it. 


  WITH successfully_picked_skus AS (select fcpicker_id, pickstart, pickend, (pickend - pickstart)::time as picktime, rsorder_id, sku_id, quantity, pickedquantity, productversionskuquantity, lineitemquantity, itemstate ,(pickend - pickstart) as timespan, sum(pickedquantity) as sum_skus_per_order 
from fulfillmentcenter.fcskutracker 
where itemstate & 512 = 512  and pickstart >= '11/15/2016' 
group by fcpicker_id, pickstart, pickend, rsorder_id, sku_id, quantity, pickedquantity, productversionskuquantity, lineitemquantity, itemstate 
 )
 , successfully_qced_skus AS (select fcqc_id, qcstart, qcend, (qcend - qcstart) as qctime, fcskutracker_id, rsorder_id, sku_id, skulocation_id, productversionskuquantity, quantity, lineitemquantity, itemstate, (qcend - qcstart) as timespan 
from fulfillmentcenter.fcskutracker 
where itemstate & 1024 = 1024  and qcstart >= '11/15/2016' 
 )
 , successfully_packed_skus AS (select fcpacker_id, packstart, packend, (packend - packstart) as packtime, fcskutracker_id, rsorder_id, sku_id, skulocation_id, productversionskuquantity, quantity, lineitemquantity, itemstate, (packend - packstart) as timespan 
from fulfillmentcenter.fcskutracker 
where itemstate & 2048 = 2048  and packstart >= '11/15/2016' 
 )
 , picked_skus_that_failed_qc AS (select fcpicker_id, pickstart, pickend, fcskutracker_id, rsorder_id, sku_id, quantity, fcqc_id 
from fulfillmentcenter.fcskutracker 
where itemstate & 61440 > 0  and pickstart >= '11/15/2016' 
 )
 select fcu.fullname as employee, fcu.username ,COALESCE(SUM(pick.quantity),0) as qty_skus_picked, AVG(pick.picktime) as avg_sku_pick_time, COALESCE(COUNT(DISTINCT pick.sku_id),0) as unique_skus_picked ,COALESCE(SUM(qc.quantity),0) as qty_skus_qced, AVG(qc.qctime) as avg_sku_qc_time ,COALESCE(SUM(pack.quantity),0) as qty_skus_packed, AVG(pack.packtime) as avg_sku_pack_time ,COALESCE(SUM(pickfail1.quantity),0) as qty_skus_user_picked_that_later_failed_qc ,COALESCE(SUM(pickfail2.quantity),0) as qty_failing_skus_that_user_caught 
from fulfillmentcenter.fcuser as fcu LEFT OUTER JOIN successfully_picked_skus as pick ON fcu.fcuser_id = pick.fcpicker_id LEFT OUTER JOIN successfully_qced_skus as qc ON fcu.fcuser_id = qc.fcqc_id LEFT OUTER JOIN successfully_packed_skus as pack ON fcu.fcuser_id = pack.fcpacker_id LEFT OUTER JOIN picked_skus_that_failed_qc as pickfail1 ON fcu.fcuser_id = pickfail1.fcpicker_id LEFT OUTER JOIN picked_skus_that_failed_qc as pickfail2 ON fcu.fcuser_id = pickfail2.fcqc_id 
where true 
group by fcu.fcuser_id 
 