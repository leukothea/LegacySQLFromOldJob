//
// Gross Sales Summary
// Moved into Pepe, Catherine Warren, 2016-07-22 & on | JIRA RPT-418
//

var orderSource = p["orderSource"];
var store_name = p["storefront_name_withextras"];
var site_abbrv = p["site_abbrv_withextras"];
var start = p["start"];
var end = p["end"];


var sitestring = ""

if (notEmpty(site_abbrv)) {
    if (site_abbrv == "show_all" || site_abbrv == "rollup_all") {
      // do not filter by site - let all results through
    } else if (site_abbrv == "rollup_ctg" || site_abbrv == "show_ctg") {
        sitestring = "'THS', 'BCS', 'ARS', 'CHS', 'DBS', 'TRS', 'LIT', 'VET', 'AUT', 'ALZ', 'TES'";
    } else if (site_abbrv == "rollup_std" || site_abbrv == "show_std") {
        sitestring = "'PRS', 'GGF', 'HFL', 'JG', 'CK', 'SB', 'GG', 'CPW', 'DGL', 'RB'" ;
    } else {
        sitestring = "'" + site_abbrv + "'";
    }
}

shippingAdjustmentProcessor = new SelectSQLBuilder();

shippingAdjustmentProcessor.setSelect("select o.oid as order_id, COALESCE(ra.amount, 0.00) as shipping_adjustment ");
shippingAdjustmentProcessor.setFrom("from ecommerce.RSOrder as o, ecommerce.RSAdjustment as ra ");
shippingAdjustmentProcessor.setWhere("where o.oid = ra.order_id and ra.adjustment_type_id = 6 ");

if (notEmpty(start)) { 
    shippingAdjustmentProcessor.appendWhere("o.orderdate >= '" + start + "' ");
}

if (notEmpty(site_abbrv)) {
    if (site_abbrv == "show_all" || site_abbrv == "rollup_all") {
        // do nothing - do not filter the results
    } else {
        shippingAdjustmentProcessor.appendFrom("ecommerce.site as st ");
        shippingAdjustmentProcessor.appendWhere("o.site_id = st.site_id ");
        shippingAdjustmentProcessor.appendWhere("st.abbreviation IN (" + sitestring + ") ");
    }
}


promotionAdjustmentProcessor = new SelectSQLBuilder();

promotionAdjustmentProcessor.setSelect("select o.oid as order_id, COALESCE(ra.amount,0.00) as promotion_adjustment ");
promotionAdjustmentProcessor.setFrom("from ecommerce.RSOrder as o, ecommerce.RSAdjustment as ra ");
promotionAdjustmentProcessor.setWhere("where o.oid = ra.order_id and ra.adjustment_type_id = 1 ");

if (notEmpty(start)) { 
    promotionAdjustmentProcessor.appendWhere("o.orderdate >= '" + start + "' ");
}

if (notEmpty(site_abbrv)) {
    if (site_abbrv == "show_all" || site_abbrv == "rollup_all") {
        // do nothing - do not filter the results
    } else {
        promotionAdjustmentProcessor.appendFrom("ecommerce.site as st ");
        promotionAdjustmentProcessor.appendWhere("o.site_id = st.site_id ");
        promotionAdjustmentProcessor.appendWhere("st.abbreviation IN (" + sitestring + ") ");
    }
}


paymentAuthProcessor = new SelectSQLBuilder();

