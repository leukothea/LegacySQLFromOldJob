WITH poliqty 
     AS (SELECT pol.purchaseorder_id     AS po_id, 
                SUM(pol.quantityordered) AS po_quantity 
         FROM   ecommerce.purchaseorderlineitem AS pol 
         GROUP  BY pol.purchaseorder_id) 
SELECT po.purchaseorder_id                            AS po_id, 
       po.ponumber                                    AS po_name, 
       po.buyeruid                                    AS buyer, 
       pos.status                                     AS po_status, 
       po.dateissued :: DATE                          AS create_date, 
       po.shipdate :: DATE                            AS ship_date, 
       po.expectedarrivaldate :: DATE                 AS eta_date, 
       poli.quantityordered                           AS qty_ordered, 
       pv.sku_id                                      AS sku_id, 
       pv.name                                        AS sku_name, 
       pv.item_id, 
       CASE 
         WHEN poli.is_reorder = 't' THEN 'Reorder' 
         ELSE 'New' 
       END                                            AS reorder_status, 
       ( CASE 
           WHEN poliqty.po_quantity > 0 THEN 
           ( SUM( 
           Coalesce(po.flat_rate_surcharge, 0.00) 
           + Coalesce(po.flat_rate_surcharge2, 0.00) 
           + Coalesce(po.flat_rate_surcharge3, 0.00)) / 
           SUM(poliqty.po_quantity) ) 
           ELSE 0 
         END )                                        AS 
       po_level_charges_appliedto_poli, 
       poli.unitprice                                 AS unit_price, 
       poli.unitsurcharge                             AS unit_surcharge, 
       poli.flatratesurcharge                         AS 
       unit_flat_rate_surcharge, 
       ( ( poli.duty_perc * 0.01 ) * poli.unitprice ) AS poli_summed_duty, 
       rs.status                                      AS line_item_status, 
       Coalesce(SUM(re.totalreceivedcount), 0)        AS qty_received, 
       Coalesce(Coalesce(a.state, a.country_code) 
                || ' ' 
                || a.postal_code, '--')               AS supplier_location 
FROM   ecommerce.purchaseorder AS po 
       left outer join poliqty AS poliqty 
                    ON po.purchaseorder_id = poliqty.po_id, 
       ecommerce.purchaseorderstatus AS pos, 
       ecommerce.sku AS pv, 
       ecommerce.receivingstatus AS rs, 
       ecommerce.supplier AS s, 
       ecommerce.supplier_address AS a, 
       ecommerce.supplier_type AS st, 
       ecommerce.purchaseorderlineitem AS poli 
       left outer join ecommerce.receivingevent AS re 
                    ON poli.polineitem_id = re.polineitem_id 
WHERE  po.purchaseorder_id = poli.purchaseorder_id 
       AND poli.sku_id = pv.sku_id 
       AND poli.receivingstatus_id = rs.receivingstatus_id 
       AND po.purchaseorderstatus_id = pos.purchaseorderstatus_id 
       AND po.supplier_id = s.supplier_id 
       AND s.supplier_id = a.supplier_id 
       AND a.is_primary = TRUE 
       AND s.supplier_type_id = st.supplier_type_id 
       AND po.dateissued >= '11/29/2017' 
GROUP  BY po.purchaseorder_id, 
          po.ponumber, 
          po.buyeruid, 
          pos.status, 
          po.dateissued :: DATE, 
          po.shipdate :: DATE, 
          po.expectedarrivaldate :: DATE, 
          poli.quantityordered, 
          poliqty.po_quantity, 
          pv.sku_id, 
          pv.name, 
          pv.item_id, 
          CASE 
            WHEN poli.is_reorder = 't' THEN 'Reorder' 
            ELSE 'New' 
          END, 
          poli.unitprice, 
          poli.unitsurcharge, 
          poli.flatratesurcharge, 
          poli.duty_perc, 
          rs.status, 
          Coalesce(Coalesce(a.state, a.country_code) 
                   || ' ' 
                   || a.postal_code, '--') 
ORDER  BY po.ponumber, 
          pos.status, 
          poli.quantityordered DESC 