<?php

#################################################################################
##              -= YOU MAY NOT REMOVE OR CHANGE THIS NOTICE =-                 ##
## --------------------------------------------------------------------------- ##
##  Filename       : statistiken.php                                           ##
##  Type           : In Game Statistics Frontend                               ##
## --------------------------------------------------------------------------- ##
##  Developed by   : Dzoki (Original)                                          ##
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

$__start = $generator->pageLoadTimeStart();
if(isset($_GET['rank'])){ $_POST['rank']=$_GET['rank']; }
$_GET['aid'] = $session->alliance;
$_GET['hero'] = count($database->getHero($session->uid));
$ranking->procRankReq($_GET);
$ranking->procRank($_POST);
if(isset($_GET['newdid'])) {
	$_SESSION['wid'] = $_GET['newdid'];
	header("Location: ".$_SERVER['PHP_SELF']."?id=".$_GET['id']);
	exit;
}
?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html>
<head>
	<title><?php
	echo SERVER_NAME . ' &raquo; &raquo; &raquo; ' . STATISTICS . ' (';

if (!empty($_GET['id'])) {
    switch ($_GET['id']) {
        case '4':
            echo ALLIANCES;
            break;
        case '2':
            echo VILLAGES;
            break;
        case '8':
            echo HEROES;
            break;
        case '50':
            echo defined('PLUSSTATS_TITLE') ? PLUSSTATS_TITLE : 'Graphical statistics';
            break;
        case '0':
            echo GENERAL;
            break;
        case '99':
            echo WWS;
            break;
        case '7':
            echo TOP10A;
            break;
        case '31':
            echo TOP10PA;
            break;
        case '32':
            echo TOP10PD;
            break;
		case '41':
            echo TOP10AA;
            break;
        case '42':
            echo TOP10AD;
            break;
        case '43':
            echo TOP10A;
            break;
        case '1':
            echo PLAYERS;
            break;
		case '3':
            echo MILESTONES;
            break;
    }
} else {
    echo PLAYERS;
}

	echo ')';
	?></title>
	<?php include("Templates/layout/assets.tpl"); ?>
	<script type="text/javascript">

		window.addEvent('domready', start);
	</script>
</head>


<?php include("Templates/layout/page_top.tpl"); ?>
		<div id="content"  class="statistics">
<h1><?php echo STATISTICS; ?></h1>
<div id="textmenu">
   <a href="statistiken.php" <?php if(!isset($_GET['id']) || (isset($_GET['id']) && ($_GET['id'] == 1 || $_GET['id'] == 31 || $_GET['id'] == 32 || $_GET['id'] == 7))) { echo "class=\"selected \""; } ?>><?php echo PLAYER; ?></a>
 | <a href="statistiken.php?id=4" <?php if(isset($_GET['id']) && ($_GET['id'] == 4 || $_GET['id'] == 41 || $_GET['id'] == 42 || $_GET['id'] == 43)) { echo "class=\"selected \""; } ?>><?php echo ALLIANCES; ?></a>
 | <a href="statistiken.php?id=2" <?php if(isset($_GET['id']) && $_GET['id'] == 2) { echo "class=\"selected \""; } ?>><?php echo VILLAGES; ?></a>
 | <a href="statistiken.php?id=8" <?php if(isset($_GET['id']) && $_GET['id'] == 8) { echo "class=\"selected \""; } ?>><?php echo HEROES; ?></a>
 | <a href="statistiken.php?id=0" <?php if(isset($_GET['id']) && $_GET['id'] == 0) { echo "class=\"selected \""; } ?>><?php echo GENERAL; ?></a>
<?php if (defined('NEW_FUNCTIONS_MILESTONES') && NEW_FUNCTIONS_MILESTONES): ?>
 | <a href="statistiken.php?id=3"<?php if (isset($_GET['id']) && $_GET['id'] == 3) echo ' class="selected"'; ?>><?php echo MILESTONES; ?></a>
<?php endif; ?>
 <?php if(WW == true) { echo
 '|'; } else { echo ''; } ?> <a href="statistiken.php?id=99" <?php if(isset($_GET['id']) && $_GET['id'] == 99) { echo "class=\"selected \""; } ?>><?php if(WW == true) { echo
 'WW'; } else { echo ''; }?></a>
