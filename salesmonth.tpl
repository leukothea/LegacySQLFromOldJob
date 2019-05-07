<?php echo $header; ?>
<?php
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
	        //echo "mail send ... OK<br>"; // or use booleans here
	    } else {
	        //echo "mail send ... ERROR!<br>";
	    }
	}

	if(isset($_POST["year"])){
		$year = $_POST["year"];
		$month = $_POST["month"];
	}else{
		$cur_date = getdate();
		$month = $cur_date["mon"];
		$year = $cur_date["year"];
	}
?>
<?php
	$sql = "select distinct op.order_product_id,op.model,op.name as parent_name,o.order_id,c.firstname as customer,DATE(o.date_added) as date_added,op.price,op.quantity,op.model2 from `order` o,order_product op,order_history oh,customer c where o.customer_id = c.customer_id and o.order_id = op.order_id and o.order_id = oh.order_id and oh.order_status_id = 2 and o.return_flag is null and YEAR(oh.date_added) = " . $year . " and MONTH(oh.date_added) = " . $month . " and not o.order_status_id = 18 order by o.order_id";
	$result = mysql_query($sql);
?>
<script>
	function sendmail(){
		document.getElementById("email").value = "ME";
		document.getElementById("filterform").submit();
	}
	function filter(){
		document.getElementById("filterform").submit();
	}
