//
// Sale Price History by Item
// Catherine Warren, 2015-11-06
// Edited 2015-11-11, Catherine Warren, to change "saleEndDateBeforeOrOn" to saleEndDateBefore"
// 


var sale_subtype = p["sale_subtype"];
var item_id = p["itemId"];
var saleStartDateOnOrAfter = p["saleStartDateOnOrAfter"];
var saleEndDateBefore = p["saleEndDateBefore"];

var sqlProcessor = new SelectSQLBuilder();

sqlProcessor.setSelect("select pt.promotion_sale_type as sale_subtype, p.promotion_id, p.name as promotion_name, i.item_id, i.name as item_name, pr.customerprice as price, pr.startdate as start_date, pr.enddate as end_date ");
sqlProcessor.setFrom("from ecommerce.promotion as p, ecommerce.promotion_sale_type as pt, ecommerce.item as i, ecommerce.price as pr ");
sqlProcessor.setWhere("where p.promotion_sale_type_id = pt.promotion_sale_type_id and p.promotion_id = pr.promotion_id and pr.sourceclass_id = 5 and pr.pricetype_id = 3 and pr.source_id = i.item_id ");
sqlProcessor.setGroupBy("group by pt.promotion_sale_type, p.promotion_id, p.name, i.item_id, i.name, pr.customerprice, pr.startdate, pr.enddate ");
sqlProcessor.setOrderBy("order by pr.enddate desc ");

//if(notEmpty(startDate)) {
//    sqlProcessor.appendWhere("ibs.date_record_added >= '" + dateAdded + "'");
//}


if (notEmpty(sale_subtype)) {
  	if(sale_subtype == "0") {
      // don't limit by sale type; show all results
		} 
    else {
    sqlProcessor.appendWhere("p.promotion_sale_type_id = " + sale_subtype);
    }
}
  
if (notEmpty (item_id)) {
    sqlProcessor.appendWhere ("i.item_id IN ( " + item_id  + ")" );
}

if (notEmpty (saleStartDateOnOrAfter)) {
    sqlProcessor.appendWhere ("CAST(pr.startdate as DATE) >= '" + saleStartDateOnOrAfter + "'");
}

if (notEmpty (saleEndDateBefore)) {
    sqlProcessor.appendWhere ("CAST(pr.enddate as DATE) < '" + saleEndDateBefore + "'");
}

sql = sqlProcessor.queryString();