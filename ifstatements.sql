if (notEmpty(dayInterval)) {
    sqlProcessor.appendWhere("pa.authDate >= now()::DATE - cast('" + dayInterval + " day' as interval)");
    if (dayInterval == 0) {
        sqlProcessor.appendWhere("pa.authDate > now()::DATE");
        sqlProcessor.appendSelect("round((sum(li.quantity * li.customerPrice))::numeric,2) AS normal_daily_price");
    } else {
        sqlProcessor.appendWhere("pa.authDate < now()::DATE");
        sqlProcessor.appendSelect("round((sum(li.quantity * li.customerPrice) / extract('day' from now()::DATE - (now()::DATE - cast('" + dayInterval + " day' as interval))))::numeric,2) AS normal_daily_price");
    }
} else {
    // empty interval, so we are using only dates...
    if (notEmpty(startDate)) {
        sqlProcessor.appendWhere("pa.authDate >= '" + startDate + "'");
        if (notEmpty(endDate)) {
            sqlProcessor.appendWhere("pa.authDate < '" + endDate + "'");
        }
        sqlProcessor.appendSelect("round((sum(li.quantity * li.customerPrice) / case when (now()::DATE - '" + startDate + "'::DATE) > 0 then now()::DATE - '" + startDate + "'::DATE else 1 end)::numeric,2) AS normal_daily_price");
    } else {
        sqlProcessor.appendWhere("pa.authDate >= date_trunc('month',now()::DATE)");
        sqlProcessor.appendSelect("round((sum(li.quantity * li.customerPrice) / extract('day' from now()::DATE - (now()::DATE - date_trunc('month',now()::DATE))))::numeric,2) AS normal_daily_price");
    }
}



if (notEmpty(vendor)) {
    if (vendor == 'All') {
      // do nothing; let all vendors pass through
    } if (vendor == 'Product Team Vendors') {
      bqProcessor.appendWhere("v.vendor_id NOT IN (77, 81, 89) ");
    } else {
      bqProcessor.appendWhere("v.name = '" + vendor + "'");
    }
}



WITH Q as (SELECT DISTINCT * FROM ( mainSet UNION pvSet) as zzzz ) SELECT q.item_id, q.item_name,