paymentAuthProcessor.setSelect("select o.oid AS order_id, pa.amount AS payment_amount, pa.authDate::DATE AS auth_date, COALESCE(shipadj.shipping_adjustment, 0.00) AS shipping_adjustment, COALESCE(promadj.promotion_adjustment, 0.00) AS promotion_adjustment, COALESCE(ash.iso_country_code,'US') AS country ");
paymentAuthProcessor.setFrom("from ecommerce.RSOrder as o LEFT OUTER JOIN ecommerce.RSAddress as ash ON COALESCE(o.shippingaddress_id, o.billingaddress_id) = ash.oid LEFT OUTER JOIN shipadj ON o.oid = shipadj.order_id LEFT OUTER JOIN promadj ON o.oid = promadj.order_id, ecommerce.PaymentAuthorization as pa ");
paymentAuthProcessor.addCommonTableExpression("shipadj", shippingAdjustmentProcessor);
paymentAuthProcessor.addCommonTableExpression("promadj", promotionAdjustmentProcessor);
paymentAuthProcessor.setWhere("where o.oid = pa.order_id and pa.payment_transaction_result_id = 1 and pa.payment_status_id in (3,5,6) ");
paymentAuthProcessor.setGroupBy("group by o.oid, pa.amount, pa.authDate, promadj.promotion_adjustment, shipadj.shipping_adjustment, ash.iso_country_code ");

if (notEmpty(start)) { 
    paymentAuthProcessor.appendWhere("pa.authdate >= '" + start + "' ");
}

if (notEmpty(end)) { 
    paymentAuthProcessor.appendWhere("pa.authdate < '" + end + "' ");
}

if (notEmpty(site_abbrv)) {
    if (site_abbrv == "show_all" || site_abbrv == "rollup_all") {
        // do nothing - do not filter the results
    } else {
        paymentAuthProcessor.appendFrom("ecommerce.site as st ");
        paymentAuthProcessor.appendWhere("o.site_id = st.site_id ");
        paymentAuthProcessor.appendWhere("st.abbreviation IN (" + sitestring + ") ");
    }
}


lineItemAdjProcessor = new SelectSQLBuilder();

lineItemAdjProcessor.setSelect("select li.oid AS line_item_id, li.order_id, sum(ra.amount) AS adjustment ");
lineItemAdjProcessor.setFrom("from ecommerce.RSLineItem li, ecommerce.RSAdjustment as ra ");
lineItemAdjProcessor.setWhere("where li.oid = ra.lineItem_id ");
lineItemAdjProcessor.setGroupBy("group by li.oid ");

if (notEmpty(start)) { 
    lineItemAdjProcessor.appendWhere("li.date_record_added >= '" + start + "' ");
}

if (notEmpty(site_abbrv)) {
    if (site_abbrv == "show_all" || site_abbrv == "rollup_all") {
        // do nothing - do not filter the results
    } else {
        lineItemAdjProcessor.appendFrom("ecommerce.rsorder as o, ecommerce.site as st ");
        lineItemAdjProcessor.appendWhere("li.order_id = o.oid and o.site_id = st.site_id ");
        lineItemAdjProcessor.appendWhere("st.abbreviation IN (" + sitestring + ") ");
    }
}


tempStuffProcessor = new SelectSQLBuilder();

tempStuffProcessor.setSelect("select o.oid AS order_id, sum(li.quantity) AS items_sold, (sum(li.quantity * li.customerPrice) - COALESCE(lineitemadj.adjustment,0.00)) AS customer_price, st.abbreviation as site_abbrv ");
tempStuffProcessor.setFrom("from ecommerce.RSOrder as o, ecommerce.RSLineItem li LEFT OUTER JOIN lineitemadj ON li.oid = lineitemadj.line_item_id ");
tempStuffProcessor.addCommonTableExpression("lineitemadj", lineItemAdjProcessor);
tempStuffProcessor.setWhere("where o.oid = li.order_id and COALESCE(li.lineItemType_id,1) in (1,5) ");
tempStuffProcessor.setGroupBy("group by o.oid, lineitemadj.adjustment, st.abbreviation ");

if (notEmpty(start)) { 
    tempStuffProcessor.appendWhere("o.orderdate >= '" + start + "' ");
}

