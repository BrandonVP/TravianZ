<?php
#################################################################################
##  Local redesign: Empire overview (Plus). Totals for every village of the    ##
##  account: income per hour, stock, gold, the whole army (home, away,         ##
##  reinforcing, captured) and one row per village. Replaces the old tabs.     ##
##  Village data comes from Village::snapshot() (read-only, same production    ##
##  code as the village page).                                                 ##
#################################################################################

$tzEmpVillages = $database->getProfileVillages($session->uid);
$tzEmpRes = ['wood' => LUMBER, 'clay' => CLAY, 'iron' => IRON, 'crop' => CROP];
$tzEmpIcon = ['wood' => 'r1', 'clay' => 'r2', 'iron' => 'r3', 'crop' => 'r4'];
$tzEmpCoin = '<svg class="tz-coin-sm" viewBox="0 0 24 24" aria-hidden="true"><circle cx="12" cy="12" r="10" fill="#e3b427" stroke="#9a7512" stroke-width="1.5"/><circle cx="12" cy="12" r="6.5" fill="none" stroke="#9a7512" stroke-width="1"/></svg>';

$tzEmpTribe = (int) $session->tribe;
$tzEmpFirst = ($tzEmpTribe - 1) * 10 + 1;
$tzEmpUnits = [];
for ($i = $tzEmpFirst; $i < $tzEmpFirst + 10; $i++) $tzEmpUnits[] = 'u' . $i;
$tzEmpUnits[] = 'hero';

$tzEmpTot = [
    'prod' => ['wood' => 0, 'clay' => 0, 'iron' => 0, 'crop' => 0],
    'have' => ['wood' => 0, 'clay' => 0, 'iron' => 0, 'crop' => 0],
    'cap'  => ['wood' => 0, 'clay' => 0, 'iron' => 0, 'crop' => 0],
    'full' => ['wood' => null, 'clay' => null, 'iron' => null, 'crop' => null], // [hours, village]
    'gold' => 0, 'goldRate' => 0, 'goldCap' => 0, 'goldFull' => null, 'pop' => 0, 'cp' => 0,
];
$tzEmpArmy = [];
foreach (['home', 'away', 'reinf', 'all'] as $k) $tzEmpArmy[$k] = array_fill_keys($tzEmpUnits, 0);
$tzEmpRows = [];
// defence per village: own troops at home + troops stationed there by other
// villages (own or allied), base defence values from unitdata (no smithy
// upgrades, hero not counted), wall type/level from field 40
$tzEmpDef = [];
$tzEmpUnitDef = function ($n) {
    if (!isset($GLOBALS['u' . $n])) {
        include __DIR__ . '/../../GameEngine/Data/unitdata.php';
        foreach (get_defined_vars() as $k => $v) if (preg_match('/^u\d+$/', $k)) $GLOBALS[$k] = $v;
    }
    $d = $GLOBALS['u' . $n] ?? null;
    return $d ? [(int) $d['di'], (int) $d['dc']] : [0, 0];
};
$tzEmpWalls = [31 => CITYWALL, 32 => EARTHWALL, 33 => PALISADE, 42 => STONEWALL, 43 => MAKESHIFTWALL, 47 => DEFENSIVEWALL];

if (!function_exists('tzEmpTime')) {
    function tzEmpTime($hours)
    {
        $m = (int) round($hours * 60);
        return $m >= 1440 ? floor($m / 1440) . 'd ' . floor(($m % 1440) / 60) . 'h'
             : ($m >= 60 ? floor($m / 60) . 'h ' . ($m % 60) . 'm' : $m . 'm');
    }
}

