//
// Period Sales - DRAFT REVISION
// Edited Catherine Warren, 2015-10-26 through 12-10 || JIRA RPT-176
// Edited Catherine Warren, 2016-12-14 | JIRA-197
//

var orderSource = p["orderSource"];
var store_name = p["store_name2"];
var site = p["site4"];

var dayInterval = p["days2"];
var startDate = p["start"];
var endDate = p["end"];

var lat = p["lat"];
var adj = p["adj"];
var plat = p["platform"];

sum.push('orders');
sum.push('items');
sum.push('customer_price');
sum.push('royalty');
sum.push('shipping');
sum.push('tax');
sum.push('adjust');
sum.push('gross_revenue');
sum.push('gtgm');
sum.push('adj_revenue');
weightedAverage['avg_order']='orders';

var dateClause = "";
if (notEmpty(dayInterval)) {
	dateClause = dateClause + "pa.authDate >= now()::DATE - cast('" + dayInterval + " day' as interval)";
    if (dayInterval == 0) {
         dateClause = dateClause + " and pa.authDate > now()::DATE";
    } else {
         dateClause = dateClause + " and pa.authDate < now()::DATE";
    }
} else {
	// empty interval, so we are using only dates...
    if (notEmpty(startDate)) {
    	dateClause = dateClause + "pa.authDate >= '" + startDate + "'";
        if (notEmpty(endDate)) {
        	dateClause = dateClause + " and pa.authDate < '" + endDate + "'";
        }
    } else {
    	dateClause = dateClause + "pa.authDate >= date_trunc('month',now()::DATE)";
    }
}

var stuffProcessor = new SelectSQLBuilder();
stuffProcessor.setSelect("select o.store_id, li.order_id, pa.authDate::DATE AS auth_date ");
stuffProcessor.appendSelect("sum(li.quantity) AS items_sold, round((sum(li.customerPrice * li.quantity))::numeric,2) AS customer_price ");
stuffProcessor.setGroupBy("group by o.store_id, li.order_id, pa.authDate::DATE ");
stuffProcessor.setFrom("from ecommerce.RSOrder AS o, ecommerce.SiteLineItem as sli ");
stuffProcessor.appendFrom("ecommerce.RSLineItem as li, ecommerce.PaymentAuthorization as pa, ecommerce.ProductVersion as pv ");
stuffProcessor.setWhere("where o.oid = li.order_id and li.oid = sli.lineItem_id ");
stuffProcessor.appendWhere("li.productversion_id = pv.productversion_id and o.oid = pa.order_id and pa.payment_transaction_result_id = 1 and pa.payment_status_id in (3,5,6)");
stuffProcessor.appendWhere(dateClause);

if (notEmpty(orderSource)) {
    stuffProcessor.appendWhere("o.order_source_id = " + orderSource );
} else {
    hide.push('order_source');
}

if (notEmpty(store_name)) {
   if (store_name == 'All') {
    stuffProcessor.appendSelect("t.name AS store");
    stuffProcessor.appendFrom("ecommerce.store as t ");
    stuffProcessor.appendWhere("o.store_id = t.store_id ");
    stuffProcessor.appendGroupBy("t.name");
   } else { 
    stuffProcessor.appendWhere("o.store_id = " + store_name );
      }
}

if (notEmpty(site)) {
	if (site > 0 && site < 99999) {
        stuffProcessor.appendWhere("o.site_id = " + site);
    }
}

if ("m" == plat) {
    stuffProcessor.appendWhere("o.client_ip_address in ('54.215.150.37','54.241.179.159','54.215.150.33','54.215.148.134','54.208.37.246','54.236.100.183','54.208.57.30','54.208.37.89','54.154.19.105','54.154.18.247','54.172.227.126','54.174.197.243','54.67.78.16','54.67.110.97','54.246.211.85','54.246.211.102','54.229.31.168','54.229.72.158','54.64.130.216','54.64.71.56')");
} else if ("d".equals(plat)) {
    stuffProcessor.appendWhere("o.client_ip_address not in ('54.215.150.37','54.241.179.159','54.215.150.33','54.215.148.134','54.208.37.246','54.236.100.183','54.208.57.30','54.208.37.89','54.154.19.105','54.154.18.247','54.172.227.126','54.174.197.243','54.67.78.16','54.67.110.97','54.246.211.85','54.246.211.102','54.229.31.168','54.229.72.158','54.64.130.216','54.64.71.56')");
}

stuffProcessor.appendWhere("pv.item_id != 1348");