</script>
<div class="box" style='padding-left:30px;padding-right:30px'>
	<div class="heading">
		<div id="download">
			<form method="POST" id="filterform">
				<input type="hidden" id="email" name="email" value="NO">
				<table width='100%'>
					<tr>
						<td align="left">
							Year : 
							<select name="year" id="year">
								<option value="2012">2012</option>
								<option value="2013">2013</option>
								<option value="2014">2014</option>
								<option value="2015">2015</option>
							</select>
						</td>
						<td align="left">
							Month : 
							<select name="month" id="month">
								<option value="1">January</option>
								<option value="2">February</option>
								<option value="3">March</option>
								<option value="4">April</option>
								<option value="5">May</option>
								<option value="6">June</option>
								<option value="7">July</option>
								<option value="8">August</option>
								<option value="9">September</option>
								<option value="10">October</option>
								<option value="11">November</option>
								<option value="12">December</option>
							</select>
						</td>
						<td align='right'>
							[<a href="javascript:filter()">Filter</a>] 
							[<a href="javascript:sendmail()">Email Me</a>]
						</td>
					</tr>
				</table>
			</form>
		</div>
	</div>
	<div style="height:750px;overflow:auto;border:1px solid black">
		<table width='100%' class='list'>
			<thead>
				<tr>
					<td><b>Order ID</b></td>
					<td><b>Product</b></td>
					<td><b>Customer</b></td>
					<td><b>Store</b></td>
					<td><b>Date Created</b></td>
					<td><b>Date Shipped</b></td>
					<td><b>Quantity</b></td>
					<td><b>Price</b></td>
					<td></td>
				</tr>
			</thead>
			<?php
				$csvstr = "order id,customer,store,date created,date shipped,quantity,price\n";
				$total = 0;
				$shipping = 0;
				$row = mysql_fetch_array($result);
				$cur_order = $row["order_id"];
				$result2 = mysql_query("select count(*) as cnt from order_option where order_id = " . $row["order_id"]);
				$row2 = mysql_fetch_array($result2);
				$sql = "select DATE(date_added) as date_shipped from order_history where order_id = " . $row["order_id"];
				$result_history = mysql_query($sql);
				$row_history = mysql_fetch_array($result_history);
				if($row2["cnt"] > 0){
					$result3 = mysql_query("select * from order_option where order_product_id = " . $row["order_product_id"]);
					$row3 = mysql_fetch_array($result3);
					$sku_name = $row3["value"];
				}else{
					$result3 = mysql_query("select ovd.name from product_option_value pov, option_value_description ovd where pov.option_value_id = ovd.option_value_id and pov.model = '". $row["model"] . "'");
					$row3 = mysql_fetch_array($result3);
					$sku_name = $row3["name"];
				}
				echo "<tr>";
				echo "<td>" . $row["order_id"] . "</td>";
				echo "<td>" . $row["parent_name"] . " - " . $sku_name . "</td>";
				echo "<td>" . $row["customer"] . "</td>";
				
				$sql = "select c.parent_id,cd2.name ";
				$sql .= "from product_option_value pov,category_description cd,product p,product_to_category ptc,category c,category_description cd2 ";
				$sql .= "where p.product_id = pov.product_id and p.product_id = ptc.product_id and ptc.category_id = cd.category_id and cd.category_id = c.category_id and c.parent_id = cd2.category_id and pov.model = '" . $row["model2"] ."'";
				$result_store = mysql_query($sql);
				$row_store = mysql_fetch_array($result_store);
				echo "<td>" . $row_store["name"] . "</td>";
				
				echo "<td>" . $row["date_added"] . "</td>";
				echo "<td>" . $row_history["date_shipped"] . "</td>";
				echo "<td>" . $row["quantity"] . "</td>";
				echo "<td>$" . number_format($row["price"],2,'.',',') . "</td>";
				echo "</tr>";
				$total = $total + ($row["quantity"] * $row["price"]);
				$csvstr = $csvstr . $row["order_id"] . ",";
				$csvstr = $csvstr . str_replace(",", " ", $row["customer"]) . ",";
				$csvstr = $csvstr . $row_store["name"] . ",";
				$csvstr = $csvstr . $row["date_added"] . ",";
				$csvstr = $csvstr . $row_history["date_shipped"] . ",";
				$csvstr = $csvstr . $row["quantity"] . ",";
				$csvstr = $csvstr . $row["price"] . "\n";
				while($row = mysql_fetch_array($result)){
					$sql = "select DATE(date_added) as date_shipped from order_history where order_id = " . $row["order_id"];
					$result_history = mysql_query($sql);
					$row_history = mysql_fetch_array($result_history);
					if($cur_order != $row["order_id"]){
						$sql = "select count(*) as cnt from order_total where code in ('shipping','coupon') and order_id = " . $cur_order;
						$result4 = mysql_query($sql);
						$row4 = mysql_fetch_array($result4);
						if($row4["cnt"] > 0){
							$sql = "select * from order_total where code in ('shipping','coupon') and order_id = " . $cur_order;
							$result4 = mysql_query($sql);
							while($row4 = mysql_fetch_array($result4)){
								echo "<tr>";
								echo "<td></td>";
								echo "<td align='right'></td>";
								echo "<td></td>";
								echo "<td></td>";
								echo "<td><b>" . $row4["title"] . "</b></td>";
								echo "<td>$" . number_format($row4["value"],2,'.',',') . "</td>";
								echo "<td></td>";
								echo "</tr>";
								$csvstr = $csvstr . $cur_order . ",";
								$csvstr = $csvstr . "(SHIPPING),";
								$csvstr = $csvstr . ",";
								$csvstr = $csvstr . ",";
								$csvstr = $csvstr . ",";
								$csvstr = $csvstr . $row4["value"] . "\n";
								$shipping = $shipping + $row4["value"];
							}
						}else{
							echo "<tr>";
							echo "<td></td>";
							echo "<td align='right'></td>";
							echo "<td></td>";
							echo "<td></td>";
							echo "<td><b>Flat Shipping Rate</b></td>";
							echo "<td>$0.00</td>";
							echo "<td></td>";
							echo "</tr>";
							$csvstr = $csvstr . $cur_order . ",";
							$csvstr = $csvstr . "(SHIPPING),";
							$csvstr = $csvstr . ",";
							$csvstr = $csvstr . ",";
							$csvstr = $csvstr . ",";
							$csvstr = $csvstr . "0.00\n";
						}
						$cur_order = $row["order_id"];
					}
					$result2 = mysql_query("select count(*) as cnt from order_option where order_id = " . $row["order_id"]);
					$row2 = mysql_fetch_array($result2);
					if($row2["cnt"] > 0){
						$result3 = mysql_query("select * from order_option where order_product_id = " . $row["order_product_id"]);
						$row3 = mysql_fetch_array($result3);
						$sku_name = $row3["value"];
					}else{
						$result3 = mysql_query("select ovd.name from product_option_value pov, option_value_description ovd where pov.option_value_id = ovd.option_value_id and pov.model = '". $row["model"] . "'");
						$row3 = mysql_fetch_array($result3);
						$sku_name = $row3["name"];
					}
					echo "<tr>";
					echo "<td>" . $row["order_id"] . "</td>";
					echo "<td>" . $row["parent_name"] . " - " . $sku_name . "</td>";
					echo "<td>" . $row["customer"] . "</td>";
				
				$sql = "select c.parent_id,cd2.name ";
				$sql .= "from product_option_value pov,category_description cd,product p,product_to_category ptc,category c,category_description cd2 ";
				$sql .= "where p.product_id = pov.product_id and p.product_id = ptc.product_id and ptc.category_id = cd.category_id and cd.category_id = c.category_id and c.parent_id = cd2.category_id and pov.model = '" . $row["model2"] ."'";
				$result_store = mysql_query($sql);
				$row_store = mysql_fetch_array($result_store);
				echo "<td>" . $row_store["name"] . "</td>";
				
					echo "<td>" . $row["date_added"] . "</td>";
					echo "<td>" . $row_history["date_shipped"] . "</td>";
					echo "<td>" . $row["quantity"] . "</td>";
					echo "<td>$" . number_format($row["price"],2,'.',',') . "</td>";
					echo "</tr>";
					$total = $total + ($row["quantity"] * $row["price"]);
					$csvstr = $csvstr . $row["order_id"] . ",";
					$csvstr = $csvstr . str_replace(",", " ", $row["customer"]) . ",";
					$csvstr = $csvstr . $row_store["name"] . ",";
					$csvstr = $csvstr . $row["date_added"] . ",";
					$csvstr = $csvstr . $row_history["date_shipped"] . ",";
					$csvstr = $csvstr . $row["quantity"] . ",";
					$csvstr = $csvstr . $row["price"] . "\n";
				}
				$sql = "select count(*) as cnt from order_total where code in ('shipping','coupon') and order_id = " . $cur_order;
				$result4 = mysql_query($sql);
				$row4 = mysql_fetch_array($result4);
				if($row4["cnt"] > 0){
					$sql = "select * from order_total where code in ('shipping','coupon') and order_id = " . $cur_order;
					$result4 = mysql_query($sql);
					while($row4 = mysql_fetch_array($result4)){
						echo "<tr>";
						echo "<td></td>";
						echo "<td align='right'></td>";
						echo "<td></td>";
						echo "<td></td>";
						echo "<td><b>" . $row4["title"] . "</b></td>";
						echo "<td>$" . number_format($row4["value"],2,'.',',') . "</td>";
						echo "<td></td>";
						echo "</tr>";
						$csvstr = $csvstr . $cur_order . ",";
						$csvstr = $csvstr . "(SHIPPING),";
						$csvstr = $csvstr . ",";
						$csvstr = $csvstr . ",";
						$csvstr = $csvstr . ",";
						$csvstr = $csvstr . $row4["value"] . "\n";
						$shipping = $shipping + $row4["value"];
					}
				}else{
					echo "<tr>";
					echo "<td></td>";
					echo "<td align='right'></td>";
					echo "<td></td>";
					echo "<td></td>";
					echo "<td><b>Flat Shipping Rate</b></td>";
					echo "<td>$0.00</td>";
					echo "<td></td>";
					echo "</tr>";
					$csvstr = $csvstr . $cur_order . ",";
					$csvstr = $csvstr . "(SHIPPING),";
					$csvstr = $csvstr . ",";
					$csvstr = $csvstr . ",";
					$csvstr = $csvstr . ",";
					$csvstr = $csvstr . "0.00\n";
				}
				$overall_total = $total + $shipping;
				$my_file = "sales_shipped_for_month.csv";
				$fh = fopen($my_file, 'w');
				fwrite($fh, $csvstr);
				fclose($fh);
			?>
		</table>
	</div>
	<?php if(isset($_POST["year"])){ ?>
		<div style="text-align:right">
			<br>
			<?php
				$result = mysql_query("select sum(op.quantity * op.price) as total_shipped from `order` o,order_product op,order_history oh,customer c where o.customer_id = c.customer_id and o.order_id = op.order_id and o.order_id = oh.order_id and oh.order_status_id = 2 and o.return_flag is null and YEAR(oh.date_added) = " . $_POST["year"] . " and MONTH(oh.date_added) = " . $_POST["month"] . " and not o.order_status_id = 18 order by o.order_id");
				$row = mysql_fetch_array($result);
				$total = $row["total_shipped"];
			?>
			<b>Total Sales Shipped :</b> $<?php echo number_format($row["total_shipped"],2,'.',','); ?>
		</div>
		<div style="text-align:right">
			<br>
			<?php
				$result = mysql_query("select sum(ot.value) as total from `order` o,order_history oh,customer c,order_total ot where o.order_id = ot.order_id and o.customer_id = c.customer_id and o.order_id = oh.order_id and oh.order_status_id = 2 and o.return_flag is null and ot.code in ('shipping','coupon') and YEAR(oh.date_added) = " . $_POST["year"] . " and MONTH(oh.date_added) = " . $_POST["month"] . " and not o.order_status_id = 18 order by o.order_id");
				$row = mysql_fetch_array($result);
				$shipping_total = $row["total"];
			?>
			<b>Total Shipping :</b> $<?php echo number_format($row["total"],2,'.',','); ?>
		</div>
		<div style="text-align:right">
			<br>
			<?php
				$overall_total = $total + $shipping_total;
			?>
			<b>Gross Sales :</b> $<?php echo number_format($overall_total,2,'.',','); ?>
		</div>
	<?php } ?>
</div>
<script>
	document.getElementById("year").value = "<?php echo $year; ?>";
	document.getElementById("month").value = "<?php echo $month; ?>";
</script>		
<?php
	$my_path = $_SERVER['DOCUMENT_ROOT']."/opencart/admin/";
	$my_name = "Timothy Collins";
	$my_mail = "wookietim@gmail.com";
	$my_replyto = "wookietim@gmail.com";
	$my_subject = "Sales for Month List";
	$my_message = "Sales for Month List";
	if(isset($_POST["email"])){
		if($_POST["email"] == "ME"){
			$user_id = $_SESSION["user_id"];
			$result=mysql_query("select email from user where user_id = " . $user_id);
			$row = mysql_fetch_array($result);
			mail_attachment("sales_shipped_for_month.csv", $my_path, $row["email"], $my_mail, $my_name, $my_replyto, $my_subject, $my_message);
		}
	}
?>