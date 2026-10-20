<?php
include_once("GameEngine/Generator.php");
$start_timer = $generator->pageLoadTimeStart();

#################################################################################
##              -= YOU MAY NOT REMOVE OR CHANGE THIS NOTICE =-                 ##
## --------------------------------------------------------------------------- ##
##  Filename       : maintenance.php                      	                   ##
##  Type           : In Game Maintenance Page                                  ##
## --------------------------------------------------------------------------- ##
##  Developed by   : iopietro 						                           ##
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

if (!function_exists('mysqli_result')) {
    function mysqli_result($res, $row, $field = 0) {
        $res->data_seek($row);
        $datarow = $res->fetch_array();
        return $datarow[$field];
    }
}

include_once("GameEngine/Village.php");
AccessLogger::logRequest();

if(isset($_GET['newdid'])) {
	$_SESSION['wid'] = $_GET['newdid'];
	header("Location: ".$_SERVER['PHP_SELF']);
	exit;
}

// ==== NOUA VERIFICARE (in loc de $_SESSION['ok']) ====
$maintenance = $database->getMaintenance();
if($maintenance['active'] == 1 && $session->access < 9){
?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html>
	<head>
		<title><?php echo SERVER_NAME ?> - Game Over</title>
	<?php include("Templates/layout/assets.tpl"); ?>
		<script type="text/javascript">window.addEvent('domready', start);</script>
		<style type="text/css">
		.style1 {
		 text-align: center;
		}
		.style2 {
		 border-width: 0px;
		}
		</style>
	</head>
	<?php include("Templates/layout/page_top.tpl"); ?>
				<div id="content" class="village2" style="font-size: 20pt;text-align: center">
					<p><b>Presently, the server is not available due to maintenance.</b></p>
					<img src="img/lol.PNG">
					<p><b>This take a few minutes. In the meantime you can drink a coffee.</b></p>
				</div>
				<br /><br /><br /><br /><?php include("Templates/layout/page_bottom.tpl"); ?>
<?php
}else{
    header("Location: dorf1.php");
    exit;
}
?>