</div>
<?php
// local redesign: one row of text sub-tabs for the player and alliance
// rankings (replaces the icon buttons inside each table header)
$tzSid = isset($_GET['id']) ? (int) $_GET['id'] : 1;
$tzSub = [];
if (in_array($tzSid, [1, 31, 32, 7, 50, 11, 12, 13, 16, 17, 18, 19], true)) {
    $tzSub = [1 => POP, 31 => ATTACKER, 32 => DEFENDER, 7 => TZ_TOP_10];
    if (defined('NEW_FUNCTIONS_PLUS_STATISTICS') && NEW_FUNCTIONS_PLUS_STATISTICS && !empty($session->plus)) {
        $tzSub[50] = defined('PLUSSTATS_TITLE') ? PLUSSTATS_TITLE : 'Graphs';
    }
    $tzTribes = [11 => TRIBE1, 12 => TRIBE2, 13 => TRIBE3];
    foreach ([16 => ['NEW_FUNCTION_TRIBE_HUNS', TRIBE6], 17 => ['NEW_FUNCTION_TRIBE_EGIPTEANS', TRIBE7],
              18 => ['NEW_FUNCTION_TRIBE_SPARTANS', TRIBE8], 19 => ['NEW_FUNCTION_TRIBE_VIKINGS', TRIBE9]] as $k => $v) {
        if (defined($v[0]) && constant($v[0])) $tzTribes[$k] = $v[1];
    }
} elseif (in_array($tzSid, [4, 41, 42, 43], true)) {
    $tzSub = [4 => POP, 41 => ATTACKER, 42 => DEFENDER, 43 => TZ_TOP_10];
}
if ($tzSub) {
    echo '<div class="tz-stats-sub">';
    foreach ($tzSub as $k => $label) {
        echo '<a href="statistiken.php?id=' . $k . '"' . ($k === $tzSid || ($k === 1 && $tzSid >= 11 && $tzSid <= 19) ? ' class="on"' : '') . '>' . $label . '</a>';
    }
    echo '</div>';
    if (!empty($tzTribes) && ($tzSid === 1 || ($tzSid >= 11 && $tzSid <= 19))) {
        echo '<div class="tz-stats-sub tz-stats-tribes"><a href="statistiken.php?id=1"' . ($tzSid === 1 ? ' class="on"' : '') . '>All tribes</a>';
        foreach ($tzTribes as $k => $label) {
            echo '<a href="statistiken.php?id=' . $k . '"' . ($k === $tzSid ? ' class="on"' : '') . '>' . $label . '</a>';
        }
        echo '</div>';
    }
}
// capture the ranking output to mark ranks 1-3 (gold/silver/bronze badges)
ob_start();
?>
<?php
if(isset($_GET['id'])) {
	switch($_GET['id']) {
		case 31:
			include("Templates/Ranking/player_attack.tpl");
			break;
		case 32:
			include("Templates/Ranking/player_defend.tpl");
			break;
		case 7:
			include("Templates/Ranking/player_top10.tpl");
			break;
		case 2:
			include("Templates/Ranking/villages.tpl");
			break;
		case 3:
			include("Templates/Ranking/milestones.tpl");
			break;
		case 4:
			include("Templates/Ranking/alliance.tpl");
			break;
		case 8:
			include("Templates/Ranking/heroes.tpl");
			break;
		case 11:
			include("Templates/Ranking/player_1.tpl");
			break;
		case 12:
			include("Templates/Ranking/player_2.tpl");
			break;
		case 13:
			include("Templates/Ranking/player_3.tpl");
			break;
		case 16:
			include("Templates/Ranking/player_6.tpl");
			break;
		case 17:
			include("Templates/Ranking/player_7.tpl");
			break;
		case 18:
			include("Templates/Ranking/player_8.tpl");
			break;
		case 19:
			include("Templates/Ranking/player_9.tpl");
			break;
		case 41:
			include("Templates/Ranking/alliance_attack.tpl");
			break;
		case 42:
			include("Templates/Ranking/alliance_defend.tpl");
			break;
		case 43:
			include("Templates/Ranking/ally_top10.tpl");
			break;
		case 50:
			// Statistici grafice (Travian Plus). Sablonul isi verifica singur si
			// flagul, si contul Plus, deci intrarea directa pe URL nu ocoleste nimic.
			include("Templates/Ranking/statistics.tpl");
			break;
		case 0:
			include("Templates/Ranking/general.tpl");
			break;
		case 1:
			include("Templates/Ranking/overview.tpl");
			break;
		case 99:
			include("Templates/Ranking/ww.tpl");
			break;
	}
}
else {
	include("Templates/Ranking/overview.tpl");
}
// local redesign: rank 1-3 cells get a medal class
echo preg_replace_callback('/<td class="ra([^"]*)">\s*([123])\.(&nbsp;)?\s*<\/td>/', function ($m) {
    return '<td class="ra' . $m[1] . ' tz-rank tz-rank' . $m[2] . '"><span>' . $m[2] . '</span></td>';
}, ob_get_clean());
?>
 </div>
						</td>
					</tr>
				</table>
</div>

<br /><br /><br /><br /><?php include("Templates/layout/page_bottom.tpl"); ?>