if (notEmpty(site_abbrv)) {
    if (site_abbrv == "show_all" || site_abbrv == "rollup_all") {
        // do nothing - do not filter the results
    } else {
        tempStuffProcessor.appendFrom("ecommerce.site as st ");
        tempStuffProcessor.appendWhere("o.site_id = st.site_id ");
        tempStuffProcessor.appendWhere("st.abbreviation IN (" + sitestring + ") ");
    }
}


tempTrafficProcessor = new SelectSQLBuilder();

tempTrafficProcessor.setSelect("select t.traffic_date::DATE, sum(t.session_count) as session_count ");
tempTrafficProcessor.setFrom("from traffic.daily_traffic as t ");
tempTrafficProcessor.setWhere("where t.application_id = 2 ");
tempTrafficProcessor.setGroupBy("group by t.traffic_date ");

if (notEmpty(start)) { 
    tempTrafficProcessor.appendWhere("t.traffic_date >= '" + start + "' ");
}

if (notEmpty(end)) { 
    tempTrafficProcessor.appendWhere("t.traffic_date < '" + end + "' ");
}

if (notEmpty(site_abbrv)) {
    if (site_abbrv == "rollup_all") {
        // do nothing - do not filter the results
    } else if (site_abbrv == "show_all") { 
        tempTrafficProcessor.appendSelect("UPPER(pa.abbrv) as site_abbrv ");
        tempTrafficProcessor.appendFrom("panacea.site as pa ");
        tempTrafficProcessor.appendWhere("t.site_id = pa.site_id ");
        tempTrafficProcessor.appendGroupBy("pa.abbrv ");
    } else {
        tempTrafficProcessor.appendSelect("UPPER(pa.abbrv) as site_abbrv ");
        tempTrafficProcessor.appendFrom("panacea.site as pa ");
        tempTrafficProcessor.appendWhere("t.site_id = pa.site_id ");
        tempTrafficProcessor.appendWhere("UPPER(pa.abbrv) IN (" + sitestring + ") ");
        tempTrafficProcessor.appendGroupBy("pa.abbrv ");
    }
}


mainProcessor = new SelectSQLBuilder();

