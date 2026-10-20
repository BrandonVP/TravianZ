<?php
include_once ("GameEngine/Generator.php");
$start_timer = $generator->pageLoadTimeStart();

#################################################################################
##              -= YOU MAY NOT REMOVE OR CHANGE THIS NOTICE =-                 ##
## --------------------------------------------------------------------------- ##
##  Filename       : a2b.php                      	                           ##
##  Type           : In Game Send Attack                                       ##
## --------------------------------------------------------------------------- ##
##  Developed by   : Dzoki & Advocaite & Donnchadh                             ##
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

include_once ("GameEngine/Village.php");
AccessLogger::logRequest();

//Check if a rally point has already been built
if($village->resarray['f39'] == 0){
	header("Location: dorf2.php");
	exit();
}

if(isset($_GET['newdid'])){
	$_SESSION['wid'] = $_GET['newdid'];
	if(isset($_GET['w'])){
		header("Location: ".$_SERVER['PHP_SELF']."?w=".$_GET['w']);
		exit();
	}else if(isset($_GET['r'])){
		header("Location: ".$_SERVER['PHP_SELF']."?r=".$_GET['r']);
		exit();
	}else if(isset($_GET['o'])){
		header("Location: ".$_SERVER['PHP_SELF']."?o=".$_GET['o']);
		exit();
	}else if(isset($_GET['z'])){
		header("Location: ".$_SERVER['PHP_SELF']."?z=".$_GET['z']);
		exit();
	}else if(isset($_GET['id']) && $_GET['id'] > 0){
		header("Location: ".$_SERVER['PHP_SELF']);
		exit();
	}
}
else $building->procBuild($_GET);

if(isset($_GET['id'])) $id = preg_replace("/[^a-zA-Z0-9_-]/", "", $_GET['id']);
if(isset($_GET['w'])) $w = preg_replace("/[^a-zA-Z0-9_-]/", "", $_GET['w']);
if(isset($_GET['r'])) $r = preg_replace("/[^a-zA-Z0-9_-]/", "", $_GET['r']);
if(isset($_GET['delprisoners'])){
	$delprisoners = preg_replace("/[^a-zA-Z0-9_-]/", "", $_GET['delprisoners']);
}
// T4 hero port: release (destroy) captured oasis animals from a nature
// enforcement row (from = 0). Same sanitization as delprisoners.
if(isset($_GET['releaseanimals'])){
	$releaseanimals = preg_replace("/[^0-9]/", "", $_GET['releaseanimals']);
}
if(isset($_GET['o'])){
	$o = preg_replace("/[^a-zA-Z0-9_-]/", "", $_GET['o']);
	$oid = preg_replace("/[^a-zA-Z0-9_-]/", "", $_GET['z']);
	$too = $database->getOasisField($oid, "conqured");
	if($too == 0){
		$disabledr = "disabled=disabled";
		$disabled = "disabled=disabled";
	}else{
		$disabledr = "";
		if($session->sit == 0) $disabled = "";
		else $disabled = "disabled=disabled";
	}
	$checked = "checked=checked";
}else{
	if($session->sit == 0) $disabled = "";
	else $disabled = "disabled=disabled";
}
$process = $units->procUnits($_POST);
?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">

<html>
<head>
<title><?php echo SERVER_NAME.' - Send Troops'?></title>
	<?php include("Templates/layout/assets.tpl"); ?>
	
?>
	<script type="text/javascript">
		window.addEvent('domready', start);
	</script>
</head>


<?php include("Templates/layout/page_top.tpl"); ?>
<?php

?>
<div id="content" class="a2b">
<?php

if(!empty($id)){
	include ("Templates/a2b/newdorf.tpl");
}else if(isset($w)){
	$enforce = $database->getEnforceArray($w, 0);
	if($enforce['vref'] == $village->wid){
		$to = $database->getVillage($enforce['from']);
		$ckey = $w;
		include("Templates/a2b/sendback.tpl");
	}else{
		include("Templates/a2b/units_".$session->tribe.".tpl");
		include("Templates/a2b/search.tpl");
	}
}else if(isset($r)){
	$enforce = $database->getEnforceArray($r, 0);
	$enforceoasis = $database->getOasisEnforceArray($r, 0);
	if($enforce['from'] == $village->wid || $enforceoasis['conqured'] == $village->wid){
		$to = $database->getVillage($enforce['from']);
		$ckey = $r;
		include("Templates/a2b/sendback.tpl");
	}else{
		include ("Templates/a2b/units_".$session->tribe.".tpl");
		include("Templates/a2b/search.tpl");
	}
}else if(isset($delprisoners) && !empty($delprisoners)) $units->deletePrisoners($delprisoners);
else if(isset($releaseanimals) && !empty($releaseanimals)){
	// T4 hero port: destroy captured animals, then back to the rally point.
	$units->releaseNatureEnforcement($releaseanimals);
	header("Location: build.php?id=39");
	exit;
}
else{
	if(isset($process['0'])){
		$coor = $database->getCoor($process['0']);
		include("Templates/a2b/attack.tpl");
	}else{
		include("Templates/a2b/units_".$session->tribe.".tpl");
		include("Templates/a2b/search.tpl");
	}
}
?>

<br />
				<br />
				<br />
				<br />
				<?php include("Templates/layout/page_bottom.tpl"); ?>
