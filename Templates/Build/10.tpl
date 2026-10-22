<?php

#################################################################################
##              -= YOU MAY NOT REMOVE OR CHANGE THIS NOTICE =-                 ##
## --------------------------------------------------------------------------- ##
##  Filename       : WAREHOUSE                                                 ##
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

// local redesign: rented storage for a day (GameEngine/StorageBoost.php) - handled before any output
include_once __DIR__ . '/../../GameEngine/StorageBoost.php';
$tzBoostLevel = max((int) $building->getTypeLevel(10), (int) $building->getTypeLevel(38));
$tzBoostMsg = '';
if (isset($_POST['tzboost']) && hash_equals((string) $session->checker, (string) ($_POST['c'] ?? ''))
    && (!method_exists($session, 'sitterCan') || $session->sitterCan(SITTER_PERM_GOLD))) {
    $tzBoostErr = StorageBoost::start($database, $village, $session->uid, 'store', $tzBoostLevel);
    $tzBoostMsg = $tzBoostErr === '' ? 'Done: the extra room is yours for another day.' : $tzBoostErr;
}

include 'next.tpl';

$field            = 'f' . $id;
$currentLevel     = (int) ($village->resarray[$field] ?? 0);
$buildingType     = $village->resarray[$field . 't'] ?? 0;

// $bid10 is keyed from level 1 upward; at level 0 (not built yet) fall back to the base capacity
$currentCapacity  = ($currentLevel > 0) ? $bid10[$currentLevel]['attri'] * STORAGE_MULTIPLIER : STORAGE_BASE;

$isMax            = $building->isMax($buildingType, $id);
$maxLevel         = count($bid10); // local redesign: levels 21-25

$nextLevelRaw     = $currentLevel + 1 + $loopsame + $doublebuild + $master;
$nextLevel        = min($nextLevelRaw, $maxLevel);
$nextCapacity     = $bid10[$nextLevel]['attri'] * STORAGE_MULTIPLIER;
?>
<div id="build" class="gid10">
    <a href="#" onclick="return Popup(10,4);" class="build_logo">
        <img class="building g10" src="img/x.gif" alt="<?= WAREHOUSE ?>" title="<?= WAREHOUSE ?>">
    </a>

    <h1>
        <?= WAREHOUSE ?>
        <span class="level"><?= LEVEL ?> <?= $currentLevel ?></span>
    </h1>

    <p class="build_desc"><?= WAREHOUSE_DESC ?></p>

    <table cellpadding="1" cellspacing="1" id="build_value">
        <tr>
            <th><?= CURRENT_CAPACITY ?>:</th>
            <td><b><?= $currentCapacity ?></b> <?= RESOURCE_UNITS ?></td>
        </tr>

        <?php if (!$isMax): ?>
        <tr>
            <th><?= CAPACITY_LEVEL ?> <?= $nextLevel ?>:</th>
            <td><b><?= $nextCapacity ?></b> <?= RESOURCE_UNITS ?></td>
        </tr>
        <?php endif; ?>
    </table>

    <?php include 'upgrade.tpl'; ?>
<?php if (VillageGold::pays($village) && $tzBoostLevel > 0):
    $tzBoostUntil = StorageBoost::until($database, $village->wid, 'store');
    $tzBoostOn = $tzBoostUntil > time();
    $tzBoostPrice = StorageBoost::price($tzBoostLevel);
    // read fresh: hiring just now changed the capacity after the page data was loaded
    $tzCapNow = (int) mysqli_fetch_row(mysqli_query($database->dblink, "SELECT maxstore FROM " . TB_PREFIX . "vdata WHERE wref = " . (int) $village->wid))[0];
    $tzNormal = $tzBoostOn ? (int) round($tzCapNow / (1 + TZ_BOOST_SHARE)) : $tzCapNow; ?>
    <div class="tz-boost<?php echo $tzBoostOn ? ' is-on' : ''; ?>">
        <h4><?php echo StorageBoost::name('store'); ?></h4>
        <p class="tz-boost-story"><?php echo StorageBoost::story('store'); ?></p>
        <p>+<?php echo round(TZ_BOOST_SHARE * 100); ?>% warehouse room for 24 hours
            (<?php echo number_format($tzNormal); ?> &rarr; <b><?php echo number_format((int) round($tzNormal * (1 + TZ_BOOST_SHARE))); ?></b>).
            Renewing adds another day.</p>
        <?php if ($tzBoostMsg !== ''): ?><p class="tz-boost-msg"><?php echo htmlspecialchars($tzBoostMsg); ?></p><?php endif; ?>
        <?php if ($tzBoostOn): ?>
            <p class="tz-boost-on">Rented until <?php echo date('d.m. H:i', $tzBoostUntil); ?>
                (<span id="timer<?php echo ++$session->timer; ?>"><?php echo $generator->getTimeFormat($tzBoostUntil - time()); ?></span>).
                When it ends, anything above <?php echo number_format($tzNormal); ?> is lost - use it up first.</p>
        <?php endif; ?>
        <form method="post" action="build.php?id=<?php echo (int) $id; ?>" class="tz-boost-form"
              onsubmit="return confirm('<?php echo $tzBoostOn ? 'Renew for another day' : 'Rent the extra room for a day'; ?> for <?php echo $tzBoostPrice['wood']; ?> wood and <?php echo $tzBoostPrice['gold']; ?> gold?');">
            <input type="hidden" name="tzboost" value="1">
            <input type="hidden" name="c" value="<?php echo htmlspecialchars((string) $session->checker); ?>">
            <span class="tz-boost-cost"><img class="r1" src="img/x.gif" alt="Lumber" title="Lumber" /><?php echo number_format($tzBoostPrice['wood']); ?> |
                <svg class="tz-coin-sm" viewBox="0 0 24 24" aria-hidden="true"><circle cx="12" cy="12" r="10" fill="#e3b427" stroke="#9a7512" stroke-width="1.5"/><circle cx="12" cy="12" r="6.5" fill="none" stroke="#9a7512" stroke-width="1"/></svg><?php echo $tzBoostPrice['gold']; ?></span>
            <button type="submit" class="tz-btn tz-btn-sm"><?php echo $tzBoostOn ? 'Renew for another day' : StorageBoost::name('store'); ?></button>
        </form>
    </div>
<?php endif; ?>
</div>