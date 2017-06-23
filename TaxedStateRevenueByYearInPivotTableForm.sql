-- States we collect tax from, revenue and tax collected by year, in a pivot table (2015-09-18 version)

select
	date_trunc('year',t.trandate)::DATE as Year_Start
	,sum(t.amount * (position(upper(a.state) IN 'AZ') * position('AZ' IN upper(a.state)))) AS AZ_Sales
	,sum(o.tax * (position(upper(a.state) IN 'AZ') * position('AZ' IN upper(a.state)))) AS AZ_Tax
	,sum(t.amount * (position(upper(a.state) IN 'CA') * position('CA' IN upper(a.state)))) AS CA_Sales
	,sum(o.tax * (position(upper(a.state) IN 'CA') * position('CA' IN upper(a.state)))) AS CA_Tax
	,sum(t.amount * (position(upper(a.state) IN 'CO') * position('CO' IN upper(a.state)))) AS CO_Sales
	,sum(o.tax * (position(upper(a.state) IN 'CO') * position('CO' IN upper(a.state)))) AS CO_Tax
	,sum(t.amount * (position(upper(a.state) IN 'IL') * position('IL' IN upper(a.state)))) AS IL_Sales
	,sum(o.tax * (position(upper(a.state) IN 'IL') * position('IL' IN upper(a.state)))) AS IL_Tax
	,sum(t.amount * (position(upper(a.state) IN 'MI') * position('MI' IN upper(a.state)))) AS MI_Sales
	,sum(o.tax * (position(upper(a.state) IN 'MI') * position('MI' IN upper(a.state)))) AS MI_Tax
	,sum(t.amount * (position(upper(a.state) IN 'MN') * position('MN' IN upper(a.state)))) AS MN_Sales
	,sum(o.tax * (position(upper(a.state) IN 'MN') * position('MN' IN upper(a.state)))) AS MN_Tax
	,sum(t.amount * (position(upper(a.state) IN 'NY') * position('NY' IN upper(a.state)))) AS NY_Sales
	,sum(o.tax * (position(upper(a.state) IN 'NY') * position('NY' IN upper(a.state)))) AS NY_Tax
	,sum(t.amount * (position(upper(a.state) IN 'OH') * position('OH' IN upper(a.state)))) AS OH_Sales
	,sum(o.tax * (position(upper(a.state) IN 'OH') * position('OH' IN upper(a.state)))) AS OH_Tax
	,sum(t.amount * (position(upper(a.state) IN 'OR') * position('OR' IN upper(a.state)))) AS OR_Sales
	,sum(o.tax * (position(upper(a.state) IN 'OR') * position('OR' IN upper(a.state)))) AS OR_Tax
	,sum(t.amount * (position(upper(a.state) IN 'PA') * position('PA' IN upper(a.state)))) AS PA_Sales
	,sum(o.tax * (position(upper(a.state) IN 'PA') * position('PA' IN upper(a.state)))) AS PA_Tax
	,sum(t.amount * (position(upper(a.state) IN 'SD') * position('SD' IN upper(a.state)))) AS SD_Sales
	,sum(o.tax * (position(upper(a.state) IN 'SD') * position('SD' IN upper(a.state)))) AS SD_Tax
	,sum(t.amount * (position(upper(a.state) IN 'TX') * position('TX' IN upper(a.state)))) AS TX_Sales
	,sum(o.tax * (position(upper(a.state) IN 'TX') * position('TX' IN upper(a.state)))) AS TX_Tax
	,sum(t.amount * (position(upper(a.state) IN 'UT') * position('UT' IN upper(a.state)))) AS UT_Sales
	,sum(o.tax * (position(upper(a.state) IN 'UT') * position('UT' IN upper(a.state)))) AS UT_Tax
	,sum(t.amount * (position(upper(a.state) IN 'WA') * position('WA' IN upper(a.state)))) AS WA_Sales
	,sum(o.tax * (position(upper(a.state) IN 'WA') * position('WA' IN upper(a.state)))) AS WA_Tax
from
	ecommerce.RSOrder o
	,ecommerce.RSAddress a
	,ecommerce.PaymentAuthorization pa
	,(select authorization_id,tranDate,amount from ecommerce.PaymentTransaction where payment_transaction_result_id = 1 and payment_transaction_type_id = 4
	) t
where
	coalesce(o.shippingAddress_id,o.billingAddress_id) = a.oid
	and o.oid = pa.order_id
	and a.country = 'United States'
	and pa.authorization_id = t.authorization_id
group by
	date_trunc('year',t.trandate)::DATE
order by
	date_trunc('year',t.trandate)::DATE;
	