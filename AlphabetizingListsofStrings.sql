-- Alphabetizing lists of strings

WITH x(t) AS 
	(
	VALUES
		('recycled')
		, ('organic')
		, ('fair trade')
		, ('solar')
		, ('eco-friendly')
		, ('natural')
		, ('sustainably harvested') 
	)
SELECT 
	t
FROM 
	x
ORDER BY (
	substring(t, '^[0-9]+'))::int
	,substring(t, '[^0-9_].*$');


-- Given a single string, split them apart at the comma, make them lower-case, sort them in alpha order, dedupe them, and return them in one column. 

with z as 
	(
	WITH x as 
		( with t1 AS (
			SELECT 
				'Pink ribbon, paw, autism, Veterans, Military, USA/patriotic, Alzheimers awareness, cat, dog, generic awareness ribbon, diabetes, wildlife, Army, Navy, Air Force, Marines, Coast Guard, Supporting Our Troops, inspirational'::TEXT AS mystring
		), t2 AS (
			SELECT 
				LOWER(TRIM(both ' ' from mystring)) AS mystring FROM t1
		), t3 AS (
			SELECT 
				LOWER(TRIM(both '\t' from mystring)) AS mystring FROM t2
		)
	SELECT 
		regexp_replace(mystring, '(( ){2,}|\t+)', ' ', 'g') as substring 
	FROM 
		t3
	) 
	select 
		regexp_split_to_table(substring, ',') as string from x
	)
select 
	distinct(TRIM(both ' ' from string)) as string 
from 
	z 
order by 
	string asc;


-- Now do the above, only this time put them Into Initial Capitalization (Pascal Case). 

with z as 
	(
	WITH x as 
		( with t1 AS (
			SELECT 
				'Pink ribbon, paw, autism, Veterans, Military, USA/patriotic, Alzheimers awareness, cat, dog, generic awareness ribbon, diabetes, wildlife, Army, Navy, Air Force, Marines, Coast Guard, Supporting Our Troops, inspirational'::TEXT AS mystring
		), t2 AS (
			SELECT 
				initcap(TRIM(both ' ' from mystring)) AS mystring FROM t1
		), t3 AS (
			SELECT 
				initcap(TRIM(both '\t' from mystring)) AS mystring FROM t2
		)
	SELECT 
		regexp_replace(mystring, '(( ){2,}|\t+)', ' ', 'g') as substring 
	FROM 
		t3
	) 
	select 
		regexp_split_to_table(substring, ',') as string from x
	)
select 
	distinct(TRIM(both ' ' from string)) as string 
from 
	z 
order by 
	string asc;
	