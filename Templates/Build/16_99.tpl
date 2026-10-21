<?php

#################################################################################
##              -= YOU MAY NOT REMOVE OR CHANGE THIS NOTICE =-                 ##
## --------------------------------------------------------------------------- ##
##  Filename       : RALLY POINT GOLD CLUB                                     ##
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

if (!$session->goldclub) {
    include 'Templates/Build/16.tpl';
    return;
}

$hideEvasion = isset($hideevasion) ? (int)$hideevasion : 0;
$user = $database->getUserArray($session->uid, 1);
?>
<div id="build" class="gid16">
    <a href="#" onclick="return Popup(16,4);" class="build_logo">
        <img class="g16" src="img/x.gif" alt="<?php echo RALLYPOINT; ?>" title="<?= RALLYPOINT ?>">
    </a>
    <h1><?= RALLYPOINT ?> <span class="level"><?= LEVEL ?> <?= $village->resarray['f'.$id] ?></span></h1>
    <p class="build_desc"><?= RALLYPOINT_DESC ?></p>

    <?php include '16_menu.tpl'; ?>

    <div id="raidList">
        <?php include 'Templates/goldClub/farmlist.tpl'; ?>
    </div>
    <br>

    <?php if ($hideEvasion == 0): ?>
    <table id="raidList" cellpadding="1" cellspacing="1">
        <thead>
            <tr><th colspan="4"><?= EVASION_SETTINGS ?></th></tr>
            <tr>
                <td></td>
                <td><?= VILLAGE ?></td>
                <td><?= OWN_TROOPS ?></td>
                <td><?= REINFORCEMENT ?></td>
            </tr>
        </thead>
        <tbody>
            <?php foreach ($session->villages as $wref):
                $vname = $database->getVillageField($wref, 'name');
                $vchecked = $database->getVillageField($wref, 'evasion');
                $reinf = $database->getEnforceVillage($wref, 0);
                $checked = $vchecked == 1 ? 'checked' : '';
            ?>
            <tr>
                <td><input type="checkbox" class="check" name="hideShow" onclick="window.location.href='?gid=16&t=99&evasion=<?= $wref ?>';" <?= $checked ?>></td>
                <td><?= $vname ?></td>
                <td><div style="text-align:center"><?= $database->getUnitsNumber($wref) ?></div></td>
                <td><div style="text-align:center"><?= count($reinf) ?></div></td>
            </tr>
            <?php endforeach; ?>
        </tbody>
    </table>

    <form action="build.php?id=39&t=99" method="POST">
        <br>
        <?= SEND_TROOPS_AWAY_MAX ?>
        <input class="text" type="text" name="maxevasion" value="<?= $user['maxevasion'] ?>" maxlength="3" style="width:50px;">
        <?= TIMES ?>
        <?php if (class_exists('VillageGold') && VillageGold::villageMode()): // local redesign: village gold ?>
        <span class="none">(<?= COSTS ?>: <svg class="tz-coin-sm" viewBox="0 0 24 24" aria-label="Gold" role="img"><circle cx="12" cy="12" r="10" fill="#e3b427" stroke="#9a7512" stroke-width="1.5"/><circle cx="12" cy="12" r="6.5" fill="none" stroke="#9a7512" stroke-width="1"/></svg><b><?= (int) TZ_GOLD_PRICE_EVASION ?></b> <?= PER_EVASION ?>, paid from the gold of the village whose troops evade; no gold there, no evasion)</span>
        <?php else: ?>
        <span class="none">(<?= COSTS ?>: <img src="<?= GP_LOCATE ?>img/a/gold_g.gif" alt="<?php echo GOLD; ?>" title="<?= GOLD ?>"><b>2</b> <?= PER_EVASION ?>)</span>
        <?php endif; ?>
        <div class="clear"></div>
        <p><button value="ok" name="s1" id="btn_ok" class="trav_buttons" tabindex="8">OK</button></p>
    </form>
    <?php endif; ?>
</div>