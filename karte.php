<?php
include_once("GameEngine/Generator.php");
$start_timer = $generator->pageLoadTimeStart();

#################################################################################
##              -= YOU MAY NOT REMOVE OR CHANGE THIS NOTICE =-                 ##
## --------------------------------------------------------------------------- ##
##  Filename       : karte.php                      	                       ##
##  Type           : In Game Map View Page                                     ##
## --------------------------------------------------------------------------- ##
##  Developed by   : Dzoki 						                               ##
##  Refactored by  : Shadow                                                    ##
##  Redesign by    : Shadow                                                    ##
## --------------------------------------------------------------------------- ##
##  Contact        : cata7007@gmail.com                                        ##
##  Project        : TravianZ                                                  ##
##  URLs:          : https://travianz.org                                      ##
##  GitHub         : https://github.com/Shadowss/TravianZ                      ##
## --------------------------------------------------------------------------- ##
##  License        : TravianZ Project                                          ##
##  Copyright      : TravianZ (c) 2010-2026. All rights reserved.              ##
## --------------------------------------------------------------------------- ##
#################################################################################

use App\Utils\AccessLogger;

if(isset($_GET['z']) && !is_numeric($_GET['z'])) die('Hacking Attempt');
include_once("GameEngine/Village.php");
AccessLogger::logRequest();

if(isset($_GET['newdid'])) {
	$_SESSION['wid'] = $_GET['newdid'];
if(isset($_GET['d']) && isset($_GET['c'])){
		header("Location: ".$_SERVER['PHP_SELF']."?d=".preg_replace("/[^a-zA-Z0-9_-]/","",$_GET['d'])."&c=".preg_replace("/[^a-zA-Z0-9_-]/","",$_GET['c']));
		exit;
}
else if(isset($_GET['d'])){
		header("Location: ".$_SERVER['PHP_SELF']."?d=".preg_replace("/[^a-zA-Z0-9_-]/","",$_GET['d']));
		exit;
}
else{
	header("Location: ".$_SERVER['PHP_SELF']);
	exit;
}
} else {
	$building->procBuild($_GET);
}
?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html>
<head>
	<title><?php echo SERVER_NAME ?> - World Map</title>
	<?php include("Templates/layout/assets.tpl"); ?>
	<script type="text/javascript">

		window.addEvent('domready', start);
	</script>
</head>


<?php include("Templates/layout/page_top.tpl"); ?>
<?php
if(isset($_GET['d']) && !empty($_GET['d']) && isset($_GET['c']) && !empty($_GET['c'])) {
    if($generator->getMapCheck($_GET['d']) == $_GET['c']) include("Templates/Map/vilview.tpl");
	else 
	{
		header("Location: dorf1.php");
		exit;
	}
}
else {
	include("Templates/Map/mapview.tpl");
}
?>
<br /><br /><br /><br /><?php include("Templates/layout/page_bottom.tpl"); ?>
