<?php
include_once("GameEngine/Generator.php");
$start_timer = $generator->pageLoadTimeStart();

#################################################################################
##              -= YOU MAY NOT REMOVE OR CHANGE THIS NOTICE =-                 ##
## --------------------------------------------------------------------------- ##
##  Filename       : plus.php                      	                           ##
##  Type           : In Game Plus Page                                         ##
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
	header("Location: ".$_SERVER['PHP_SELF']);
	exit;
}
else $building->procBuild($_GET);

// Gold shop: promo-code redemption (player-side). Best-effort; the engine
// self-creates its tables and validates the code (active / expiry / uses /
// once-per-player) before granting gold.
$promoMsg = '';
$promoOk  = false;
if (isset($_POST['redeem_code']) && class_exists('GoldShop')) {
    $__uid = isset($session) && isset($session->uid) ? (int)$session->uid : 0;
    $rr = GoldShop::redeem($__uid, $_POST['redeem_code']);
    $promoOk  = $rr[0];
    $promoMsg = $rr[1];
}

?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html>
<head>
	<title><?php
	echo SERVER_NAME . ' &raquo; &raquo; &raquo; PLUS ';

	if (!empty($_GET['id'])) {
	    switch ($_GET['id']) {
	        case '2':
	            echo 'Advantages';
	            break;

	        case '3':
	            echo 'Gold';
	            break;

	        case '4':
	            echo 'FAQ';
	            break;

	        case '5':
	            echo 'Earn Gold';
	            break;
	    }
	} else {
	    echo 'Tariffs';
	}
	?></title>
	<?php include("Templates/layout/assets.tpl"); ?>
	<script type="text/javascript">

		window.addEvent('domready', start);
	</script>
</head>


<?php include("Templates/layout/page_top.tpl"); ?>
<?php
if(isset($_GET['id'])){
	$id = preg_replace("/[^a-zA-Z0-9_-]/", "", $_GET['id']);
} 
else $id = "";

if(empty($id)) include ("Templates/Plus/1.tpl");

if($id == 1){
	include ("Templates/Plus/3.tpl");
}
if($id == 2){
	include ("Templates/Plus/2.tpl");
}
if($id == 3){
	include ("Templates/Plus/3.tpl");
}
if($id == 4){
	include ("Templates/Plus/4.tpl");
}
if(isset($_GET['mail']) && $id == 5){
	include ("Templates/Plus/invite.tpl");
}else if($id == 5){
	include ("Templates/Plus/5.tpl");
}
if($id == 7){
	include ("Templates/Plus/7.tpl");
}
if($id == 8){
	include ("Templates/Plus/8.tpl");
}
if($id == 9){
	include ("Templates/Plus/9.tpl");
}
if($id == 10){
	include ("Templates/Plus/10.tpl");
}
if($id == 11){
	include ("Templates/Plus/11.tpl");
}
if($id == 12){
	include ("Templates/Plus/12.tpl");
}
/**
 * BUG REPARAT: id-urile 13 si 14 includeau Templates/Plus/13.tpl si 14.tpl,
 * fisiere care NU EXISTA in proiect. Orice acces la plus.php?id=13 dadea
 * eroare fatala si pagina alba.
 *
 * Verificam existenta inainte de includere; daca lipsesc, aratam pagina
 * obisnuita de functii Plus, ca jucatorul sa aiba unde merge.
 */
if($id == 13 || $id == 14){
	$plusExtraTpl = "Templates/Plus/" . (int) $id . ".tpl";

	if (is_file($plusExtraTpl)) {
		include ($plusExtraTpl);
	} else {
		include ("Templates/Plus/3.tpl");
	}
}
if($id == 15){
	include ("Templates/Plus/15.tpl");
}
if($id > 15){
	include ("Templates/Plus/3.tpl");
}
if (isset($_POST['mail'])) {

	$email = trim($_POST['mail']);
	$text = isset($_POST['text']) ? trim($_POST['text']) : '';

	// Blocăm CRLF injection și validăm adresa
	if (
		strpos($email, "\r") === false &&
		strpos($email, "\n") === false &&
		filter_var($email, FILTER_VALIDATE_EMAIL)
	) {
		// Limităm dimensiunea și eliminăm caracterele de control
		$text = substr($text, 0, 2000);
		$text = preg_replace('/[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]/', '', $text);

		$mailer->sendInvite($email, $session->uid, $text);
	}
}
?>

<br /><br /><br /><br /><?php include("Templates/layout/page_bottom.tpl"); ?>
