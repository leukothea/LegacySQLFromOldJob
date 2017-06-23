// Gross Sales Summary report
// Includes the full list of all versions, including old retired versions.
//
// Edited Catherine Warren, 2016-04-01 | JIRA RPT-99 & 242
// Edited Catherine Warren, 2016-07-07 | JIRA RPT-412
// Edited Catherine Warren, 2016-08-31 to 09-12 | JIRA RPT-457
// Edited Catherine Warren, 2016-09-14 | JIRA RPT-467
// Edited Catherine Warren, 2017-01-04 | JIRA RPT-513
// Edited Catherine Warren, 2017-01-11 | JIRA RPT-457


WITH versionskuquantity AS 
( 
       SELECT pvs.productversion_id AS versionid, 
              pvs.sku_id            AS skuid, 
              pvs.quantity 
       FROM   ecommerce.productversionsku AS pvs 
       WHERE  true ) , versiondata AS ( WITH versiondetails AS 
( 
       SELECT v.productversion_id      AS versionid, 
              v.item_id                AS versionfamilyid, 
              v.itemstatus_id          AS versionstatusid, 
              v.NAME                   AS versionname, 
              ist.itemstatus           AS versionstatus, 
              i.NAME                   AS versionfamilyname 
       FROM   ecommerce.productversion AS v, 
              ecommerce.itemstatus     AS ist, 
              ecommerce.item           AS i 
       WHERE  v.itemstatus_id = ist.itemstatus_id 
       AND    v.item_id = i.item_id ) , versionsales AS 
( 
         SELECT   rsli.productversion_id                     AS versionid, 
                  Extract( 'year' FROM rsli.fulfillmentdate) AS year, 
                  Sum(rsli.quantity)                         AS units, 
                  Sum(rsli.customerprice * rsli.quantity)    AS revenue 
         FROM     ecommerce.rslineitem                       AS rsli, 
                  ecommerce.rsorder                          AS o 
         WHERE    o.oid = rsli.order_id 
         AND      rsli.fulfillmentdate >= '2016-01-01' 
         AND      COALESCE(rsli.lineitemtype_id,1) IN (1,5) 
         AND      rsli.productversion_id IS NOT NULL 
         GROUP BY rsli.productversion_id, 
                  Extract( 'year' FROM rsli.fulfillmentdate) 
         ORDER BY Extract( 'year' FROM rsli.fulfillmentdate) DESC ) , vac AS ( WITH tempnext AS 
( 
         SELECT   ii.sku_id, ( 
                  CASE 
                           WHEN ( 
                                             ii.quantity = 0 
                                    OR       ii.merchantprice = 0) THEN Max(ii.merchantprice) 
                           WHEN ( 
                                             ii.quantity > 0 
                                    AND      ii.merchantprice > 0) THEN Sum(ii.quantity * ii.merchantprice) / Sum(ii.quantity)
                           ELSE NULL 
                  END)                      AS cost 
         FROM     ecommerce.rsinventoryitem AS ii 
         WHERE    ii.quantity > 0 
         AND      ii.merchantprice > 0 
         AND      ii.active = true 
         AND      ii.sku_id IS NOT NULL 
         GROUP BY ii.sku_id, 
                  ii.quantity, 
                  ii.merchantprice ) 
SELECT          pvs.productversion_id             AS versionid, 
                Sum(pvs.quantity * tempnext.cost) AS cost 
FROM            ecommerce.productversionsku       AS pvs 
LEFT OUTER JOIN tempnext                          AS tempnext 
ON              tempnext.sku_id = pvs.sku_id 
WHERE           true 
GROUP BY        pvs.productversion_id ) , vap AS 
( 
         SELECT   rsli.productversion_id                                     AS versionid, 
                  Sum(rsli.customerprice/rsli.quantity) / Sum(rsli.quantity) AS price 
         FROM     ecommerce.rslineitem                                       AS rsli 
         WHERE    rsli.fulfillmentdate IS NOT NULL 
         AND      rsli.fulfillmentdate > '2016-01-01' 
         AND      rsli.quantity > 0 
         GROUP BY rsli.productversion_id ) , vcp AS 
( 
                SELECT DISTINCT pv.productversion_id                        AS versionid, 
                                COALESCE(p1.customerprice,p2.customerprice) AS price, 
                                p1.active 
                FROM            ecommerce.productversion AS pv 
                LEFT OUTER JOIN ecommerce.price          AS p1 
                ON              pv.productversion_id = p1.source_id 
                AND             p1.sourceclass_id = 9 
                AND             p1.pricetype_id = 1 
                AND             ( 
                                                p1.active = true 
                                OR              p1.active IS NULL) 
                LEFT OUTER JOIN ecommerce.price AS p2 
                ON              pv.item_id = p2.source_id 
                AND             p2.sourceclass_id = 5 
                AND             p2.pricetype_id = 1 
                AND             ( 
                                                p2.active = true 
                                OR              p2.active IS NULL) 
                WHERE           true ) , vsppp AS 
( 
       SELECT pv.productversion_id              AS versionid, 
              COALESCE(pr1.customerprice, 0.00) AS recommended_sale_price, 
              COALESCE(pr2.customerprice, 0.00) AS recommended_pop_pick_price 
       FROM   ecommerce.productversion          AS pv, 
              ecommerce.item                    AS i, 
              ecommerce.price                   AS pr1, 
              ecommerce.price                   AS pr2 
       WHERE  pv.item_id = i.item_id 
       AND    i.item_id = pr1.source_id 
       AND    pr1.sourceclass_id = 5 
       AND    pr1.pricetype_id = 5 
       AND    i.item_id = pr2.source_id 
       AND    pr2.sourceclass_id = 5 
       AND    pr2.pricetype_id = 6 ) , vfds AS 
( 
         SELECT   rsli.productversion_id                             AS versionid, 
                  Min(To_char(rsli.fulfillmentdate,'yyyymmdd')::int) AS firstdatesold 
         FROM     ecommerce.rslineitem                               AS rsli 
         WHERE    rsli.lineitemtype_id = 1 
         AND      rsli.fulfillmentdate IS NOT NULL 
         GROUP BY rsli.productversion_id ) , last14 AS 
( 
         SELECT   rsli.productversion_id                  AS versionid, 
                  Sum(rsli.customerprice * rsli.quantity) AS revenue, 
                  Sum(rsli.quantity)                      AS units 
         FROM     ecommerce.rslineitem                    AS rsli, 
                  ecommerce.rsorder                       AS o 
         WHERE    COALESCE(rsli.lineitemtype_id,1) IN (1,5) 
         AND      o.oid = rsli.order_id 
         AND      rsli.fulfillmentdate >= Now() - interval '14 days' 
         GROUP BY rsli.productversion_id ) , last30 AS 
( 
         SELECT   rsli.productversion_id                  AS versionid, 
                  sum(rsli.customerprice * rsli.quantity) AS revenue, 
                  sum(rsli.quantity)                      AS units 
         FROM     ecommerce.rslineitem                    AS rsli, 
                  ecommerce.rsorder                       AS o 
         WHERE    COALESCE(rsli.lineitemtype_id,1) IN (1,5) 
         AND      o.oid = rsli.order_id 
         AND      rsli.fulfillmentdate >= now() - interval '30 days' 
         GROUP BY rsli.productversion_id ) , last90 AS 
( 
         SELECT   rsli.productversion_id                  AS versionid, 
                  sum(rsli.customerprice * rsli.quantity) AS revenue, 
                  sum(rsli.quantity)                      AS units 
         FROM     ecommerce.rslineitem                    AS rsli, 
                  ecommerce.rsorder                       AS o 
         WHERE    COALESCE(rsli.lineitemtype_id,1) IN (1,5) 
         AND      o.oid = rsli.order_id 
         AND      rsli.fulfillmentdate >= now() - interval '90 days' 
         GROUP BY rsli.productversion_id ) , last180 AS 
( 
         SELECT   rsli.productversion_id                  AS versionid, 
                  sum(rsli.customerprice * rsli.quantity) AS revenue, 
                  sum(rsli.quantity)                      AS units 
         FROM     ecommerce.rslineitem                    AS rsli, 
                  ecommerce.rsorder                       AS o 
         WHERE    COALESCE(rsli.lineitemtype_id,1) IN (1,5) 
         AND      o.oid = rsli.order_id 
         AND      rsli.fulfillmentdate >= now() - interval '180 days' 
         GROUP BY rsli.productversion_id ) , last365 AS 
( 
         SELECT   rsli.productversion_id                  AS versionid, 
                  sum(rsli.customerprice * rsli.quantity) AS revenue, 
                  sum(rsli.quantity)                      AS units 
         FROM     ecommerce.rslineitem                    AS rsli, 
                  ecommerce.rsorder                       AS o 
         WHERE    COALESCE(rsli.lineitemtype_id,1) IN (1,5) 
         AND      o.oid = rsli.order_id 
         AND      rsli.fulfillmentdate >= now() - interval '365 days' 
         GROUP BY rsli.productversion_id ) 
SELECT          versiondetails.versionid, 
                versiondetails.versionfamilyid, 
                ist.itemstatus AS versionfamilystatus, 
                versiondetails.versionfamilyname, 
                versiondetails.versionstatusid, 
                versiondetails.versionstatus, 
                versiondetails.versionname , 
                versionsales.units   AS units2017, 
                versionsales.revenue AS rev2017 , 
                vac.cost             AS versionaveragecost, 
                vap.price            AS versionaverageprice, 
                vcp.price            AS currentprice, 
                vsppp.recommended_sale_price, 
                vsppp.recommended_pop_pick_price , 
                vfds.firstdatesold, 
                last14.units             AS last14units, 
                last14.revenue           AS last14rev, 
                last30.units             AS last30units, 
                last30.revenue           AS last30rev , 
                last90.units             AS last90units, 
                last90.revenue           AS last90rev, 
                last180.units            AS last180units, 
                last180.revenue          AS last180rev, 
                last365.units            AS last365units, 
                last365.revenue          AS last365rev 
FROM            ecommerce.productversion AS pv 
LEFT OUTER JOIN versiondetails           AS versiondetails 
ON              pv.productversion_id = versiondetails.versionid 
LEFT OUTER JOIN versionsales AS versionsales 
ON              pv.productversion_id::integer = versionsales.versionid::integer 
AND             versionsales.year::   varchar = '2017' 
LEFT OUTER JOIN vac AS vac 
ON              pv.productversion_id::integer = vac.versionid::integer 
LEFT OUTER JOIN vap AS vap 
ON              pv.productversion_id::integer = vap.versionid::integer 
LEFT OUTER JOIN vcp AS vcp 
ON              pv.productversion_id::integer = vcp.versionid::integer 
LEFT OUTER JOIN vsppp AS vsppp 
ON              pv.productversion_id::integer = vsppp.versionid::integer 
LEFT OUTER JOIN vfds AS vfds 
ON              pv.productversion_id::integer = vfds.versionid::integer 
LEFT OUTER JOIN last14 AS last14 
ON              pv.productversion_id::integer = last14.versionid::integer 
LEFT OUTER JOIN last30 AS last30 
ON              pv.productversion_id::integer = last30.versionid::integer 
LEFT OUTER JOIN last90 AS last90 
ON              pv.productversion_id::integer = last90.versionid::integer 
LEFT OUTER JOIN last180 AS last180 
ON              pv.productversion_id::integer = last180.versionid::integer 
LEFT OUTER JOIN last365 AS last365 
ON              pv.productversion_id::integer = last365.versionid::integer , 
                ecommerce.item       AS i, 
                ecommerce.itemstatus AS ist 
WHERE           i.item_id = pv.item_id 
AND             versiondetails.versionfamilyid = i.item_id 
AND             i.itemstatus_id = ist.itemstatus_id 
ORDER BY        versiondetails.versionid ASC ) , skumain AS ( WITH skucalc AS ( WITH skuprice AS 
( 
         SELECT   pr.source_id          AS sku_id, 
                  min(pr.customerprice) AS price 
         FROM     ecommerce.price       AS pr 
         WHERE    pr.pricetype_id = 1 
         AND      pr.sourceclass_id = 13 
         AND      pr.customerprice > 0 
         GROUP BY pr.source_id ) , skuac AS 
( 
         SELECT   ii.sku_id, 
                  sum(ii.quantity * ii.merchantprice) / sum(ii.quantity) AS cost 
         FROM     ecommerce.rsinventoryitem                              AS ii 
         WHERE    ii.quantity > 0 
         AND      ii.merchantprice > 0 
         AND      ii.sku_id IS NOT NULL 
         GROUP BY ii.sku_id ) , skuccost AS ( WITH tempskudra AS 
( 
         SELECT   s.sku_id, 
                  max(ii.daterecordadded)     AS dra 
         FROM     ecommerce.sku               AS s, 
                  ecommerce.rsinventoryitem   AS ii, 
                  ecommerce.productversionsku AS pvs 
         WHERE    s.sku_id = ii.sku_id 
         AND      s.sku_id = pvs.sku_id 
         AND      s.skubitmask & 1 = 1 
         AND      ii.merchantprice > 0 
         GROUP BY s.sku_id ) 
SELECT          s.sku_id, 
                max(ii.merchantprice) AS price 
FROM            ecommerce.sku         AS s 
LEFT OUTER JOIN tempskudra            AS tempskudra 
ON              s.sku_id = tempskudra.sku_id, 
                ecommerce.rsinventoryitem   AS ii, 
                ecommerce.productversionsku AS pvs 
WHERE           s.sku_id = ii.sku_id 
AND             s.sku_id = pvs.sku_id 
AND             s.skubitmask & 1 = 1 
AND             tempskudra.sku_id = ii.sku_id 
AND             tempskudra.dra::date = ii.daterecordadded::date 
AND             ii.merchantprice > 0 
GROUP BY        s.sku_id ) , skuinitcost AS ( WITH dra AS 
( 
         SELECT   s.sku_id, 
                  min(ii.daterecordadded)     AS dra 
         FROM     ecommerce.sku               AS s, 
                  ecommerce.rsinventoryitem   AS ii, 
                  ecommerce.productversionsku AS pvs 
         WHERE    s.sku_id = ii.sku_id 
         AND      s.sku_id = pvs.sku_id 
         AND      s.skubitmask & 1 = 1 
         AND      ii.merchantprice > 0 
         GROUP BY s.sku_id ) 
SELECT          s.sku_id, 
                max(ii.merchantprice) AS cost 
FROM            ecommerce.sku         AS s 
LEFT OUTER JOIN dra                   AS dra 
ON              s.sku_id = dra.sku_id, 
                ecommerce.rsinventoryitem   AS ii, 
                ecommerce.productversionsku AS pvs 
WHERE           s.sku_id = ii.sku_id 
AND             s.sku_id = pvs.sku_id 
AND             s.skubitmask & 1 = 1 
AND             dra.dra::date = ii.daterecordadded::date 
AND             ii.merchantprice > 0 
GROUP BY        s.sku_id ) 
SELECT          s.sku_id , 
                COALESCE(max(rcvd.receiveddate::date), s.initiallaunchdate::date, s.daterecordadded::date)                                                       AS skureorderdate ,
                (abs(extract(day FROM COALESCE(max(rcvd.receiveddate), max(ii.daterecordadded), max(s.daterecordadded), max(s.initiallaunchdate)) - now())))/365 AS skureorderage ,
                (COALESCE(skuprice.price,0.00))                                                                                                                  AS skuprice ,
                (COALESCE(skuac.cost,0.00))                                                                                                                      AS skuaveragecost ,
                (COALESCE(skuinitcost.cost,0.00))                                                                                                                AS skuinitialcost ,
                (COALESCE(skuccost.price,0.00))                                                                                                                  AS skucurrentcost
FROM            ecommerce.sku                                                                                                                                    AS s
LEFT OUTER JOIN skuccost 
ON              s.sku_id = skuccost.sku_id 
LEFT OUTER JOIN skuinitcost 
ON              s.sku_id = skuinitcost.sku_id 
LEFT OUTER JOIN skuac 
ON              s.sku_id = skuac.sku_id 
LEFT OUTER JOIN skuprice 
ON              s.sku_id = skuprice.sku_id , 
                ecommerce.rsinventoryitem AS ii, 
                ecommerce.receivingevent  AS rcvd 
WHERE           ii.sku_id = s.sku_id 
AND             ii.receivingevent_id = rcvd.receivingevent_id 
GROUP BY        s.sku_id, 
                skuccost.price, 
                skuinitcost.cost, 
                skuac.cost, 
                skuprice.price ) , skudata AS 
( 
         SELECT   s.sku_id                                  AS skuid, 
                  sum(ii.quantity)                          AS skuquantity, 
                  min(ii.merchantprice)                     AS skulowerofcost, 
                  max(COALESCE(ii.weight,0.0))              AS skuweight, 
                  max(ii.oid)                               AS mostrecentinventoryitem , 
                  string_agg(DISTINCT sup.suppliername,'|') AS all_suppliers 
         FROM     ecommerce.sku                             AS s, 
                  ecommerce.rsinventoryitem                 AS ii, 
                  ecommerce.supplier                        AS sup 
         WHERE    s.sku_id = ii.sku_id 
         AND      ii.active = true 
         AND      s.skubitmask & 1 = 1 
         AND      ii.supplier_id = sup.supplier_id 
         GROUP BY s.sku_id ) , skudetails AS 
( 
                SELECT          sku.item_id     AS skufamilyid, 
                                i.NAME          AS skufamilyname, 
                                i.itemstatus_id AS skufamilystatusid, 
                                istb.itemstatus AS skufamilystatus , 
                                v.NAME          AS skufamilyvendor, 
                                sku.sku_id      AS skuid, 
                                ist.itemstatus  AS skustatus , 
                                CASE 
                                                WHEN sku.skubitmask & 1 = 1 THEN 1 
                                                ELSE 0 
                                END                        AS tracksinventory , 
                                sku.NAME                   AS skuname, 
                                sku.partnumber             AS partnumber, 
                                sku.isocountrycodeoforigin AS countrycode, 
                                ist.itemstatus, 
                                skucat.buyer AS skubuyer , 
                                skucat.skucategory1, 
                                skucat.skucategory2, 
                                skucat.skucategory3, 
                                skucat.skucategory4, 
                                skucat.skucategory5, 
                                skucat.skucategory6 
                FROM            ecommerce.sku         AS sku 
                LEFT OUTER JOIN ecommerce.skucategory AS skucat 
                ON              skucat.sku_id = sku.sku_id, 
                                ecommerce.itemstatus AS ist , 
                                ecommerce.item       AS i, 
                                ecommerce.itemstatus AS istb, 
                                ecommerce.vendor     AS v 
                WHERE           sku.itemstatus_id = ist.itemstatus_id 
                AND             sku.item_id = i.item_id 
                AND             i.itemstatus_id = istb.itemstatus_id 
                AND             v.vendor_id = i.vendor_id 
                ORDER BY        sku.item_id, 
                                sku.sku_id ) , mostrecentsupplier AS ( WITH skudata AS 
( 
         SELECT   s.sku_id                                  AS skuid, 
                  sum(ii.quantity)                          AS skuquantity, 
                  min(ii.merchantprice)                     AS skulowerofcost, 
                  max(COALESCE(ii.weight,0.0))              AS skuweight, 
                  max(ii.oid)                               AS mostrecentinventoryitem , 
                  string_agg(DISTINCT sup.suppliername,'|') AS all_suppliers 
         FROM     ecommerce.sku                             AS s, 
                  ecommerce.rsinventoryitem                 AS ii, 
                  ecommerce.supplier                        AS sup 
         WHERE    s.sku_id = ii.sku_id 
         AND      ii.active = true 
         AND      s.skubitmask & 1 = 1 
         AND      ii.supplier_id = sup.supplier_id 
         GROUP BY s.sku_id ) 
SELECT     s.sku_id, 
           sup.suppliername          AS most_recent_supplier 
FROM       ecommerce.sku             AS s, 
           ecommerce.supplier        AS sup, 
           ecommerce.rsinventoryitem AS ii 
RIGHT JOIN skudata                   AS skudata 
ON         skudata.mostrecentinventoryitem = ii.oid 
WHERE      ii.sku_id = s.sku_id 
AND        ii.supplier_id = sup.supplier_id 
ORDER BY   s.sku_id ) 
SELECT          skudetails.skufamilyid, 
                skudetails.skufamilyname, 
                skudetails.skufamilystatusid, 
                skudetails.skufamilystatus, 
                skudetails.skufamilyvendor, 
                skudetails.skuid, 
                skudetails.skustatus, 
                skudetails.tracksinventory , 
                skudetails.skuname, 
                skudetails.partnumber, 
                skudetails.countrycode, 
                skudetails.skubuyer, 
                skudetails.skucategory1, 
                skudetails.skucategory2, 
                skudetails.skucategory3, 
                skudetails.skucategory4, 
                skudetails.skucategory5, 
                skudetails.skucategory6 , 
                skudata.skuquantity, 
                skudata.skulowerofcost, 
                skudata.skuweight, 
                skucalc.skureorderdate, 
                skucalc.skureorderage, 
                skucalc.skuprice, 
                skucalc.skuaveragecost , 
                skucalc.skuinitialcost, 
                skucalc.skucurrentcost, 
                COALESCE(skudata.all_suppliers, mrsup.most_recent_supplier) AS supplier_name 
FROM            ecommerce.sku                                               AS s 
LEFT OUTER JOIN skucalc                                                     AS skucalc 
ON              s.sku_id = skucalc.sku_id 
LEFT OUTER JOIN skudetails AS skudetails 
ON              s.sku_id = skudetails.skuid 
LEFT OUTER JOIN skudata 
ON              s.sku_id = skudata.skuid 
LEFT OUTER JOIN mostrecentsupplier AS mrsup 
ON              s.sku_id = mrsup.sku_id 
WHERE           true 
ORDER BY        skudetails.skufamilyid, 
                skudetails.skuid ) 