mainProcessor.setSelect("select distinct payauth.auth_date::DATE AS auth_date ");
mainProcessor.appendSelect("to_char(payauth.auth_date::DATE,'Dy') AS day_of_week ");
mainProcessor.appendSelect("SUM(position(payauth.country IN 'US') * position('US' IN payauth.country)) AS us_order_count ");
mainProcessor.appendSelect("SUM(1 * (1 - position(payauth.country IN 'US') * position('US' IN payauth.country))) AS intl_order_count ");
mainProcessor.appendSelect("count(o.oid) AS total_order_count ");
mainProcessor.appendSelect("SUM(tempstuff.items_sold * (position(payauth.country IN 'US') * position('US' IN payauth.country))) AS us_items_sold ");
mainProcessor.appendSelect("SUM(tempstuff.items_sold * (1 - position(payauth.country IN 'US') * position('US' IN payauth.country))) AS intl_items_sold ");
mainProcessor.appendSelect("SUM(tempstuff.items_sold) AS total_sold ");
mainProcessor.appendSelect("SUM(o.tax * (position(payauth.country IN 'US') * position('US' IN payauth.country))) AS us_sales_tax ");
mainProcessor.appendSelect("SUM(o.tax * (1 - position(payauth.country IN 'US') * position('US' IN payauth.country))) AS intl_sales_tax ");
mainProcessor.appendSelect("SUM(o.tax) AS total_sales_tax ");
mainProcessor.appendSelect("SUM((o.shippingcost) * (position(payauth.country IN 'US') * position('US' IN payauth.country))) AS us_shipping ");
mainProcessor.appendSelect("SUM((o.shippingcost) * (1 - position(payauth.country IN 'US') * position('US' IN payauth.country))) AS intl_shipping ");
mainProcessor.appendSelect("SUM(o.shippingcost) AS total_shipping ");
mainProcessor.appendSelect("SUM(o.adjustmentamount * (position(payauth.country IN 'US') * position('US' IN payauth.country))) AS us_adjustments ");
mainProcessor.appendSelect("SUM(o.adjustmentamount * (1 - position(payauth.country IN 'US') * position('US' IN payauth.country))) AS intl_adjustments ");
mainProcessor.appendSelect("SUM(COALESCE(payauth.shipping_adjustment,0.00)) AS shipping_adjustments ");
mainProcessor.appendSelect("SUM(COALESCE(payauth.promotion_adjustment,0.00)) AS promotion_adjustments ");
mainProcessor.appendSelect("SUM(o.adjustmentamount - COALESCE(payauth.shipping_adjustment,0.00) - COALESCE(payauth.promotion_adjustment,0.00)) AS product_adjustments ");
mainProcessor.appendSelect("SUM(o.adjustmentamount) AS total_adjustments ");
mainProcessor.appendSelect("SUM(COALESCE(o.shippingcost,0.00) - COALESCE(payauth.shipping_adjustment,0.00)) AS shipping_revenue ");
mainProcessor.appendSelect("SUM(payauth.payment_amount * (position(payauth.country IN 'US') * position('US' IN payauth.country))) AS us_payment_amount ");
mainProcessor.appendSelect("SUM(payauth.payment_amount * (1 - position(payauth.country IN 'US') * position('US' IN payauth.country))) AS intl_payment_amount ");
mainProcessor.appendSelect("SUM(payauth.payment_amount) AS total_payment_amount ");
mainProcessor.appendSelect("SUM((COALESCE(tempstuff.customer_price,0.00) + COALESCE(o.shippingcost,0.00) - COALESCE(payauth.shipping_adjustment,0.00) - COALESCE(payauth.promotion_adjustment,0.00))  * (position(payauth.country IN 'US') * position('US' IN payauth.country))) AS us_gross_revenue ");
mainProcessor.appendSelect("SUM((COALESCE(tempstuff.customer_price,0.00) + COALESCE(o.shippingcost,0.00) - COALESCE(payauth.shipping_adjustment,0.00) - COALESCE(payauth.promotion_adjustment,0.00))  * (1 - position(payauth.country IN 'US') * position('US' IN payauth.country))) AS intl_gross_revenue ");
mainProcessor.appendSelect("SUM(COALESCE(tempstuff.customer_price,0.00) + COALESCE(o.shippingcost,0.00) - COALESCE(payauth.shipping_adjustment,0.00) - COALESCE(payauth.promotion_adjustment,0.00)) AS total_gross_revenue ");
mainProcessor.appendSelect("SUM((COALESCE(tempstuff.customer_price,0.00)) * (position(payauth.country IN 'US') * position('US' IN payauth.country))) AS us_customer_price ");
mainProcessor.appendSelect("SUM((COALESCE(tempstuff.customer_price,0.00)) * (1 - position(payauth.country IN 'US') * position('US' IN payauth.country))) AS intl_customer_price ");
mainProcessor.appendSelect("SUM(COALESCE(tempstuff.customer_price,0.00)) AS total_customer_price ");
mainProcessor.appendSelect("SUM(COALESCE(traffic.session_count,0)) AS session_count ");
mainProcessor.appendSelect("case when SUM(COALESCE(traffic.session_count,0)) != 0 then ((sum(payauth.payment_amount) - sum(o.tax)) / SUM(COALESCE(traffic.session_count,0))::numeric(10,2)) else 0.00 end AS gross_revenue_per_session ");
mainProcessor.appendSelect("case when SUM(COALESCE(traffic.session_count,0)) != 0 then (100.0 * count(o.oid) / SUM(COALESCE(traffic.session_count,0)))::numeric(10,2) else 0.00 end AS orders_per_session ");
mainProcessor.addCommonTableExpression("payauth", paymentAuthProcessor);
mainProcessor.addCommonTableExpression("tempstuff", tempStuffProcessor);
mainProcessor.addCommonTableExpression("traffic", tempTrafficProcessor);
mainProcessor.setFrom("from ecommerce.RSOrder as o LEFT OUTER JOIN payauth ON o.oid = payauth.order_id LEFT OUTER JOIN tempstuff ON o.oid = tempstuff.order_id, ecommerce.paymentauthorization as pa LEFT OUTER JOIN traffic ON pa.authdate::DATE = traffic.traffic_date ");
mainProcessor.setWhere("where payauth.auth_date IS NOT NULL and o.oid = pa.order_id ");
mainProcessor.setGroupBy("group by payauth.auth_date::DATE ");
mainProcessor.appendGroupBy("to_char(payauth.auth_date::DATE,'Dy') ");
//mainProcessor.appendGroupBy("SUM(COALESCE(traffic.session_count,0)) ");
mainProcessor.setOrderBy("order by payauth.auth_date::DATE ");

