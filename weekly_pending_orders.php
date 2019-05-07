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
    
  	$sql = "select o.date_purchased,op.orders_id,op.products_id,op.products_model,op.products_name,op.final_price as price_after_discount,op.products_quantity,(op.final_price * op.products_quantity) as price_on_invoice from orders o,orders_products op,orders_status os where o.orders_id = op.orders_id and o.orders_status = os.orders_status_id and os.orders_status_name = 'Pending' order by o.date_purchased,o.orders_id";
  	$result = mysql_query($sql);
  	$csvstr = "Date Purchased,Order ID,Product ID,Product Model,Product Name,Product Price,Quantity on Order\n";
	while($row = mysql_fetch_array($result)){
		$csvstr = $csvstr . $row["date_purchased"] . ",";
		$csvstr = $csvstr . $row["orders_id"] . ",";
		$csvstr = $csvstr . $row["products_id"] . ",";
		$csvstr = $csvstr . $row["products_model"] . ",";
		$csvstr = $csvstr . $row["products_name"] . ",";
		$csvstr = $csvstr . $row["price_after_discount"] . ",";
		$csvstr = $csvstr . $row["products_quantity"] . "\n";
	}
	$my_file = "report.csv";
	$fh = fopen($my_file, 'w');
	fwrite($fh, $csvstr);
	fclose($fh);

	$my_path = $_SERVER['DOCUMENT_ROOT']."/reports/";
	$my_name = "Timothy Collins";
	$my_mail = "wookietim@gmail.com";
	$my_replyto = "wookietim@gmail.com";
	$my_subject = "QB PENDING ORDERS!";
	$my_message = "Report on pending orders in OSC";
	mail_attachment($my_file, $my_path, "tcollins@thehungersite.com", $my_mail, $my_name, $my_replyto, $my_subject, $my_message);
	mail_attachment($my_file, $my_path, "jgehrt@qs3.biz", $my_mail, $my_name, $my_replyto, $my_subject, $my_message);
	mail_attachment($my_file, $my_path, "jokantey@qs3.biz", $my_mail, $my_name, $my_replyto, $my_subject, $my_message);
	mail_attachment($my_file, $my_path, "stacey@globalgirlfriend.com", $my_mail, $my_name, $my_replyto, $my_subject, $my_message);
?>
    						