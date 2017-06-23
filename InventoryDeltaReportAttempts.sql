with final as (
WITH dates AS (
select generate_series( '01/13/2017', '2017-02-11', '1 day'::INTERVAL)::date as date
), dateArray AS (
select array_agg(date) as date_array from dates     
) SELECT distinct
  ia.sku_id
  , s.name AS sku_name
  , sum(ia.inventory_count) FILTER (WHERE ia.audit_date = dr.date_array[1]) AS day_1_count 
  , sum(ia.inventory_count) FILTER (WHERE ia.audit_date = dr.date_array[2]) AS day_2_count 
  , sum(ia.inventory_count) FILTER (WHERE ia.audit_date = dr.date_array[3]) AS day_3_count
  , sum(ia.inventory_count) FILTER (WHERE ia.audit_date = dr.date_array[4]) AS day_4_count 
  , sum(ia.inventory_count) FILTER (WHERE ia.audit_date = dr.date_array[5]) AS day_5_count 
  , sum(ia.inventory_count) FILTER (WHERE ia.audit_date = dr.date_array[6]) AS day_6_count
  , sum(ia.inventory_count) FILTER (WHERE ia.audit_date = dr.date_array[7]) AS day_7_count
  , sum(ia.inventory_count) FILTER (WHERE ia.audit_date = dr.date_array[8]) AS day_8_count 
  , sum(ia.inventory_count) FILTER (WHERE ia.audit_date = dr.date_array[9]) AS day_9_count 
  , sum(ia.inventory_count) FILTER (WHERE ia.audit_date = dr.date_array[10]) AS day_10_count
  , sum(ia.inventory_count) FILTER (WHERE ia.audit_date = dr.date_array[11]) AS day_11_count 
  , sum(ia.inventory_count) FILTER (WHERE ia.audit_date = dr.date_array[12]) AS day_12_count 
  , sum(ia.inventory_count) FILTER (WHERE ia.audit_date = dr.date_array[13]) AS day_13_count
  , sum(ia.inventory_count) FILTER (WHERE ia.audit_date = dr.date_array[14]) AS day_14_count 
  , sum(ia.inventory_count) FILTER (WHERE ia.audit_date = dr.date_array[15]) AS day_15_count 
  , sum(ia.inventory_count) FILTER (WHERE ia.audit_date = dr.date_array[16]) AS day_16_count
  , sum(ia.inventory_count) FILTER (WHERE ia.audit_date = dr.date_array[17]) AS day_17_count
  , sum(ia.inventory_count) FILTER (WHERE ia.audit_date = dr.date_array[18]) AS day_18_count 
  , sum(ia.inventory_count) FILTER (WHERE ia.audit_date = dr.date_array[19]) AS day_19_count 
  , sum(ia.inventory_count) FILTER (WHERE ia.audit_date = dr.date_array[20]) AS day_20_count
  , sum(ia.inventory_count) FILTER (WHERE ia.audit_date = dr.date_array[21]) AS day_21_count 
  , sum(ia.inventory_count) FILTER (WHERE ia.audit_date = dr.date_array[22]) AS day_22_count 
  , sum(ia.inventory_count) FILTER (WHERE ia.audit_date = dr.date_array[23]) AS day_23_count
  , sum(ia.inventory_count) FILTER (WHERE ia.audit_date = dr.date_array[24]) AS day_24_count 
  , sum(ia.inventory_count) FILTER (WHERE ia.audit_date = dr.date_array[25]) AS day_25_count 
  , sum(ia.inventory_count) FILTER (WHERE ia.audit_date = dr.date_array[26]) AS day_26_count
  , sum(ia.inventory_count) FILTER (WHERE ia.audit_date = dr.date_array[27]) AS day_27_count
  , sum(ia.inventory_count) FILTER (WHERE ia.audit_date = dr.date_array[28]) AS day_28_count 
  , sum(ia.inventory_count) FILTER (WHERE ia.audit_date = dr.date_array[29]) AS day_29_count 
  , sum(ia.inventory_count) FILTER (WHERE ia.audit_date = dr.date_array[30]) AS day_30_count
FROM
  ecommerce.inventory_audit AS ia
  ,dateArray AS dr
  , ecommerce.sku AS s
WHERE
  s.sku_id = ia.sku_id
GROUP BY
  ia.sku_id
  , s.name
ORDER BY
  ia.sku_id ASC
) select distinct final.sku_id, final.sku_name
, final.day_1_count
, final.day_2_count
, final.day_3_count
, final.day_4_count
, final.day_5_count
, final.day_6_count
, final.day_7_count
, final.day_8_count
, final.day_9_count
, final.day_10_count
, final.day_11_count
, final.day_12_count
, final.day_13_count
, final.day_14_count
, final.day_15_count
, final.day_16_count
, final.day_17_count
, final.day_18_count
, final.day_19_count
, final.day_20_count
, final.day_21_count
, final.day_22_count
, final.day_23_count
, final.day_24_count
, final.day_25_count
, final.day_26_count
, final.day_27_count
, final.day_28_count
, final.day_29_count
, final.day_30_count
from final
where (final.day_1_count IS NOT NULL 
OR final.day_2_count IS NOT NULL 
OR final.day_3_count IS NOT NULL 
OR final.day_4_count IS NOT NULL
OR final.day_5_count IS NOT NULL 
OR final.day_6_count IS NOT NULL 
OR final.day_7_count IS NOT NULL 
OR final.day_8_count IS NOT NULL 
OR final.day_9_count IS NOT NULL 
OR final.day_10_count IS NOT NULL 
OR final.day_11_count IS NOT NULL 
OR final.day_12_count IS NOT NULL 
OR final.day_13_count IS NOT NULL 
OR final.day_14_count IS NOT NULL 
OR final.day_15_count IS NOT NULL 
OR final.day_16_count IS NOT NULL 
OR final.day_17_count IS NOT NULL 
OR final.day_18_count IS NOT NULL 
OR final.day_19_count IS NOT NULL 
OR final.day_20_count IS NOT NULL 
OR final.day_21_count IS NOT NULL 
OR final.day_22_count IS NOT NULL 
OR final.day_23_count IS NOT NULL 
OR final.day_24_count IS NOT NULL 
OR final.day_25_count IS NOT NULL 
OR final.day_26_count IS NOT NULL 
OR final.day_27_count IS NOT NULL 
OR final.day_28_count IS NOT NULL 
OR final.day_29_count IS NOT NULL 
OR final.day_30_count IS NOT NULL )


// actually works! but, takes forever to run

