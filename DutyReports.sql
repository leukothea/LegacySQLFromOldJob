
select 
	ibs.inbound_shipment_id as shipment_id
	, COALESCE(ibs.duty_invoice_amount,0.00) as shipment_duty_amount
	, sli_tmp.sli_duty as line_item_duty_amount
	,sli_tmp.summed_shipmentlineitem_value 
from 
	ecommerce.inbound_shipment as ibs
	, ecommerce.inbound_shipment_line_item as sli
	, ecommerce.purchaseorderlineitem as poli
	, ecommerce.receivingevent as re 
	,(
		select 
			sli.inbound_shipment_id as shipment_id
			, sum(COALESCE(sli.duty_percent,0.00) *.01 * COALESCE(poli.unitprice) * sli.quantity) as sli_duty
			, sum(coalesce(re.totalreceivedcount * poli.unitprice )) as summed_shipmentlineitem_value 
		from 
			ecommerce.inbound_shipment_line_item sli
			, ecommerce.purchaseorderlineitem poli
			, ecommerce.receivingevent as re 
		where 
			sli.po_line_item_id = poli.polineitem_id 
			and poli.polineitem_id = re.polineitem_id 
			and sli.shipment_line_item_id = re.shipment_line_item_id 
		group by 
			sli.inbound_shipment_id) 
	as sli_tmp 

where 
	ibs.inbound_shipment_id = sli.inbound_shipment_id 
	and poli.polineitem_id = sli.po_line_item_id 
	and ibs.inbound_shipment_id = sli_tmp.shipment_id 
	and poli.polineitem_id = re.polineitem_id 
	and (COALESCE(ibs.duty_invoice_amount,0.00) + COALESCE(ibs.additional_duty_amount,0.00) + sli_tmp.sli_duty != 0)  
	and ibs.date_record_added >= '12/01/2015'
group by 
	ibs.inbound_shipment_id
	, ibs.duty_invoice_amount
	, ibs.additional_duty_amount
	, sli_tmp.sli_duty
	, sli_tmp.summed_shipmentlineitem_value 
order by shipment_id
 

// SECOND QUERY

select 
	ibs.inbound_shipment_id as shipment_id
	, sli_tmp.po_id as po_id
	, sli_tmp.polineitem_id as polineitem_id
	, sli_tmp.description as poli_description
	, COALESCE(ibs.duty_invoice_amount,0.00) as shipment_duty_amount
	, sli_tmp.sli_duty as line_item_duty_amount 
	,sli_tmp.qty_received as qty_received
	, sli_tmp.shipmentlineitem_value as shipmentlineitem_value 
from 
	ecommerce.inbound_shipment as ibs
	, ecommerce.inbound_shipment_line_item as sli
	, ecommerce.purchaseorderlineitem as poli
	, ecommerce.receivingevent as re 
	,(
			select 
				sli.inbound_shipment_id as shipment_id
				, poli.purchaseorder_id as po_id
				, poli.polineitem_id as polineitem_id
				, poli.description
				, sum(COALESCE(sli.duty_percent,0.00) *.01 * COALESCE(poli.unitprice,0.00) * sli.quantity) as sli_duty
				, sum(COALESCE(re.totalreceivedcount,0.00)) as qty_received
				, sum(re.totalreceivedcount * poli.unitprice) as shipmentlineitem_value 
			from 
				ecommerce.inbound_shipment_line_item sli
				, ecommerce.purchaseorderlineitem poli
				, ecommerce.receivingevent as re 
			where 
				sli.po_line_item_id = poli.polineitem_id 
				and poli.polineitem_id = re.polineitem_id 
				and sli.shipment_line_item_id = re.shipment_line_item_id 
			group by 
				sli.inbound_shipment_id
				, poli.purchaseorder_id
				, poli.polineitem_id
				, poli.description
				, re.totalReceivedCount
				, poli.unitprice
		) as sli_tmp 
where 
	ibs.inbound_shipment_id = sli.inbound_shipment_id 
	and poli.polineitem_id = sli.po_line_item_id 
	and ibs.inbound_shipment_id = sli_tmp.shipment_id 
	and poli.polineitem_id = re.polineitem_id 
	and (COALESCE(ibs.duty_invoice_amount,0.00) + COALESCE(ibs.additional_duty_amount,0.00) + sli_tmp.sli_duty != 0)  
	and ibs.date_record_added >= '12/01/2015'
group by 
	ibs.inbound_shipment_id
	, ibs.duty_invoice_amount
	, ibs.additional_duty_amount
	, sli_tmp.sli_duty
	, sli_tmp.po_id
	, sli_tmp.polineitem_id
	, sli_tmp.description
	, sli_tmp.qty_received
	, sli_tmp.shipmentlineitem_value 
order by shipment_id
 