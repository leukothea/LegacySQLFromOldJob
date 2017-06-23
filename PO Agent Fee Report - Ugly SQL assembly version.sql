//
//  PO Agent Fee Report
//

var startDate = p["start"];
var endDate = p["end"];

sum.push("flat_rate_surcharge");

sql = "select 'PO' as record_type,po.purchaseorder_id as po_id, po.dateissued as date_issued, pos.status as po_status, po.flat_rate_surcharge ";
sql += " from ecommerce.purchaseorder po,ecommerce.purchaseorderstatus pos "; 
sql += " where po.dateissued > '" + startDate + "' and po.purchaseorderstatus_id = pos.purchaseorderstatus_id"; 
sql += " and po.dateissued < '" + endDate + "'"; 
sql += " and po.flat_rate_surcharge is not null ";
sql += " and po.surcharge_type_id = 32 ";
sql += " and po.purchaseorderstatus_id != 6"; 
sql += " UNION select 'PO LineItem' as record_type,po.purchaseorder_id as po_id, po.dateissued as date_issued, pos.status as pos_status, li.flatratesurcharge as flat_rate_surcharge ";
sql += " from ecommerce.purchaseorder po, ecommerce.purchaseorderlineitem li,ecommerce.purchaseorderstatus pos ";
sql += " where po.purchaseorder_id = li.purchaseorder_id and po.purchaseorderstatus_id = pos.purchaseorderstatus_id ";
sql += " and po.dateissued > '" + startDate + "' ";
sql += " and po.dateissued < '" + endDate + "' ";
sql += " and li.flatratesurcharge is not null ";
sql += " and li.surchargetype_id = 32 ";
sql += " and po.purchaseorderstatus_id != 6 ";

sql += " UNION select 'POLI Unit Surcharge' as record_type,po.purchaseorder_id as po_id, po.dateissued as date_issued, pos.status, li.flatratesurcharge as flat_rate_surcharge";
sql += " from ecommerce.purchaseorder as po, ecommerce.purchaseorderlineitem as li ,ecommerce.purchaseorderstatus pos ";
sql += " where po.purchaseorder_id = li.purchaseorder_id  and po.purchaseorderstatus_id = pos.purchaseorderstatus_id ";
sql += " and po.dateissued > '" + startDate + "'  ";
sql += " and po.dateissued < '" + endDate + "'  ";
sql += " and li.unitsurcharge is not null  ";
sql += " and li.surchargetype_id = 32  ";
sql += " and po.purchaseorderstatus_id != 6 ";