// Table FCUser

select fcuser_id, username, fullname from fulfillmentcenter.fcuser;

// bit[0], decimal value 1 = Administration : admins
// bit[1], decimal value 2 = Picking : general user
// bit[2], decimal value 4 = Quality Checking : quality checker
// bit[3], decimal value 8 = Packing : general user 

// Any user with the Administration permission:

select fcuser_id, username, fullname from fulfillmentcenter.fcuser
where permission &1 = 1;


// A user who has found a failing SKU, and how many failed SKUs they found

select fcu.fullname as employee, sum((fcs.itemstate & 61440) / 4096) as failedskucount
from fulfillmentcenter.fcuser as fcu, fulfillmentcenter.fcskutracker as fcs 
where fcu.fcuser_id = fcs.fcqc_id and fcs.itemstate & 61440 > 0
group by fcu.fullname;



// Table FCSkuTracker
// NOTE: The order of operations is Pick --> QC --> Pack

// bit[0], decimal value 1 = temporary bit
// bit[1], decimal value 2 = temporary bit
// bit[2], decimal value 4 = temporary bit
// bit[3], decimal value 8 = temporary bit
// bit[4], decimal value 16 = temporary bit
// bit[5], decimal value 32 = free bit
// bit[6], decimal value 64 = free bit
// bit[7], decimal value 128 = free bit
// bit[8], decimal value 256 = free bit
// bit[9], decimal value 512 = Picking
// bit[10], decimal value 1024 = Quality checking
// bit[11], decimal value 2048 = Packing
// bit[12], decimal value 4096 = contains order failing count, value is in range [0:15]. can be used only for quality checking process
// bit[13], decimal value 8192 = contains order failing count, value is in range [0:15]. can be used only for quality checking process
// bit[14], decimal value 16384 = contains order failing count, value is in range [0:15]. can be used only for quality checking process
// bit[15], decimal value 32768 = contains order failing count, value is in range [0:15]. can be used only for quality checking process
// bit[16], decimal value 65536 = free bit

// Any SKU that has been successfully picked (bit 9)  - YES

select fcpicker_id, pickstart, pickend, fcskutracker_id, rsorder_id, sku_id, skulocation_id, quantity, productversionskuquantity, lineitemquantity, itemstate, aisle, bay, shelf, bin, description 
from fulfillmentcenter.fcskutracker
where itemstate & 512 = 512

// Any SKU that has been successfully QCed (bit 10) - YES

select fcqc_id, qcstart, qcend, fcskutracker_id, rsorder_id, sku_id, skulocation_id, quantity, productversionskuquantity, lineitemquantity, itemstate, aisle, bay, shelf, bin, description, pickstart 
from fulfillmentcenter.fcskutracker
where itemstate & 1024 = 1024

// Any SKU that has been successfully packed - YES

select fcpacker_id, packstart, packend, fcskutracker_id, rsorder_id, sku_id, skulocation_id, quantity, productversionskuquantity, lineitemquantity, itemstate, aisle, bay, shelf, bin, description, pickstart 
from fulfillmentcenter.fcskutracker
where itemstate & 2048 = 2048

// Any SKU that has been successfully picked, QCed, and packed - YES

select fcpicker_id, pickstart, pickend, fcqc_id, qcstart, qcend, fcpacker_id, packstart, packend, fcskutracker_id, rsorder_id, sku_id, skulocation_id, quantity, productversionskuquantity, lineitemquantity, itemstate, aisle, bay, shelf, bin, description, pickstart 
from fulfillmentcenter.fcskutracker
where itemstate & 3584 = 3584

// A SKU that was successfully picked, but that failed QC, and who caught it 

select fcpicker_id, pickstart, pickend, fcskutracker_id, rsorder_id, sku_id, quantity, fcqc_id
from fulfillmentcenter.fcskutracker
where itemstate & 61440 > 0;

// The time it took to pick a SKU 

select (pickend - pickstart)::time as picking_time_elapsed
from fulfillmentcenter.fcskutracker
where itemstate & 512 = 512;

// The time it took to QC a SKU

select (qcend - qcstart)::time as qc_time_elapsed
from fulfillmentcenter.fcskutracker
where itemstate & 1024 = 1024;

// The time it took to pack a SKU 

select (packend - packstart)::time as packing_time_elapsed
from fulfillmentcenter.fcskutracker
where itemstate & 2048 = 2048;




// Table FCOrderTracker

// Any order that has been successfully picked, QAed, and packed

select rsorder_id, <other columns>
from fulfillmentcenter.fcordertracker
where itemstate & 3584 = 3584