if (notEmpty(orderSource)) {
    mainProcessor.appendSelect("os.order_source ");
    mainProcessor.appendFrom("ecommerce.order_source as os ");
    mainProcessor.appendWhere("o.order_source_id = os.order_source_id ");
    mainProcessor.appendWhere("o.order_source_id = " + orderSource);
    mainProcessor.appendGroupBy("os.order_source ");
} 

if (notEmpty(store_name)) {
    if (store_name == "show_all_stores") {
        mainProcessor.appendSelect("st.name as store_name ");
        mainProcessor.appendFrom("ecommerce.store as st ");
        mainProcessor.appendWhere("o.store_id = st.store_id ");
        mainProcessor.appendGroupBy("st.name ");
    } else {
        mainProcessor.appendSelect("st.name as store_name ");
        mainProcessor.appendFrom("ecommerce.store as st ");
        mainProcessor.appendWhere("o.store_id = st.store_id ");
        mainProcessor.appendWhere("st.name = '" + store_name + "' ");
        mainProcessor.appendGroupBy("st.name ");
    }
} 

if (notEmpty(site_abbrv)) {
    if (site_abbrv == "rollup_all" || site_abbrv == "rollup_ctg" || site_abbrv == "rollup_std") { 
        mainProcessor.appendFrom("ecommerce.site as si ");
        mainProcessor.appendWhere("o.site_id = si.site_id ");
        mainProcessor.appendWhere("traffic.site_abbrv = si.abbreviation ");
        mainProcessor.appendWhere("si.abbreviation IN (" + sitestring + ") ");
        hide.push('site_abbrv');
    } else { 
        mainProcessor.appendSelect("si.abbreviation as site_abbrv ");
        mainProcessor.appendFrom("ecommerce.site as si ");
        mainProcessor.appendWhere("o.site_id = si.site_id ");
        mainProcessor.appendGroupBy("si.abbreviation ");
        mainProcessor.appendWhere("si.abbreviation IN (" + sitestring + ") ");
    } 
}

mainString = mainProcessor.queryString();

groupedProcessor = new SelectSQLBuilder();