foreach ($tzEmpVillages as $tzEmpV) {
    $tzWid = (int) $tzEmpV['wref'];
    $tzSnap = ($tzWid === (int) $village->wid) ? $village->preview() : Village::snapshot($tzWid);
    if (!$tzSnap) continue;

    foreach ($tzEmpRes as $r => $label) {
        $cap = ($r === 'crop') ? $tzSnap['maxcrop'] : $tzSnap['maxstore'];
        $tzEmpTot['prod'][$r] += $tzSnap['production'][$r];
        $tzEmpTot['have'][$r] += $tzSnap['amount'][$r];
        $tzEmpTot['cap'][$r]  += $cap;
        if ($tzSnap['production'][$r] > 0) {
            $h = max(0, $cap - $tzSnap['amount'][$r]) / $tzSnap['production'][$r];
            if ($tzEmpTot['full'][$r] === null || $h < $tzEmpTot['full'][$r][0]) {
                $tzEmpTot['full'][$r] = [$h, $tzSnap['name']];
            }
        }
    }
    if ($tzSnap['gold']) {
        $tzEmpTot['gold'] += $tzSnap['gold']['amount'];
        $tzEmpTot['goldRate'] += $tzSnap['gold']['rate'];
        $tzEmpTot['goldCap'] += $tzSnap['gold']['cap'];
        if ($tzSnap['gold']['rate'] > 0) {
            $h = max(0, $tzSnap['gold']['cap'] - $tzSnap['gold']['amount']) / $tzSnap['gold']['rate'];
            if ($tzEmpTot['goldFull'] === null || $h < $tzEmpTot['goldFull'][0]) {
                $tzEmpTot['goldFull'] = [$h, $tzSnap['name']];
            }
        }
    }
    $tzEmpTot['pop'] += $tzSnap['pop'];
    $tzEmpTot['cp'] += $tzSnap['cp'];

    // army: at home, reinforcing elsewhere, on the move (attacks, returns,
    // settlers) and captured
    $tzHome = $database->getUnit($tzWid) ?: [];
    foreach ($tzEmpUnits as $u) $tzEmpArmy['home'][$u] += (int) ($tzHome[$u] ?? 0);

    $tzD = ['units' => [], 'support' => 0, 'from' => [], 'di' => 0, 'dc' => 0];
    foreach ($tzEmpUnits as $u) {
        $n = (int) ($tzHome[$u] ?? 0);
        $tzD['units'][$u] = $n;
        if ($u !== 'hero' && $n > 0) {
            list($di, $dc) = $tzEmpUnitDef((int) substr($u, 1));
            $tzD['di'] += $n * $di; $tzD['dc'] += $n * $dc;
        }
    }
    foreach ((array) $database->getEnforceVillage($tzWid, 0) as $tzE) {
        $cnt = 0;
        for ($n = 1; $n <= 90; $n++) {
            $c = (int) ($tzE['u' . $n] ?? 0);
            if ($c <= 0) continue;
            $cnt += $c;
            list($di, $dc) = $tzEmpUnitDef($n);
            $tzD['di'] += $c * $di; $tzD['dc'] += $c * $dc;
        }
        $cnt += (int) ($tzE['hero'] ?? 0);
        if ($cnt > 0) {
            $tzD['support'] += $cnt;
            // from = 0: animals caught with cages and released here
            $src = ((int) $tzE['from'] > 0) ? (string) $database->getVillageField((int) $tzE['from'], 'name') : 'Tamed animals';
            $tzD['from'][$src] = ($tzD['from'][$src] ?? 0) + $cnt;
        }
    }
    $tzFd = $database->getResourceLevel($tzWid) ?: [];
    $tzWallType = (int) ($tzFd['f40t'] ?? 0);
    $tzD['wall'] = isset($tzEmpWalls[$tzWallType]) ? [$tzEmpWalls[$tzWallType], (int) $tzFd['f40']] : null;
    $tzEmpDef[$tzWid] = $tzD;
    foreach ((array) $database->getEnforceVillage($tzWid, 1) as $tzE) {
        foreach ($tzEmpUnits as $u) $tzEmpArmy['reinf'][$u] += (int) ($tzE[$u] ?? 0);
    }
    $tzMove = $database->getVillageMovement($tzWid) ?: [];
    foreach ($tzEmpUnits as $u) $tzEmpArmy['away'][$u] += (int) ($tzMove[$u] ?? 0);
    foreach ((array) $database->getPrisoners($tzWid, 1) as $tzP) {
        for ($i = 1; $i <= 10; $i++) $tzEmpArmy['away']['u' . ($tzEmpFirst + $i - 1)] += (int) ($tzP['t' . $i] ?? 0);
        $tzEmpArmy['away']['hero'] += (int) ($tzP['t11'] ?? 0);
    }

    // building queue (what is building now, how many wait)
    $tzJobs = (array) $database->getJobs($tzWid);
    $tzNowJobs = [];
    $tzWaiting = 0;
    foreach ($tzJobs as $tzJ) {
        if ((int) $tzJ['master'] == 0 && (int) $tzJ['loopcon'] == 0) $tzNowJobs[] = $tzJ;
        else $tzWaiting++;
    }

    // incoming attacks / raids
    $tzAtt = 0;
    foreach ((array) $database->getMovement(3, $tzWid, 1) as $tzM) {
        if (in_array((int) ($tzM['attack_type'] ?? 0), [3, 4], true)) $tzAtt++;
    }

    $tzMerchTotal = (int) $building->getTypeLevel(17, $tzWid);
    $tzEmpRows[] = [
        'snap' => $tzSnap,
        'jobs' => $tzNowJobs,
        'waiting' => $tzWaiting,
        'attacks' => $tzAtt,
        'merchants' => [$tzMerchTotal - (int) $database->totalMerchantUsed($tzWid), $tzMerchTotal],
    ];
}
foreach ($tzEmpUnits as $u) {
    $tzEmpArmy['all'][$u] = $tzEmpArmy['home'][$u] + $tzEmpArmy['away'][$u] + $tzEmpArmy['reinf'][$u];
}
$tzEmpArmyTotal = array_sum($tzEmpArmy['all']);
?>
<div class="tz-empire">
    <h1>Empire</h1>
    <p class="tz-emp-sub">
        <?php echo count($tzEmpRows); ?> villages &middot; <?php echo number_format($tzEmpTot['pop']); ?> population
        &middot; <?php echo number_format($tzEmpTot['cp']); ?> culture points per day
    </p>

    <div class="tz-emp-totals">
        <?php $tzGoldPct = $tzEmpTot['goldCap'] > 0 ? min(100, $tzEmpTot['gold'] / $tzEmpTot['goldCap'] * 100) : 0; ?>
        <div class="tz-emp-card tz-emp-gold">
            <div class="tz-emp-head"><?php echo $tzEmpCoin; ?> Gold</div>
            <div class="tz-emp-rate">+<?php echo number_format($tzEmpTot['goldRate'], $tzEmpTot['goldRate'] < 10 ? 1 : 0); ?>/h</div>
            <div class="tz-emp-amt"><?php echo number_format(floor($tzEmpTot['gold'])); ?> <span>/ <?php echo number_format($tzEmpTot['goldCap']); ?></span></div>
            <div class="tz-emp-bar tz-emp-bar-gold"><span style="width:<?php echo round($tzGoldPct, 1); ?>%"></span></div>
            <div class="tz-emp-note"><?php echo $tzEmpTot['goldFull'] ? 'First full: ' . htmlspecialchars($tzEmpTot['goldFull'][1]) . ' in ' . tzEmpTime($tzEmpTot['goldFull'][0]) : '&nbsp;'; ?></div>
        </div>
        <?php foreach ($tzEmpRes as $r => $label) {
            $pct = $tzEmpTot['cap'][$r] > 0 ? min(100, $tzEmpTot['have'][$r] / $tzEmpTot['cap'][$r] * 100) : 0;
            $full = $tzEmpTot['full'][$r];
        ?>
        <div class="tz-emp-card">
            <div class="tz-emp-head"><img class="<?php echo $tzEmpIcon[$r]; ?>" src="img/x.gif" alt="" /> <?php echo $label; ?></div>
            <div class="tz-emp-rate<?php echo $tzEmpTot['prod'][$r] < 0 ? ' tz-neg' : ''; ?>"><?php echo ($tzEmpTot['prod'][$r] >= 0 ? '+' : '') . number_format($tzEmpTot['prod'][$r]); ?>/h</div>
            <div class="tz-emp-amt"><?php echo number_format(floor($tzEmpTot['have'][$r])); ?> <span>/ <?php echo number_format($tzEmpTot['cap'][$r]); ?></span></div>
            <div class="tz-emp-bar"><span style="width:<?php echo round($pct, 1); ?>%"></span></div>
            <div class="tz-emp-note"><?php echo $full ? 'First full: ' . htmlspecialchars($full[1]) . ' in ' . tzEmpTime($full[0]) : '&nbsp;'; ?></div>
        </div>
        <?php } ?>
    </div>

    <h2>Army <span class="tz-emp-h2note"><?php echo number_format($tzEmpArmyTotal); ?> units</span></h2>
    <div class="tz-emp-scroll">
    <table class="tz-emp-army" cellpadding="1" cellspacing="1">
        <thead>
            <tr>
                <th></th>
                <?php foreach ($tzEmpUnits as $u) {
                    $tzName = ($u === 'hero') ? (defined('TZ_HERO') ? TZ_HERO : 'Hero') : $technology->getUnitName((int) substr($u, 1)); ?>
                    <th><img class="unit <?php echo $u === 'hero' ? 'uhero' : $u; ?>" src="img/x.gif" title="<?php echo htmlspecialchars($tzName); ?>" alt="<?php echo htmlspecialchars($tzName); ?>" /></th>
                <?php } ?>
            </tr>
        </thead>
        <tbody>
            <?php foreach (['all' => 'Total', 'home' => 'At home', 'away' => 'Away', 'reinf' => 'Reinforcing'] as $k => $label) { ?>
            <tr class="tz-emp-<?php echo $k; ?>">
                <th><?php echo $label; ?></th>
                <?php foreach ($tzEmpUnits as $u) { $n = $tzEmpArmy[$k][$u]; ?>
                    <td class="<?php echo $n == 0 ? 'none' : ''; ?>"><?php echo number_format($n); ?></td>
                <?php } ?>
            </tr>
            <?php } ?>
        </tbody>
    </table>
    </div>
    <p class="tz-emp-foot">Away = attacking, returning, settling or captured. Reinforcing = stationed in other villages or oases.</p>

    <h2>Defence by village</h2>
    <div class="tz-emp-scroll">
    <table class="tz-emp-army tz-emp-def" cellpadding="1" cellspacing="1">
        <thead>
            <tr>
                <th class="tz-l"><?php echo VILLAGE; ?></th>
                <?php foreach ($tzEmpUnits as $u) {
                    $tzName = ($u === 'hero') ? (defined('TZ_HERO') ? TZ_HERO : 'Hero') : $technology->getUnitName((int) substr($u, 1)); ?>
                    <th><img class="unit <?php echo $u === 'hero' ? 'uhero' : $u; ?>" src="img/x.gif" title="<?php echo htmlspecialchars($tzName); ?>" alt="<?php echo htmlspecialchars($tzName); ?>" /></th>
                <?php } ?>
                <th title="Troops other villages (yours or allies') and tamed animals stationed here">Support</th>
                <th>Wall</th>
                <th title="Defence against infantry">Def inf</th>
                <th title="Defence against cavalry">Def cav</th>
            </tr>
        </thead>
        <tbody>
            <?php $tzDefTot = ['units' => array_fill_keys($tzEmpUnits, 0), 'support' => 0, 'di' => 0, 'dc' => 0];
            foreach ($tzEmpRows as $row) {
                $s = $row['snap'];
                $d = $tzEmpDef[(int) $s['wid']] ?? null;
                if (!$d) continue;
                foreach ($tzEmpUnits as $u) $tzDefTot['units'][$u] += $d['units'][$u];
                $tzDefTot['support'] += $d['support']; $tzDefTot['di'] += $d['di']; $tzDefTot['dc'] += $d['dc'];
                $tzFromTitle = [];
                foreach ($d['from'] as $src => $c) $tzFromTitle[] = $src . ': ' . number_format($c);
            ?>
            <tr class="<?php echo ((int) $s['wid'] === (int) $village->wid) ? 'tz-cur' : ''; ?>">
                <th class="tz-emp-vil">
                    <a href="build.php?newdid=<?php echo (int) $s['wid']; ?>&amp;id=39"><?php echo htmlspecialchars($s['name']); ?></a>
                    <?php if ($row['attacks'] > 0) { ?><span class="tz-emp-att" title="<?php echo $row['attacks']; ?> incoming attack(s)">&#9876; <?php echo $row['attacks']; ?></span><?php } ?>
                </th>
                <?php foreach ($tzEmpUnits as $u) { $n = $d['units'][$u]; ?>
                    <td class="<?php echo $n == 0 ? 'none' : ''; ?>"><?php echo number_format($n); ?></td>
                <?php } ?>
                <td class="<?php echo $d['support'] == 0 ? 'none' : ''; ?>" title="<?php echo htmlspecialchars(implode("\n", $tzFromTitle)); ?>"><?php echo number_format($d['support']); ?></td>
                <td class="<?php echo $d['wall'] ? '' : 'none'; ?>" title="<?php echo $d['wall'] ? htmlspecialchars($d['wall'][0]) : 'No wall'; ?>"><?php echo $d['wall'] ? $d['wall'][1] : '-'; ?></td>
                <td class="tz-emp-defv"><?php echo number_format($d['di']); ?></td>
                <td class="tz-emp-defv"><?php echo number_format($d['dc']); ?></td>
            </tr>
            <?php } ?>
            <tr class="tz-emp-all">
                <th>Total</th>
                <?php foreach ($tzEmpUnits as $u) { $n = $tzDefTot['units'][$u]; ?>
                    <td class="<?php echo $n == 0 ? 'none' : ''; ?>"><?php echo number_format($n); ?></td>
                <?php } ?>
                <td class="<?php echo $tzDefTot['support'] == 0 ? 'none' : ''; ?>"><?php echo number_format($tzDefTot['support']); ?></td>
                <td></td>
                <td class="tz-emp-defv"><?php echo number_format($tzDefTot['di']); ?></td>
                <td class="tz-emp-defv"><?php echo number_format($tzDefTot['dc']); ?></td>
            </tr>
        </tbody>
    </table>
    </div>
    <p class="tz-emp-foot">Troops in each village right now: your own at home plus support stationed there (hover for where it comes from). Defence is the base value of all of them, before smithy upgrades and the wall bonus; the hero is not included.</p>

    <h2>Villages</h2>
    <div class="tz-emp-scroll">
    <table class="tz-emp-villages" cellpadding="1" cellspacing="1">
        <thead>
            <tr>
                <th class="tz-l"><?php echo VILLAGE; ?></th>
                <?php foreach ($tzEmpRes as $r => $label) { ?><th><img class="<?php echo $tzEmpIcon[$r]; ?>" src="img/x.gif" alt="<?php echo $label; ?>" title="<?php echo $label; ?>" /></th><?php } ?>
                <th><?php echo $tzEmpCoin; ?></th>
                <th>Merchants</th>
                <th class="tz-l">Building</th>
            </tr>
        </thead>
        <tbody>
        <?php foreach ($tzEmpRows as $row) {
            $s = $row['snap'];
            $cur = ((int) $s['wid'] === (int) $village->wid);
        ?>
            <tr class="<?php echo $cur ? 'tz-cur' : ''; ?>">
                <td class="tz-l tz-emp-vil">
                    <a href="dorf1.php?newdid=<?php echo (int) $s['wid']; ?>"><?php echo htmlspecialchars($s['name']); ?></a>
                    <?php if ($s['capital']) { ?><span class="tz-emp-cap">Capital</span><?php } ?>
                    <?php if ($row['attacks'] > 0) { ?><span class="tz-emp-att" title="<?php echo $row['attacks']; ?> incoming attack(s)">&#9876; <?php echo $row['attacks']; ?></span><?php } ?>
                    <div class="tz-emp-small"><?php echo number_format($s['pop']); ?> pop &middot; <?php echo floor($s['loyalty']); ?>% loyalty</div>
                </td>
                <?php foreach ($tzEmpRes as $r => $label) {
                    $cap = ($r === 'crop') ? $s['maxcrop'] : $s['maxstore'];
                    $pct = $cap > 0 ? min(100, $s['amount'][$r] / $cap * 100) : 0;
                    $p = $s['production'][$r];
                ?>
                <td class="tz-emp-res<?php echo $pct >= 90 ? ' tz-near-full' : ''; ?>">
                    <?php echo number_format(floor($s['amount'][$r])); ?>
                    <div class="tz-emp-mini"><span style="width:<?php echo round($pct, 1); ?>%"></span></div>
                    <div class="tz-emp-small<?php echo $p < 0 ? ' tz-neg' : ''; ?>"><?php echo ($p >= 0 ? '+' : '') . number_format($p); ?>/h</div>
                </td>
                <?php } ?>
                <td class="tz-emp-res">
                    <?php if ($s['gold']) { ?>
                        <?php echo number_format(floor($s['gold']['amount'])); ?>
                        <div class="tz-emp-small">+<?php echo number_format($s['gold']['rate'], $s['gold']['rate'] < 10 ? 1 : 0); ?>/h</div>
                    <?php } else { ?><span class="none">-</span><?php } ?>
                </td>
                <td><?php if ($row['merchants'][1] > 0) { ?>
                    <a href="build.php?newdid=<?php echo (int) $s['wid']; ?>&amp;gid=17"><?php echo $row['merchants'][0]; ?>/<?php echo $row['merchants'][1]; ?></a>
                <?php } else { ?><span class="none">-</span><?php } ?></td>
                <td class="tz-l tz-emp-small">
                    <?php if (empty($row['jobs'])) { ?><span class="none">Nothing</span><?php } ?>
                    <?php foreach ($row['jobs'] as $j) { ?>
                        <div><?php echo Building::procResType($j['type']); ?> <?php echo (int) $j['level']; ?>
                            <span class="tz-emp-dim">&middot; <?php echo $generator->getTimeFormat(max(0, $j['timestamp'] - time())); ?></span></div>
                    <?php } ?>
                    <?php if ($row['waiting'] > 0) { ?><div class="tz-emp-dim">+<?php echo $row['waiting']; ?> waiting</div><?php } ?>
                </td>
            </tr>
        <?php } ?>
        </tbody>
    </table>
    </div>
</div>
