<?php

#################################################################################
##              -= YOU MAY NOT REMOVE OR CHANGE THIS NOTICE =-                 ##
## --------------------------------------------------------------------------- ##
##  Project:       TravianZ      					       		 		  	   ##
##  Version:       06.05.2026 						       	 				   ##
##  Filename       overview.tpl                                                ##
##  Refactored by  Shadow					                                   ##
##  License:       TravianZ Project                                            ##
##  Copyright:     TravianZ (c) 2010-2026. All rights reserved.                ##
##  URLs:          http://travianz.org						       	 		   ##
##  Source code:   http://github.com/Shadowss/TravianZ/         	       	   ##
##                                                                             ##
#################################################################################

// =========================
// SECURITY: sanitize UID
// =========================
$uid = isset($_GET['uid']) ? (int)$_GET['uid'] : (int)$session->uid;

// =========================
// RANK PROCESS
// =========================
$ranking->procRankReq($_GET);

// ensure safe overwrite
$_GET['uid'] = $uid;

// =========================
// USER DATA
// =========================
$displayarray = $database->getUserArray($uid, 1);
$varmedal     = $database->getProfileMedal($uid);

// =========================
// PROFILE SAFE MERGE
// =========================

// marker legacy (păstrat pentru compatibilitate DB)
$profileSeparator = md5('skJkev3');

// Issue #250: profile descriptions are user-controlled free text. Escape them
// BEFORE any markup expansion so embedded HTML/JS (e.g. a stored
// <details open ontoggle="eval(...)"> payload) is rendered inert, then expand
// the BBCode the form advertises ("Suport BBCode"). The md5 separator and the
// [#..] medal markers carry no HTML/BBCode-special characters, so they survive
// htmlspecialchars()/BBCode.php untouched and are still handled by medal.php.
$input = htmlspecialchars($displayarray['desc1'] ?? '', ENT_QUOTES, 'UTF-8')
       . $profileSeparator
       . htmlspecialchars($displayarray['desc2'] ?? '', ENT_QUOTES, 'UTF-8');
include("GameEngine/BBCode.php");
$profiel = $bbcoded;

// medal.php se ocupă de procesare (NU îi strica inputul)
require("medal.php");

// split DUPĂ medal processing
$profiel = explode($profileSeparator, $profiel);

// safety fallback
if (!isset($profiel[0])) $profiel[0] = '';
if (!isset($profiel[1])) $profiel[1] = '';

// =========================
// VILLAGES + POPULATION
// =========================
$varray = $database->getProfileVillages($uid);
$totalpop = 0;

foreach ($varray as $vil) {
    $totalpop += (int)$vil['pop'];
}
?>

<h1><?php echo PLAYER_PROFILE; ?></h1>

<?php
// =========================
// MENU SWITCH (SELF vs SIT)
// =========================
if ($uid == $session->uid) {
    if ($session->sit == 0) {
        include("menu.tpl");
    } else {
        include("menu2.tpl");
    }
}
?>

<?php
/* =========================
   local redesign: header card, stat tiles, detail chips, description cards
   and village cards instead of the old nested tables
========================= */
$tribeArrays = [TRIBE1, TRIBE2, TRIBE3, TRIBE4, TRIBE5, TRIBE6, TRIBE7, TRIBE8, TRIBE9];
$tribeIndex  = (int) ($displayarray['tribe'] ?? 0) - 1;
$tzTribe     = isset($tribeArrays[$tribeIndex]) ? $tribeArrays[$tribeIndex] : '';

$tzFlags = [];
if ($displayarray['access'] == ADMIN)       $tzFlags[] = ['admin', PROFILE_FLAG_ADMIN];
if ($displayarray['access'] == MULTIHUNTER) $tzFlags[] = ['mh', PROFILE_FLAG_MULTIHUNTER];
if ($displayarray['access'] == BANNED)      $tzFlags[] = ['banned', PROFILE_FLAG_BANNED];
if ($displayarray['vac_mode'] == 1)         $tzFlags[] = ['vac', PROFILE_FLAG_VACATION];

