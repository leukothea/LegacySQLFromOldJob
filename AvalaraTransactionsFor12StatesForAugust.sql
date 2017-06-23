with zz as ( 
WITH tax_addresses AS (
select 
    o.oid as order_id
    , COALESCE(o.shippingaddress_id,o.billingaddress_id) as address_id
from 
    ecommerce.paymentauthorization pa
    ,ecommerce.paymenttransaction pt 
    ,ecommerce.rsorder o
where 
    pa.payment_transaction_result_id = 1 
    and pt.trandate >= '2016-07-01 00:00:00.0' 
    and pt.trandate < '2016-08-01 00:00:00.0' 
    and pa.authorization_id = pt.authorization_id
    and pa.order_id = o.oid
), shippingadjustments as (
	select 
		adj.order_id
		, adj.adjustment_type_id
		, adj.amount as adjustment
		, adj.promotion_id 
	from 
		ecommerce.rsadjustment as adj
		where adj.adjustment_type_id = 6
)

(select 
	'3' as ProcessCode
	, o.oid as DocCode
	, 1 as DocType
	, pa.authdate::DATE as DocDate
	, '' as CompanyCode
	, o.account_id as CustomerCode
	, '' as EntityUseCode
	, '' as LineNo
	, tx.tax_code as TaxCode
	, pa.authdate::DATE as TaxDate
	, tx.tax_code as ItemCode
	, pv.name as Description
	, rsli.quantity as Qty
	, (rsli.quantity * rsli.customerprice) as Amount
	, '' as Discount
	, '' as Ref1
	, '' as Ref2
	, '' as ExemptionNo
	, '' as RevAcct
	, a.address1 as DestAddress
	, a.city as DestCity
	, a.state as DestRegion
	, a.zip as DestPostalCode
	, a.iso_country_code as DestCountry
	, '11700 48th Ave' as OrigAddress
	, 'Allendale' as OrigCity
	, 'MI' as OrigRegion
	, '49401-8901' as OrigPostalCode
	, 'US' as OrigCountry
	, '' as LocationCode
	, '' as SalesPersonCode
	, '' as PurchaseOrderNo
	, '' as CurrencyCode
	, '' as ExchangeRate
	, '' as ExchangeRateEffDate
	, '' as PaymentDate
	, 0 as TaxIncluded
	, '' as DestTaxRegion
	, '' as OrigTaxRegion
	, '' as Taxable
	, '' as TaxType
	, rsli.tax as TotalTax
	, '' as CountryName
	, '' as CountryCode
	, '' as CountryRate
	, '' as CountryTax
	, cr.countryregionname as StateName
	, cr.countryregion as StateCode
	, '' as StateRate
	, '' as StateTax
	, '' as CountyName 
	, '' as CountyCode
	, '' as CountyRate
	, '' as CountyTax
	, a.city as CityName
	, '' as CityCode
	, '' as CityRate
	, '' as CityTax
	, '' as Other1Name
	, '' as Other1Code
	, '' as Other1Rate
	, '' as Other1Tax
	, '' as Other2Name
	, '' as Other2Code
	, '' as Other2Rate
	, '' as Other2Tax
	, '' as Other3Name
	, '' as Other3Code
	, '' as Other3Rate
	, '' as Other3Tax
	, '' as Other4Name
	, '' as Other4Code
	, '' as Other4Rate
	, '' as Other4Tax
	, '' as ReferenceCode
	, '' as BuyersVATNo
	, 'TRUE' as IsSellerImporterOfRecord

from 
	ecommerce.productversion as pv
	, ecommerce.rslineitem as rsli
	, ecommerce.rsorder as o 
	, ecommerce.rsaddress as a 
	, ecommerce.paymentauthorization as pa
	, ecommerce.item as i
	, tax_addresses as ta 
	, ecommerce.tax_category as tx
	, ecommerce.countryregion as cr

where
	o.oid = pa.order_id 
	and o.oid = rsli.order_id 
	and o.oid = ta.order_id
	and ta.address_id = a.oid
	and rsli.productversion_id = pv.productversion_id 
	and pv.item_id = i.item_id
	and i.primarycategory_id = tx.tax_category_id
	and pa.authdate >= '2016-07-01'
	and pa.authdate < '2016-08-01'
	and pa.payment_status_id IN (3, 5, 6)
	and pa.payment_transaction_result_id = 1
	and o.store_id IN (11, 12, 14, 15, 16)
	and a.state = cr.countryregion
	and a.state IN ('AZ', 'CA', 'CO', 'IL', 'MI', 'MN', 'NY', 'PA', 'SD', 'TX', 'UT', 'WA')

group by 
	ProcessCode
	, DocCode
	, DocType
	, DocDate
	, CompanyCode
	, o.account_id
	, EntityUseCode
	, LineNo
	, tx.tax_code
	, pa.authdate
	, ItemCode
	, pv.name
	, rsli.quantity
	, rsli.customerprice
	, Discount
	, Ref1
	, Ref2
	, ExemptionNo
	, RevAcct
	, a.address1
	, a.city
	, a.state
	, cr.countryregionname
	, cr.countryregion
	, a.zip
	, a.iso_country_code
	, OrigAddress
	, OrigCity
	, OrigRegion
	, OrigPostalCode
	, OrigCountry
	, LocationCode
	, SalesPersonCode
	, PurchaseOrderNo
	, CurrencyCode
	, ExchangeRate
	, ExchangeRateEffDate
	, pa.authdate
	, TaxIncluded
	, DestTaxRegion
	, OrigTaxRegion
	, i.itembitmask
	, rsli.lineitemtype_id
	, TaxType
	, TotalTax
	, CountryName
	, CountryCode
	, CountryRate
	, CountryTax
	, StateCode
	, StateRate
	, StateTax
	, CountyName
	, CountyCode
	, CountyRate
	, CountyTax
	, CityCode
	, CityRate
	, CityTax
	, Other1Name
	, Other1Code
	, Other1Rate
	, Other1Tax
	, Other2Name
	, Other2Code
	, Other2Rate
	, Other2Tax
	, Other3Name
	, Other3Code
	, Other3Rate
	, Other3Tax
	, Other4Name
	, Other4Code
	, Other4Rate
	, Other4Tax
	, ReferenceCode
	, BuyersVATNo
	, IsSellerImporterOfRecord
order by 
	pa.authdate asc, o.oid asc )
UNION 
( select 
	'3' as ProcessCode
	, o.oid as DocCode
	, 1 as DocType
	, pa.authdate::DATE as DocDate
	, '' as CompanyCode
	, o.account_id as CustomerCode
	, '' as EntityUseCode
	, '' as LineNo
	, '' as TaxCode
	, pa.authdate::DATE as TaxDate
	, '' as ItemCode
	, so.shippingoption as Description
	, '1' as Qty
	, (o.shippingcost - COALESCE(shippingadjustments.adjustment,0.00)) as Amount
	, '' as Discount
	, '' as Ref1
	, '' as Ref2
	, '' as ExemptionNo
	, '' as RevAcct
	, a.address1 as DestAddress
	, a.city as DestCity
	, a.state as DestRegion
	, a.zip as DestPostalCode
	, a.iso_country_code as DestCountry
	, '11700 48th Ave' as OrigAddress
	, 'Allendale' as OrigCity
	, 'MI' as OrigRegion
	, '49401-8901' as OrigPostalCode
	, 'US' as OrigCountry
	, '' as LocationCode
	, '' as SalesPersonCode
	, '' as PurchaseOrderNo
	, '' as CurrencyCode
	, '' as ExchangeRate
	, '' as ExchangeRateEffDate
	, '' as PaymentDate
	, 0 as TaxIncluded
	, '' as DestTaxRegion
	, '' as OrigTaxRegion
	, '' as Taxable
	, '' as TaxType
	, (o.tax - SUM(rsli.tax)) as TotalTax
	, '' as CountryName
	, '' as CountryCode
	, '' as CountryRate
	, '' as CountryTax
	, cr.countryregionname as StateName
	, cr.countryregion as StateCode
	, '' as StateRate
	, '' as StateTax
	, '' as CountyName 
	, '' as CountyCode
	, '' as CountyRate
	, '' as CountyTax
	, a.city as CityName
	, '' as CityCode
	, '' as CityRate
	, '' as CityTax
	, '' as Other1Name
	, '' as Other1Code
	, '' as Other1Rate
	, '' as Other1Tax
	, '' as Other2Name
	, '' as Other2Code
	, '' as Other2Rate
	, '' as Other2Tax
	, '' as Other3Name
	, '' as Other3Code
	, '' as Other3Rate
	, '' as Other3Tax
	, '' as Other4Name
	, '' as Other4Code
	, '' as Other4Rate
	, '' as Other4Tax
	, '' as ReferenceCode
	, '' as BuyersVATNo
	, 'TRUE' as IsSellerImporterOfRecord

from 
	ecommerce.rsorder as o LEFT OUTER JOIN shippingadjustments ON o.oid = shippingadjustments.order_id
	, ecommerce.rsaddress as a
	, tax_addresses as ta 
	, ecommerce.paymentauthorization as pa
	, ecommerce.shippingoption as so
	, ecommerce.rslineitem as rsli
	, ecommerce.countryregion as cr

where
	o.oid = pa.order_id 
	and o.oid = rsli.order_id
	and o.oid = ta.order_id
	and ta.address_id = a.oid
	and o.shipping_option_id = so.shippingoption_id
	and pa.authdate >= '2016-07-01'
	and pa.authdate < '2016-08-01'
	and pa.payment_status_id IN (3, 5, 6)
	and pa.payment_transaction_result_id = 1
	and o.store_id IN (11, 12, 14, 15, 16)
	and a.state = cr.countryregion
	and a.state IN ('AZ', 'CA', 'CO', 'IL', 'MI', 'MN', 'NY', 'PA', 'SD', 'TX', 'UT', 'WA')

group by 
	ProcessCode
	, DocCode
	, DocType
	, DocDate
	, CompanyCode
	, o.account_id
	, EntityUseCode
	, LineNo
	, pa.authdate
	, ItemCode
	, Discount
	, Ref1
	, Ref2
	, ExemptionNo
	, RevAcct
	, a.address1
	, a.city
	, a.state
	, cr.countryregionname
	, cr.countryregion
	, a.zip
	, a.iso_country_code
	, OrigAddress
	, OrigCity
	, OrigRegion
	, OrigPostalCode
	, OrigCountry
	, LocationCode
	, SalesPersonCode
	, PurchaseOrderNo
	, CurrencyCode
	, ExchangeRate
	, ExchangeRateEffDate
	, pa.authdate
	, TaxIncluded
	, DestTaxRegion
	, OrigTaxRegion
	, o.tax
	, o.shipping_option_id
	, so.shippingoption
	, shippingadjustments.adjustment
	, TaxType
	, CountryName
	, CountryCode
	, CountryRate
	, CountryTax
	, StateCode
	, StateRate
	, StateTax
	, CountyName
	, CountyCode
	, CountyRate
	, CountyTax
	, CityCode
	, CityRate
	, CityTax
	, Other1Name
	, Other1Code
	, Other1Rate
	, Other1Tax
	, Other2Name
	, Other2Code
	, Other2Rate
	, Other2Tax
	, Other3Name
	, Other3Code
	, Other3Rate
	, Other3Tax
	, Other4Name
	, Other4Code
	, Other4Rate
	, Other4Tax
	, ReferenceCode
	, BuyersVATNo
	, IsSellerImporterOfRecord
order by 
	pa.authdate, o.oid asc
	) 
) 

