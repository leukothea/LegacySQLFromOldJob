//
// Launched Item Count Report
// Catherine Warren, 2015-07-30
// Edited Catherine Warren & Ted Kubaitis, 2015-08-20
// Edited Catherine Warren, 2015-10-30, to add vendor dropdown and two checkboxes
// Edited Catherine Warren, 2015-11-02, to add product version launch history as well (RPT-162)
// Edited Catherine Warren, 2015-12-23, to remove items that actually launched a long time ago and merely had a recently-launched version (RPT-164), and to add a column to hold the value "1" (RPT-201)
//

var startDate = p["start"];
var endDate = p["end"];
var vendor = p["vendor"];
var disallow_nfr = p["disallow_notforresale_items"];
var disallow_fp = p["disallow_familypet_items"];

count.push('item_id');

var bqProcessor = new SelectSQLBuilder();

bqProcessor.setSelect("select i.item_id, i.name as item_name, st.itemstatus as item_status, s.name as site_name, v.name as vendor, MIN(CAST(sh.date_record_added as DATE)) as launch_date ");
bqProcessor.setFrom("from ecommerce.item as i, ecommerce.site as s, ecommerce.itemstatus as st, ecommerce.vendor as v, ecommerce.source_product_status_history as sh ");
bqProcessor.setWhere("where i.item_id = sh.source_id and i.itemstatus_id = st.itemstatus_id and i.primary_site_id = s.site_id and i.vendor_id = v.vendor_id and sh.sourceclass_id = 5 and sh.previous_itemstatus_id IN (2, 3, 4) and sh.new_itemstatus_id = 0 and i.itemstatus_id IN (0, 1, 5) ");
bqProcessor.setGroupBy("GROUP BY item_id, item_name, item_status, site_name, vendor ");

if (notEmpty(startDate)) {
    bqProcessor.appendWhere("sh.date_record_added >= '" + startDate + "'"); 
}

if (notEmpty(endDate)) {
    bqProcessor.appendWhere("sh.date_record_added < '" + endDate + "'"); 
}

if (notEmpty(vendor)) {
    bqProcessor.appendWhere("v.vendor_id = '" + vendor + "'");
}

if (notEmpty(disallow_nfr)) {
    bqProcessor.appendWhere("i.itembitmask & 256 != 256 ");
}

if (notEmpty(disallow_fp)) {
    bqProcessor.appendWhere("i.name NOT LIKE 'FP - %' ");
}

var mainProcessor = new SelectSQLBuilder();

mainProcessor.setSelect("select item_id, item_name, item_status, site_name, vendor, min(launch_date) as launch_date ");
mainProcessor.appendRelationToFromWithAlias(bqProcessor, "bq");
mainProcessor.setGroupBy("group by item_id, item_name, item_status, site_name, vendor ");

var pvProcessor = new SelectSQLBuilder();

pvProcessor.setSelect("select distinct i.item_id, i.name, st.itemstatus as item_status, s.name as site_name, v.name as vendor, MIN(CAST(pv.initiallaunchdate as DATE)) as launch_date ");
pvProcessor.setFrom("from ecommerce.item as i, ecommerce.itemstatus as st, ecommerce.productversion as pv, ecommerce.site as s, ecommerce.vendor as v ");
pvProcessor.setWhere("where i.item_id = pv.item_id and i.itemstatus_id = st.itemstatus_id and i.primary_site_id = s.site_id and i.vendor_id = v.vendor_id and i.itemstatus_id IN (0, 1, 5) ");

if (notEmpty(startDate)) {
    pvProcessor.appendWhere("pv.initiallaunchdate >= '" + startDate + "'"); 
}

if (notEmpty(endDate)) {
    pvProcessor.appendWhere("pv.initiallaunchdate < '" + endDate + "'"); 
}

if (notEmpty(vendor)) {
    pvProcessor.appendWhere("v.vendor_id = '" + vendor + "'");
}

if (notEmpty(disallow_nfr)) {
    pvProcessor.appendWhere("i.itembitmask & 256 != 256 ");
}

if (notEmpty(disallow_fp)) {
    pvProcessor.appendWhere("i.name NOT LIKE 'FP - %' ");
}

pvProcessor.setGroupBy("group by i.item_id, i.name, st.itemstatus, s.name, v.name, pv.initiallaunchdate ");

var mainSet = mainProcessor.queryString();
var pvSet = pvProcessor.queryString();

var sql = "WITH Q as (SELECT DISTINCT * FROM ( " + mainSet;
sql += " UNION " + pvSet;
sql += " ) zzzz ) SELECT q.item_id, q.item_name, q.item_status, q.site_name, q.vendor, MIN(q.launch_date) as launch_date FROM Q where q.item_id = q.item_id ";

sql += " and q.item_id NOT IN (select i.item_id from ecommerce.source_product_status_history as sh, ecommerce.item as i, ecommerce.itemstatus as st where i.item_id = sh.source_id and i.itemstatus_id = st.itemstatus_id and sh.sourceclass_id = 5 and sh.previous_itemstatus_id IN (2, 3, 4) and sh.new_itemstatus_id = 0 and i.itemstatus_id IN (0, 1) ";

if (notEmpty(startDate)) {
    sql += "and sh.date_record_added < '" + startDate + "'";
}

if (notEmpty(vendor)) {
    sql += "and i.vendor_id = '" + vendor + "'";
}

if (notEmpty(disallow_nfr)) {
    sql += "and i.itembitmask & 256 != 256 ";
}

if (notEmpty(disallow_fp)) {
    sql += "and i.name NOT LIKE 'FP - %' ";
}

sql += ") and q.item_id NOT IN (select i.item_id from ecommerce.item as i, ecommerce.itemstatus as st, ecommerce.productversion as pv where i.item_id = pv.item_id and i.itemstatus_id = st.itemstatus_id and i.itemstatus_id IN (0, 1) ";

if (notEmpty(startDate)) {
    sql += "and pv.initiallaunchdate < '" + startDate + "'";
}

if (notEmpty(vendor)) {
    sql += "and i.vendor_id = '" + vendor + "'";
}

if (notEmpty(disallow_nfr)) {
    sql += "and i.itembitmask & 256 != 256 ";
}

if (notEmpty(disallow_fp)) {
    sql += "and i.name NOT LIKE 'FP - %' ";
}

sql += ") ";

if (notEmpty(startDate)) {
    sql += "and q.launch_date >= '" + startDate + "'"; 
}

if (notEmpty(endDate)) {
    sql += "and q.launch_date < '" + endDate + "'"; 
}

sql += " GROUP BY q.item_id, q.item_name, q.item_status, q.site_name, q.vendor, q.launch_date ";
sql += " ORDER BY q.launch_date ASC ";