$tzFacts = [];
if ($tzTribe !== '') $tzFacts[] = [TRIBE, $tzTribe];
if (!empty($displayarray['birthday'])) {
    $age = date('Y') - substr($displayarray['birthday'], 0, 4);
    if ((date('m') - substr($displayarray['birthday'], 5, 2)) < 0) $age--;
    elseif ((date('m') - substr($displayarray['birthday'], 5, 2)) == 0) {
        if (date('d') < substr($displayarray['birthday'], 8, 2)) $age--;
    }
    $tzFacts[] = [AGE, (int) $age];
}
if (!empty($displayarray['gender'])) $tzFacts[] = [GENDER, ($displayarray['gender'] == 1) ? MALE : FEMALE];
if (!empty($displayarray['location'])) $tzFacts[] = [LOCATION, htmlspecialchars($displayarray['location'], ENT_QUOTES, 'UTF-8')];

$isNatar  = (isset($displayarray['tribe']) && $displayarray['tribe'] == 5);
$isNature = ($uid == 2);

$tzHasText = function ($html) { return trim(strip_tags($html)) !== '' || strpos($html, '<img') !== false; };
$tzDescMain = $tzHasText($profiel[1]);
$tzDescSide = $tzHasText($profiel[0]);
$tzOasisOn  = defined('NEW_FUNCTIONS_OASIS') && NEW_FUNCTIONS_OASIS;
$tzOasisIcon = [1 => ['r100', '+25% Lumber'], 2 => ['r100', '+25% Lumber'], 3 => ['r200', '+25% Lumber +25% Crop'],
                4 => ['r400', '+25% Clay'], 5 => ['r400', '+25% Clay'], 6 => ['r500', '+25% Clay +25% Crop'],
                7 => ['r700', '+25% Iron'], 8 => ['r700', '+25% Iron'], 9 => ['r800', '+25% Iron +25% Crop'],
                10 => ['r1000', '+25% Crop'], 11 => ['r1000', '+25% Crop'], 12 => ['r1100', '+50% Crop']];
?>

