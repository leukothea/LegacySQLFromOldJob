<?php echo $header; ?>
<script type="text/javascript" src="/ajax/jscharts.js"></script>
<script type="text/javascript" src="/ajax/jx.js"></script>
<?php
	$result = mysql_query("select product_id,model,vendor_cost from product_option_value group by product_id");
	while($row = mysql_fetch_array($result)){
		$sql = "update product set vendor_cost = " . $row["vendor_cost"] . " where product_id = " . $row["product_id"];
		mysql_query($sql);
	}
?>

<script>
	function filter(){
		url = "index.php?route=report/grossnumbers&token=<?php echo $_GET["token"]; ?>&month=" + document.getElementById("month").value + "&year=" + document.getElementById("year").value;
		document.location = url;
	}
	function send_monthly_coupons(uid,month,year){
		//displaywin = window.open("/ajax/monthly_coupons_ajax.php?uid=" + uid + "&month=" + month + '&year=' + year,'displaywin','width=500,height=300');
		//displaywin.moveTo(screen.width/2-300,screen.height/2-250);
		//displaywin.resizeTo(500,300);
		//document.getElementById(model).style.display = 'inline';
		
		url = "/ajax/monthly_coupons_ajax.php?uid=" + uid + "&month=" + month + '&year=' + year;
		document.getElementById("display_td").innerHTML = "<iframe src='" + url + "'></iframe>";
		document.getElementById("display_table").style.display = "inline";
	}
	function get_more_info(month,year){
		document.getElementById("more_info" + month + year).innerHTML = '<img src="/ajax/pleasewait.gif" id="pleasewait">';
		url = "/ajax/grossnumbers_ajax.php?month=" + month + "&year=" + year;
		jx.load(url, function(data){
			document.getElementById("more_info" + month + year).innerHTML = data;
		});
	}
	function open_stores(year,month){
		displaywin = window.open("/ajax/monthly_numbers_stores.php?month=" + month + '&year=' + year,'displaywin','width=500,height=300');
		displaywin.moveTo(screen.width/2-300,screen.height/2-250);
		displaywin.resizeTo(1300,700);
	}
	function open_count(year,month){
		displaywin = window.open("/ajax/monthly_numbers_by_store_2.php?month=" + month + '&year=' + year,'displaywin','width=500,height=300');
		displaywin.moveTo(screen.width/2-300,screen.height/2-250);
		displaywin.resizeTo(1300,700);
	}
	function open_daily(year,month){
		displaywin = window.open("/ajax/daily_sales_breakdown.php?month=" + month + '&year=' + year,'displaywin','width=500,height=300');
		displaywin.moveTo(screen.width/2-300,screen.height/2-250);
		displaywin.resizeTo(1900,700);
	}
	function close_display_table(){
		document.getElementById("display_table").style.display = "none";
	}
	function open_giveback(year,month){
		displaywin = window.open("/ajax/Give_back_report.php?month=" + month + '&year=' + year,'displaywin','width=500,height=300');
		displaywin.moveTo(screen.width/2-300,screen.height/2-250);
		displaywin.resizeTo(700,500);
	}
