//
// Items by Site / Category
// Catherine Warren, 2016-01-18
// Edited Catherine Warren, 2016-05-03 | JIRA RPT-340, 342
// Edited Catherine Warren, 2016-05-05 | JIRA RPT-358
//

var site = p["site4"];
var category_id = p["category_id"];
var category_name = p["category_name"];
var show_sale_categories = p["show_sale_categories"];
var item_status = p["item_status"];

var bitProcessor = new SelectSQLBuilder();

bitProcessor.setSelect("select bit_value, site_id ");
bitProcessor.setFrom("from ecommerce.site ");
bitProcessor.setWhere("where active = true ");

if (notEmpty(site)) {
    bitProcessor.appendWhere("site_id = " + site);
}

var catProcessor = new SelectSQLBuilder();

catProcessor.setSelect("select i.item_id, c.category_id, c.name as category_name ");
catProcessor.setFrom("from ecommerce.item as i, ecommerce.category_item as ci, ecommerce.category as c ");
catProcessor.setWhere("where i.item_id = ci.item_id and ci.category_id = c.category_id ");
catProcessor.setGroupBy("group by i.item_id, c.category_id, c.name ");
catProcessor.setOrderBy("order by i.item_id asc ")

var sqlProcessor = new SelectSQLBuilder();

sqlProcessor.setSelect("select distinct i.item_id, i.name AS item_name, ist.itemstatus as item_status ");
sqlProcessor.setFrom("from ecommerce.item as i, ecommerce.itemstatus as ist ");
sqlProcessor.setWhere("where i.itemstatus_id = ist.itemstatus_id ");
sqlProcessor.setGroupBy("group by i.item_id, i.name, ist.itemstatus ");

if (notEmpty(show_sale_categories)) {
  	count.push('category_id');
    sqlProcessor.appendSelect("c.category_id, c.name as category_name");
    sqlProcessor.appendFrom("ecommerce.promotion_item_category as pic, ecommerce.promotion as p, ecommerce.category as c ");
    sqlProcessor.appendWhere("i.item_id = pic.item_id and pic.category_id = c.category_id and pic.promotion_id = p.promotion_id ");
    sqlProcessor.appendWhere("p.active = true ");
    sqlProcessor.appendGroupBy("c.category_id, c.name ");

    if (notEmpty(site)) {
      sqlProcessor.addCommonTableExpression("bit", bitProcessor);
      if (site == 354 || site == 355 || site == 2005) {
          sqlProcessor.appendFrom("ecommerce.site as s LEFT OUTER JOIN bit ON s.site_id = bit.site_id ");
          sqlProcessor.appendWhere("i.site_availability_mask & bit.bit_value = bit.bit_value ");
          hide.push('category_id');
          hide.push('category_name');
      } else {
          sqlProcessor.appendFrom("ecommerce.site as s LEFT OUTER JOIN bit ON s.site_id = bit.site_id ");
      	  sqlProcessor.appendWhere("s.site_id = " + site);
      	  sqlProcessor.appendWhere("i.site_availability_mask & bit.bit_value = bit.bit_value ");
      }
    }
  
      if (notEmpty(category_id) || notEmpty(category_name)) {      
    	sqlProcessor.appendSelect("c.category_id, c.name as category_name");
    	sqlProcessor.appendFrom("ecommerce.category_item as ci ");
    	sqlProcessor.appendWhere("i.item_id = ci.item_id and ci.category_id = c.category_id ");
    	sqlProcessor.appendGroupBy("c.category_id, c.name ");
		if (notEmpty(category_id)) {
      		sqlProcessor.appendWhere("pic.category_id IN (" + category_id + ")");
        } 
      	if (notEmpty(category_name)) {
          	sqlProcessor.appendWhere("c.name ILIKE '" + category_name + "'");
        } 
      } else {
        hide.push('category_id');
  		hide.push('category_name');
    }
 
    if (notEmpty(item_status)) {
      sqlProcessor.appendWhere("i.itemstatus_id IN (" + item_status + ") ");
    }

} else {
 
	if (notEmpty(site)) {
      sqlProcessor.addCommonTableExpression("bit", bitProcessor);
      	if (site == 354 || site == 355 || site == 2005) {
		  sqlProcessor.appendFrom("ecommerce.site as s LEFT OUTER JOIN bit ON s.site_id = bit.site_id ");
          sqlProcessor.appendWhere("i.site_availability_mask & bit.bit_value = bit.bit_value ");
          hide.push('category_id');
          hide.push('category_name');
        } else {
          	sqlProcessor.appendFrom("ecommerce.site as s LEFT OUTER JOIN bit ON s.site_id = bit.site_id ");
      		sqlProcessor.appendWhere("s.site_id = " + site);
      		sqlProcessor.appendWhere("i.site_availability_mask & bit.bit_value = bit.bit_value ");
        }
    }
     
    if (notEmpty(category_id) || notEmpty(category_name)) {      
    	count.push('category_id');
        sqlProcessor.appendSelect("cat.category_id, cat.category_name");
    	sqlProcessor.appendFrom("ecommerce.item as ie LEFT OUTER JOIN cat ON ie.item_id = cat.item_id ");
      	sqlProcessor.addCommonTableExpression("cat",catProcessor);
    	sqlProcessor.appendWhere("i.item_id = ie.item_id  ");
    	sqlProcessor.appendGroupBy("cat.category_id, cat.category_name ");
		if (notEmpty(category_id)) {
      		sqlProcessor.appendWhere("cat.category_id IN (" + category_id + ")");
        } 
      	if (notEmpty(category_name)) {
          sqlProcessor.appendWhere("cat.category_name ILIKE '" + category_name + "'");
        }
    } else {
        	count.push('item_id');
      		hide.push('category_id');
  			hide.push('category_name');
	}

    if (notEmpty(item_status)) {
      sqlProcessor.appendWhere("i.itemstatus_id IN (" + item_status + ") ");
    }
}

sql = sqlProcessor.queryString();