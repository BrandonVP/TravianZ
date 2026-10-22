<?php

#################################################################################
##                -= YOU MAY NOT REMOVE OR CHANGE THIS NOTICE =-               ##
## --------------------------------------------------------------------------- ##
##  Filename       : overview.tpl                                              ##
##  Type           : Alliance Member Overview                                  ##
## --------------------------------------------------------------------------- ##
##  Developed by   : Shadow                                                    ##
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

/*
|--------------------------------------------------------------------------
| TravianZ - Alliance Overview (FINAL STABLE VERSION)
|--------------------------------------------------------------------------
| FIXES:
|   - medals safe
|   - population correct
|   - rank FIX (no more 0)
|   - no breaking DB assumptions
|--------------------------------------------------------------------------
*/

/* =========================
   Alliance ID
========================= */
$aid = isset($_GET['aid']) ? (int)$_GET['aid'] : (int)$session->alliance;

/* =========================
   Load data
========================= */
$allianceinfo = $database->getAlliance($aid);
$memberlist   = $database->getAllMember($aid);

/* safety check */
if (empty($allianceinfo) || $allianceinfo['tag'] == "") {
    header("Location: allianz.php");
    exit;
}

/* =========================
   MEDALS SAFE
========================= */
$varmedal = $database->getProfileMedalAlly($aid);
if (!is_array($varmedal)) {
    $varmedal = [];
}

/* =========================
   POPULATION
========================= */
$totalpop = 0;

foreach ($memberlist as $member) {
    $popData = $database->getVSumField((int)$member['id'], "pop");

    if (is_array($popData)) {
        if (isset($popData[0]['Total'])) {
            $totalpop += (int)$popData[0]['Total'];
        }
    } else {
        $totalpop += (int)$popData;
    }
}

/* =========================
   HEADER
========================= */
echo "<h1>" . htmlspecialchars($allianceinfo['tag']) . " - " . htmlspecialchars($allianceinfo['name']) . "</h1>";

/* =========================
   PROFILE + MEDALS
========================= */
/**
 * FIX SECURITATE (XSS stocat): descrierea aliantei e text liber, scris de
 * conducerea aliantei, si se afisa oricui viziteaza pagina - fara escapare.
 * Un <script> introdus acolo se executa in browserul fiecarui vizitator.
 *
 * Aceeasi problema a fost reparata la profilul de JUCATOR (vezi
 * Templates/Profile/overview.tpl), dar varianta de alianta a fost uitata.
 *
 * Escapam INAINTE de procesarea medaliilor, exact ca acolo: separatorul md5 si
 * marcajele [#..] nu contin caractere speciale HTML, deci trec neatinse prin
 * htmlspecialchars() si medal.php le gaseste asa cum le asteapta.
 */
$profileSeparator = md5('skJkev3');

$profiel = htmlspecialchars($allianceinfo['notice'] ?? '', ENT_QUOTES, 'UTF-8')
         . $profileSeparator
         . htmlspecialchars($allianceinfo['desc'] ?? '', ENT_QUOTES, 'UTF-8');

require("medal.php");

$profiel = explode($profileSeparator, $profiel);

// plasa de siguranta, ca la profilul de jucator
if (!isset($profiel[0])) { $profiel[0] = ''; }
if (!isset($profiel[1])) { $profiel[1] = ''; }

include("alli_menu.tpl");
?>

<?php
/* =========================
   local redesign: stat tiles, leadership, description cards and member
   cards instead of the old nested tables
========================= */
if (!isset($ranking) || !is_object($ranking)) { global $ranking; }
$ranking->getAllianceRank(1); // warm the ranking cache (same as before)
$tzRankValue = (int) $ranking->getAllianceRank((int) $aid);
if ($tzRankValue < 1) $tzRankValue = 1;

$tzLeaders = [];
$tzMembers = [];
$tzVillTotal = 0;
foreach ($memberlist as $member) {
    $muid = (int) $member['id'];
    $mrank = $database->getAlliancePermission($muid, "rank", $aid);
    if ($mrank != '') $tzLeaders[] = [$muid, stripslashes($mrank), $member['username']];
    $popData = $database->getVSumField($muid, "pop");
    $mpop = is_array($popData) ? (isset($popData[0]['Total']) ? (int) $popData[0]['Total'] : 0) : (int) $popData;
    $mvil = count((array) $database->getProfileVillages($muid));
    $tzVillTotal += $mvil;
    $tzMembers[] = ['uid' => $muid, 'name' => $member['username'], 'pop' => $mpop, 'vil' => $mvil,
                    'ts' => (int) $member['timestamp'], 'title' => $mrank != '' ? stripslashes($mrank) : ''];
}
usort($tzMembers, function ($a, $b) { return $b['pop'] <=> $a['pop']; });
$tzOwnAlly = ($aid == $session->alliance);
$tzOnline = function ($ts) {
    $d = time() - $ts;
    if ($d < 600)    return ['on', 'Online now'];
    if ($d < 86400)  return ['day', 'Active today'];
    if ($d < 259200) return ['days3', 'Active in the last 3 days'];
    if ($d < 604800) return ['week', 'Active this week'];
    return ['off', 'Inactive for over a week'];
};
$tzNotice = trim(strip_tags($profiel[0])) !== '' || strpos($profiel[0], '<img') !== false;
$tzDesc   = trim(strip_tags($profiel[1])) !== '' || strpos($profiel[1], '<img') !== false;
?>

