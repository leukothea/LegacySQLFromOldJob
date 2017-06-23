-- Rich's queries about what accounts were recently inserted or updated. He notes, "Here are a couple of queries for querying subscription records that were created and updated on October 7, 2014. By adding additional lines to the where clause and using the less-than symbol you can use a more restrictive time range. Note that subscription records don't reflect exactly-the-same update attempts. In other words if nothing about the subscription record would've changed in the update, no update actually occurs, so the "date_record_modified" timestamp doesn't change."

-- Created:

select 
	s.site_offer_id
	, so.description
	, count(*)
from 
	pheme.subscription s
	, pheme.site_offer so
where 
	s.site_offer_id = so.site_offer_id
	and s.date_record_added > to_timestamp('07 Oct 2014 00:00:00', 'DD Mon YYYY HH24:MI:SS')
group by 
	s.site_offer_id
	, so.description
order by 
	s.site_offer_id;

-- Updated:

select 
	s.site_offer_id
	, so.description
	, count(*)
from 
	pheme.subscription s
	, pheme.site_offer so
where 
	s.site_offer_id = so.site_offer_id
	and s.date_record_added < to_timestamp('07 Oct 2014 00:00:00', 'DD Mon YYYY HH24:MI:SS')
	and s.date_record_modified > to_timestamp('07 Oct 2014 00:00:00', 'DD Mon YYYY HH24:MI:SS')
group by 
	s.site_offer_id
	, so.description
order by 
	s.site_offer_id;