var royaltySubProcessor = new SelectSQLBuilder();
// Sub-sub-query to get correct royalty info (excluding GTGM)
royaltySubProcessor.setSelect("select li.order_id, sum(COALESCE(sli.quantity,0.00) * coalesce(df.royaltyFactor,0.00)) AS royalty ");
royaltySubProcessor.setFrom("from ecommerce.rsorder as o, ecommerce.RSLineItem as li, ecommerce.SiteLineItem as sli, ecommerce.DonationFactor as df, ecommerce.PaymentAuthorization as pa, ecommerce.productversion as pv, ecommerce.item as i ");
royaltySubProcessor.setWhere("where li.order_id = o.oid and li.oid = sli.lineItem_id and sli.site_id = df.site_id and li.productversion_id = pv.productversion_id and pv.item_id = i.item_id and pa.order_id = li.order_id ");
royaltySubProcessor.appendWhere("COALESCE(li.customerprice,0.00) >= df.minPrice and COALESCE(li.customerprice,0.00) < df.maxPrice ");
royaltySubProcessor.appendWhere("i.itembitmask &2 != 2 ");
royaltySubProcessor.appendWhere(dateClause);
royaltySubProcessor.appendWhere("pa.payment_transaction_result_id = 1 and pa.payment_status_id in (3,5,6) ");
royaltySubProcessor.setGroupBy("group by li.order_id");

if (notEmpty(orderSource)) {
    royaltySubProcessor.appendWhere("o.order_source_id = " + orderSource );
}

if (notEmpty(store_name)) {
   if (store_name == 'All') {
    royaltySubProcessor.appendSelect("t.name AS store");
    royaltySubProcessor.appendFrom("ecommerce.store as t ");
    royaltySubProcessor.appendWhere("o.store_id = t.store_id ");
    royaltySubProcessor.appendGroupBy("t.name");
   } else { 
    royaltySubProcessor.appendWhere("o.store_id = " + store_name );
      }
}

if (notEmpty(site)) {
	if (site > 0 && site < 99999) {
        royaltySubProcessor.appendSelect("COALESCE(si.name,'no name available') AS site");
        royaltySubProcessor.appendFrom("ecommerce.site as si ");
        royaltySubProcessor.appendWhere("o.site_id = si.site_id and o.site_id = " + site);
        royaltySubProcessor.appendGroupBy("COALESCE(si.name,'no name available')");
    } else { // if the site id is all_ctg or all_std
    	if ("ignoreAll" == site ) { // do nothing; let everything pass through
        } else if ( "showAll" == site ) { // it's for a specific site or for all sites
            royaltySubProcessor.appendSelect("COALESCE(si.name,'no name available') AS site");
            royaltySubProcessor.appendFrom("ecommerce.site as si ");
            royaltySubProcessor.appendWhere("o.site_id = si.site_id and o.site_id = " + site);
            royaltySubProcessor.appendGroupBy("COALESCE(si.name,'no name available')");
        } else {
        	royaltySubProcessor.appendSelect("COALESCE(si.name,'no name available') AS site");
            royaltySubProcessor.appendFrom("ecommerce.site as si ");
            royaltySubProcessor.appendWhere("o.site_id = si.site_id" );
            royaltySubProcessor.appendGroupBy("COALESCE(si.name,'no name available')");
            var negateString = "";
            if ("all_std" == site) {
            	negateString = "NOT";
            }
            royaltySubProcessor.appendWhere("si.site_id  " + negateString + " IN (Select e.site_id from ecommerce.site as e , panacea.click_to_give as p where e.active = true and e.panaceasite_id = p.site_id )");
        }
    }
}
  
var royaltyProcessor = new SelectSQLBuilder();
// Subquery to group together the royaltySubProcessor output into days rather than order IDs. 
royaltyProcessor.setSelect("select coalesce(sum(rysub.royalty),0.00) as royalty, pa.authDate::DATE AS auth_date " );
royaltyProcessor.setFrom ("from ecommerce.rsorder as o LEFT OUTER JOIN rysub ON o.oid = rysub.order_id, ecommerce.paymentauthorization as pa, ecommerce.site as si ");
royaltyProcessor.addCommonTableExpression("rysub",royaltySubProcessor);
royaltyProcessor.setWhere("where o.oid = pa.order_id and o.site_id = si.site_id and pa.payment_transaction_result_id = 1 and pa.payment_status_id IN (3, 5, 6) ");
royaltyProcessor.appendWhere(dateClause);
royaltyProcessor.setGroupBy("group by pa.authdate::DATE ");