</script>
<div style="padding-left:20px;padding-top:20px;padding-right:20px">
	<div class="heading">
		<table width='100%'>
			<tr>
				<td align='left'><h1>Monthly Numbers Report</h1></td>
				<td align='right'>
					Year : 
					<select id="year">
						<option value="2012">2012</option>
						<option value="2013">2013</option>
						<option value="2014">2014</option>
						<option value="2015">2015</option>
					</select> 
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
					[ <a href="javascript:filter()">Filter</a> ]
				</td>
			</tr>
		</table>
	</div>
	<table class='list'>
		<?php
			if(isset($_GET["month"])){
				$sql = "select YEAR(o.date_added) as 'year',MONTH(o.date_added) as 'month',MONTHNAME(o.date_added) as 'month_name', sum(op.price * op.quantity) as total from `order` o,order_product op where o.order_id = op.order_id and (o.return_flag is null or o.return_flag = '') and o.date_added > DATE_SUB(NOW(),INTERVAL 1 YEAR) and not o.order_status_id = 18 and YEAR(o.date_added) = " . $_GET["year"] . " and MONTH(o.date_added) = " . $_GET["month"] . " group by YEAR(o.date_added),MONTH(o.date_added) order by year desc,month desc limit 0,3";
			}else{
				$sql = "select YEAR(o.date_added) as 'year',MONTH(o.date_added) as 'month',MONTHNAME(o.date_added) as 'month_name', sum(op.price * op.quantity) as total from `order` o,order_product op where o.order_id = op.order_id and (o.return_flag is null or o.return_flag = '') and o.date_added > DATE_SUB(NOW(),INTERVAL 1 YEAR) and not o.order_status_id = 18 group by YEAR(o.date_added),MONTH(o.date_added) order by year desc,month desc limit 0,3";
			}
			$result = mysql_query($sql);
			while($row = mysql_fetch_array($result)){
				echo "<thead>";
				echo "<tr>";
				echo "<td><b>Year/Month</b></td>";
				echo "<td><b>Start Inventory Value</b></td>";
				echo "<td><b>Orders Added</b></td>";
				echo "<td><b>PO Receipts</b></td>";
				echo "<td><b>Returns</b></td>";
				echo "<td><b>Returns - Bad</b></td>";
				echo "<td><b>Returns - Restock</b></td>";
				echo "<td><b>Sales Shipped</b></td>";
				echo "<td><b>Sales Paid</b></td>";
				echo "<td><b>Shipping Charges</b></td>";
				echo "</tr>";
				echo "</thead>";
				echo "<tr>";
				echo "<td>" . $row["month_name"] . ", " . $row["year"] . "</td>";
				
				$sql = "SELECT amount as total FROM start_inventory where YEAR(timestamp) = " . $row["year"] . " and MONTH(timestamp) = " . $row["month"] . " order by id asc";
				$results_valuation = mysql_query($sql);
				$row_valuation = mysql_fetch_array($results_valuation);
				echo "<td>$" . number_format($row_valuation["total"],2,'.',',') . "</td>";
				
				$sql = "select sum(value) as total from order_total ot,`order` o where o.order_id = ot.order_id and YEAR(o.date_added) = " . $row["year"] . " and MONTH(o.date_added) = " . $row["month"] . " and code in ('sub_total','coupon') and not o.order_status_id = 18";
				$result_added = mysql_query($sql);
				$row_added = mysql_fetch_array($result_added);
				echo "<td>$" . number_format($row_added["total"],2,'.',',') . "</td>"; 
				
				$sql = "select sum(qty_received * cost) as total from purchase_orders_products where YEAR(date_received) = " . $row["year"] . " and MONTH(date_received) = " . $row["month"];
				$results_receipts = mysql_query($sql);
				$row_receipts = mysql_fetch_array($results_receipts);
				echo "<td>$" . number_format($row_receipts["total"],2,'.',',') . "</td>";

				$sql = "select sum(op.quantity * op.price) as total from `order` o,order_product op,product_option_value pov where o.order_id = op.order_id and op.model = pov.model and o.return_flag = 'YES' and YEAR(o.date_added) = " . $row["year"] . " and MONTH(o.date_added) = " . $row["month"] . " and o.order_status_id in (1,19)";
				$results_returns = mysql_query($sql);
				$row_returns = mysql_fetch_array($results_returns);
				$net_sales_returns = $row_returns["total"];
				$sql = "select sum(op.quantity * op.price) as total from `order` o,order_product op,product_option_value pov where o.order_id = op.order_id and op.model = pov.model and o.return_flag = 'YES' and op.damaged = 'YES' and YEAR(o.date_added) = " . $row["year"] . " and MONTH(o.date_added) = " . $row["month"] . " and o.order_status_id in (1,19)";
				$results_returns_bad = mysql_query($sql);
				$row_returns_bad = mysql_fetch_array($results_returns_bad);
				$sql = "select sum(op.quantity * op.price) as total from `order` o,order_product op,product_option_value pov where o.order_id = op.order_id and op.model = pov.model and o.return_flag = 'YES' and op.restocked = 'YES' and YEAR(o.date_added) = " . $row["year"] . " and MONTH(o.date_added) = " . $row["month"] . " and o.order_status_id in (1,19)";
				$results_returns_restock = mysql_query($sql);
				$row_returns_restock = mysql_fetch_array($results_returns_restock);
				$total_returns = 0;
				$total_returns = $row_returns["total"] - ($row_returns_bad["total"] + $row_returns_restock["total"]);
				if($total_returns > .001){
					$color = 'red';
				}else{
					$color = 'black';
				}
				//$color = 'black';
				echo "<td style='color:" . $color . "'>$" . number_format($row_returns["total"],2,'.',',') . "</td>";
				echo "<td style='color:" . $color . "'>$" . number_format($row_returns_bad["total"],2,'.',',') . "</td>";				
				echo "<td style='color:" . $color . "'>$" . number_format($row_returns_restock["total"],2,'.',',') . "</td>";

				$sql = "select sum(op.price * op.quantity) as total from `order` o,order_product op,order_history oh where o.order_id = op.order_id and o.order_id = oh.order_id and oh.order_status_id = 2 and o.return_flag is null and YEAR(oh.date_added) = " . $row["year"] . " and MONTH(oh.date_added) = " . $row["month"] . " and not o.order_status_id = 18 order by o.order_id";
				$results_shipped = mysql_query($sql);
				$row_shipped = mysql_fetch_array($results_shipped);
				$sql = "select sum(ot.value) as coupon_total from order_total ot,order_history oh,`order` o where ot.order_id = oh.order_id and o.order_id = ot.order_id and o.coupon_used = 'YES' and oh.order_status_id = 2 and ot.code = 'coupon' and MONTH(oh.date_added) = " . $row["month"] . " and YEAR(oh.date_added) = " . $row["year"];
				$results_coupon_total = mysql_query($sql);
				$row_coupon_total = mysql_fetch_array($results_coupon_total);
				$sql = "select sum(ot.value) as coupon_total from order_total ot,order_history oh,`order` o where ot.order_id = oh.order_id and o.order_id = ot.order_id and o.coupon_used = 'BOOK' and oh.order_status_id = 2 and ot.code = 'coupon' and MONTH(oh.date_added) = " . $row["month"] . " and YEAR(oh.date_added) = " . $row["year"];
				$results_book_coupon_total = mysql_query($sql);
				$row_book_coupon_total = mysql_fetch_array($results_book_coupon_total);
				$sql = "select sum(ot.value) as shipping_total from order_total ot,order_history oh,`order` o where ot.order_id = oh.order_id and o.order_id = ot.order_id and o.coupon_used = 'YES' and oh.order_status_id = 2 and ot.code = 'shipping' and MONTH(oh.date_added) = " . $row["month"] . " and YEAR(oh.date_added) = " . $row["year"];
				$results_shipping_total = mysql_query($sql);
				$row_shipping_total = mysql_fetch_array($results_shipping_total);
				$row_shipped_total = ($row_shipped["total"] + ($row_coupon_total["coupon_total"] + $row_shipping_total["shipping_total"])) + $row_book_coupon_total["coupon_total"];
				echo "<td>$" . number_format($row_shipped["total"],2,'.',',') . " <br>$" . number_format($row_shipped_total,2,'.',',') . " after coupons</td>"; 
	
				$sql = "select sum(ot.value) as total from order_history oh,`order` o,order_total ot where o.order_id = oh.order_id and o.order_id = ot.order_id and o.return_flag is null and oh.order_status_id = 17 and ot.code in ('sub_total','shipping','coupon') and YEAR(oh.date_added) = " . $row["year"] . " and MONTH(oh.date_added) = " . $row["month"] . " and not o.order_status_id = 18 and not notify = 1 order by date_paid desc,oh.order_id desc";
				$results_paid = mysql_query($sql);
				$row_paid = mysql_fetch_array($results_paid);
				echo "<td>$" . number_format($row_paid["total"],2,'.',',') . "</td>";
	
				$sql = "select sum(ot.value) as total from `order` o,order_history oh,order_total ot where o.order_id = oh.order_id and ot.order_id = o.order_id and oh.order_status_id = 2 and o.return_flag is null and YEAR(oh.date_added) = " . $row["year"] . " and MONTH(oh.date_added) = " . $row["month"] . " and (ot.code in ('shipping','coupon'))";
				$results_paid = mysql_query($sql);
				$row_paid = mysql_fetch_array($results_paid);
				$shipping_charges = $row_paid["total"];
				echo "<td>$" . number_format($shipping_charges,2,'.',',') . "</td>";

				echo "</tr>";			
				echo "<tr>";
				echo "<td></td>";
				echo "<td colspan='20'>";

				echo "<table width='100%'>";

				$gross_sales = $row_shipped["total"] + $shipping_charges;
				$net_sales = $gross_sales - $net_sales_returns;
				echo "<tr>";
				
				echo "<td width='33%'>";
				echo "<br><b>Gross Sales :</b> $" . number_format($gross_sales,2,'.',',') . " (" . number_format($row_shipped["total"],2,'.',',') . " + " . number_format($shipping_charges,2,'.',',') . ")<br>";
				echo "<b>Net Sales :</b> $" . number_format($net_sales,2,'.',',') . " (Above - " . number_format($net_sales_returns,2,'.',',') . ")<br><br>";
				echo "<a href=javascript:open_stores('" . $row["year"] . "','" . $row["month"] . "')>Drill Down to Stores</a> | ";
				echo "<a href=javascript:open_count('" . $row["year"] . "','" . $row["month"] . "')>Order Count By Store</a> | ";
				echo "<a href=javascript:open_daily('" . $row["year"] . "','" . $row["month"] . "')>Daily Breakdown</a> | <br>";
				echo "<a href=javascript:open_giveback('" . $row["year"] . "','" . $row["month"] . "')>Give Back Report</a> | ";
				echo "</td>";
				
				$result_bads = mysql_query("SELECT sum(b.qty * pov.vendor_cost) as total FROM bads b,product_option_value pov where b.product_id = pov.product_option_value_id and YEAR(b.timestamp) = " . $row["year"] . " and MONTH(b.timestamp) = " . $row["month"] . " and not reason = 'Doubled Rcvng'");
				$row_bads = mysql_fetch_array($result_bads);
				echo "<td width='33%'>";
				echo "<b>Inventory Adjustments COGS :</b> $" . number_format($row_bads["total"],2,'.',',');
				echo "</td>";

				$sql = "SELECT sum(ot.value) as total FROM order_total ot,`order` o,order_history oh where ot.order_id = o.order_id and o.order_id = oh.order_id and ot.code = 'coupon' and oh.order_status_id = 2 and year(oh.date_added) = " . $row["year"] . " and month(oh.date_added) = " . $row["month"];
				$result_coupon = mysql_query($sql);
				$row_coupon = mysql_fetch_array($result_coupon);
				echo "<td width='34%'>";
				echo "<a href=javascript:send_monthly_coupons('" . $_SESSION["user_id"] . "','" . $row["month"] . "','" . $row["year"] . "')>Coupon Report</a><br>";
				echo "<b>Total Coupons including shipping :</b> $" . number_format($row_coupon["total"],2,'.',',');
				echo "</td>";

				echo "</tr>";
				echo "</table>";

				echo "</td>";
				echo "</tr>";
				
				echo "<tr><td colspan='20' id='more_info" . $row["month"] . $row["year"] . "'><a href=javascript:get_more_info('" . $row["month"] . "','" . $row["year"] . "')>Get More Info</a></td></tr>";
				echo "<tr>";
				echo "<td colspan='20' style='background:#cccccc'><hr></td>";
				echo "</tr>";

			}
		?>
	</table>
