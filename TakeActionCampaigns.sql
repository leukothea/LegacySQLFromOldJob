-- All campaigns ever, with the fields Nikki wants.

select 
	c.title
	, c.campaign_tag
	, s.organization_name
	, ps.abbrv
	, c.date_released
	, c.record_added_by
	, c.date_last_modified
	, c.last_modified_by
	, t.name
	, cc.name
from 
	takeaction.campaign as c
	, takeaction.sponsor as s
	, takeaction.campaign_site as cs
	, takeaction.category as cc
	, takeaction.campaign_category as ccc
	, takeaction.status as t
	, panacea.site as ps
where 
	s.sponsor_id = c.sponsor_id
	and cs.campaign_id = c.campaign_id
	and cc.category_id = ccc.category_id
	and ccc.campaign_id = c.campaign_id
	and t.status_id = c.status_id
	and ps.site_id = cs.site_id;