groupedProcessor.setSelect("select main.auth_date, main.day_of_week ");
groupedProcessor.appendSelect("sum(main.us_order_count) as us_order_count, sum(main.intl_order_count) as intl_order_count, sum(main.total_order_count) as total_order_count ");
groupedProcessor.appendSelect("sum(main.us_items_sold) as us_items_sold, sum(main.intl_items_sold) as intl_items_sold, sum(main.total_sold) as total_sold ");
groupedProcessor.appendSelect("sum(main.us_sales_tax) as us_sales_tax, sum(main.intl_sales_tax) as intl_sales_tax, sum(main.total_sales_tax) as total_sales_tax ");
groupedProcessor.appendSelect("sum(main.us_shipping) as us_shipping, sum(main.intl_shipping) as intl_shipping, sum(main.total_shipping) as total_shipping ");
groupedProcessor.appendSelect("sum(main.us_adjustments) as us_adjustments, sum(main.intl_adjustments) as intl_adjustments, sum(main.shipping_adjustments) as shipping_adjustments ");
groupedProcessor.appendSelect("sum(main.promotion_adjustments) as promotion_adjustments, sum(main.product_adjustments) as product_adjustments, sum(main.total_adjustments) as total_adjustments, sum(main.shipping_revenue) as shipping_revenue ");
groupedProcessor.appendSelect("sum(main.us_payment_amount) as us_payment_amount, sum(main.intl_payment_amount) as intl_payment_amount, sum(main.total_payment_amount) as total_payment_amount ");
groupedProcessor.appendSelect("CAST(CASE WHEN sum(main.total_gross_revenue) > 0 THEN (sum(main.intl_gross_revenue) / sum(main.total_gross_revenue)) ELSE 0 END AS numeric(10,2)) AS percent_intl_gross_sales ");
groupedProcessor.appendSelect("sum(main.us_gross_revenue) as us_gross_revenue, sum(main.intl_gross_revenue) as intl_gross_revenue, sum(main.total_gross_revenue) as total_gross_revenue ");
groupedProcessor.appendSelect("sum(main.us_customer_price) as us_customer_price, sum(main.intl_customer_price) as intl_customer_price, sum(main.total_customer_price) as total_customer_price ");
groupedProcessor.appendSelect("sum(main.session_count) as session_count, sum(main.gross_revenue_per_session) as gross_revenue_per_session, sum(main.orders_per_session) as orders_per_session ");
groupedProcessor.setFrom("from (" + mainString + ") as main ");
groupedProcessor.setWhere("where true ");
groupedProcessor.setGroupBy("group by main.auth_date, main.day_of_week ");
//groupedProcessor.appendGroupBy("main.us_order_count, main.intl_order_count, main.total_order_count, main.us_items_sold, main.intl_items_sold, main.total_sold, main.us_sales_tax, main.intl_sales_tax, main.total_sales_tax ");
//groupedProcessor.appendGroupBy("main.us_shipping, main.intl_shipping, main.total_shipping, main.us_adjustments, main.intl_adjustments, main.shipping_adjustments ");
//groupedProcessor.appendGroupBy("main.promotion_adjustments, main.product_adjustments, main.total_adjustments, main.shipping_revenue ");
//groupedProcessor.appendGroupBy("main.us_payment_amount, main.intl_payment_amount, main.total_payment_amount ");
//groupedProcessor.appendGroupBy("main.us_gross_revenue, main.intl_gross_revenue, main.total_gross_revenue, main.us_customer_price, main.intl_customer_price, main.total_customer_price ");
//groupedProcessor.appendGroupBy("main.session_count, main.gross_revenue_per_session, main.orders_per_session ");

if (notEmpty(orderSource)) {
    groupedProcessor.appendSelect("main.order_source ");
    groupedProcessor.appendGroupBy("main.order_source ");
} else {
    hide.push('order_source');
}

if (notEmpty(store_name)) {
    groupedProcessor.appendSelect("main.store_name ");
    groupedProcessor.appendGroupBy("main.store_name ");
} else {
    hide.push('store_name');
}

if (notEmpty(site_abbrv)) {
    if (site_abbrv == "rollup_all" || site_abbrv == "rollup_ctg" || site_abbrv == "rollup_std") { 
        // do nothing; let the rolled-up results through as-is
    } else { 
        groupedProcessor.appendSelect("main.site_abbrv ");
        groupedProcessor.appendGroupBy("main.site_abbrv ");
        groupedProcessor.appendWhere("main.site_abbrv IN (" + sitestring + ") ");
    }
}


sum.push("total_order_count");

sql = groupedProcessor.queryString();