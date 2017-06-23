with all_skus as (
	select 
		distinct audit_date 
	from 
		ecommerce.inventory_audit
), low_skus as (
	select 
		distinct audit_date 
	from 
		ecommerce.inventory_audit 
	group by 
		audit_date having count(*) < 25000
), high_skus as (
	select 
		distinct audit_date 
	from 
		ecommerce.inventory_audit 
	group by 
		audit_date having count(*) >= 25000
) select 
	count(distinct all_skus.audit_date) as count_all_skus
	, count(distinct low_skus.audit_date) as count_low_skus
	, count(distinct high_skus.audit_date) as count_high_skus
from 
	all_skus
	, low_skus
	, high_skus;