<?php

#################################################################################
##              -= YOU MAY NOT REMOVE OR CHANGE THIS NOTICE =-                 ##
## --------------------------------------------------------------------------- ##
##  Project:       TravianZ      					       		 		  	   ##
##  Version:       22.06.2026 						       	 				   ##
##  Filename       general.tpl                                                 ##
##  Refactored by  Shadow					                                   ##
##  License:       TravianZ Project                                            ##
##  Copyright:     TravianZ (c) 2010-2026. All rights reserved.                ##
##  URLs:          http://travianz.org	     				       	 		   ##
##  Source code:   http://github.com/Shadowss/TravianZ/         	       	   ##
##                                                                             ##
#################################################################################

mysqli_report(MYSQLI_REPORT_OFF);

// =========================
// TRIBURI ACTIVE (1-3 mereu; 6-9 doar daca flagul e activ)
// =========================
$activeTribes = [1, 2, 3];
$tribeFlagMap = [
    6 => 'NEW_FUNCTION_TRIBE_HUNS',
    7 => 'NEW_FUNCTION_TRIBE_EGIPTEANS',
    8 => 'NEW_FUNCTION_TRIBE_SPARTANS',
    9 => 'NEW_FUNCTION_TRIBE_VIKINGS',
];
foreach ($tribeFlagMap as $tid => $flag) {
    if (defined($flag) && constant($flag)) $activeTribes[] = $tid;
}
$tribeInList = implode(',', $activeTribes); // ex: "1,2,3,6,7"

// =========================
// TRIBES COUNT
// =========================
$tribes = array_fill(1, 9, 0); // tribes[1..9]
$tribesRes = mysqli_query($database->dblink,
    "SELECT tribe, COUNT(*) AS Total FROM ".TB_PREFIX."users WHERE tribe IN ($tribeInList) GROUP BY tribe");
if ($tribesRes) {
    while ($row = mysqli_fetch_assoc($tribesRes)) {
        $tribes[(int)$row['tribe']] = (int)$row['Total'];
    }
}

$userRes = mysqli_query($database->dblink,
    "SELECT COUNT(*) AS Total FROM ".TB_PREFIX."users WHERE tribe IN ($tribeInList)");
$users = $userRes? (int)mysqli_fetch_assoc($userRes)['Total'] : 0;

// =========================
// VILLAGES + POPULATION
// =========================
$villageRes = mysqli_query($database->dblink, "SELECT COUNT(*) AS Total FROM ".TB_PREFIX."vdata");
$num_villages = $villageRes? (int)mysqli_fetch_assoc($villageRes)['Total'] : 0;

$popRes = mysqli_query($database->dblink, "SELECT SUM(pop) AS totalpop FROM ".TB_PREFIX."vdata");
$total_pop = $popRes? (int)mysqli_fetch_assoc($popRes)['totalpop'] : 0;

// =========================
// ONLINE / ACTIVE USERS
// =========================
$active = 0; 
$res = mysqli_query($database->dblink,
    "SELECT COUNT(*) AS Total FROM ".TB_PREFIX."users WHERE timestamp > ".(time()-86400)." AND tribe IN ($tribeInList)");
if($res) 
	$active = (int)mysqli_fetch_assoc($res)['Total'];

$online = 0; 
$res = mysqli_query($database->dblink,
    "SELECT COUNT(*) AS Total FROM ".TB_PREFIX."users WHERE timestamp > ".(time()-600)." AND tribe IN ($tribeInList)");
if($res) $online = (int)mysqli_fetch_assoc($res)['Total'];

// =========================
// GOLD TOTAL
// =========================
$goldRes = mysqli_query($database->dblink, "SELECT SUM(gold) AS totalgold FROM ".TB_PREFIX."users");
$total_gold = $goldRes? (int)mysqli_fetch_assoc($goldRes)['totalgold'] : 0;

// =========================
// 2026 - NEW STATISTICS
// =========================
$daysSinceStart = defined('COMMENCE')? floor((time()-COMMENCE)/86400) : 0;

