/*
	CadmusRecipTemplate -- an sql template based on the new query template

	2015-01-29

	This is the new template that will be used in Cadmus when we get around to developing
	that software.

	The theory is the same -- we use CTEs to perform the actual customer selection,
	which are called by an insert query.  However there are some new features for
	this Cadmus version.

	First, the master query now supports four CTEs, two for select, and two for 
	exclusion/suppression (normal DNC suppressions are handled in the main insert
	as always.)  If one of the slots isn't being used, it should use the following
	stub query as a placeholder:

		SELECT NULL::INT as customer_key, NULL::INT as effort_id

	Because the master query uses set operations, this will just pass through.

	Second, we support random selection out of the box, which we do in the main
	query via a sort by random() and a LIMIT TO clause that defaults to ALL in the
	master template.  Now this gets tricky when used with queries that have set ops,
	particularly because when you have queries that are formulated by set ops, 
	can only sort on what is in the SELECT clause, period -- no expressions, formulae
	or sorting on underlying base table columns that do not appear in the select.
	To work around this issue, we put the master set ops query in as a fifth CTE, then
	call that in the main query where we can sort.  Because the CTE is technically 
	a separate query, the sort restrictions will not apply.  (Techically, CTE queries
	are treated as a kind of temp table, and do not appear lexically in the main query,
	it is not a case of substitution.)

	As a minor fix, change the effort tag to simply <targetEffort> and the campaign
	to <targetCampaign> everywhere, that way we can substitute.
*/

/*
	Product Site

	Note this requires the PDI job GtgmProductSite to be run
	before this select can be (accurately) made.  Site are identified
	by their warehouse store site key IDNO's.

	site_abv | store_site_key 
	----------+----------------
	ALZ      |             20
	ARS      |             14
	AUT      |             17
	BCS      |             13
	CHS      |             15
	CK       |             22
	CSS      |              3
	DBS      |             19
	EDS      |              5
	GGF      |              9
	HFL      |             18
	JG       |             21
	KAS      |              2
	LIT      |             25
	LIT      |             16
	MS       |              7
	PRS      |              8
	SB       |             23
	THS      |             11
	TLS      |              4
	TRS      |             12
	TRS      |             24
	VET      |             10

*/

SELECT DISTINCT psf.customer_key,
	<targetEffort> AS effort_id
	FROM lookup.gtgm_item_site_lookup gisl INNER JOIN sales_data_mart.product_dim pdim USING (product_item_key)
		INNER JOIN sales_data_mart.product_sales_fact psf USING (product_key)
		INNER JOIN sales_data_mart.order_dim odim USING (order_key)
		WHERE (gisl.store_site_key = <storeSiteKey>)
		AND odim.order_date_key >= to_char(now(), 'j')::INT - 728


/*
	Product Category

	Category_name can be one of GTGM/Disaster,
	GTGM/People, GTGM/Pets, GTGM/Planet, or GTGM/GTGM
*/

SELECT DISTINCT psf.customer_key,
	<targetEffort> AS effort_id
	FROM sales_data_mart.product_dim pdim INNER JOIN sales_data_mart.product_sales_fact psf USING (product_key)
	INNER JOIN sales_data_mart.order_dim odim USING (order_key)
	WHERE pdim.category_name = '<categoryName>'
	AND odim.order_date_key >= to_char(now(), 'j')::INT - 728



/*
	Product ID list 
	
	This is usually given as a product number (itemID) rather than a 
	warehouse product key because that's all they know down there in
	Tucson.  
*/
	
SELECT DISTINCT psf.customer_key,
	<targetEffort> AS effort_id
	FROM sales_data_mart.product_dim pdim INNER JOIN sales_data_mart.product_sales_fact psf USING (product_key)
		INNER JOIN sales_data_mart.order_dim odim USING (order_key)
	WHERE pdim.product_number IN (<productNumberList>)
		AND odim.order_date_key >= to_char(now(), 'j')::INT - 728
		
		
/*
	The Insert Query
		
	The CTE query slots get replaced by one or more of the above queries.
	The CTE selection CTE slots are all occupied by the default SELECT NULL
	queries; these must either remain, or be replaced by a query from above.
	Note that the <targetEffort> tags in the CTE templates above that
	will be used need to be changed to an actual effortID.  
*/

SELECT setseed(extract(milliseconds from now()) / 100000);

WITH include1 AS (SELECT NULL::INT AS customer_key, NULL::INT as effort_id),
	
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
	WHERE effort.effort_id = <targetEffort>
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

	<campaignTag>_<effortName>.tsv
	
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
\cd '/Users/gdsawyer/Google Drive/Email Recipient Files/'
\pset format unaligned
\pset recordsep '\r\n'
\pset fieldsep '\t'
\pset footer off
\o C<targetCampaign>E<targetEffort>_<effortName>.tsv

SELECT DISTINCT email.email_address
FROM campaign.effort effort INNER JOIN campaign.effort_recipient recipient USING (effort_id)
	INNER JOIN campaign.customer customer USING (customer_key)
		INNER JOIN campaign.customer_email_address email USING (customer_key)
WHERE effort.campaign_id = <targetCampaign>
AND effort.effort_id = <targetEffort>
ORDER BY email.email_address;
