WITH min 
     AS (SELECT Min(pa.authorization_id) AS authorization_id, 
                pa.order_id, 
                1                        AS min_lineitem 
         FROM   ecommerce.paymentauthorization AS pa, 
                ecommerce.rslineitem AS li 
         WHERE  pa.order_id = li.order_id 
                AND pa.payment_status_id IN ( 3, 5, 6 ) 
                AND pa.payment_transaction_result_id = 1 
                AND pa.order_id IN ( 30724867 ) 
         GROUP  BY pa.order_id 
         ORDER  BY pa.order_id ASC), 
     paymentauths 
     AS (SELECT pt.transaction_id, 
                pt.trandate, 
                pa.authorization_id, 
                pa.order_id, 
                pa.authdate, 
                pa.payment_method_id 
         FROM   ecommerce.paymentauthorization AS pa, 
                ecommerce.paymenttransaction AS pt 
         WHERE  pa.authorization_id = pt.authorization_id 
                AND pa.payment_status_id IN ( 3, 5, 6 ) 
                AND pa.payment_transaction_result_id = 1 
                AND pa.order_id IN ( 30724867 ) 
         GROUP  BY pt.transaction_id, 
                   pt.trandate, 
                   pa.authorization_id, 
                   pa.order_id, 
                   pa.authdate, 
                   pa.payment_method_id 
         ORDER  BY pa.authorization_id ASC) 
SELECT DISTINCT pa.authorization_id, 
                li.order_id, 
                li.productversion_id AS version_id, 
                pv.NAME              AS version_name, 
                ( CASE 
                    WHEN ( ( min.min_lineitem IS NOT NULL ) 
                            OR ( min.min_lineitem IS NULL 
                                 AND li.subscription_id IS NOT NULL ) ) THEN 
                    li.quantity 
                    ELSE 0 
                  END )              AS quantity, 
                ( CASE 
                    WHEN ( li.subscription_id IS NULL 
                            OR s.subscription_status_id = 1 ) THEN 
                    li.quantity * li.customerprice 
                    ELSE 0 
                  END )              AS lineitem_total, 
                pa.authdate          AS auth_date, 
                ( CASE 
                    WHEN min.min_lineitem = 1 THEN li.quantity 
                    ELSE 0 
                  END )              AS count_initial_subscription, 
                ( CASE 
                    WHEN min.min_lineitem IS NULL THEN li.quantity 
                    ELSE 0 
                  END )              AS count_recurring_subscription, 
                ( CASE 
                    WHEN min.min_lineitem = 1 THEN 
                    li.quantity * li.customerprice 
                    ELSE 0 
                  END )              AS revenue_initial_subscription, 
                ( CASE 
                    WHEN min.min_lineitem IS NULL THEN 
                    li.quantity * li.customerprice 
                    ELSE 0 
                  END )              AS revenue_recurring_subscription 
FROM   paymentauths AS pa 
       LEFT OUTER JOIN min 
                    ON pa.authorization_id = min.authorization_id 
       LEFT OUTER JOIN ecommerce.subscription_payment_authorization AS spa 
                    ON pa.authorization_id = spa.authorization_id, 
       ecommerce.rsorder AS o, 
       ecommerce.productversion AS pv, 
       ecommerce.rslineitem AS li 
       LEFT OUTER JOIN ecommerce.subscription AS s 
                    ON li.subscription_id = s.subscription_id 
WHERE  li.order_id = o.oid 
       AND li.productversion_id = pv.productversion_id 
       AND li.date_record_added >= '03/29/2017' 
       AND o.oid IN ( 30724867 ) 
GROUP  BY pa.authorization_id, 
          pa.authdate, 
          li.order_id, 
          li.productversion_id, 
          li.quantity, 
          li.customerprice, 
          li.subscription_id, 
          s.subscription_status_id, 
          pv.NAME, 
          min.min_lineitem 
HAVING ( ( min.min_lineitem IS NOT NULL ) 
          OR ( min.min_lineitem IS NULL 
               AND li.subscription_id IS NOT NULL ) ) 
ORDER  BY li.order_id, 
          pa.authdate ASC 