<?php

#################################################################################
##                -= YOU MAY NOT REMOVE OR CHANGE THIS NOTICE =-               ##
## --------------------------------------------------------------------------- ##
##  Filename       : 26.tpl                                                    ##
##  Type           : Hero Report - Adventure Result                            ##
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
 * Local redesign (Empires of Rome): quest report. Shows where the hero went,
 * who it faced, how the fight went (the hero's real fighting strength against
 * the strength expected at its level - the ratio that scaled the damage),
 * health before/after, level progress and the rewards. Reports filed before
 * this redesign carry fewer fields; every section only shows what it has.
 */

if (!function_exists('tz_hero_adv')) {
    function tz_hero_adv($const, $fallback) {
        return defined($const) ? constant($const) : $fallback;
    }
}

parse_str((string)($message->readingNotice['data'] ?? ''), $adv);

global $heroAdventureConfig, $heroItemCatalog, $hero_levels;
if (!isset($heroAdventureConfig) || !function_exists('heroItemName')) {
    include_once 'GameEngine/Data/hero_items.php';
}

$q = function ($k, $d = 0) use ($adv) { return isset($adv[$k]) ? $adv[$k] : $d; };
$difficulty = (int) $q('difficulty');
$died       = (int) $q('died');
$exp        = (int) $q('exp');
$expBase    = (int) $q('xpb', $exp);
$silver     = (int) $q('silver');
$hp         = (int) $q('hp');
$heal       = (int) $q('heal');
$res        = array(1 => (int) $q('wood'), 2 => (int) $q('clay'), 3 => (int) $q('iron'), 4 => (int) $q('crop'));
$itemId     = (int) $q('itemid');
$itemQty    = (int) $q('itemqty');
$itemQual   = (int) $q('itemq');
$advType    = (int) $q('type');
$advStory   = isset($adv['story']) ? (int) $adv['story'] : -1;
$hasCtx     = isset($adv['lvl']);
$heroName   = trim((string) $q('hero', ''));
$who        = $heroName !== '' ? htmlspecialchars($heroName) : 'Your hero';

$advDef  = $heroAdventureConfig['types'][$advType] ?? null;
$place   = $advDef ? htmlspecialchars($advDef['name']) : ($difficulty === 1 ? 'A hard quest' : 'A quest');
$hardTag = $difficulty === 1 ? ' <span class="tzq-chip tzq-chip-hard">Hard</span>' : '';
$story   = ($advDef && $advStory >= 0 && isset($advDef['story'][$advStory])) ? $advDef['story'][$advStory] : '';
$foe     = ($advDef && !empty($advDef['foe'])) ? ($advDef['foe'][$difficulty] ?? $advDef['foe'][0]) : '';

// Level progress (thresholds from Data/hero_full.php)
$lvlBefore = (int) $q('lvl');
$xpBefore  = (int) $q('xp0');
$xpAfter   = $xpBefore + $exp;
$levelOf = function ($xp) use ($hero_levels) {
    $l = 0;
    if (is_array($hero_levels)) foreach ($hero_levels as $lv => $need) { if ($xp >= $need) $l = (int) $lv; }
    return $l;
};
$lvlAfter = $hasCtx ? max($lvlBefore, $levelOf($xpAfter)) : 0;
$nextNeed = is_array($hero_levels) && isset($hero_levels[$lvlAfter + 1]) ? (int) $hero_levels[$lvlAfter + 1] : 0;
$thisNeed = is_array($hero_levels) && isset($hero_levels[$lvlAfter]) ? (int) $hero_levels[$lvlAfter] : 0;
$lvlPct   = $nextNeed > $thisNeed ? max(0, min(100, round(100 * ($xpAfter - $thisNeed) / ($nextNeed - $thisNeed)))) : 100;

// The fight: fac = expected strength / hero strength (clamped), the factor on damage
$fac = (float) $q('fac', 1);
if ($fac <= 0.8)      { $verdict = 'Your hero overpowered them'; $vClass = 'good'; }
elseif ($fac < 1.25)  { $verdict = 'An even fight';               $vClass = 'even'; }
else                  { $verdict = 'Your hero was outmatched';    $vClass = 'bad'; }
$pow = (int) $q('pow'); $ref = (int) $q('ref'); $red = (int) $q('red');
$powPct = ($pow + $ref) > 0 ? round(100 * $pow / ($pow + $ref)) : 50;

$hpBefore = (float) $q('hpb', -1);
$hpAfter  = (float) $q('hpa', -1);

