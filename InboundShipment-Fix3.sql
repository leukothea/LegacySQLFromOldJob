WITH sum_sli AS 
	(  WITH sli_tmp AS 
		(  WITH rec AS 
			(select 
				ii.sku_id
				, (((COALESCE(sli.duty_percent,0.00) * 0.01) * (COALESCE(poli.unitprice,0.00) * sli.quantity))) as sli_duty
				, (sli.quantity * poli.unitprice) as summed_shipment_lineitem_value 
			from 
				ecommerce.inbound_shipment_line_item as sli
				, ecommerce.purchaseorderlineitem as poli
				, ecommerce.receivingevent as re
				, ecommerce.rsinventoryitem as ii 
			where 
				sli.shipment_line_item_id = re.shipment_line_item_id 
				and poli.polineitem_id = re.polineitem_id 
				and poli.sku_id = ii.sku_id  
				and re.receiveddate::DATE >= '03/01/2016'
			group by 
				ii.sku_id
				, sli.duty_percent
				, poli.unitprice
				, sli.quantity 
			order by 
				ii.sku_id asc 
			)
		select 
			poli.polineitem_id as polineitem_id
			, sli.inbound_shipment_id as shipment_id
			, rec.sli_duty
			, rec.summed_shipment_lineitem_value
			, 'true' as true
			, sum(ii.quantity) as remaining_quantity 
		from 
			ecommerce.inbound_shipment_line_item sli
			, ecommerce.purchaseorderlineitem poli INNER JOIN rec ON poli.sku_id = rec.sku_id
			, ecommerce.receivingevent as re
			, ecommerce.rsinventoryitem as ii 
		where 
			sli.po_line_item_id = poli.polineitem_id 
			and poli.polineitem_id = re.polineitem_id 
			and sli.shipment_line_item_id = re.shipment_line_item_id 
			and ii.sku_id = rec.sku_id 
		group by 
			poli.polineitem_id
			, rec.sli_duty
			, rec.summed_shipment_lineitem_value 
			,sli.inbound_shipment_id having sum(ii.quantity) > 0 
		order by 
			sli.inbound_shipment_id asc 
		)
	select 
		sli_tmp.shipment_id
		, sum(sli_tmp.sli_duty) as sli_duty
		, sum(sli_tmp.summed_shipment_lineitem_value) as summed_shipmentlineitem_value
		, sum(sli_tmp.remaining_quantity) as remaining_quantity
		, 'true' as true 
	from 
		sli_tmp 
	where 
		true 
	group by 
		sli_tmp.shipment_id 
	order by 
		sli_tmp.shipment_id asc 
	)
select 
	ibs.inbound_shipment_id as shipment_id
	, COALESCE(ibs.duty_invoice_amount,0.00) as shipment_duty_amount
	, sum_sli.sli_duty as line_item_duty_amount
	,CAST(abs((COALESCE(ibs.duty_invoice_amount,0.00) - (sum_sli.sli_duty))) as numeric(9,2)) as delta 
	,sum_sli.summed_shipmentlineitem_value 
	,sum_sli.remaining_quantity as remaining 
from 
	ecommerce.inbound_shipment as ibs
	, ecommerce.inbound_shipment_line_item as sli LEFT OUTER JOIN sum_sli ON sli.inbound_shipment_id = sum_sli.shipment_id
	, ecommerce.purchaseorderlineitem as poli
	, ecommerce.receivingevent as re 
where 
	ibs.inbound_shipment_id = sli.inbound_shipment_id 
	and poli.polineitem_id = sli.po_line_item_id 
	and ibs.inbound_shipment_id = sum_sli.shipment_id 
	and poli.polineitem_id = re.polineitem_id 
	and (COALESCE(ibs.duty_invoice_amount,0.00) + COALESCE(ibs.additional_duty_amount,0.00) + sum_sli.sli_duty != 0)  
	and ibs.delivery_date::DATE >= '03/01/2016' 
	and sum_sli.true IS NOT NULL  
	and CAST(abs((COALESCE(ibs.duty_invoice_amount,0.00) - (sum_sli.sli_duty))) as numeric(9,2)) > 0.009 
group by 
	ibs.inbound_shipment_id
	, ibs.duty_invoice_amount
	, ibs.additional_duty_amount
	, sum_sli.sli_duty
	, sum_sli.summed_shipmentlineitem_value 
	,sum_sli.remaining_quantity
order by 
	delta desc
 