// Natars
$natars = 0; 
$q = mysqli_query($database->dblink, "SELECT COUNT(*) AS n FROM ".TB_PREFIX."vdata WHERE natar=1");
if($q) 
	$natars = (int)mysqli_fetch_assoc($q)['n'];

// Occupied Oasis
$oasis = 0;
$q = mysqli_query($database->dblink,
    "SELECT COUNT(*) AS o 
     FROM ".TB_PREFIX."odata 
     WHERE owner <> 2 AND owner <> 0 AND owner IS NOT NULL");
if($q) $oasis = (int)mysqli_fetch_assoc($q)['o'];

// Alliances
$alliCount = 0; 
$q = mysqli_query($database->dblink, "SELECT COUNT(*) AS a FROM ".TB_PREFIX."alidata");
if($q) 
	$alliCount = (int)mysqli_fetch_assoc($q)['a'];

$topAlliances = [];
$q = mysqli_query($database->dblink,
    "SELECT a.tag, a.name, COUNT(u.id) AS members FROM ".TB_PREFIX."alidata a
     LEFT JOIN ".TB_PREFIX."users u ON u.alliance=a.id
     GROUP BY a.id ORDER BY members DESC LIMIT 5");
if($q) while($r=mysqli_fetch_assoc($q)) 
	$topAlliances[] = $r;

// New Players Today
$newToday = 0; 
$q = mysqli_query($database->dblink,
    "SELECT COUNT(*) AS n FROM ".TB_PREFIX."users WHERE regtime > ".(time()-86400)." AND tribe IN ($tribeInList)");
if($q) 
	$newToday = (int)mysqli_fetch_assoc($q)['n'];

// Top 10
$topPop = [];
$q = mysqli_query($database->dblink,
    "SELECT u.username, COALESCE(SUM(v.pop),0) AS totalpop
     FROM ".TB_PREFIX."users u
     LEFT JOIN ".TB_PREFIX."vdata v ON v.owner = u.id
     WHERE u.tribe IN ($tribeInList)
     GROUP BY u.id
     ORDER BY totalpop DESC
     LIMIT 10");
if($q) while($r = mysqli_fetch_assoc($q)) 
	$topPop[] = $r;

$topAtk = [];
$q = mysqli_query($database->dblink,
    "SELECT username, ap AS points 
     FROM ".TB_PREFIX."users 
     WHERE tribe IN ($tribeInList) 
     ORDER BY ap DESC 
     LIMIT 10");
if($q) while($r = mysqli_fetch_assoc($q)) 
	$topAtk[] = $r;

$topDef = [];
$q = mysqli_query($database->dblink,
    "SELECT username, dp AS points 
     FROM ".TB_PREFIX."users 
     WHERE tribe IN ($tribeInList) 
     ORDER BY dp DESC 
     LIMIT 10");
if($q) while($r = mysqli_fetch_assoc($q)) 
	$topDef[] = $r;

// WW
$wonders=[]; $q=mysqli_query($database->dblink,
    "SELECT v.name AS village, u.username, f.f99 AS level
     FROM ".TB_PREFIX."fdata f
     JOIN ".TB_PREFIX."vdata v ON f.vref=v.wref
     JOIN ".TB_PREFIX."users u ON v.owner=u.id
     WHERE f.f99t=40 AND f.f99>0 ORDER BY f.f99 DESC LIMIT 3");
if($q) while($r=mysqli_fetch_assoc($q)) 
	$wonders[]=$r;

// Artefacts
$artefacts=[]; 
$q=mysqli_query($database->dblink,
    "SELECT a.name, u.username FROM ".TB_PREFIX."artefacts a
     LEFT JOIN ".TB_PREFIX."users u ON a.owner=u.id WHERE a.active=1 LIMIT 5");
if($q) while($r=mysqli_fetch_assoc($q)) 
	$artefacts[]=$r;

// Troops (toate unitatile 1-90, insumate)
$units=[]; 
$result = mysqli_query($database->dblink, "SELECT " . implode(',', array_map(fn($i) => "SUM(u$i) AS u$i",range(1,90)))." FROM ".TB_PREFIX."units");
if($result) 
	$units=mysqli_fetch_assoc($result);
function u($units,$k){ 
return isset($units[$k])? (int)$units[$k] : 0; 
}
$isStaff = isset($session) && $session->access >= 8; // MH si Admin
?>

<!-- local redesign: stat tiles and cards instead of stacked tables -->
<div class="tz-stats-general">
<div class="tz-ally-stats tz-stats-tiles">
    <div class="tz-ally-stat"><span class="tz-ally-k"><?php echo TZ_TOTAL_VILLAGES; ?></span><span class="tz-ally-v"><?= number_format($num_villages) ?></span></div>
    <div class="tz-ally-stat"><span class="tz-ally-k"><?php echo TZ_TOTAL_POPULATION; ?></span><span class="tz-ally-v"><?= number_format($total_pop) ?></span></div>
    <div class="tz-ally-stat"><span class="tz-ally-k"><?php echo TZ_REGISTERED_PLAYERS; ?></span><span class="tz-ally-v"><?= number_format($users) ?></span></div>
    <div class="tz-ally-stat"><span class="tz-ally-k">Days since start</span><span class="tz-ally-v"><?= (int) $daysSinceStart ?></span></div>
</div>

<div class="tz-prof-grid">
    <div class="tz-prof-card">
        <h3><?php echo PLAYERS; ?></h3>
        <div class="tz-stats-kv">
            <span><?php echo ACTIVE_PLAYERS; ?></span><b><?= $active ?></b>
            <span>Online now</span><b><?= $online ?></b>
            <span>New today</span><b><?= $newToday ?></b>
        </div>
    </div>
    <div class="tz-prof-card">
        <h3>World</h3>
        <div class="tz-stats-kv">
            <span>Alliances</span><b><?= $alliCount ?></b>
            <span>Conquered oases</span><b><?= $oasis ?></b>
            <span>Natar villages</span><b><?= $natars ?></b>
            <?php if ($isStaff) { ?><span><?php echo GOLD; ?> (staff)</span><b><?= number_format($total_gold) ?></b><?php } ?>
        </div>
    </div>
</div>

<div class="tz-prof-grid">
    <div class="tz-prof-card">
        <h3><?php echo TZ_TRIBES; ?></h3>
        <?php foreach ($activeTribes as $tid):
            $cnt = $tribes[$tid];
            $pct = ($users > 0) ? round(100 * $cnt / $users, 1) : 0;
            $tribeName = defined('TRIBE'.$tid) ? constant('TRIBE'.$tid) : ('Tribe '.$tid);
        ?>
        <div class="tz-stats-bar">
            <span class="tz-stats-bar-l"><?= $tribeName ?></span>
            <span class="tz-stats-bar-t"><i style="width:<?= $pct ?>%"></i></span>
            <span class="tz-stats-bar-v"><?= $cnt ?> &middot; <?= $pct ?>%</span>
        </div>
        <?php endforeach; ?>
    </div>
    <div class="tz-prof-card">
        <h3>Largest alliances</h3>
        <?php if (empty($topAlliances)) { ?><p class="tz-prof-note">No alliances yet.</p><?php } else { ?>
        <table class="tz-prof-table" cellpadding="0" cellspacing="0">
            <tr><th>Tag</th><th><?php echo NAME; ?></th><th class="tz-stats-r">Members</th></tr>
            <?php foreach ($topAlliances as $a) { ?>
            <tr><td><b><?= htmlspecialchars($a['tag']) ?></b></td><td><?= htmlspecialchars($a['name']) ?></td><td class="tz-stats-r"><?= (int) $a['members'] ?></td></tr>
            <?php } ?>
        </table>
        <?php } ?>
    </div>
</div>

<div class="tz-prof-grid">
    <div class="tz-prof-card">
        <h3><?php echo TZ_MISCELLANEOUS; ?> <span>the last 7 days</span></h3>
        <table class="tz-prof-table" cellpadding="0" cellspacing="0">
            <tr><th><?php echo DATE; ?></th><th class="tz-stats-r"><?php echo TZ_ATTACKS; ?></th><th class="tz-stats-r"><?php echo CASUALTIES; ?></th></tr>
            <?php for ($d = 0; $d <= 6; $d++) { ?>
            <tr><td><?= date("j. M", time() - (86400 * $d)) ?></td>
                <td class="tz-stats-r"><?= number_format((int) $database->getAttackByDate(time() - (86400 * $d))) ?></td>
                <td class="tz-stats-r"><?= number_format((int) $database->getAttackCasualties(time() - (86400 * $d))) ?></td></tr>
            <?php } ?>
        </table>
    </div>
    <div class="tz-prof-card">
        <h3>Endgame</h3>
        <div class="tz-stats-kv">
            <span>Wonders of the World</span><b><?php if (empty($wonders)) echo '-'; else foreach ($wonders as $w) echo htmlspecialchars($w['village']) . ' <span class="tz-prof-dim">lv ' . (int) $w['level'] . '</span><br>'; ?></b>
            <span>Artefacts</span><b><?php if (empty($artefacts)) echo '-'; else foreach ($artefacts as $a) echo htmlspecialchars($a['name']) . ' <span class="tz-prof-dim">' . htmlspecialchars($a['username'] ?? 'Natars') . '</span><br>'; ?></b>
        </div>
    </div>
</div>

<?php if ($isStaff): ?>
<div class="tz-prof-card">
    <h3>Top players <span>staff only</span></h3>
    <table class="tz-prof-table" cellpadding="0" cellspacing="0">
        <tr><th><?php echo POP; ?></th><th class="tz-stats-r"></th><th>Attackers</th><th class="tz-stats-r"></th><th>Defenders</th><th class="tz-stats-r"></th></tr>
        <?php for ($i = 0; $i < 10; $i++):
            $p = $topPop[$i] ?? null; $a = $topAtk[$i] ?? null; $d = $topDef[$i] ?? null; ?>
        <tr>
            <td><?= ($i + 1) . '. ' . ($p ? htmlspecialchars($p['username']) : '-') ?></td><td class="tz-stats-r"><?= $p ? number_format((int) ($p['totalpop'] ?? 0)) : 0 ?></td>
            <td><?= ($i + 1) . '. ' . ($a ? htmlspecialchars($a['username']) : '-') ?></td><td class="tz-stats-r"><?= $a ? number_format((int) $a['points']) : 0 ?></td>
            <td><?= ($i + 1) . '. ' . ($d ? htmlspecialchars($d['username']) : '-') ?></td><td class="tz-stats-r"><?= $d ? number_format((int) $d['points']) : 0 ?></td>
        </tr>
        <?php endfor; ?>
    </table>
</div>
<div class="tz-prof-card">
    <h3><?php echo TROOPS; ?> <span>all players, staff only</span></h3>
    <div class="tz-stats-troops">
    <?php foreach ($activeTribes as $tid): $tribeName = defined('TRIBE'.$tid) ? constant('TRIBE'.$tid) : ('Tribe '.$tid); ?>
        <div class="tz-stats-troopcol">
            <div class="tz-stats-troophead"><?= $tribeName ?></div>
            <?php for ($i = 1; $i <= 10; $i++): $u = ($tid - 1) * 10 + $i; ?>
            <div class="tz-stats-troop"><img src="img/x.gif" class="unit u<?= $u ?>" alt=""> <?= number_format(u($units, 'u' . $u)) ?></div>
            <?php endfor; ?>
        </div>
    <?php endforeach; ?>
    </div>
</div>
<?php endif; ?>
</div>
<?php?>
<table cellpadding="1" cellspacing="1" id="search_navi">