</div>

<div id="graph" style="border:1px solid black">Loading graph...</div>

<script type="text/javascript">
	<?php
		$sql = "select monthname(o.date_added) as month, sum(value) as total from order_total ot,`order` o where o.order_id = ot.order_id and code in ('sub_total','coupon') and not o.order_status_id = 18 and year(o.date_added) = year(NOW()) group by year(o.date_added), month(o.date_added) order by year(o.date_added), month(o.date_added)";
		$result = mysql_query($sql);
		$mydata = "";
		$xaxiscnt = 0;
		while($row = mysql_fetch_array($result)){
			$xaxiscnt = $xaxiscnt + 1;
			$mydata .= "['" . $row["month"] . "'," . $row["total"] . "],";
		}
		$mydata .= "[0,0]"; 
		$mydata = str_replace(",[0,0]", "",$mydata);
	?>
	<?php if($xaxiscnt > 1){ ?>
		var myData = new Array(<?php echo $mydata; ?>);
		var myChart = new JSChart('graph', 'line');
		myChart.setDataArray(myData);
		myChart.setTitle('Sales by month for this year');
		myChart.setTitleColor('#8E8E8E');
		myChart.setTitleFontSize(11);
		myChart.setAxisNameX('Month');
		myChart.setAxisNameY('Total Sales');
		myChart.setAxisColor('#C4C4C4');
		myChart.setAxisValuesColor('#343434');
		myChart.setAxisPaddingLeft(80);
		myChart.setAxisPaddingRight(60);
		myChart.setAxisPaddingTop(50);
		myChart.setAxisPaddingBottom(40);
		myChart.setAxisValuesNumberX(<?php echo $xaxiscnt; ?>);
		myChart.setGraphExtend(true);
		myChart.setGridColor('#c2c2c2');
		myChart.setLineWidth(4);
		myChart.setLineColor('#9F0505');
		myChart.setSize(1300, 321);
		//myChart.setBackgroundImage('chart_bg.jpg');
		myChart.draw();
	<?php }else{ ?>
		document.getElementById("graph").innerHTML = "No data to graph yet - wait until next month.";
	<?php } ?>
</script>
<?php
	if(isset($_GET["year"])){
		$year = $_GET["year"];
		$month = $_GET["month"];
	}else{
		$cur_date = getdate();
		$month = $cur_date["mon"];
		$year = $cur_date["year"];
	}
?>
<script>
	document.getElementById("year").value = "<?php echo $year; ?>";
	document.getElementById("month").value = "<?php echo $month; ?>";
</script>

<table id="display_table" style="position:fixed;top:175px;left:300px;background:#dddddd;border:2px solid black;display:none;">
	<tr>
		<td align="right"><b><a href="javascript:close_display_table()" style='padding-bottom:10px'>X Close</a></b></td>
	</tr>
	<tr>
		<td id="display_td"></td>
	</tr>
</table>