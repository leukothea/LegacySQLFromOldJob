WITH tpoq AS
	(select 
		pol.purchaseorder_id as po_id
		, sum(pol.quantityordered) as po_quantity
	from 
		ecommerce.purchaseorderlineitem pol
	group by pol.purchaseorder_id
	)
	
	select 
		sum(poli.unitPrice * poli.quantityOrdered) AS po_value
		, sum(COALESCE(poli.unitSurcharge,0.00) * poli.quantityOrdered + COALESCE(poli.flatratesurcharge,0.00)) + COALESCE(po.flat_rate_surcharge,0.00) + COALESCE(po.flat_rate_surcharge2,0.00) + COALESCE(po.flat_rate_surcharge3,0.00) AS po_charges
		, count(distinct po.purchaseOrder_id) AS po_count
		, sum(poli.unitPrice * poli.quantityOrdered * coalesce(poli.duty_perc,0.00) * 0.01)::numeric(9,4) AS po_duty
		, count(*) AS line_item_count
		, sum(poli.quantityOrdered) AS qty_ordered
		, to_char(po.shipDate::DATE,'YYYY-Q') AS ship_quarter
		, pos.status AS po_status, pt.paymentterms
		, s.supplierName AS supplier_name

	from 
		ecommerce.PurchaseOrder as po
		, ecommerce.purchaseorderlineitem as poli
		, ecommerce.Supplier as s
		, tpoq
		, ecommerce.PurchaseOrderStatus as pos
		, ecommerce.paymentterms as pt
	where 
		tpoq.po_id = po.purchaseorder_id
		and po.supplier_id = s.supplier_id
		and po.shipDate >= '2016-01-01'
		and po.purchaseOrderStatus_id != 6
		and po.purchaseOrderStatus_id = pos.purchaseOrderStatus_id 
		and po.paymentterms_id = pt.paymentterms_id
	group by
		to_char(po.shipDate::DATE,'YYYY-Q')
		, s.supplierName,pos.status
		, pos.status
		, pt.paymentterms
		, po.flat_rate_surcharge
		, po.flat_rate_surcharge2
		, po.flat_rate_surcharge3


sum (sum(poli.unitPrice * poli.quantityOrdered) + (sum(COALESCE(poli.unitSurcharge,0.00) * poli.quantityOrdered + COALESCE(poli.flatratesurcharge,0.00)) + COALESCE(po.flat_rate_surcharge,0.00) + COALESCE(po.flat_rate_surcharge2,0.00) + COALESCE(po.flat_rate_surcharge3,0.00))) as po_grand_total ");