-- Accounts that have written more than one review, and the # of reviews they've written

select 
	ir.account_id
	,a.email
	,count(*) 
From 
	ecommerce.item_review as ir
	,pheme.account as a 
where 
	ir.account_id = a.account_id 
group by 
	ir.account_id
	,a.email 
having 
	count(*) > 1 
order by 
	count(*);
