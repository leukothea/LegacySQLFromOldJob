//
// Orders By Item / Vendor / Status
// Catherine Warren, 2015-07-15
// Revised Catherine Warren, 2015-07-31 (adding item search)
// Revised Catherine Warren, 2015-08-03 to 06 (adding lineItemProcessor to fetch all order rows)
// Revised Catherine Warren, 2015-09-09 (fixing columns for searches that don't have Show All Line Items checked)
// Revised Catherine Warren & Sopheary Chiv, 2015-10-09 (adding Site dropdown to select)
// Revised Catherine Warren, 2015-11-17 (adding Order Status as an input & output)
// Revised Catherine Warren, 2016-01-04, JIRA RPT-202
//

var startDate = p["start"];
var endDate = p["end"];
var vendorId = p["vendor"];
var item_id = p["itemId"];
var item_name = p["itemName"];
var show_all_line_items = p["show_all_line_items"];
var site = p["site"];
var payment_status = p["payment_status"];

var lineItemProcessor = new SelectSQLBuilder();

lineItemProcessor.setSelect("select li.order_id ");
lineItemProcessor.setFrom("from ecommerce.item as i, ecommerce.rslineitem as li, ecommerce.site as s, ecommerce.rsorder as o, ecommerce.productversion as v, ecommerce.paymentauthorization as pa, ecommerce.payment_transaction_result as pt, ecommerce.payment_status as ps ");
lineItemProcessor.setWhere("where i.item_id = v.item_id and li.productversion_id = v.productversion_id and li.order_id = o.oid and li.order_id = pa.order_id and o.site_id = s.site_id and pa.payment_transaction_result_id = pt.payment_transaction_result_id and pa.payment_status_id = ps.payment_status_id and pa.payment_transaction_result_id = 1 ");
if (notEmpty(startDate)) {
            lineItemProcessor.appendWhere("pa.authDate >= '" + startDate + "'");
        } else {
            lineItemProcessor.appendWhere("pa.authDate::DATE >= date_trunc('month',now()::DATE)");
        }
        if (notEmpty(endDate)) {
            lineItemProcessor.appendWhere("pa.authDate < '" + endDate + "'");
        }
if (notEmpty(vendorId)) {
        lineItemProcessor.appendWhere("i.vendor_id = " + vendorId);
    }

if (notEmpty (item_id)) {
  lineItemProcessor.appendWhere ("i.item_id IN ( " + item_id  + ")" );
}

if (notEmpty (item_name)) {
  lineItemProcessor.appendWhere ("i.name ILIKE ( %" + item_name  + "%)" );
}

if (notEmpty(site)) {
  	if("ignoreAll" == site) {
		} 
    else if("showAll" == site) {
		}  
	else if ("all_ctg" == site) {
		lineItemProcessor.appendWhere("o.site_id IN (220,221,224,310,345,346,348,349,2001)");
    	}
	else if ("all_std" == site) {
		lineItemProcessor.appendWhere("o.site_id IN (343,344,347,350,351,352)");
    	} 
    else {
		lineItemProcessor.appendWhere("o.site_id = " + site);
    	}
    }


var sqlProcessor = new SelectSQLBuilder();

sqlProcessor.setSelect("select distinct o.oid as order_id, s.name as site_name, pt.payment_transaction_result as payment_result, ps.payment_status, pa.authdate as auth_date ");
sqlProcessor.setFrom("from ecommerce.item as i, ecommerce.rslineitem as li, ecommerce.site as s, ecommerce.rsorder as o, ecommerce.productversion as v, ecommerce.paymentauthorization as pa, ecommerce.payment_transaction_result as pt, ecommerce.payment_status as ps ");
sqlProcessor.setWhere("where i.item_id = v.item_id and li.productversion_id = v.productversion_id and li.order_id = o.oid and li.order_id = pa.order_id and o.site_id = s.site_id and pa.payment_transaction_result_id = pt.payment_transaction_result_id and pa.payment_status_id = ps.payment_status_id and pa.payment_transaction_result_id = 1 ");
sqlProcessor.setOrderBy("order by o.oid asc ");
sqlProcessor.setGroupBy("group by o.oid, s.name, pt.payment_transaction_result, ps.payment_status, pa.authdate ");

if (notEmpty (show_all_line_items)) {
 sqlProcessor.appendSelect("v.name as version_name, li.customerprice as customer_price, li.tax ");
 sqlProcessor.appendRelationToFromWithAlias(lineItemProcessor, "lp");
 sqlProcessor.appendWhere("lp.order_id = li.order_id ");
 sqlProcessor.appendGroupBy ("v.name, li.customerprice, li.tax");
 hide.push('order_total');
 hide.push('adjustment_amount');
 hide.push('shipping');
} else {
	sqlProcessor.appendSelect("o.tax as tax, o.shippingcost as shipping, -(o.adjustmentamount) as adjustment_amount, round((sum(li.quantity * li.customerPrice))::numeric,2) AS customer_price, pa.amount as order_total ");
  	sqlProcessor.appendGroupBy ("pa.amount, o.tax, o.shippingcost, o.adjustmentamount ");
	if (notEmpty(startDate)) {
            sqlProcessor.appendWhere("pa.authDate >= '" + startDate + "'");
        } else {
            sqlProcessor.appendWhere("pa.authDate::DATE >= date_trunc('month',now()::DATE)");
        }
        if (notEmpty(endDate)) {
            sqlProcessor.appendWhere("pa.authDate < '" + endDate + "'");
        }
	if (notEmpty(vendorId)) {
        sqlProcessor.appendWhere("i.vendor_id = " + vendorId);
    }
	if (notEmpty (item_id)) {
  		sqlProcessor.appendWhere ("i.item_id IN ( " + item_id  + ")" );
	}
	if (notEmpty (item_name)) {
  		sqlProcessor.appendWhere ("i.name ILIKE ( '%" + item_name  + "%')" );
	}

    if (notEmpty(site)) {
  		if("ignoreAll" == site) {
		} 
      	else if("showAll" == site) {
		}  
		else if ("all_ctg" == site) {
		sqlProcessor.appendWhere("o.site_id IN (220,221,224,310,345,346,348,349,2001)");
    	}
		else if ("all_std" == site) {
		sqlProcessor.appendWhere("o.site_id IN (343,344,347,350,351,352)");
    	} 
    	else {
		sqlProcessor.appendWhere("o.site_id = " + site);
    	}
    }
  
  //else if (notEmpty(site)) {
   // sqlProcessor.appendWhere("o.site_id = " + site);
//}
	hide.push('version_name');
  
	}

if (notEmpty (payment_status)) {
  	if("all_but_voided" == payment_status) {
        sqlProcessor.appendWhere("pa.payment_status_id IN (3, 5, 6) ");
    } else {
        sqlProcessor.appendWhere("ps.payment_status = '" + payment_status + "' ");
    } 
}

sql = sqlProcessor.queryString();