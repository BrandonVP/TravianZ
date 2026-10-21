<?php

#################################################################################
##              -= YOU MAY NOT REMOVE OR CHANGE THIS NOTICE =-                 ##
## --------------------------------------------------------------------------- ##
##  Filename       : TOURNAMENT SQUARE                                         ##
##  Type           : BUILDING TEMPLATE                                         ##
## --------------------------------------------------------------------------- ##
##  Refactored by  : Shadow                                                    ##
##  Redesign by    : Shadow                                                    ##
## --------------------------------------------------------------------------- ##
##  Contact        : cata7007@gmail.com                                        ##
##  Project        : TravianZ                                                  ##
##  Test Server    : https://travianz.org                                      ##
##  GitHub         : https://github.com/Shadowss/TravianZ                      ##
## --------------------------------------------------------------------------- ##
##  License        : TravianZ Project                                          ##
##  Copyright      : TravianZ (c) 2010-2026. All rights reserved.              ##
## --------------------------------------------------------------------------- ##
#################################################################################

// local redesign: war games (GameEngine/WarGames.php) - handled before any output
include_once __DIR__ . '/../../GameEngine/WarGames.php';
$tzWgMsg = '';
if (isset($_POST['tzwargames']) && VillageGold::pays($village)
    && (!method_exists($session, 'sitterCan') || $session->sitterCan(SITTER_PERM_GOLD))
    && hash_equals((string) $session->checker, (string) ($_POST['c'] ?? ''))) {
    $tzWgErr = WarGames::start($database, $village, $session->uid, (int) ($village->resarray['f' . $id] ?? 0));
    $tzWgMsg = $tzWgErr === '' ? 'War games started.' : $tzWgErr;
}

include 'next.tpl';

$field         = 'f' . $id;
$currentLevel  = (int)($village->resarray[$field] ?? 0);
$buildingType  = $village->resarray[$field . 't'] ?? 0;

$currentSpeed  = $currentLevel > 0 ? $bid14[$currentLevel]['attri'] : 100;

$isMax         = $building->isMax($buildingType, $id);
$maxLevel      = 20;

$nextLevelRaw  = $currentLevel + 1 + $loopsame + $doublebuild + $master;
$nextLevel     = min($nextLevelRaw, $maxLevel);
$nextSpeed     = $bid14[$nextLevel]['attri'];
?>
<div id="build" class="gid14">
    <a href="#" onclick="return Popup(14,4);" class="build_logo">
        <img class="building g14" src="img/x.gif" alt="<?= TOURNAMENTSQUARE ?>" title="<?= TOURNAMENTSQUARE ?>">
    </a>

    <h1>
        <?= TOURNAMENTSQUARE ?>
        <span class="level"><?= LEVEL ?> <?= $currentLevel ?></span>
    </h1>

    <p class="build_desc"><?= TOURNAMENTSQUARE_DESC ?></p>

    <table cellpadding="1" cellspacing="1" id="build_value">
        <tr>
            <th><?= CURRENT_SPEED ?>:</th>
            <td><b><?= $currentSpeed ?></b> <?= PERCENT ?></td>
        </tr>

        <?php if (!$isMax): ?>
        <tr>
            <th><?= SPEED_LEVEL ?> <?= $nextLevel ?>:</th>
            <td><b><?= $nextSpeed ?></b> <?= PERCENT ?></td>
        </tr>
        <?php endif; ?>
    </table>

    <?php include 'upgrade.tpl'; ?>
<?php
if ($currentLevel > 0 && VillageGold::pays($village)) {
    $tzWg     = WarGames::state($database, $village->wid);
    $tzPhase  = WarGames::phase($tzWg);
    $tzCost   = WarGames::cost($currentLevel);
    $tzBonus  = WarGames::bonusFor($currentLevel);
    $tzLeft   = function ($until) { return $GLOBALS['generator']->getTimeFormat(max(0, (int) $until - time())); };
?>
<div class="tz-wargames">
    <h4>War games</h4>
    <p class="tz-wg-desc">Run a training exercise. When it is over, the next attack or raid you send
        from this village within <?php echo (int) (TZ_WARGAMES_WINDOW / 3600); ?> hours fights with
        <b>+<?php echo $tzBonus; ?>% attack</b> (<?php echo TZ_WARGAMES_BONUS_L1; ?>% at level 1 up to
        <?php echo TZ_WARGAMES_BONUS_L20; ?>% at level 20). One exercise per week.</p>
    <?php if ($tzWgMsg !== '') echo '<p class="tz-wg-msg">' . htmlspecialchars($tzWgMsg) . '</p>'; ?>
    <?php if ($tzPhase === 'training') { ?>
        <p class="tz-wg-state">Exercise running (+<?php echo (int) $tzWg['bonus']; ?>%): done in
            <span id="timer<?php echo ++$session->timer; ?>"><?php echo $tzLeft($tzWg['ready']); ?></span>.</p>
    <?php } elseif ($tzPhase === 'ready') { ?>
        <p class="tz-wg-state tz-on">Troops are ready: +<?php echo (int) $tzWg['bonus']; ?>% attack on the next attack or raid sent from here.
            Expires in <span id="timer<?php echo ++$session->timer; ?>"><?php echo $tzLeft($tzWg['until']); ?></span>.</p>
    <?php } elseif ($tzPhase === 'cooldown') { ?>
        <?php $tzNext = (int) $tzWg['started'] + TZ_WARGAMES_COOLDOWN; $tzIn = max(0, $tzNext - time()); ?>
        <p class="tz-wg-state">Next exercise possible on <?php echo date('d.m.Y H:i', $tzNext); ?>
            (in <?php echo floor($tzIn / 86400); ?> d <?php echo floor(($tzIn % 86400) / 3600); ?> h).</p>
    <?php } else { ?>
        <form method="post" action="build.php?id=<?php echo (int) $id; ?>" class="tz-wg-form"
              onsubmit="return confirm('Start war games for <?php echo (int) $tzCost['gold']; ?> gold and the resources shown?');">
            <input type="hidden" name="tzwargames" value="1">
            <input type="hidden" name="c" value="<?php echo htmlspecialchars((string) $session->checker); ?>">
            <div class="tz-wg-cost">
                <img class="r1" src="img/x.gif" alt="<?php echo LUMBER; ?>" title="<?php echo LUMBER; ?>" /><?php echo $tzCost['wood']; ?> |
                <img class="r2" src="img/x.gif" alt="<?php echo CLAY; ?>" title="<?php echo CLAY; ?>" /><?php echo $tzCost['clay']; ?> |
                <img class="r3" src="img/x.gif" alt="<?php echo IRON; ?>" title="<?php echo IRON; ?>" /><?php echo $tzCost['iron']; ?> |
                <img class="r4" src="img/x.gif" alt="<?php echo CROP; ?>" title="<?php echo CROP; ?>" /><?php echo $tzCost['crop']; ?> |
                <svg class="tz-coin-sm" viewBox="0 0 24 24" aria-label="Gold" role="img"><circle cx="12" cy="12" r="10" fill="#e3b427" stroke="#9a7512" stroke-width="1.5"/><circle cx="12" cy="12" r="6.5" fill="none" stroke="#9a7512" stroke-width="1"/></svg><?php echo $tzCost['gold']; ?> |
                <img class="clock" src="img/x.gif" alt="duration" title="duration" /><?php echo $generator->getTimeFormat(WarGames::duration()); ?>
            </div>
            <button type="submit" class="tz-btn tz-btn-sm">Start war games</button>
        </form>
    <?php } ?>
</div>
<?php } ?>
</div>