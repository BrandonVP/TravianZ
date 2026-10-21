<?php
#################################################################################
##  Local redesign: Plus features bought with the capital's village gold,      ##
##  in the capital's Main Building, with auto-buy for the 7-day features.      ##
##  Buying goes through plus.php?id=8..15 (Templates/Plus/8-15.tpl).           ##
#################################################################################

$tzIsCapital = !empty($village->capital) && (string) $village->capital !== '0';

if (!$tzIsCapital) {
    $tzCap = VillageGold::capitalOf($database, $session->uid);
    ?>
    <div class="tz-mbplus tz-mbplus-away">
        Plus features are bought with your capital's gold, in its Main Building.
        <?php if ($tzCap) { ?>
            <a class="tz-btn" href="build.php?newdid=<?php echo (int) $tzCap['wref']; ?>&amp;gid=15">Go to <?php echo htmlspecialchars($tzCap['name']); ?></a>
        <?php } ?>
    </div>
    <?php
    return;
}

$tzMayPay = !method_exists($session, 'sitterCan') || $session->sitterCan(SITTER_PERM_GOLD);

// auto-buy switch (explicit on/off, so a reload does not flip it back)
if ($tzMayPay && isset($_GET['tzauto'])) {
    VillageGold::setAutoBuy($database, $session->uid, (string) $_GET['tzauto'], !empty($_GET['on']));
}
$tzMask = VillageGold::autoBuyMask($database, $session->uid);

$tzRes = mysqli_query($database->dblink, "SELECT plus, b1, b2, b3, b4, goldclub FROM " . TB_PREFIX . "users WHERE id = " . (int) $session->uid . " LIMIT 1");
$tzUser = $tzRes ? mysqli_fetch_assoc($tzRes) : array();
$tzHave = (int) floor($village->agold);
$tzNow = time();
$tzBanned = defined('BANNED') && $session->access == BANNED;

$tzLeft = function ($until) use ($tzNow) {
    $s = (int) $until - $tzNow;
    if ($s <= 0) return '';
    $d = intdiv($s, 86400);
    $h = intdiv($s % 86400, 3600);
    $m = intdiv($s % 3600, 60);
    return $d > 0 ? $d . 'd ' . $h . 'h left' : ($h > 0 ? $h . 'h ' . $m . 'm left' : $m . 'm left');
};
$tzDur = function ($sec) {
    return $sec >= 86400 ? round($sec / 86400) . ' days' : round($sec / 3600) . ' hours';
};
$tzCoin = '<svg class="tz-coin-sm" viewBox="0 0 24 24" aria-hidden="true"><circle cx="12" cy="12" r="10" fill="#e3b427" stroke="#9a7512" stroke-width="1.5"/><circle cx="12" cy="12" r="6.5" fill="none" stroke="#9a7512" stroke-width="1"/></svg>';
$tzGuard = 'onclick="if(this.dataset.c) return false; this.dataset.c=1; this.style.pointerEvents=\'none\'; this.style.opacity=\'0.5\';"';
?>
<div class="tz-mbplus" id="plus">
    <h2>Plus features</h2>
    <p class="tz-mbplus-intro">
        Paid with this capital's gold: <?php echo $tzCoin; ?><b><?php echo number_format($tzHave); ?></b>.
        Turn on <b>auto-buy</b> to renew a feature automatically when it runs out (it is bought again
        a few minutes before the end, if the capital has the gold).
    </p>
    <table class="tz-mbplus-table" cellpadding="1" cellspacing="1">
        <thead>
            <tr><th>Feature</th><th>Duration</th><th>Gold</th><th>Status</th><th></th><th>Auto-buy</th></tr>
        </thead>
        <tbody>
        <?php foreach (VillageGold::plusFeatures() as $tzKey => $tzF) {
            $tzUntil = (int) ($tzUser[$tzF['field']] ?? 0);
            $tzActive = $tzUntil > $tzNow;
            $tzAuto = ($tzMask & $tzF['bit']) != 0;
        ?>
            <tr class="<?php echo $tzActive ? 'tz-on' : ''; ?>">
                <td class="tz-f"><?php echo $tzF['label']; ?></td>
                <td><?php echo $tzDur($tzF['duration']); ?></td>
                <td class="tz-p"><?php echo $tzCoin . number_format($tzF['price']); ?></td>
                <td class="tz-s"><?php echo $tzActive ? '<span class="tz-active">Active</span> · ' . $tzLeft($tzUntil) : '<span class="tz-off">Inactive</span>'; ?></td>
                <td class="tz-a"><?php
                    if ($tzBanned || !$tzMayPay) {
                        echo '<span class="none">—</span>';
                    } elseif ($tzHave < $tzF['price']) {
                        echo '<span class="none">Too little gold</span>';
                    } else {
                        echo '<a class="tz-btn" href="plus.php?id=' . (int) $tzF['id'] . '" ' . $tzGuard . '>' . ($tzActive ? 'Extend' : 'Buy') . '</a>';
                    }
                ?></td>
                <td class="tz-auto"><?php
                    if ($tzMayPay && !$tzBanned) {
                        echo '<a class="tz-switch' . ($tzAuto ? ' is-on' : '') . '" href="build.php?gid=15&amp;tzauto=' . $tzKey . '&amp;on=' . ($tzAuto ? 0 : 1) . '#plus"'
                           . ' title="' . ($tzAuto ? 'Auto-buy is on: click to turn off' : 'Turn on auto-buy') . '">'
                           . '<span class="tz-knob"></span>' . ($tzAuto ? 'On' : 'Off') . '</a>';
                    }
                ?></td>
            </tr>
        <?php } ?>
            <tr class="<?php echo !empty($tzUser['goldclub']) ? 'tz-on' : ''; ?>">
                <td class="tz-f"><?php echo defined('GOLD_CLUB') ? GOLD_CLUB : 'Gold Club'; ?></td>
                <td>Whole round</td>
                <td class="tz-p"><?php echo $tzCoin . number_format(TZ_GOLD_PRICE_GOLDCLUB); ?></td>
                <td class="tz-s"><?php echo !empty($tzUser['goldclub']) ? '<span class="tz-active">Active</span>' : '<span class="tz-off">Inactive</span>'; ?></td>
                <td class="tz-a"><?php
                    if (!empty($tzUser['goldclub'])) {
                        echo '';
                    } elseif ($tzBanned || !$tzMayPay) {
                        echo '<span class="none">—</span>';
                    } elseif ($tzHave < TZ_GOLD_PRICE_GOLDCLUB) {
                        echo '<span class="none">Too little gold</span>';
                    } else {
                        echo '<a class="tz-btn" href="plus.php?id=15" ' . $tzGuard . '>Buy</a>';
                    }
                ?></td>
                <td></td>
            </tr>
        </tbody>
    </table>
</div>