<div class="tz-prof">
    <div class="tz-prof-head">
        <div>
            <div class="tz-prof-name"><?php echo htmlspecialchars($displayarray['username'], ENT_QUOTES, 'UTF-8'); ?>
                <?php foreach ($tzFlags as $f) { ?><span class="tz-prof-flag tz-prof-flag-<?php echo $f[0]; ?>"><?php echo $f[1]; ?></span><?php } ?>
            </div>
            <?php if ($tzFacts) { ?>
            <div class="tz-prof-facts">
                <?php foreach ($tzFacts as $f) { ?><span class="tz-prof-fact"><span><?php echo $f[0]; ?></span> <?php echo $f[1]; ?></span><?php } ?>
            </div>
            <?php } ?>
        </div>
        <div class="tz-prof-action">
        <?php if ($uid == $session->uid) { ?>
            <?php if ($session->sit == 0) { ?><a class="tz-btn" href="spieler.php?s=1"><?php echo CHANGE_PROFILE; ?></a><?php } ?>
        <?php } elseif ($isNatar || $isNature) { ?>
            <span class="tz-prof-dim"><?php echo WRITE_MESSAGE_UNAVAILABLE; ?></span>
        <?php } else { ?>
            <a class="tz-btn" href="nachrichten.php?t=1&amp;id=<?php echo (int) $uid; ?>"><?php echo WRITE_MESSAGE; ?></a>
        <?php } ?>
        </div>
    </div>

    <div class="tz-ally-stats">
        <div class="tz-ally-stat"><span class="tz-ally-k"><?php echo RANK; ?></span><span class="tz-ally-v"><?php echo $ranking->getUserRank($displayarray['id']); ?>.</span></div>
        <div class="tz-ally-stat"><span class="tz-ally-k"><?php echo POP; ?></span><span class="tz-ally-v"><?php echo number_format((int) $totalpop); ?></span></div>
        <div class="tz-ally-stat"><span class="tz-ally-k"><?php echo VILLAGES; ?></span><span class="tz-ally-v"><?php echo count($varray); ?></span></div>
        <div class="tz-ally-stat"><span class="tz-ally-k"><?php echo ALLIANCE; ?></span><span class="tz-ally-v tz-prof-ally"><?php
            if ($displayarray['alliance'] == 0) {
                echo '<span class="tz-prof-dim">-</span>';
            } else {
                echo '<a href="allianz.php?aid=' . (int) $displayarray['alliance'] . '">' . htmlspecialchars($database->getAllianceName($displayarray['alliance']), ENT_QUOTES, 'UTF-8') . '</a>';
            }
        ?></span></div>
    </div>

    <?php if ($tzDescMain || $tzDescSide) { ?>
    <div class="tz-ally-texts">
        <?php if ($tzDescMain) { ?>
        <div class="tz-ally-text">
            <h3><?php echo DESCRIPTION; ?></h3>
            <!-- Issue #250: the "messages" wrapper re-uses the smiley sprite CSS -->
            <div class="tz-ally-body messages" style="padding:0;width:auto"><?php echo nl2br($profiel[1]); ?></div>
        </div>
        <?php } ?>
        <?php if ($tzDescSide) { ?>
        <div class="tz-ally-text">
            <h3>Notes &amp; medals</h3>
            <div class="tz-ally-body messages" style="padding:0;width:auto"><?php echo nl2br($profiel[0]); ?></div>
        </div>
        <?php } ?>
    </div>
    <?php } elseif ($uid == $session->uid && $session->sit == 0) { ?>
    <div class="tz-ally-texts"><div class="tz-ally-text tz-ally-empty">No description yet. <a href="spieler.php?s=1">Write one</a> - other players see it here.</div></div>
    <?php } ?>

    <h2 class="tz-ally-h2"><?php echo VILLAGES; ?> <span><?php echo count($varray); ?></span></h2>
    <div class="tz-prof-villages">
    <?php foreach ($varray as $vil) {
        $coor = $database->getCoor($vil['wref']);
        $tags = [];
        if ($vil['capital'] == 1) $tags[] = CAPITAL_TAG;
        if (defined('NEW_FUNCTIONS_DISPLAY_ARTIFACT') && NEW_FUNCTIONS_DISPLAY_ARTIFACT && $database->villageHasArtefact($vil['wref'])) $tags[] = 'Artifact';
        if (defined('NEW_FUNCTIONS_DISPLAY_WONDER') && NEW_FUNCTIONS_DISPLAY_WONDER && $vil['natar'] == 1) $tags[] = 'WoW';
    ?>
        <div class="tz-prof-village">
            <div class="tz-prof-vname">
                <a href="karte.php?d=<?php echo (int) $vil['wref']; ?>&amp;c=<?php echo $generator->getMapCheck($vil['wref']); ?>"><?php echo htmlspecialchars($vil['name'], ENT_QUOTES, 'UTF-8'); ?></a>
                <?php foreach ($tags as $tg) { ?><span class="tz-ally-role"><?php echo $tg; ?></span><?php } ?>
            </div>
            <div class="tz-ally-mstats">
                <?php echo number_format((int) $vil['pop']); ?> <?php echo strtolower(INHABITANTS); ?> &middot; (<?php echo $coor['x']; ?>|<?php echo $coor['y']; ?>)
                <?php if ($tzOasisOn) { foreach ((array) $database->getOasis($vil['wref']) as $oasis) {
                    $oi = $tzOasisIcon[(int) $oasis['type']] ?? null;
                    if ($oi) echo " <img class='" . $oi[0] . "' src='img/x.gif' title='" . $oi[1] . "' alt=''>";
                } } ?>
            </div>
        </div>
    <?php } ?>
    </div>
</div>
