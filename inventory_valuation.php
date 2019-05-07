<?php
	mysql_connect('greatergood', 'soemoe', '');
    mysql_select_db('greatergoodwholesale');
	function mail_attachment($filename, $path, $mailto, $from_mail, $from_name, $replyto, $subject, $message) {
	    $file = $path.$filename;
	    $file_size = filesize($file);
	    $handle = fopen($file, "r");
	    $content = fread($handle, $file_size);
	    fclose($handle);
	    $content = chunk_split(base64_encode($content));
	    $uid = md5(uniqid(time()));
	    $name = basename($file);
	    $header = "From: ".$from_name." <".$from_mail.">\r\n";
	    $header .= "Reply-To: ".$replyto."\r\n";
	    $header .= "MIME-Version: 1.0\r\n";
	    $header .= "Content-Type: multipart/mixed; boundary=\"".$uid."\"\r\n\r\n";
	    $header .= "This is a multi-part message in MIME format.\r\n";
	    $header .= "--".$uid."\r\n";
	    $header .= "Content-type:text/plain; charset=iso-8859-1\r\n";
	    $header .= "Content-Transfer-Encoding: 7bit\r\n\r\n";
	    $header .= $message."\r\n\r\n";
	    $header .= "--".$uid."\r\n";
	    $header .= "Content-Type: application/octet-stream; name=\"".$filename."\"\r\n"; // use different content types here
	    $header .= "Content-Transfer-Encoding: base64\r\n";
	    $header .= "Content-Disposition: attachment; filename=\"".$filename."\"\r\n\r\n";
	    $header .= $content."\r\n\r\n";
	    $header .= "--".$uid."--";
	    if (mail($mailto, $subject, "", $header)) {
	        echo "mail send ... OK<br>"; // or use booleans here
	    } else {
	        echo "mail send ... ERROR!<br>";
	    }
	}
    
  	$sql = "select p.products_model,pd.products_name,p.products_quantity,p.vendor_price from products p,products_description pd where p.products_id = pd.products_id and products_model > '' order by p.products_model";
  	$result = mysql_query($sql);
  	$csvstr = "Product Model,Product Quantity,Vendor Price\n";
	while($row = mysql_fetch_array($result)){
		if($row["vendor_price"] == ""){
			$price = "0";
		}else{
			$price = $row["vendor_price"];
		}
		$csvstr = $csvstr . $row["products_model"] . ",";
		$csvstr = $csvstr . $row["products_quantity"] . ",";
		$csvstr = $csvstr . $price . "\n";
	}
	$sql = "select sum(p.products_quantity * p.vendor_price) as total from	products p,products_description pd where p.products_id = pd.products_id and products_model > ''";
	$result = mysql_query($sql);
	$row = mysql_fetch_array($result);
	$total = $row["total"];
	$my_file = "inventory_valuation.csv";
	$fh = fopen($my_file, 'w');
	fwrite($fh, $csvstr);
	fclose($fh);

	$my_path = $_SERVER['DOCUMENT_ROOT']."/reports/";
	$my_name = "Timothy Collins";
	$my_mail = "wookietim@gmail.com";
	$my_replyto = "wookietim@gmail.com";
	$my_subject = "Wholesale Inventory Valuation";
	$my_message = "Inventory Valuation for Wholesale : " . $total;
	mail_attachment($my_file, $my_path, "tcollins@thehungersite.com", $my_mail, $my_name, $my_replyto, $my_subject, $my_message);
	mail_attachment($my_file, $my_path, "jgehrt@qs3.biz", $my_mail, $my_name, $my_replyto, $my_subject, $my_message);
	mail_attachment($my_file, $my_path, "stacey@globalgirlfriend.com", $my_mail, $my_name, $my_replyto, $my_subject, $my_message);

	$date_rep = getdate();
	$date_rep_2 = $date_rep["year"] . "-" . $date_rep["mon"] . "-01";
	$sql = "select * from purchase_orders_products where date_received > '" . $date_rep_2 . "'";
	$result = mysql_query($sql);
	$csvstr = "PO Number,Product Model,QTY Expected,QTY Received,Date Received,Vendor Cost\n";
	while($row = mysql_fetch_array($result)){
		$csvstr = $csvstr . $row["purchase_orders_id"] . ",";
		$csvstr = $csvstr . $row["products_model"] . ",";
		$csvstr = $csvstr . $row["qty_expected"] . ",";
		$csvstr = $csvstr . $row["qty_received"] . ",";
		$csvstr = $csvstr . $row["date_received"] . ",";
		$csvstr = $csvstr . $row["cost"] . "\n";
	}
	$sql = "select * from purchase_orders_products_secondary where date_received > '" . $date_rep_2 . "'";
	$result = mysql_query($sql);
	while($row = mysql_fetch_array($result)){
		$csvstr = $csvstr . $row["purchase_orders_id"] . ",";
		$csvstr = $csvstr . $row["products_model"] . ",";
		$csvstr = $csvstr . $row["qty_expected"] . ",";
		$csvstr = $csvstr . $row["qty_received"] . ",";
		$csvstr = $csvstr . $row["date_received"] . ",";
		$csvstr = $csvstr . $row["cost"] . "\n";
	}
	$result = mysql_query($sql);
	$row = mysql_fetch_array($result);
	$total = $row["total"];
	$my_file = "month_receipts.csv";
	$fh = fopen($my_file, 'w');
	fwrite($fh, $csvstr);
	fclose($fh);

	$my_path = $_SERVER['DOCUMENT_ROOT']."/reports/";
	$my_name = "Timothy Collins";
	$my_mail = "wookietim@gmail.com";
	$my_replyto = "wookietim@gmail.com";
	$my_subject = "Wholesale Receipts";
	$my_message = "Inventory receipts ";
	mail_attachment($my_file, $my_path, "tcollins@thehungersite.com", $my_mail, $my_name, $my_replyto, $my_subject, $my_message);
	mail_attachment($my_file, $my_path, "jgehrt@qs3.biz", $my_mail, $my_name, $my_replyto, $my_subject, $my_message);
	mail_attachment($my_file, $my_path, "stacey@globalgirlfriend.com", $my_mail, $my_name, $my_replyto, $my_subject, $my_message);
?>
    						