SELECT DISTINCT vsid.productversion_id      AS version_id, 
                vsid.sku_id                 AS sku_id, 
                versionskuquantity.quantity AS versionskuquantity, 
                '0'                         AS skurevenuepercentage , 
                versiondata.versionfamilyid, 
                versiondata.versionfamilyname, 
                versiondata.versionfamilystatus, 
                versiondata.versionstatusid, 
                versiondata.versionstatus, 
                versiondata.versionname AS version_name , 
                versiondata.units2017, 
                versiondata.rev2017 , 
                versiondata.versionaveragecost, 
                versiondata.versionaverageprice, 
                versiondata.currentprice, 
                versiondata.recommended_sale_price, 
                versiondata.recommended_pop_pick_price , 
                versiondata.firstdatesold, 
                versiondata.last14units, 
                versiondata.last14rev, 
                versiondata.last30units, 
                versiondata.last30rev, 
                versiondata.last90units, 
                versiondata.last90rev, 
                versiondata.last180units, 
                versiondata.last180rev, 
                versiondata.last365units, 
                versiondata.last365rev , 
                skumain.skufamilyid, 
                skumain.skufamilyname, 
                skumain.skufamilystatusid, 
                skumain.skufamilystatus, 
                skumain.skufamilyvendor, 
                skumain.skustatus, 
                skumain.tracksinventory, 
                skumain.skuname AS sku_name , 
                skumain.partnumber, 
                skumain.countrycode AS country_code, 
                skumain.skubuyer, 
                skumain.skucategory1, 
                skumain.skucategory2, 
                skumain.skucategory3, 
                skumain.skucategory4, 
                skumain.skucategory5, 
                skumain.skucategory6 , 
                skumain.skuquantity, 
                skumain.skulowerofcost, 
                skumain.skuweight, 
                skumain.supplier_name, 
                skumain.skureorderdate, 
                skumain.skureorderage, 
                skumain.skuprice, 
                skumain.skuaveragecost , 
                skumain.skuinitialcost, 
                skumain.skucurrentcost, 
                skumain.supplier_name , 
                ''                          AS salesmonth, 
                0                           AS salesmonthunits, 
                0                           AS salesmonthrevenue 
FROM            ecommerce.productversionsku AS vsid 
LEFT OUTER JOIN skumain                     AS skumain 
ON              vsid.sku_id = skumain.skuid 
LEFT OUTER JOIN versiondata AS versiondata 
ON              versiondata.versionid = vsid.productversion_id 
LEFT OUTER JOIN versionskuquantity AS versionskuquantity 
ON              vsid.productversion_id = versionskuquantity.versionid 
AND             vsid.sku_id = versionskuquantity.skuid 
WHERE           true 
AND             skumain.skufamilyvendor ilike '%CharityUSA Properties%' 
ORDER BY        vsid.productversion_id, 
                vsid.sku_id