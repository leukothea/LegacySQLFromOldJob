{\rtf1\ansi\ansicpg1252\cocoartf1404\cocoasubrtf470
{\fonttbl\f0\fswiss\fcharset0 Helvetica;}
{\colortbl;\red255\green255\blue255;}
\margl1440\margr1440\vieww21680\viewh16800\viewkind0
\pard\tx720\tx1440\tx2160\tx2880\tx3600\tx4320\tx5040\tx5760\tx6480\tx7200\tx7920\tx8640\pardirnatural\partightenfactor0

\f0\fs24 \cf0 with toplayer as (\
with dataset as \
(with subquery as (select i.item_id, string_to_array(i.keywords, ',') as keyword from ecommerce.item as i)\
select i.item_id,  keyword[1] as kw1, keyword[2] as kw2, keyword[3] as kw3, keyword[4] as kw4, keyword[5] as kw5, keyword[6] as kw6, keyword[7] as kw7, keyword[8] as kw8, keyword[9] as kw9, keyword[10] as kw10, \
keyword[11] as kw11, keyword[12] as kw12, keyword[13] as kw13, keyword[14] as kw14, keyword[15] as kw15, keyword[16] as kw16, keyword[17] as kw17, keyword[18] as kw18, keyword[19] as kw19, keyword[20] as kw20, \
keyword[21] as kw21, keyword[22] as kw22, keyword[23] as kw23, keyword[24] as kw24, keyword[25] as kw25, keyword[26] as kw26, keyword[27] as kw27, keyword[28] as kw28, keyword[29] as kw29, keyword[30] as kw30, \
keyword[31] as kw31, keyword[32] as kw32, keyword[33] as kw33, keyword[34] as kw34, keyword[35] as kw35, keyword[36] as kw36, keyword[37] as kw37, keyword[38] as kw38, keyword[39] as kw39, keyword[40] as kw40, \
keyword[41] as kw41, keyword[42] as kw42, keyword[43] as kw43, keyword[44] as kw44, keyword[45] as kw45, keyword[46] as kw46, keyword[47] as kw47, keyword[48] as kw48, keyword[49] as kw49, keyword[50] as kw50, \
keyword[51] as kw51, keyword[52] as kw52, keyword[53] as kw53, keyword[54] as kw54\
from ecommerce.item as i LEFT OUTER JOIN subquery ON i.item_id = subquery.item_id\
where i.itemstatus_id IN (0, 1)\
group by i.item_id, subquery.keyword)\
\
(select dataset.item_id, dataset.kw1 as keyword\
from dataset\
where dataset.kw1 IS NOT NULL)\
UNION \
(select dataset.item_id, dataset.kw2 as keyword\
from dataset\
where dataset.kw2 IS NOT NULL)\
UNION \
(select dataset.item_id, dataset.kw3 as keyword\
from dataset\
where dataset.kw3 IS NOT NULL)\
UNION \
(select dataset.item_id, dataset.kw4 as keyword\
from dataset\
where dataset.kw4 IS NOT NULL)\
UNION \
(select dataset.item_id, dataset.kw5 as keyword\
from dataset\
where dataset.kw5 IS NOT NULL)\
UNION \
(select dataset.item_id, dataset.kw6 as keyword\
from dataset\
where dataset.kw6 IS NOT NULL)\
UNION \
(select dataset.item_id, dataset.kw7 as keyword\
from dataset\
where dataset.kw7 IS NOT NULL)\
UNION \
(select dataset.item_id, dataset.kw8 as keyword\
from dataset\
where dataset.kw8 IS NOT NULL)\
UNION \
(select dataset.item_id, dataset.kw9 as keyword\
from dataset\
where dataset.kw9 IS NOT NULL)\
UNION \
(select dataset.item_id, dataset.kw10 as keyword\
from dataset\
where dataset.kw10 IS NOT NULL)\
UNION \
(select dataset.item_id, dataset.kw11 as keyword\
from dataset\
where dataset.kw11 IS NOT NULL)\
UNION \
(select dataset.item_id, dataset.kw12 as keyword\
from dataset\
where dataset.kw12 IS NOT NULL)\
UNION \
(select dataset.item_id, dataset.kw13 as keyword\
from dataset\
where dataset.kw13 IS NOT NULL)\
UNION \
(select dataset.item_id, dataset.kw14 as keyword\
from dataset\
where dataset.kw14 IS NOT NULL)\
UNION \
(select dataset.item_id, dataset.kw15 as keyword\
from dataset\
where dataset.kw15 IS NOT NULL)\
UNION \
(select dataset.item_id, dataset.kw16 as keyword\
from dataset\
where dataset.kw16 IS NOT NULL)\
UNION \
(select dataset.item_id, dataset.kw17 as keyword\
from dataset\
where dataset.kw17 IS NOT NULL)\
UNION \
(select dataset.item_id, dataset.kw18 as keyword\
from dataset\
where dataset.kw18 IS NOT NULL)\
UNION \
(select dataset.item_id, dataset.kw19 as keyword\
from dataset\
where dataset.kw19 IS NOT NULL)\
UNION \
(select dataset.item_id, dataset.kw20 as keyword\
from dataset\
where dataset.kw20 IS NOT NULL)\
UNION \
(select dataset.item_id, dataset.kw21 as keyword\
from dataset\
where dataset.kw21 IS NOT NULL)\
UNION \
(select dataset.item_id, dataset.kw22 as keyword\
from dataset\
where dataset.kw22 IS NOT NULL)\
UNION \
(select dataset.item_id, dataset.kw23 as keyword\
from dataset\
where dataset.kw23 IS NOT NULL)\
UNION \
(select dataset.item_id, dataset.kw24 as keyword\
from dataset\
where dataset.kw24 IS NOT NULL)\
UNION \
(select dataset.item_id, dataset.kw25 as keyword\
from dataset\
where dataset.kw25 IS NOT NULL)\
UNION \
(select dataset.item_id, dataset.kw26 as keyword\
from dataset\
where dataset.kw26 IS NOT NULL)\
UNION \
(select dataset.item_id, dataset.kw27 as keyword\
from dataset\
where dataset.kw27 IS NOT NULL)\
UNION \
(select dataset.item_id, dataset.kw28 as keyword\
from dataset\
where dataset.kw28 IS NOT NULL)\
UNION \
(select dataset.item_id, dataset.kw29 as keyword\
from dataset\
where dataset.kw29 IS NOT NULL)\
UNION \
(select dataset.item_id, dataset.kw30 as keyword\
from dataset\
where dataset.kw30 IS NOT NULL)\
UNION \
(select dataset.item_id, dataset.kw31 as keyword\
from dataset\
where dataset.kw31 IS NOT NULL)\
UNION \
(select dataset.item_id, dataset.kw32 as keyword\
from dataset\
where dataset.kw32 IS NOT NULL)\
UNION \
(select dataset.item_id, dataset.kw33 as keyword\
from dataset\
where dataset.kw33 IS NOT NULL)\
UNION \
(select dataset.item_id, dataset.kw34 as keyword\
from dataset\
where dataset.kw34 IS NOT NULL)\
UNION \
(select dataset.item_id, dataset.kw35 as keyword\
from dataset\
where dataset.kw35 IS NOT NULL)\
UNION \
(select dataset.item_id, dataset.kw36 as keyword\
from dataset\
where dataset.kw36 IS NOT NULL)\
UNION \
(select dataset.item_id, dataset.kw37 as keyword\
from dataset\
where dataset.kw37 IS NOT NULL)\
UNION \
(select dataset.item_id, dataset.kw38 as keyword\
from dataset\
where dataset.kw38 IS NOT NULL)\
UNION \
(select dataset.item_id, dataset.kw39 as keyword\
from dataset\
where dataset.kw39 IS NOT NULL)\
UNION \
(select dataset.item_id, dataset.kw40 as keyword\
from dataset\
where dataset.kw40 IS NOT NULL)\
UNION \
(select dataset.item_id, dataset.kw41 as keyword\
from dataset\
where dataset.kw41 IS NOT NULL)\
UNION \
(select dataset.item_id, dataset.kw42 as keyword\
from dataset\
where dataset.kw42 IS NOT NULL)\
UNION \
(select dataset.item_id, dataset.kw43 as keyword\
from dataset\
where dataset.kw43 IS NOT NULL)\
UNION \
(select dataset.item_id, dataset.kw44 as keyword\
from dataset\
where dataset.kw44 IS NOT NULL)\
UNION \
(select dataset.item_id, dataset.kw45 as keyword\
from dataset\
where dataset.kw45 IS NOT NULL)\
UNION \
(select dataset.item_id, dataset.kw46 as keyword\
from dataset\
where dataset.kw46 IS NOT NULL)\
UNION \
(select dataset.item_id, dataset.kw47 as keyword\
from dataset\
where dataset.kw47 IS NOT NULL)\
UNION \
(select dataset.item_id, dataset.kw48 as keyword\
from dataset\
where dataset.kw48 IS NOT NULL)\
UNION \
(select dataset.item_id, dataset.kw49 as keyword\
from dataset\
where dataset.kw49 IS NOT NULL)\
UNION \
(select dataset.item_id, dataset.kw50 as keyword\
from dataset\
where dataset.kw50 IS NOT NULL)\
UNION \
(select dataset.item_id, dataset.kw51 as keyword\
from dataset\
where dataset.kw51 IS NOT NULL)\
UNION \
(select dataset.item_id, dataset.kw52 as keyword\
from dataset\
where dataset.kw52 IS NOT NULL)\
UNION \
(select dataset.item_id, dataset.kw53 as keyword\
from dataset\
where dataset.kw53 IS NOT NULL)\
UNION \
(select dataset.item_id, dataset.kw54 as keyword\
from dataset\
where dataset.kw54 IS NOT NULL))\
select toplayer.item_id, toplayer.keyword\
from toplayer\
where toplayer.keyword NOT ILIKE '%20off%'\
and toplayer.keyword NOT ILIKE '%xmas%'\
and toplayer.keyword NOT ILIKE '%blowout%'\
and toplayer.keyword NOT ILIKE '%card%'\
and toplayer.keyword NOT ILIKE '%sale%'\
and toplayer.keyword NOT ILIKE '%deals%'\
and toplayer.keyword NOT ILIKE 'edv'\
and toplayer.keyword NOT ILIKE '%holi%'\
and toplayer.keyword NOT ILIKE '%GTGM%'\
and toplayer.keyword NOT ILIKE '%poppick%'\
and toplayer.keyword NOT ILIKE '%weeklyspecial%'\
and toplayer.keyword NOT ILIKE '%10'\
and toplayer.keyword NOT ILIKE '%11'\
and toplayer.keyword NOT ILIKE '%12'\
and toplayer.keyword NOT ILIKE '%13'\
and toplayer.keyword NOT ILIKE '%14'\
and toplayer.keyword NOT ILIKE '%15'\
and toplayer.keyword NOT ILIKE '%16'\
and toplayer.keyword IS NOT NULL\
order by toplayer.item_id asc;}