<?php
include_once("GameEngine/Generator.php");
$start_timer = $generator->pageLoadTimeStart();

#################################################################################
##              -= YOU MAY NOT REMOVE OR CHANGE THIS NOTICE =-                 ##
## --------------------------------------------------------------------------- ##
##  Filename       : dorf1.php                      	                       ##
##  Type           : In Game Resource View Page                                ##
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

include_once("GameEngine/Village.php");
AccessLogger::logRequest();

if(isset($_GET['ok'])){
	$database->updateUserField($session->uid,'ok', 0, 1);
	$_SESSION['ok'] = '0';
	// Invalidate the 30s session user-cache (see Session::PopulateVar); otherwise
	// it re-seeds $_SESSION['ok'] from the stale row and the welcome/maintenance
	// redirect keeps firing for up to 30s after acknowledging.
	unset($_SESSION['cache_user_' . ($_SESSION['username'] ?? '')]);
}

if(isset($_GET['newdid'])) {
    $_SESSION['wid'] = $_GET['newdid'];
    $database->query("UPDATE ".TB_PREFIX."users SET village_select=".$database->escape((int) $_GET['newdid'])." WHERE id=".$session->uid);  
	header("Location: ".$_SERVER['PHP_SELF']);
	exit;
} 
else $building->procBuild($_GET);
?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html>
<head>
	<title><?php echo SERVER_NAME . ' - Village overview &raquo; ' . $village->vname; ?></title>
	<?php include("Templates/layout/assets.tpl"); ?>
	<link href="css/fieldmap.css?v=1" rel="stylesheet" type="text/css" />
	<script type="text/javascript">
	window.addEvent('domready', start);
	</script>
</head>


<?php include("Templates/layout/page_top.tpl"); ?>
<div id="content"  class="village1">
<h1><?php echo $village->vname; if($village->loyalty!='100'){ if($village->loyalty>'33'){ $color="gr"; }else{ $color="re"; } ?><div id="loyality" class="<?php echo $color; ?>"><?php echo LOYALTY; ?> <?php echo floor($village->loyalty); ?>%</div><?php } ?></h1>
<div id="cap" align="left"><?php if($village->capital!='0') { echo "<font color=gray>(".CAPITAL1.")</font>"; } ?></div>
<?php include("Templates/field.tpl");
$timer = 1;
?>
<div id="map_details">
<br /><br />
<?php
include("Templates/movement.tpl");
include("Templates/production.tpl");
include("Templates/troops.tpl");

if($building->NewBuilding) include("Templates/Building.tpl");
?>
</div>
<br /><br /><br /><br /><?php include("Templates/layout/page_bottom.tpl"); ?>