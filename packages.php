<?php
include_once("GameEngine/Generator.php");
$start_timer = $generator->pageLoadTimeStart();

#################################################################################
##              -= YOU MAY NOT REMOVE OR CHANGE THIS NOTICE =-                 ##
## --------------------------------------------------------------------------- ##
##  Project:       TravianZ                                                    ##
##  Filename       packages.php                                                ##
##  Developed by:  yi12345                                                     ##
##  License:       TravianZ Project                                            ##
##  Copyright:     TravianZ (c) 2010-2026. All rights reserved.                ##
##  URLs:          http://travian.shadowss.ro                		           ##
##  Source code:   https://github.com/Shadowss/TravianZ		                   ##
##                                                                             ##
#################################################################################

use App\Utils\AccessLogger;

include_once("GameEngine/Village.php");
AccessLogger::logRequest();

$id = $_GET['id'];
?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html>
<head>
	<title><?php echo SERVER_NAME ?> - PLUS packages</title>
	<?php include("Templates/layout/assets.tpl"); ?>
	<script type="text/javascript">
	window.addEvent('domready', start);
	</script>
</head>


<?php include("Templates/layout/page_top.tpl"); ?>
<div id="content"  class="village1">
<?php
if ($id == "") {
include("Templates/Plus/1.tpl");
}
if ($id == 1) {
include("Templates/Packages/3.tpl");
}
if ($id == 2) {
include("Templates/Packages/2.tpl");
}
if ($id == 3) {
include("Templates/Packages/3.tpl");
}
if ($id == 4) {
include("Templates/Packages/4.tpl");
}
if ($id == 5) {
include("Templates/Packages/5.tpl");
}
?>
</div>
<br /><br /><br /><br /><?php include("Templates/layout/page_bottom.tpl"); ?>