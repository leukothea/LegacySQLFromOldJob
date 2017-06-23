//
// Artisans by Country of Origin
// Catherine Warren, 2015-09-02
// Revised to add the full country name, 2015-10-06
// Revised to add a checkbox for Novica identity, 2015-10-15
// Revised to change the checkbox to a dropdown, 2015-10-16
//

var continent = p["continent"];
var countryCode = p["countryOfOrigin3"];
var artisan_id = p["artisan_id"];
var artisan_name = p["artisan_name"];
var novica_ID_or_not = p["novica_ID_or_not"];

var sqlProcessor = new SelectSQLBuilder();

sqlProcessor.setSelect("select c.countryname as country, a.artisan_id, a.artisanname as artisan_name, a.display_name as artisan_display_name, a.imageurl as artisan_url ");
sqlProcessor.setFrom("from ecommerce.artisan as a, ecommerce.countrycode as c ");
sqlProcessor.setWhere("where a.isocountrycodeoforigin = c.isocountrycode ");

if (notEmpty (continent)) {
  sqlProcessor.appendWhere ("a.isocountrycodeoforigin IN ( " + continent + ")" );
}

if (notEmpty (countryCode)) {
  sqlProcessor.appendWhere ("a.isocountrycodeoforigin ILIKE ( '%" + countryCode + "%')" );
}

//else {
//	hide.push("country");
//}

if (notEmpty(artisan_id)) {
    sqlProcessor.appendWhere("a.artisan_id = " + artisan_id);
    }

if (notEmpty (artisan_name)) {
    sqlProcessor.appendWhere ("a.artisanname ILIKE ( '%" + artisan_name  + "%')" );
    }

if ("NovicaRecords".equals(novica_ID_or_not)) { 
    sqlProcessor.appendSelect("na.novica_id as novica_artisan_id ");
    sqlProcessor.appendFrom("ecommerce.novica_identity as na ");
    sqlProcessor.appendWhere("na.source_id = a.artisan_id and na.sourceclass_id = 19 ");
} else if ("CharityUSARecords".equals(novica_ID_or_not)) { 
    sqlProcessor.appendWhere("a.artisan_id NOT IN (select na.source_id from ecommerce.novica_identity as na, ecommerce.artisan as a where na.source_id = a.artisan_id and na.sourceclass_id = 19) ");
    hide.push('novica_artisan_id');
} else if ("AllRecords".equals(novica_ID_or_not)) {
    hide.push('novica_artisan_id');
}

sqlProcessor.setOrderBy("order by a.artisanname ");

sql = sqlProcessor.queryString();