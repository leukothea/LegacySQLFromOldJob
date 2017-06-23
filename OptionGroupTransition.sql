-- Find all items that have a "Size" option group as their #2, plus info about their #1 and #2 option groups. 

with pool as (
	select 
		i.item_id
		, i.name as item_name
		, og.option_group_id as optiongroup_id
		, og.name as optiongroup_name
	from 
		ecommerce.item as i
		, ecommerce.item_option as io
		, ecommerce.option_group as og
	where 
		i.item_id = io.item_id
		and io.option_group_id = og.option_group_id
		and i.itemstatus_id != 5
		and og.name ILIKE '%Size%'
		and io.display_level = 2
	group by 
		i.item_id 
		, i.name
		, og.option_group_id
		, og.name
) select 
distinct 
	pool.item_id
	, pool.item_name
	, og1.option_group_id as optiongroup1_id
	, og1.name as optiongroup1_name
	, pool.optiongroup_id as optiongroup2_id
	, pool.optiongroup_name as optiongroup2_name
from
	pool
	, ecommerce.item_option as io 
		INNER JOIN ecommerce.option_group as og1 
			ON io.option_group_id = og1.option_group_id 
			AND io.display_level = 1
where 
	pool.item_id = io.item_id
order by 
	pool.item_id asc


-- Detailed view, including what option groups and specific option IDs already exist for each qualifying version. 

with og1 as (
	select 
		i.item_id
		, pv.productversion_id
		, io.option_group_id
		, og.name as optiongroup_name
		, po.option_id
		, o.name as option_name
	from 
		ecommerce.item as i
		, ecommerce.productversion as pv
		, ecommerce.item_option as io
		, ecommerce.rsproductversionoption as po
		, ecommerce.rsproductoption as o
		, ecommerce.rsoptiongroup as og
	where 
		i.item_id = pv.item_id 
		and i.item_id = io.item_id 
		and po.productversion_id = pv.productversion_id 
		and og.oid = io.option_group_id 
		and og.oid = o.group_id 
		and po.option_id = o.oid 
		and io.display_level = 1
), og2 as (
	select 
		i.item_id
		, pv.productversion_id
		, io.option_group_id
		, og.name as optiongroup_name
		, po.option_id
		, o.name as option_name
	from 
		ecommerce.item as i
		, ecommerce.productversion as pv
		, ecommerce.item_option as io
		, ecommerce.rsproductversionoption as po
		, ecommerce.rsproductoption as o
		, ecommerce.rsoptiongroup as og
	where 
		i.item_id = pv.item_id 
		and i.item_id = io.item_id 
		and po.productversion_id = pv.productversion_id 
		and og.oid = io.option_group_id 
		and og.oid = o.group_id 
		and po.option_id = o.oid 
		and io.display_level = 2
)
select 
	i.item_id
	, i.name
	, pv.productversion_id
	, pv.name
	, og1.option_group_id as optiongroup1
	, og1.optiongroup_name as optiongroupname1
	, og1.option_id as optionid1
	, og1.option_name as optionname1
	, og2.option_group_id as optiongroup2
	, og2.optiongroup_name as optiongroupname2
	, og2.option_id as optionid2
	, og2.option_name as optionname2
from 
	ecommerce.item as i
	, ecommerce.productversion as pv 
		RIGHT JOIN og1 
			ON pv.productversion_id = og1.productversion_id 
		LEFT OUTER JOIN og2 
			ON pv.productversion_id = og2.productversion_id
where 
	i.item_id = pv.item_id 
	and i.item_id = og1.item_id
	and i.itemstatus_id IN (0, 1)
order by 
	i.item_id asc;



-- Without the Outlet items, and also counting only active versions

select 
	i.item_id
	, i.name
	, count(pv.productversion_id) from ecommerce.item as i
	, ecommerce.item_option as io
	, ecommerce.productversion as pv
where 
	i.item_id = io.item_id
	and i.item_id = pv.item_id
	and io.option_group_id = 254
	and i.itemstatus_id IN (0, 1)
	and pv.itemstatus_id = 0
	and i.item_id NOT IN (
		select 
			item_id 
		from 
			ecommerce.category_item 
		where 
			category_id = 2711
	)
group by 
	i.item_id
	, i.name
order by 
	count(pv.productversion_id) desc;

-- rename any totally unused option to "void"+option ID

update 
	ecommerce.rsproductoption 
set 
	name = 'void' || oid
	, ordinal = NULL 
where oid IN (
	select 
		oid 
	from 
		ecommerce.rsproductoption 
	where 
		oid NOT IN (
			select 
				option_id 
			from 
				ecommerce.rsproductversionoption
		)
	and name not like 'void%'
);

-- Options that are only associated with retired versions

select 
	distinct o.oid
	, o.group_id
	, o.name 
from 
	ecommerce.rsproductversionoption as pvo
	, ecommerce.rsproductoption as o
	, ecommerce.productversion as pv
where 
	pv.productversion_id = pvo.productversion_id
	and pvo.option_Id = o.oid
	and o.name not like 'void%'
	and pv.itemstatus_id = 5
	and o.oid NOT IN (
		select 
			o.oid 
		from 
			ecommerce.rsproductversionoption as pvo
			, ecommerce.rsproductoption as o
			, ecommerce.productversion as pv
		where 
			pv.productversion_id = pvo.productversion_id
			and pvo.option_id = o.oid
			and pv.itemstatus_id IN (0, 1, 2, 3, 4)
	);

