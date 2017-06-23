//
// Items with Nonstandard Shipping
// Catherine Warren, 2015-08-27
//

var site_name = p["site5"];
var shipping_mechanism = p["shipping_mechanism"];
var vendorId = p["vendor"];

var sqlProcessor = new SelectSQLBuilder();

sqlProcessor.setSelect("select i.item_id, i.name as item_name, st.itemstatus as item_status, si.name as site_name, sm.shippingmechanism as shipping_mechanism, v.name as vendor");
sqlProcessor.setFrom("from ecommerce.item as i, ecommerce.shippingmechanism as sm, ecommerce.itemstatus as st, ecommerce.site as si, ecommerce.vendor as v ");
sqlProcessor.setWhere("where i.shippingmechanism_id = sm.shippingmechanism_id and i.itemstatus_id = st.itemstatus_id and i.primary_site_id = si.site_id and i.vendor_id = v.vendor_id and i.shippingmechanism_id NOT IN (2, 8) and i.itemstatus_id != 5 ");

if (notEmpty(shipping_mechanism)) {
   sqlProcessor.appendWhere("sm.shippingmechanism_id = " + shipping_mechanism);
}

if (notEmpty(vendorId)) {
    sqlProcessor.appendWhere("i.vendor_id = " + vendorId);
    }

if (notEmpty(site_name)) {
   sqlProcessor.appendWhere("si.site_id = " + site_name);
}

sqlProcessor.setGroupBy("group by i.item_id, i.name, st.itemstatus, si.name, sm.shippingmechanism, v.name ");

sql = sqlProcessor.queryString();