<?php
include_once("GameEngine/Generator.php");
$start_timer = $generator->pageLoadTimeStart();

#################################################################################
##              -= YOU MAY NOT REMOVE OR CHANGE THIS NOTICE =-                 ##
## --------------------------------------------------------------------------- ##
##  Filename       : dorf3.php                      	                       ##
##  Type           : In Game General View Page                                 ##
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

if(isset($_GET['newdid'])) {
    $_SESSION['wid'] = $_GET['newdid'];
    $database->query("UPDATE ".TB_PREFIX."users SET village_select=".$database->escape((int) $_GET['newdid'])." WHERE id=".$session->uid);  
	if(isset($_GET['s'])){
	header("Location: ".$_SERVER['PHP_SELF']."?s=".$_GET['s']);
	exit;
	}else{
	header("Location: ".$_SERVER['PHP_SELF']);
	exit;
}
}
?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">

<html>
<head>
	<title><?php echo SERVER_NAME ?> - Cross-Village Totals</title>
	<?php include("Templates/layout/assets.tpl"); ?>
	<script type="text/javascript">

		window.addEvent('domready', start);
	</script>
</head>


<?php include("Templates/layout/page_top.tpl"); ?>
<div id="content"  class="village3">

<?php
if($session->plus){
  if(isset($_GET['s'])){
	if($_GET['s'] == 2){
	  include("Templates/dorf3/2.tpl");
	}elseif($_GET['s'] == 3){
	  include("Templates/dorf3/3.tpl");
	}elseif($_GET['s'] == 4){
	  include("Templates/dorf3/4.tpl");
	}elseif($_GET['s'] == 5){
	  include("Templates/dorf3/5.tpl");
	}
  }else{
	include("Templates/dorf3/1.tpl");
  }
}else{
  include("Templates/dorf3/noplus.tpl");
}
?>
</div>

<br /><br /><br /><br /><?php include("Templates/layout/page_bottom.tpl"); ?>
