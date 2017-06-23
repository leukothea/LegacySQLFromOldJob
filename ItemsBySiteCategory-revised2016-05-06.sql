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
catProcessor.appendWhere("c.active = TRUE ");
catProcessor.setGroupBy("group by i.item_id, c.category_id, c.name ");
catProcessor.setOrderBy("order by i.item_id asc ")

if (notEmpty(category_id)) {
  catProcessor.appendWhere("c.category_id IN (" + category_id + ")");
} 

if (notEmpty(category_name)) {
  catProcessor.appendWhere("c.name ILIKE '" + category_name + "'");
}

if (notEmpty(site)) {
  catProcessor.appendFrom("ecommerce.site as s, ecommerce.sitecategory as sc ");
  catProcessor.appendWhere("c.category_id = sc.category_id and sc.site_id = s.site_id ");
  catProcessor.appendWhere("sc.site_id = " + site);
}


var saleCatProcessor = new SelectSQLBuilder();

saleCatProcessor.setSelect("select i.item_id, c.category_id, c.name as category_name ");
saleCatProcessor.setFrom("from ecommerce.item as i, ecommerce.promotion_item_category as pic, ecommerce.promotion as p, ecommerce.category as c ");
saleCatProcessor.setWhere("where i.item_id = pic.item_id and pic.category_id = c.category_id and pic.promotion_id = p.promotion_id ");
saleCatProcessor.appendWhere("p.active = true and c.active = true ");
saleCatProcessor.appendWhere("p.startdate < now()" );
saleCatProcessor.appendWhere("((p.enddate IS NULL) OR (p.enddate > now()))");
saleCatProcessor.setGroupBy("group by i.item_id, c.category_id, c.name ");
saleCatProcessor.setOrderBy("order by i.item_id asc ")

if (notEmpty(category_id)) {
  saleCatProcessor.appendWhere("pic.category_id IN (" + category_id + ")");
}

if (notEmpty(category_name)) {
  saleCatProcessor.appendWhere("c.name ILIKE '" + category_name + "'");
} 

if (notEmpty(site)) {
  saleCatProcessor.appendFrom("ecommerce.site as s, ecommerce.sitecategory as sc ");
  saleCatProcessor.appendWhere("c.category_id = sc.category_id and sc.site_id = s.site_id ");
  saleCatProcessor.appendWhere("sc.site_id = " + site);
}

var sqlProcessor = new SelectSQLBuilder();

sqlProcessor.setSelect("select distinct i.item_id, i.name AS item_name, ist.itemstatus as item_status ");
sqlProcessor.setFrom("from ecommerce.item as i, ecommerce.itemstatus as ist ");
sqlProcessor.setWhere("where i.itemstatus_id = ist.itemstatus_id ");
sqlProcessor.setGroupBy("group by i.item_id, i.name, ist.itemstatus ");

if (notEmpty(site)) {
  sqlProcessor.addCommonTableExpression("bit", bitProcessor);
  if (site == 354 || site == 355 || site == 2005) {
      sqlProcessor.appendFrom("ecommerce.site as s LEFT OUTER JOIN bit ON s.site_id = bit.site_id ");
      sqlProcessor.appendWhere("i.site_availability_mask & bit.bit_value = bit.bit_value ");
      count.push('item_id');
      hide.push('category_id');
      hide.push('category_name');

      if (notEmpty(show_sale_categories)) {
      // do nothing; this box has no effect on these sites
      }

      if (notEmpty(category_id)) {
      // do nothing; this input has no effect on these sites
      }

      if (notEmpty(category_name)) {
      // do nothing; this input has no effect on these sites 
      }

      if (notEmpty(item_status)) {
        sqlProcessor.appendWhere("i.itemstatus_id IN (" + item_status + ") ");
      }

      } else if (site > 0) {  
          sqlProcessor.appendFrom("ecommerce.site as s LEFT OUTER JOIN bit ON s.site_id = bit.site_id ");
          sqlProcessor.appendWhere("s.site_id = " + site);
          sqlProcessor.appendWhere("i.site_availability_mask & bit.bit_value = bit.bit_value ");

            if (notEmpty(item_status)) {
              sqlProcessor.appendWhere("i.itemstatus_id IN (" + item_status + ") ");
            }

          if (notEmpty(show_sale_categories) || notEmpty(category_id) || notEmpty(category_name)) {
            count.push('category_id');


          if (notEmpty(show_sale_categories)) {
            sqlProcessor.appendSelect("saleCat.category_id, saleCat.category_name ");
            sqlProcessor.appendFrom("ecommerce.item as im RIGHT JOIN saleCat ON im.item_id = saleCat.item_id ");
            sqlProcessor.addCommonTableExpression("saleCat",saleCatProcessor);
            sqlProcessor.appendWhere("im.item_id = i.item_id ");
            sqlProcessor.appendGroupBy("saleCat.category_id, saleCat.category_name ");
            
          } else if (notEmpty(category_id) || notEmpty(category_name)) {      
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
          }
          } else {
          hide.push('category_id');
          hide.push('category_name');
          }
        } else { 
            count.push('item_id');

            if (notEmpty(item_status)) {
              sqlProcessor.appendWhere("i.itemstatus_id IN (" + item_status + ") ");
            }

            if (notEmpty(show_sale_categories) || notEmpty(category_id) || notEmpty(category_name)) {
            count.push('category_id');


          if (notEmpty(show_sale_categories)) {
            sqlProcessor.appendSelect("saleCat.category_id, saleCat.category_name ");
            sqlProcessor.appendFrom("ecommerce.item as im RIGHT JOIN saleCat ON im.item_id = saleCat.item_id ");
            sqlProcessor.addCommonTableExpression("saleCat",saleCatProcessor);
            sqlProcessor.appendWhere("im.item_id = i.item_id ");
            sqlProcessor.appendGroupBy("saleCat.category_id, saleCat.category_name ");
            
          } else if (notEmpty(category_id) || notEmpty(category_name)) {      
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
          }
          } else {
          hide.push('category_id');
          hide.push('category_name');
          }
}  
}
            
sql = sqlProcessor.queryString();