if (notEmpty(orderSource)) {
    royaltyProcessor.appendWhere("o.order_source_id = " + orderSource );
}

if (notEmpty(store_name)) {
   if (store_name == 'All') {
    royaltyProcessor.appendSelect("t.name AS store");
    royaltyProcessor.appendFrom("ecommerce.store as t ");
    royaltyProcessor.appendWhere("o.store_id = t.store_id ");
    royaltyProcessor.appendGroupBy("t.name");
   } else { 
    royaltyProcessor.appendSelect("t.name AS store");
    royaltyProcessor.appendFrom("ecommerce.store as t ");
    royaltyProcessor.appendWhere("o.store_id = t.store_id and o.store_id = " + store_name );
    royaltyProcessor.appendGroupBy("t.name");
      }
}

if (notEmpty(site)) {
	if (site > 0 && site < 99999) {
        royaltyProcessor.appendSelect("COALESCE(si.name,'no name available') AS site");
        royaltyProcessor.appendWhere("o.site_id = " + site);
        royaltyProcessor.appendGroupBy("COALESCE(si.name,'no name available')");
    } else { // if the site id is all_ctg or all_std
    	if ("ignoreAll" == site ) { // do nothing; let everything pass through
        } else if ( "showAll" == site ) { // it's for a specific site or for all sites
            royaltyProcessor.appendSelect("COALESCE(si.name,'no name available') AS site");
            royaltyProcessor.appendGroupBy("COALESCE(si.name,'no name available')");
        } else {
        	royaltyProcessor.appendSelect("COALESCE(si.name,'no name available') AS site");
            royaltyProcessor.appendGroupBy("COALESCE(si.name,'no name available')");
            var negateString = "";
            if ("all_std" == site) {
            	negateString = "NOT";
            }
            royaltyProcessor.appendWhere("si.site_id  " + negateString + " IN (Select e.site_id from ecommerce.site as e , panacea.click_to_give as p where e.active = true and e.panaceasite_id = p.site_id )");
        }
    }
} 
  
var sqlProcessor = new SelectSQLBuilder();
sqlProcessor.setSelect("select s.auth_date AS auth_date");
sqlProcessor.appendSelect("count(*) AS orders, sum(s.items_sold) AS items");
sqlProcessor.appendSelect("round((sum(s.customer_price))::numeric,2) AS customer_price");
sqlProcessor.appendSelect("round((COALESCE(ry.royalty,0.00))::numeric,2) AS royalty");
sqlProcessor.appendSelect("round((sum(COALESCE(o.shippingCost,0.00)))::numeric,2) AS shipping");
sqlProcessor.appendSelect("round((sum(COALESCE(o.tax,0.00)))::numeric,2) AS tax");
sqlProcessor.appendSelect("round((sum(COALESCE(o.adjustmentAmount,0.00)))::numeric,2) AS adjust");
sqlProcessor.appendSelect("round((sum(pa.amount - COALESCE(o.tax,0.00)))::numeric,2) AS gross_revenue");
sqlProcessor.appendSelect("round((sum(pa.amount - COALESCE(o.tax,0.00))/count(*))::numeric,2) AS avg_order");
sqlProcessor.setFrom("from ecommerce.rsorder as o LEFT OUTER JOIN s on o.oid = s.order_id, ecommerce.store as t, ecommerce.paymentauthorization as pa LEFT OUTER JOIN ry ON pa.authDate::DATE = ry.auth_date::DATE, ecommerce.site as si ");
sqlProcessor.addCommonTableExpression("s", stuffProcessor);
sqlProcessor.addCommonTableExpression("ry",royaltyProcessor);
sqlProcessor.setWhere("where o.oid = s.order_id and o.site_id = si.site_id and o.store_id = t.store_id and o.oid = pa.order_id");
sqlProcessor.appendWhere("pa.payment_transaction_result_id = 1 and pa.payment_status_id in (3,5,6)");
sqlProcessor.appendWhere(dateClause);
sqlProcessor.setGroupBy("group by s.auth_date, ry.royalty");

if (notEmpty(orderSource)) {
    sqlProcessor.appendSelect("os.order_source as order_source ");
    sqlProcessor.appendFrom("ecommerce.order_source as os ");
    sqlProcessor.appendWhere("o.order_source_id = os.order_source_id and o.order_source_id = " + orderSource );
    sqlProcessor.appendGroupBy("os.order_source ");
} else {
    hide.push('order_source');
}

