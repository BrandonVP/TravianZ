<?php
include_once("GameEngine/Generator.php");
$start_timer = $generator->pageLoadTimeStart();

#################################################################################
##              -= YOU MAY NOT REMOVE OR CHANGE THIS NOTICE =-                 ##
## --------------------------------------------------------------------------- ##
##  Filename       : nachrichten.php                  	                       ##
##  Type           : In Game Reports Page                                      ##
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

include_once( "GameEngine/Village.php" );
AccessLogger::logRequest();

$message->procMessage($_POST);

if(isset($_GET['newdid'])){
	$_SESSION['wid'] = $_GET['newdid'];
	if(isset($_GET['t'])){
		header("Location: ".$_SERVER['PHP_SELF']."?t=".$_GET['t']);
		exit();
	}else if(isset($_GET['id']) && $_GET['id'] != 0){
		header("Location: ".$_SERVER['PHP_SELF']."?id=".$_GET['id']);
		exit();
	}else{
		header("Location: ".$_SERVER['PHP_SELF']);
		exit();
	}
}

if(isset($_GET['delfriend']) && is_numeric($_GET['delfriend'])){
	$friend = $database->getUserField($session->uid, "friend".$_GET['delfriend'], 0);
	
	for($i = 0; $i <= 19; $i++){
		$friend1 = $database->getUserField($friend, "friend".$i, 0);
		if($friend1 == $session->uid){
			$database->deleteFriend($friend, "friend".$i);
		}
		$friendwait1 = $database->getUserField($friend, "friend".$i."wait", 0);
		if($friendwait1 == $session->uid){
			$database->deleteFriend($friend, "friend".$i."wait");
		}
		$database->checkFriends($friend);
	}
	
	$database->deleteFriend($session->uid, "friend".$_GET['delfriend']);
	$database->deleteFriend($session->uid, "friend".$_GET['delfriend']."wait");
	$database->checkFriends($session->uid);
	header("Location: ".$_SERVER['PHP_SELF']."?t=1");
	exit();
}

if(isset($_GET['confirm']) && is_numeric($_GET['confirm'])){
	$myid = $database->getUserArray($session->uid, 1);
	$wait = $database->getUserArray($myid['friend'.$_GET['confirm'].'wait'], 1);
	$added = 0;
	
	for($i = 0; $i < 20; $i++){
		$user = $database->getUserField($wait['id'], "friend".$i, 0);
		if($user == $session->uid && $added == 0){
			$database->addFriend($wait['id'], "friend".$i."wait", 0);
			$added = 1;
		}
	}
	
	$database->addFriend($session->uid, "friend".$_GET['confirm'], $wait['id']);
	$database->addFriend($session->uid, "friend".$_GET['confirm']."wait", 0);
	header("Location: ".$_SERVER['PHP_SELF']."?t=1");
	exit();
}
?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html>
<head>
	<title><?php echo SERVER_NAME ?> - Messages</title>
	<?php include("Templates/layout/assets.tpl"); ?>
	<meta name="X-UA-Compatible" content="IE=8" />
	<script type="text/javascript">

		window.addEvent('domready', start);
	</script>
</head>


<?php include("Templates/layout/page_top.tpl"); ?>
<?php
if(isset($_GET['id']) && (!isset($_GET['t']) || $_GET['t'] == '2a')) {
	$message->loadMessage($_GET['id']);
	include("Templates/Message/read.tpl");
}
else if(isset($_GET['t'])) {
	switch($_GET['t']) {
		case 1:
		if(isset($_GET['id'])) {
		    $id = preg_replace("/[^a-zA-Z0-9_-]/","",$_GET['id']);
		}
		include("Templates/Message/write.tpl");
		break;
		case 2:
		include("Templates/Message/sent.tpl");
		break;
		case 3:
		if($session->plus) {
			include("Templates/Message/archive.tpl");
		}
		break;
		case 4:
		if($session->plus) {
			$message->loadNotes();
			include("Templates/Message/notes.tpl");
		}
		break;
		default:
		include("Templates/Message/inbox.tpl");
		break;
	}
}
else {
	include("Templates/Message/inbox.tpl");
}
			?>

<br /><br /><br /><br /><?php include("Templates/layout/page_bottom.tpl"); ?>
