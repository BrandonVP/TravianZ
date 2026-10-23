<?php
#################################################################################
##              -= YOU MAY NOT REMOVE OR CHANGE THIS NOTICE =-                 ##
## --------------------------------------------------------------------------- ##
##  Filename       res.tpl                                                     ##
##  Developed by:  Dzoki                                                       ##
##  Refactored by: Shadow Incremental Refactor 			                       ##
##  License:       TravianZ Project                                            ##
##  Copyright:     TravianZ (c) 2010-2026. All rights reserved.                ##
##                                                                             ##
##  Incremental Refactor Notes:                                                ##
##  - Preserved original functionality                                         ##
##  - Added safety checks for legacy PHP                                       ##
##  - Reduced repeated property access                                         ##
##  - Improved readability                                                     ##
##  - Kept UI structure unchanged                                              ##
##                                                                             ##
#################################################################################

/**
 * ---------------------------------------------------------
 * Safety check (avoid undefined village context)
 * ---------------------------------------------------------
 */
// printed once per page: Templates/layout/page_top.tpl puts the cards at the
// top of the page; later includes (old page bottoms) print nothing
if (!empty($GLOBALS['tzResPrinted'])) {
    return;
}

if (!empty($village)) {
    $GLOBALS['tzResPrinted'] = true;

    /**
     * -----------------------------------------------------
     * Production values (rounded)
     * -----------------------------------------------------
     */
    $wood = round($village->getProd("wood"));
    $clay = round($village->getProd("clay"));
    $iron = round($village->getProd("iron"));
    $crop = round($village->getProd("crop"));

    /**
     * Total crop production capacity
     */
    $totalproduction = $village->allcrop;

    /**
     * Safely cache values to reduce repeated access
     */
    // floor, not round: stock is stored fractional (vdata float) and every
    // server-side check compares against the real value. Rounding up made the
    // header (and the JS ticker seeded from it) show 1 unit more than exists,
    // so "send max" on the marketplace failed with "Not enough resources".
    $woodStore = floor($village->awood);
    $clayStore = floor($village->aclay);
    $ironStore = floor($village->airon);
    $cropStore = floor($village->acrop);

    $maxStore  = $village->maxstore;
    $maxCrop   = $village->maxcrop;

    $upkeep = $village->pop + $technology->getUpkeep($village->unitall, 0);

    /**
     * One card per resource. The hidden #l1..#l4 spans keep the exact
     * "amount/capacity" text and production title that unx.js reads and ticks;
     * tzres.js copies the ticking value into the visible card every second.
     */
    $tzCards = array(
        array('l4', 'r1', 'wood', LUMBER, $woodStore, $maxStore, $wood, true),
        array('l3', 'r2', 'clay', CLAY,   $clayStore, $maxStore, $clay, true),
        array('l2', 'r3', 'iron', IRON,   $ironStore, $maxStore, $iron, true),
        array('l1', 'r4', 'crop', CROP,   $cropStore, $maxCrop,  $crop, $village->acrop > 0),
    );

    $tzSigned = function ($n) {
        return ($n < 0 ? '&minus;' : '+') . number_format(abs($n));
    };
?>

<div id="res">
<div id="resWrap">

    <!-- ================= RESOURCES ================= -->
    <div class="tz-rcards">
<?php
    /**
     * Village gold (local redesign, phase 1): first card, replacing net crop.
     * The raw span has no id: unx.js leaves it alone, tzres.js ticks it.
     */
    if (!empty($village->goldActive)) {
        $tzGold = floor(max(0, $village->agold));
        $tzGoldRate = $village->goldRate;
        $tzGoldCap = VillageGold::capOf($village);
$tzGoldSafe = VillageGold::treasuryHolds(VillageGold::treasuryLevel($village->resarray));
$tzGoldPct = $tzGoldCap > 0 ? max(0, min(100, $tzGold / $tzGoldCap * 100)) : 0;
        // local redesign: gold comes from the village's Gold Mines
        $tzGoldTip = ((int) ($tzGoldRate['count'] ?? 0) > 0
                       ? (int) $tzGoldRate['count'] . ' gold mine' . ((int) $tzGoldRate['count'] === 1 ? '' : 's') . ' +' . round($tzGoldRate['mines'] ?? 0, 1) . '/h'
                       : 'No gold mines in this village')
    . ($tzGoldSafe > 0
        ? ' · Treasury protects ' . number_format($tzGoldSafe) . ' gold'
        : ' · No Treasury: raids can steal gold');
?>
        <div class="tz-rcard tz-r-gold" style="--fill:<?php echo round($tzGoldPct, 1); ?>%" title="<?php echo htmlspecialchars($tzGoldTip, ENT_QUOTES, 'UTF-8'); ?>">
            <div class="tz-rhead">
                <svg class="tz-rcoin" viewBox="0 0 24 24" aria-hidden="true"><circle cx="12" cy="12" r="10" fill="#e3b427" stroke="#9a7512" stroke-width="1.5"/><circle cx="12" cy="12" r="6.5" fill="none" stroke="#9a7512" stroke-width="1"/><path d="M9.5 9.5h4a1.6 1.6 0 0 1 0 3.2h-3a1.6 1.6 0 0 0 0 3.2h4" fill="none" stroke="#7a5a0e" stroke-width="1.3" stroke-linecap="round"/></svg>
                <span class="tz-rname"><?php echo defined('TZ_VILLAGE_GOLD') ? TZ_VILLAGE_GOLD : 'Gold'; ?></span>
                <span class="tz-rprod">+<?php echo number_format($tzGoldRate['total'], $tzGoldRate['total'] < 10 ? 1 : 0); ?>/h</span>
            </div>
            <div class="tz-ramt"><strong class="tz-rnow"><?php echo number_format($tzGold); ?></strong> <span class="tz-rcap">/ <?php echo number_format($tzGoldCap); ?></span></div>
            <div class="tz-rbar"><span></span></div>
            <div class="tz-rfull">&nbsp;</div>
            <span class="tz-rraw" title="<?php echo round($tzGoldRate['total'], 3); ?>"><?php echo $tzGold . "/" . (int) $tzGoldCap; ?></span>
        </div>
<?php } ?>
<?php foreach ($tzCards as $c) {
    list($id, $icon, $kind, $label, $amount, $cap, $prod, $ticks) = $c;
    $pct = $cap > 0 ? max(0, min(100, $amount / $cap * 100)) : 0;
?>
        <div class="tz-rcard tz-r-<?php echo $kind; ?>" style="--fill:<?php echo round($pct, 1); ?>%">
            <div class="tz-rhead">
                <img src="img/x.gif" class="<?php echo $icon; ?>" alt="" />
                <span class="tz-rname"><?php echo $label; ?></span>
                <span class="tz-rprod<?php echo $prod < 0 ? ' neg' : ''; ?>"><?php echo $tzSigned($prod); ?>/h</span>
            </div>
            <div class="tz-ramt"><strong class="tz-rnow"><?php echo number_format(max(0, $amount)); ?></strong> <span class="tz-rcap">/ <?php echo number_format($cap); ?></span></div>
            <div class="tz-rbar"><span></span></div>
            <div class="tz-rfull">&nbsp;</div>
            <?php if ($kind === 'crop' && !empty($village->goldActive)) { ?>
            <div class="tz-rnote"><?php echo number_format($totalproduction); ?> produced &middot; <?php echo number_format($upkeep); ?> upkeep</div>
            <?php } ?>
            <span class="tz-rraw"<?php echo $ticks ? ' id="' . $id . '"' : ''; ?> title="<?php echo $prod; ?>"><?php echo max(0, $amount) . "/" . $cap; ?></span>
        </div>
<?php } ?>

<?php if (empty($village->goldActive)) { ?>
        <div class="tz-rcard tz-r-net">
            <div class="tz-rhead">
                <img src="img/x.gif" class="r4" alt="" />
                <span class="tz-rname"><?php echo defined('TZ_NET_CROP') ? TZ_NET_CROP : 'Net crop'; ?></span>
            </div>
            <div class="tz-ramt"><strong class="tz-rnet<?php echo $crop < 0 ? ' neg' : ''; ?>"><?php echo $tzSigned($crop); ?>/h</strong></div>
            <div class="tz-rfull" title="<?php echo CROP_COM; ?>"><?php echo number_format($totalproduction); ?> produced &middot; <?php echo number_format($upkeep); ?> upkeep</div>
        </div>
<?php } ?>
    </div>

</div>
</div>

<?php } ?>
