-- Meta descriptions that don’t start with a capital letter.

select 
	item_id
	,meta_description 
from 
	ecommerce.item
where 
	itemstatus_id IN (0, 1)
	and meta_description ~ '^[a-z].*'
order by 
	meta_description asc;

--> Add the letter F to the beginning of the meta_description for item 57000

update 
	ecommerce.item 
set 
	meta_description = 'F' || meta_description 
where 
	item_id = 57000;


→ Add the letter E to the beginning of the meta_description for any item with a meta_description that starts with “xtend”

update 
	ecommerce.item 
set 
	meta_description = 'E' || meta_description
where 
	meta_description like 'xtend %';