if (notEmpty(store_name)) {
   if (store_name == 'All') {
    sqlProcessor.appendSelect("t.name AS store");
    sqlProcessor.appendGroupBy("t.name");
    }
   else { 
    sqlProcessor.appendSelect("t.name AS store");
    sqlProcessor.appendWhere("o.store_id = " + store_name );
    sqlProcessor.appendGroupBy("t.name");
   } 

} else {
    hide.push('store'); 
    }

if (notEmpty(site)) {
	if (site > 0 && site < 99999) {
        sqlProcessor.appendWhere("o.site_id = " + site);
        sqlProcessor.appendSelect("COALESCE(si.name,'no name available') AS site");
        sqlProcessor.appendGroupBy("COALESCE(si.name,'no name available')");
    } else { // if the site id is all_ctg or all_std
    	if ("ignoreAll" == site ) {
          hide.push('order_source')
          hide.push('store')
          hide.push('site')
        } else if ( "showAll" == site ) { // it's for a specific site or for all sites
            sqlProcessor.appendSelect("COALESCE(si.name,'no name available') AS site");
            sqlProcessor.appendGroupBy("COALESCE(si.name,'no name available')");
        } else {
        	sqlProcessor.appendSelect("COALESCE(si.name,'no name available') AS site");
            sqlProcessor.appendGroupBy("COALESCE(si.name,'no name available')");
            var negateString = "";
            if ("all_std" == site) {
            	negateString = "NOT";
            }
            sqlProcessor.appendWhere("si.site_id  " + negateString + " IN (Select e.site_id from ecommerce.site as e , panacea.click_to_give as p where e.active = true and e.panaceasite_id = p.site_id )");
        }
    }
}  	else {
    	hide.push('site'); 
    	}


if ("true" == adj) {
	var gtgmProcessor = new SelectSQLBuilder();
    gtgmProcessor.setSelect("select li.order_id, sum(li.customerPrice * li.quantity) as gtgm_total");
    gtgmProcessor.setFrom("from ecommerce.rslineitem as li, ecommerce.productversion as pv, ecommerce.item as i");
    gtgmProcessor.setWhere("where li.productversion_id = pv.productversion_id and pv.item_id = i.item_id and i.itembitmask & 32 = 32");
    gtgmProcessor.setGroupBy("group by li.order_id");
    sqlProcessor.appendSelect("round((sum(COALESCE(gtgm.gtgm_total,0.00)))::numeric,2) AS gtgm");
    sqlProcessor.appendSelect("sum(pa.amount - coalesce(o.shippingcost,0.00) - coalesce(gtgm.gtgm_total,0.00) - coalesce(o.tax,0.00) - coalesce(ry.royalty,0.00)) as adj_revenue");
    sqlProcessor.appendFrom("ecommerce.rsorder as ord LEFT OUTER JOIN (" + gtgmProcessor.queryString() + ")  gtgm ON ord.oid = gtgm.order_id");
    sqlProcessor.appendWhere("ord.oid = o.oid ");
} else {
	hide.push('gtgm');
	hide.push('adj_revenue');
}

if ("true" == lat) {
    sqlProcessor.appendSelect("max(pa.authDate) AS last_auth_time");
    sqlProcessor.setOrderBy("order by last_auth_time");
} else {
    hide.push('last_auth_time');
    sqlProcessor.setOrderBy("order by s.auth_date");
}

if ("m" == plat) {
    sqlProcessor.appendWhere("o.client_ip_address in ('54.215.150.37','54.241.179.159','54.215.150.33','54.215.148.134','54.208.37.246','54.236.100.183','54.208.57.30','54.208.37.89','54.154.19.105','54.154.18.247','54.172.227.126','54.174.197.243','54.67.78.16','54.67.110.97','54.246.211.85','54.246.211.102','54.229.31.168','54.229.72.158','54.64.130.216','54.64.71.56')");
} else if ("d".equals(plat)) {
    sqlProcessor.appendWhere("o.client_ip_address not in ('54.215.150.37','54.241.179.159','54.215.150.33','54.215.148.134','54.208.37.246','54.236.100.183','54.208.57.30','54.208.37.89','54.154.19.105','54.154.18.247','54.172.227.126','54.174.197.243','54.67.78.16','54.67.110.97','54.246.211.85','54.246.211.102','54.229.31.168','54.229.72.158','54.64.130.216','54.64.71.56')");
}

sql = sqlProcessor.queryString();