<?php
#################################################################################
##  Local redesign (Empires of Rome): Gold Mine - a resource field that       ##
##  produces village gold. Gold per hour comes from TZ_GOLDMINE_GOLD          ##
##  (GameEngine/Data/gold.php) times the server speed.                        ##
#################################################################################

include 'next.tpl';

$field         = 'f' . $id;
$currentLevel  = (int) ($village->resarray[$field] ?? 0);
$buildingType  = $village->resarray[$field . 't'] ?? 0;

$tzGoldTable   = defined('TZ_GOLDMINE_GOLD') ? TZ_GOLDMINE_GOLD : array(0);
$tzGoldAt      = function ($lvl) use ($tzGoldTable) {
    return (float) ($tzGoldTable[$lvl] ?? end($tzGoldTable)) * SPEED;
};
$currentProd   = $tzGoldAt($currentLevel);

$isMax         = $building->isMax($buildingType, $id);
$maxLevel      = ($village->capital == 1) ? 20 : (defined('FIELD_MAX_NONCAPITAL') ? (int) FIELD_MAX_NONCAPITAL : 10);

$nextLevelRaw  = $currentLevel + 1 + $loopsame + $doublebuild + $master;
$nextLevel     = min($nextLevelRaw, $maxLevel);
$nextProd      = $tzGoldAt($nextLevel);
$tzFmt         = function ($v) { return rtrim(rtrim(number_format($v, 1), '0'), '.'); };
?>
<div id="build" class="gid51">
    <a href="#" onclick="return false;" class="build_logo">
        <img class="building g51" src="img/x.gif" alt="<?= GOLDMINE ?>" title="<?= GOLDMINE ?>">
    </a>

    <h1>
        <?= GOLDMINE ?>
        <span class="level"><?= LEVEL ?> <?= $currentLevel ?></span>
    </h1>

    <p class="build_desc"><?= GOLDMINE_DESC ?></p>

    <table cellpadding="1" cellspacing="1" id="build_value">
        <tr>
            <th><?= CUR_PROD ?>:</th>
            <td><b><?= $tzFmt($currentProd) ?></b> gold <?= PER_HR ?></td>
        </tr>

        <?php if (!$isMax): ?>
        <tr>
            <th><?= NEXT_PROD ?> <?= $nextLevel ?>:</th>
            <td><b><?= $tzFmt($nextProd) ?></b> gold <?= PER_HR ?></td>
        </tr>
        <?php endif; ?>
    </table>

    <?php include 'upgrade.tpl'; ?>
</div>
