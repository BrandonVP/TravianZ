<?php
include_once("GameEngine/Generator.php");
$start_timer = $generator->pageLoadTimeStart();

#################################################################################
##              -= YOU MAY NOT REMOVE OR CHANGE THIS NOTICE =-                 ##
## --------------------------------------------------------------------------- ##
##  Filename       : banned.php                      	                       ##
##  Type           : In Game Banned Page                                       ##
## --------------------------------------------------------------------------- ##
##  Developed by   : yi12345     				                               ##
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

if($session->access == BANNED){
?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html>
<head>
	<title><?php echo SERVER_NAME ?> - Player Banned</title>
	<?php include("Templates/layout/assets.tpl"); ?>
	<script type="text/javascript">
	window.addEvent('domready', start);
	</script>
</head>


<?php include("Templates/layout/page_top.tpl"); ?>
<div id="content"  class="village1">
<?php
include("Admin/Templates/ban_msg.tpl");
?>
</div>
<br /><br /><br /><br /><?php include("Templates/layout/page_bottom.tpl"); ?>
<?php
}
else{header("Location: dorf1.php");exit;}?>
