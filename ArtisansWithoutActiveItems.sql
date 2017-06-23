//
// Artisans Without Active Items
// Catherine Warren, 2015-09-08
// Revised 2015-10-06 to add full country name
//

var sqlProcessor = new SelectSQLBuilder();

sqlProcessor.setSelect("select distinct a.artisan_id, a.artisanname as artisan_name, c.countryname as country ");
sqlProcessor.setFrom("from ecommerce.artisan as a, ecommerce.item as i, ecommerce.countrycode as c ");
sqlProcessor.setWhere("where a.artisan_id = i.artisan_id and a.isocountrycodeoforigin = c.isocountrycode and a.artisan_id NOT IN (select a.artisan_id from ecommerce.artisan as a, ecommerce.item as i where a.artisan_id = i.artisan_id and i.itemstatus_id = 0) ");

sqlProcessor.setOrderBy("order by a.artisan_id asc ");

sql = sqlProcessor.queryString();