-- Multiple option groups (NEW STYLE)

select 
	i.item_id
	, count(io.item_id)
	, i.itemstatus_id 
from 
	ecommerce.item as i
	, ecommerce.item_option as io
where 
	i.item_id = io.item_id
	and i.itemstatus_id != 5
group by 
	i.item_id
	, i.itemstatus_id
order by 
	io.count desc;

/* De-Comboing Info

1) Build the spreadsheet. You will need the option ID for each new option, and the productversion IDs. 
select item_id, productversion_id, name from ecommerce.productversion
where item_id = <item_id>;
*/

select 
	* 
from 
	ecommerce.rsproductoption 
where 
	name like '%January%' 
	and group_id != 254;

-- or, for an exact match within a group,
select 
	* 
from 
	ecommerce.rsproductoption 
where 
	name = 'S' 
	and group_id = 297;


--The spreadsheet can start with this bit: 

insert into 
		ecommerce.rsproductversionoption (option_id, productversion_id)
values

--and then gets built out of 5 cells: 
(	option_id	,	productversion_id	),

/*
Build out the spreadsheet until you have it all populated for each desired option + productversion combination, one row for each. 
NOTE that you have to maintain the option group IDs inside each item. So, if you're migrating something off combination to a color group plus a size group, and you find a "Raspberry" option in option group Color but a "Yellow Chevron" option in option group Design, and you want to use them both in the same item, you can't. You have to create "Raspberry" in option group "Design" and maintain that option group consistently within the item. 
Don't forget to change the final comma to a semicolon. 

2) Once you have the spreadsheet built out, run this command: 
delete from ecommerce.rsproductversionoption where productversion_id IN (select productversion_id from ecommerce.productversion where item_id = <item_id>);
 

3) Then, in the app, remove the “Combination” option group. Or you could run: 
*/
 
delete 
from 
	ecommerce.item_option
where 
	item_id = <item_id>;
 
-- for a longer list of items, use: 
 
delete 
from 
	ecommerce.item_option 
where 
	item_id IN (	49470	,
	49503	,
	49650	,
	50132	,
	53004	,
	53005	,
	53352	,
	53354	,
	53355	,
	53784	,
	61955	,
	63727	)
and option_group_id = 254;


 
/*
4) Next, hand-add the new option groups to the item in Fawkes.

Or, you could run this with the multi-script run button so it inserts both groups at once: 
*/

insert into 
	ecommerce.item_option (item_option_id, item_id, option_group_id, display_level) 
	values	
		(nextval('ecommerce.seq_item_option'), 	49470	, 	297	, 	1), 
		(nextval('ecommerce.seq_item_option'), 	49470	,	53	,	2),
 
 /*
etc.

5) Finally, paste in the option ID - version ID bits of the spreadsheet, starting from the "insert" all the way through the semicolon, into PostGres and run the command. 

6) QA in Fawkes on the Version List page to make sure you didn't double-add or screw up anything in another way. Also QA (optionally) on the front end. 

*/

--DONE
 
-- Flag / Flag Stand option QAing – DONE 2015-07-06
select 
	pv.item_id
	, pv.productversion_id
	, pv.name
	, pvo.option_id
	, o.name
	, o.group_id 
from 
	ecommerce.productversion as pv
	, ecommerce.rsproductversionoption as pvo
	, ecommerce.rsproductoption as o
where 
	pv.productversion_id = pvo.productversion_id
	and pvo.option_id = o.oid
	and pv.item_id IN ( < blah blah blah >)
order by 
	pv.item_id asc;

 
-- Non-retired items that are in more than one option group (OLD STYLE OPTION GROUP) 
 
select 
	i.item_id
	, count(io.item_id)
	, i.itemstatus_id 
from 
	ecommerce.item as i
	, ecommerce.rsitemoption as io
where 
	i.item_id = io.item_id
	and i.itemstatus_id != 5
group by 
	i.item_id
	, i.itemstatus_id
order by 
	io.count desc;

-- Items that need to be migrated off the Combination option group, with the version count of each. (DEPRECATED - this job is done)

select 
	i.item_id
	, i.name
	, count(pv.productversion_id) 
from 
	ecommerce.item as i
	, ecommerce.item_option as io
	, ecommerce.productversion as pv
where 
	i.item_id = io.item_id
	and i.item_id = pv.item_id
	and io.option_group_id = 254
	and i.itemstatus_id IN (0, 1)
	and pv.itemstatus_id IN (0, 1)
group by 
	i.item_id
	, i.name
order by 
	count(pv.productversion_id) desc;


-- Any non-retired items that associated with the "Animal" option group (98), ordered by quantity of total option groups desc
 
select 
	i.item_id
	, count(io.item_id) 
from 
	ecommerce.item as i
	, ecommerce.item_option as io
where 
	i.item_id = io.item_id
	and i.itemstatus_id != 5
	and i.item_id IN (
		select 
			i.item_id 
		from 
			ecommerce.item as i
			, ecommerce.item_option as io
		where 
			i.item_id = io.item_id
			and i.itemstatus_id != 5
			and io.option_group_id = 98
	)
group by 
	i.item_id
order by 
	count(io.item_id) desc;