<div class="tz-ally">
    <div class="tz-ally-stats">
        <div class="tz-ally-stat"><span class="tz-ally-k"><?php echo RANK; ?></span><span class="tz-ally-v"><?php echo $tzRankValue; ?>.</span></div>
        <div class="tz-ally-stat"><span class="tz-ally-k">Population</span><span class="tz-ally-v"><?php echo number_format((int) $totalpop); ?></span></div>
        <div class="tz-ally-stat"><span class="tz-ally-k"><?php echo TZ_MEMBERS; ?></span><span class="tz-ally-v"><?php echo count($memberlist); ?></span></div>
        <div class="tz-ally-stat"><span class="tz-ally-k"><?php echo VILLAGES; ?></span><span class="tz-ally-v"><?php echo number_format($tzVillTotal); ?></span></div>
    </div>

    <?php if ($tzLeaders || (!empty($allianceinfo['forumlink']) && $allianceinfo['forumlink'] != '0')) { ?>
    <div class="tz-ally-leaders">
        <?php foreach ($tzLeaders as $l) { ?>
            <span class="tz-ally-chip"><span class="tz-ally-chip-k"><?php echo htmlspecialchars($l[1]); ?></span> <a href="spieler.php?uid=<?php echo $l[0]; ?>"><?php echo htmlspecialchars($l[2]); ?></a></span>
        <?php } ?>
        <?php if (!empty($allianceinfo['forumlink']) && $allianceinfo['forumlink'] != '0') { ?>
            <a class="tz-btn tz-btn-sm" href="<?php echo htmlspecialchars($allianceinfo['forumlink']); ?>">External forum &rsaquo;</a>
        <?php } ?>
    </div>
    <?php } ?>

    <div class="tz-ally-texts">
        <?php if ($tzDesc) { ?>
        <div class="tz-ally-text">
            <h3><?php echo DESCRIPTION; ?></h3>
            <div class="tz-ally-body"><?php echo stripslashes(nl2br($profiel[1])); ?></div>
        </div>
        <?php } ?>
        <?php if ($tzNotice) { ?>
        <div class="tz-ally-text">
            <h3>Notice board</h3>
            <div class="tz-ally-body"><?php echo stripslashes(nl2br($profiel[0])); ?></div>
        </div>
        <?php } ?>
        <?php if (!$tzDesc && !$tzNotice) { ?>
        <div class="tz-ally-text tz-ally-empty">
            No description yet.<?php if ($tzOwnAlly && !empty($alliance->userPermArray['opt3'])) { ?> Leaders can add one under <a href="allianz.php?s=5">Options</a> &rsaquo; Change alliance description.<?php } ?>
        </div>
        <?php } ?>
    </div>

    <h2 class="tz-ally-h2"><?php echo TZ_MEMBERS; ?> <span><?php echo count($tzMembers); ?></span></h2>
    <div class="tz-ally-members">
        <?php $n = 0; foreach ($tzMembers as $m) { $n++; $st = $tzOnline($m['ts']); ?>
        <div class="tz-ally-member">
            <span class="tz-ally-pos"><?php echo $n; ?></span>
            <div class="tz-ally-mname">
                <?php if ($tzOwnAlly) { ?><span class="tz-ally-dot tz-ally-<?php echo $st[0]; ?>" title="<?php echo $st[1]; ?>"></span><?php } ?>
                <a href="spieler.php?uid=<?php echo $m['uid']; ?>"><?php echo htmlspecialchars($m['name']); ?></a>
                <?php if ($m['title'] !== '') { ?><span class="tz-ally-role"><?php echo htmlspecialchars($m['title']); ?></span><?php } ?>
            </div>
            <div class="tz-ally-mstats"><?php echo number_format($m['pop']); ?> pop &middot; <?php echo $m['vil']; ?> <?php echo $m['vil'] == 1 ? 'village' : 'villages'; ?></div>
        </div>
        <?php } ?>
    </div>
</div>