select zz.ProcessCode, zz.DocCode, zz.DocType, zz.DocDate, zz.CompanyCode, zz.CustomerCode, zz.EntityUseCode, 
zz.LineNo, zz.TaxCode, zz.TaxDate, zz.ItemCode, zz.Description, zz.Qty, zz.Amount, zz.Discount, zz.Ref1, zz.Ref2, zz.ExemptionNo, zz.RevAcct, 
zz.DestAddress, zz.DestCity, zz.DestRegion, zz.DestPostalCode, zz.DestCountry, zz.OrigAddress, zz.OrigCity, zz.OrigRegion, zz.OrigPostalCode, 
zz.OrigCountry, zz.LocationCode, zz.SalesPersonCode, zz.PurchaseOrderNo, zz.CurrencyCode, zz.ExchangeRate, zz.ExchangeRateEffDate, zz.PaymentDate, 
zz.TaxIncluded, zz.DestTaxRegion, zz.OrigTaxRegion, zz.Taxable, zz.TaxType, zz.TotalTax, zz.CountryName, zz.CountryCode, zz.CountryRate, zz.CountryTax, 
zz.StateName, zz.StateCode, zz.StateRate, zz.StateTax, zz.CountyName, zz.CountyCode, zz.CountyRate, zz.CountyTax, zz.CityName, zz.CityCode, zz.CityRate, 
zz.CityTax, zz.Other1Name, zz.Other1Code, zz.Other1Rate, zz.Other1Tax, zz.Other1Tax, zz.Other2Code, zz.Other2Rate, zz.Other2Tax, zz.Other3Name, zz.Other3Code, 
zz.Other3Rate, zz.Other3Tax, zz.Other4Name, zz.Other4Code, zz.Other4Rate, zz.Other4Tax, zz.ReferenceCode, zz.BuyersVATNo, zz.IsSellerImporterOfRecord
from zz
group by zz.ProcessCode, zz.DocCode, zz.DocType, zz.DocDate, zz.CompanyCode, zz.CustomerCode, zz.EntityUseCode, 
zz.LineNo, zz.TaxCode, zz.TaxDate, zz.ItemCode, zz.Description, zz.Qty, zz.Amount, zz.Discount, zz.Ref1, zz.Ref2, zz.ExemptionNo, zz.RevAcct, 
zz.DestAddress, zz.DestCity, zz.DestRegion, zz.DestPostalCode, zz.DestCountry, zz.OrigAddress, zz.OrigCity, zz.OrigRegion, zz.OrigPostalCode, 
zz.OrigCountry, zz.LocationCode, zz.SalesPersonCode, zz.PurchaseOrderNo, zz.CurrencyCode, zz.ExchangeRate, zz.ExchangeRateEffDate, zz.PaymentDate, 
zz.TaxIncluded, zz.DestTaxRegion, zz.OrigTaxRegion, zz.Taxable, zz.TaxType, zz.TotalTax, zz.CountryName, zz.CountryCode, zz.CountryRate, zz.CountryTax, 
zz.StateName, zz.StateCode, zz.StateRate, zz.StateTax, zz.CountyName, zz.CountyCode, zz.CountyRate, zz.CountyTax, zz.CityName, zz.CityCode, zz.CityRate, 
zz.CityTax, zz.Other1Name, zz.Other1Code, zz.Other1Rate, zz.Other1Tax, zz.Other1Tax, zz.Other2Code, zz.Other2Rate, zz.Other2Tax, zz.Other3Name, zz.Other3Code, 
zz.Other3Rate, zz.Other3Tax, zz.Other4Name, zz.Other4Code, zz.Other4Rate, zz.Other4Tax, zz.ReferenceCode, zz.BuyersVATNo, zz.IsSellerImporterOfRecord
order by zz.doccode asc