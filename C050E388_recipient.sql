/*
	C050E388 -- GGO SEM Test 1

	2016-02-04

	All GTGM Customer for past year
*/



/*
	Product Category

	Category_name can be one of GTGM/Disaster,
	GTGM/People, GTGM/Pets, GTGM/Planet, or GTGM/GTGM
*/






		
		
/*
	The Insert Query
		
	The CTE query slots get replaced by one or more of the above queries.
	The CTE selection CTE slots are all occupied by the default SELECT NULL
	queries; these must either remain, or be replaced by a query from above.
	Note that the 388 tags in the CTE templates above that
	will be used need to be changed to an actual effortID.  
*/

SELECT setseed(extract(milliseconds from now()) / 100000);

WITH include1 AS (SELECT DISTINCT psf.customer_key,
	388 AS effort_id
	FROM sales_data_mart.product_dim pdim INNER JOIN sales_data_mart.product_sales_fact psf USING (product_key)
	INNER JOIN sales_data_mart.order_dim odim USING (order_key)
	WHERE pdim.is_gifts_that_give = 'T'
	AND odim.order_date_key >= to_char(now(), 'j')::INT - 364),
	
	include2 AS (SELECT NULL::INT AS customer_key, NULL::INT as effort_id),
	
	exclude1 AS (SELECT NULL::INT AS customer_key, NULL::INT as effort_id),
	
	exclude2 AS (SELECT NULL::INT AS customer_key, NULL::INT as effort_id),
	
	prime_select AS ((SELECT customer_key, effort_id
			FROM include1
		UNION
			SELECT customer_key, effort_id
			FROM include2)
		EXCEPT
			(SELECT customer_key, effort_id
			FROM exclude1
		UNION
			SELECT customer_key, effort_id
			FROM exclude2))
INSERT INTO campaign.effort_recipient (customer_key, effort_id)
SELECT customer_key,
	effort_id
FROM prime_select INNER JOIN campaign.customer_email_address email USING (customer_key)
WHERE email.email_address_status = 0
ORDER BY random()
LIMIT ALL;


/*
	The remainder of these fill out the selection -- update the counts
	and generate the actual recipient dispatch file
*/


/*
	UPDATE the recipient count in the effort table

	The count is obtained in the CTE portion, and inserted
	in the main portion.  NOTE the effortID must be replaced
	by the target effortID
*/

WITH effort_circ AS (SELECT
		effort.campaign_id,
		recip.effort_id,
		count(*) as circ
	FROM campaign.effort effort INNER JOIN campaign.effort_recipient recip
		USING (effort_id)
	WHERE effort.effort_id = 388
	GROUP BY effort.campaign_id, recip.effort_id)
UPDATE campaign.effort
SET target_circulation = effort_circ.circ
FROM effort_circ
WHERE campaign.effort.campaign_id = effort_circ.campaign_id
AND campaign.effort.effort_id = effort_circ.effort_id;


/*
	Pull the list

	The directory is set to the GGO Google Drive for
	transfering dispatch files. The format is set to be variable length
	records (unaligned) with a CRLF record separater (lineending)
	and a tab field separater.  Footer goes off because we don't
	want the record selection count summary to appear in the file

	The \o tag sets the output file, and has two elements:

	<campaignTag>_ggo_sem_test_1.tsv
	
	<campaignTag> :: <campaignIdent><effortIdent>
	<campaignIdent> :: C<campaignID>
	<effortIdent> :: E<effortID>

	The campaignID and effortID elements are left zero filled
	to a fixed four places.

	Effort name are underscore separated words from the actual
	effort name, up to a maximum of about 15 chars or so.
	
	E.G.:  C0028E0074_NAAF_Buildingtsv

	Note that in the query, the campaignID and effortID must be 
	changed.  (Yes, its true, the campaignID is really useless here)

*/
\cd '/Users/catherine/Documents/'
\pset format unaligned
\pset recordsep '\r\n'
\pset fieldsep '\t'
\pset footer off
\o C50E388_ggo_sem_test_1.tsv

SELECT DISTINCT email.email_address
FROM campaign.effort effort INNER JOIN campaign.effort_recipient recipient USING (effort_id)
	INNER JOIN campaign.customer customer USING (customer_key)
		INNER JOIN campaign.customer_email_address email USING (customer_key)
WHERE effort.campaign_id = 50
AND effort.effort_id = 388
ORDER BY email.email_address;
