<?php
include_once("GameEngine/Generator.php");
$start_timer = $generator->pageLoadTimeStart();

use App\Utils\AccessLogger;

include_once("GameEngine/Village.php");
AccessLogger::logRequest();

if(isset($_GET['newdid'])) {
	$_SESSION['wid'] = $_GET['newdid'];
	header("Location: ".$_SERVER['PHP_SELF']);
	exit;
}
else {
	$building->procBuild($_GET);
}

?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html>
<head>
	<title><?php echo SERVER_NAME ?> - PLUS Packages</title>
	<?php include("Templates/layout/assets.tpl"); ?>
	<script type="text/javascript">

		window.addEvent('domready', start);
	</script>
</head>


<?php include("Templates/layout/page_top.tpl"); ?>
<?php
if(isset($_GET['id'])) {
$id = $_GET['id'];
} else {
$id = "";
}
if ($id == 110) {
include("Templates/Plus/110.tpl");
}
if ($id == 111) {
include("Templates/Plus/111.tpl");
}
if ($id == 112) {
include("Templates/Plus/112.tpl");
}
if ($id == 113) {
include("Templates/Plus/113.tpl");
}
if ($id == 114) {
include("Templates/Plus/114.tpl");
}
if ($id == 116) {
include("Templates/Plus/116.tpl");
}
if ($id == 3110) {
include("Templates/Plus/3110.tpl");
}
?>

<div class="footer-stopper"></div>
<div class="clear"></div>

<?php
include("Templates/footer.tpl");
include("Templates/res.tpl");
?>
<div id="stime" class="tz-rendertime">
<?php echo CALCULATED_IN;?> <b><?php
echo round(($generator->pageLoadTimeEnd()-$start_timer)*1000);
?></b> ms
</div>

<div id="ce"></div>
</body>
</html>