$fmtTime = function ($s) { $s = (int) $s; return sprintf('%d:%02d:%02d', floor($s / 3600), floor($s / 60) % 60, $s % 60); };
$resNames = array(1 => LUMBER, 2 => CLAY, 3 => IRON, 4 => CROP);
$slotName = '';
if ($itemId > 0 && isset($heroItemCatalog[$itemId]['slot']) && defined('HERO_SLOT_' . (int) $heroItemCatalog[$itemId]['slot'])) {
    $slotName = constant('HERO_SLOT_' . (int) $heroItemCatalog[$itemId]['slot']);
}
?>
<style>
.tzq { font-size: 13px; color: var(--tz-ink, #3b2a1a); }
.tzq-lead { margin: 4px 0 2px; font-size: 14px; }
.tzq-story { margin: 0 0 10px; color: #7a6650; font-style: italic; }
.tzq-grid { display: flex; flex-wrap: wrap; margin: 0 -5px; }
.tzq-box { flex: 1 1 230px; margin: 5px; padding: 9px 11px; background: var(--tz-panel, #fbf5e8);
           border: 1px solid var(--tz-line, #e3d3b0); border-radius: 8px; box-sizing: border-box; }
.tzq-box h4 { margin: 0 0 7px; font-size: 11px; letter-spacing: .06em; text-transform: uppercase; color: #8a6d3b; }
.tzq-row { display: flex; justify-content: space-between; padding: 2px 0; }
.tzq-row span:first-child { color: #7a6650; }
.tzq-row b { text-align: right; }
.tzq-bar { height: 8px; background: #eadfc8; border-radius: 4px; overflow: hidden; margin: 5px 0 3px; }
.tzq-bar i { display: block; height: 100%; background: #8a6d3b; }
.tzq-bar.hp i { background: #4f8a3a; }
.tzq-bar.hp.low i { background: #b5552f; }
.tzq-vs { display: flex; height: 10px; border-radius: 5px; overflow: hidden; margin: 6px 0 2px; }
.tzq-vs .me { background: #4f6e9a; }
.tzq-vs .them { background: #a0402a; }
.tzq-vs-legend { display: flex; justify-content: space-between; font-size: 11px; color: #7a6650; }
.tzq-chip { display: inline-block; padding: 1px 7px; border-radius: 9px; font-size: 11px; font-weight: 700; vertical-align: middle; }
.tzq-chip-hard { background: #f3dcd3; color: #a0402a; }
.tzq-chip-good { background: #dcebd0; color: #3f6b1c; }
.tzq-chip-even { background: #efe4c8; color: #7a5a1a; }
.tzq-chip-bad  { background: #f3dcd3; color: #a0402a; }
.tzq-chip-lvl  { background: #e6dcf3; color: #5a3f8a; margin-left: 6px; }
.tzq-res img { vertical-align: middle; }
.tzq-res span { margin-left: 8px; white-space: nowrap; }
.tzq-neg { color: #a0402a; }
.tzq-pos { color: #3f7a2a; }
.tzq-note { margin-top: 6px; font-size: 11px; color: #8a7a62; }
@media (max-width: 640px) {
    /* .reports table has min-width 500px (gpack); a quest report can shrink */
    .reports table#report_surround { min-width: 0; width: 100%; }
    .tzq-grid { display: block; margin: 0; }
    .tzq-box { margin: 0 0 8px; }
    .tzq-res span, .tzq-vs-legend span { white-space: normal; }
    .tzq-vs-legend { flex-wrap: wrap; }
}
.tzq-dead { padding: 9px 11px; margin-bottom: 8px; background: #f8e3dc; border: 1px solid #e3b8a8; border-radius: 8px; color: #8a2f1a; }
</style>

<table cellpadding="1" cellspacing="1" id="report_surround">
<thead>
<tr>
    <th><?php echo defined('SUBJECT') ? SUBJECT : 'Subject'; ?>:</th>
    <th><?php echo htmlspecialchars(tz_loc_topic($message->readingNotice['topic'])); ?></th>
</tr>
<tr>
    <?php $date = $generator->procMtime($message->readingNotice['time']); ?>
    <td class="sent"><?php echo defined('TZ_SENT') ? TZ_SENT : 'Sent'; ?></td>
    <td><?php echo (defined('ON') ? ON : 'on') . ' '; ?><span><?php echo $date[0] . " " . $date[1]; ?></span></td>
</tr>
</thead>
<tbody>
<tr><td colspan="2" class="empty"></td></tr>
<tr><td colspan="2" class="report_content">
<div class="tzq">

<?php if ($died) { ?>
    <div class="tzq-dead"><b><?php echo $who; ?> fell at <?php echo $place; ?></b><?php echo $hardTag; ?><br>
        Everything found on the quest was lost. The hero can be revived at the Hero's Mansion.</div>
<?php } else { ?>
    <p class="tzq-lead"><b><?php echo $who; ?></b> completed the quest at <b><?php echo $place; ?></b><?php echo $hardTag; ?>.</p>
    <?php if ($story !== '') { ?><p class="tzq-story"><?php echo htmlspecialchars($story); ?></p><?php } ?>
<?php } ?>

<div class="tzq-grid">

    <?php if ($hasCtx) { ?>
    <div class="tzq-box">
        <h4>The trip</h4>
        <div class="tzq-row"><span>Destination</span><b><?php echo $place; ?>
            <a href="karte.php?z=<?php echo (int) $q('site'); ?>">(<?php echo (int) $q('x'); ?>|<?php echo (int) $q('y'); ?>)</a></b></div>
        <div class="tzq-row"><span>Distance</span><b><?php echo number_format((float) $q('dist'), 1); ?> fields</b></div>
        <div class="tzq-row"><span>Travel time</span><b><?php echo $fmtTime($q('leg')); ?> each way</b></div>
    </div>

    <div class="tzq-box">
        <h4>Opposition</h4>
        <?php if ((int) $q('foe') === 1 && $foe !== '') { ?>
            <div class="tzq-row"><span>Faced</span><b><?php echo htmlspecialchars(ucfirst($foe)); ?></b></div>
            <div class="tzq-vs" title="Fighting strength"><i class="me" style="width:<?php echo $powPct; ?>%"></i><i class="them" style="width:<?php echo 100 - $powPct; ?>%"></i></div>
            <div class="tzq-vs-legend"><span>Your hero <?php echo number_format($pow); ?></span><span>Expected at level <?php echo $lvlBefore; ?>: <?php echo number_format($ref); ?></span></div>
            <p style="margin:7px 0 0"><span class="tzq-chip tzq-chip-<?php echo $vClass; ?>"><?php echo $verdict; ?></span></p>
            <?php if ($red > 0) { ?><div class="tzq-note">Armour took <?php echo $red; ?> off the health lost.</div><?php } ?>
        <?php } else { ?>
            <p style="margin:0">No opposition &ndash; a peaceful place.</p>
        <?php } ?>
    </div>
    <?php } ?>

    <div class="tzq-box">
        <h4>Your hero</h4>
        <?php if ($hpBefore >= 0 && $hpAfter >= 0) { ?>
            <div class="tzq-row"><span>Health</span><b><?php echo floor($hpBefore); ?>% &rarr; <?php echo floor($hpAfter); ?>%</b></div>
            <div class="tzq-bar hp<?php echo $hpAfter < 30 ? ' low' : ''; ?>"><i style="width:<?php echo max(0, min(100, $hpAfter)); ?>%"></i></div>
        <?php } ?>
        <?php if ($hp > 0) { ?><div class="tzq-row"><span>Damage taken</span><b class="tzq-neg">&minus;<?php echo $hp; ?>%</b></div><?php } ?>
        <?php if ($heal > 0) { ?><div class="tzq-row"><span>Healed</span><b class="tzq-pos">+<?php echo $heal; ?>%</b></div><?php } ?>
        <?php if ($hasCtx && !$died) { ?>
            <div class="tzq-row" style="margin-top:4px"><span>Level</span><b><?php echo $lvlAfter; ?><?php if ($lvlAfter > $lvlBefore) { ?><span class="tzq-chip tzq-chip-lvl">Level up!</span><?php } ?></b></div>
            <div class="tzq-bar"><i style="width:<?php echo $lvlPct; ?>%"></i></div>
            <div class="tzq-vs-legend"><span><?php echo number_format($xpAfter); ?> XP</span><span><?php echo $nextNeed > 0 ? number_format($nextNeed) . ' for level ' . ($lvlAfter + 1) : 'max level'; ?></span></div>
        <?php } ?>
    </div>

    <?php if (!$died) { ?>
    <div class="tzq-box">
        <h4>Rewards</h4>
        <div class="tzq-row"><span><?php echo tz_hero_adv('HERO_EXPERIENCE', 'Experience'); ?></span><b>+<?php echo number_format($exp); ?><?php if ($exp > $expBase) { ?> <small>(+<?php echo $exp - $expBase; ?> helmet)</small><?php } ?></b></div>
        <?php if (array_sum($res) > 0) { ?>
            <div class="tzq-row tzq-res"><span>Resources</span><b><?php foreach ($res as $k => $n) { if ($n > 0) { ?><span><img class="r<?php echo $k; ?>" src="img/x.gif" alt="<?php echo $resNames[$k]; ?>" title="<?php echo $resNames[$k]; ?>"> <?php echo number_format($n); ?></span><?php } } ?></b></div>
            <div class="tzq-note">Carried home by the hero &ndash; added to the village when it arrives.</div>
        <?php } ?>
        <?php if ($itemId > 0 && $itemQty > 0) { ?>
            <div class="tzq-row"><span>Item found</span><b><?php echo $itemQty > 1 ? $itemQty . '&times; ' : ''; ?><?php echo heroItemName($itemId); ?></b></div>
            <?php if ($slotName !== '' || $itemQual !== 0) { ?><div class="tzq-note" style="text-align:right"><?php echo htmlspecialchars($slotName); ?><?php if ($itemQual !== 0) echo ($slotName !== '' ? ' &middot; ' : '') . ($itemQual > 0 ? '+' : '') . $itemQual . '% quality'; ?></div><?php } ?>
        <?php } ?>
        <?php if ($silver > 0) { ?><div class="tzq-row"><span><?php echo tz_hero_adv('HERO_SILVER', 'Silver'); ?></span><b>+<?php echo number_format($silver); ?></b></div><?php } ?>
    </div>
    <?php } ?>

</div>
</div>
</td></tr>
</tbody>
</table>
