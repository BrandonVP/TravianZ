<?php

#################################################################################
##              -= YOU MAY NOT REMOVE OR CHANGE THIS NOTICE =-                 ##
## --------------------------------------------------------------------------- ##
##  Filename       : UPGRADE PAGE			                                   ##
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

global $village, $building, $database, $generator, $session, $technology, $id;

$bid = (int)$village->resarray['f'.$id.'t'];
$bindicate = $building->canBuild($id, $bid);

if ($bindicate == 1) {
    echo '<p><span class="none">'.MAX_LEVEL.'</span></p>';
    return;
}
if ($bindicate == 10) {
    echo '<p><span class="none">'.BUILDING_MAX_LEVEL_UNDER.'</span></p>';
    return;
}
if ($bindicate == 11) {
    echo '<p><span class="none">'.BUILDING_BEING_DEMOLISHED.'</span></p>';
    return;
}
if ($bindicate == 12) {
    // local redesign: raid balance
    echo '<p><span class="none">Cranny levels above 10 need a level 20 Warehouse (or Great Warehouse) and a level 20 Granary (or Great Granary) in this village.</span></p>';
    return;
}

$loopsame = ($building->isCurrent($id) || $building->isLoop($id))? 1 : 0;
$doublebuild = ($building->isCurrent($id) && $building->isLoop($id))? 1 : 0;
$master = count($database->getMasterJobsByField($village->wid, $id));
if ($master == 1 && $loopsame == 1) $loopsame = 0;

// local redesign: any number of levels can be queued per field
$tzQueued = $building->queuedOnField($id);
$nextLevel = (int)$village->resarray['f'.$id] + 1 + $tzQueued;
$uprequire = $building->resourceRequired($id, $bid, 1 + $tzQueued);
$total_required = (int)($uprequire['wood'] + $uprequire['clay'] + $uprequire['iron'] + $uprequire['crop']);
?>
<p id="contract">
    <b><?php echo COSTS_UPGRADING_LEVEL;?> <?php echo $nextLevel;?>:</b><br />
    <img class="r1" src="img/x.gif" title="<?php echo LUMBER;?>"/><span class="little_res"><?php echo $uprequire['wood'];?></span> |
    <img class="r2" src="img/x.gif" title="<?php echo CLAY;?>"/><span class="little_res"><?php echo $uprequire['clay'];?></span> |
    <img class="r3" src="img/x.gif" title="<?php echo IRON;?>"/><span class="little_res"><?php echo $uprequire['iron'];?></span> |
    <img class="r4" src="img/x.gif" title="<?php echo CROP;?>"/><span class="little_res"><?php echo $uprequire['crop'];?></span> |
    <?php if (!empty($uprequire['gold'])):?><svg class="tz-coin-sm" viewBox="0 0 24 24" aria-label="Gold" role="img"><circle cx="12" cy="12" r="10" fill="#e3b427" stroke="#9a7512" stroke-width="1.5"/><circle cx="12" cy="12" r="6.5" fill="none" stroke="#9a7512" stroke-width="1"/></svg><span class="little_res"><?php echo $uprequire['gold'];?></span> |<?php endif;?>
    <img class="r5" src="img/x.gif" title="<?php echo CROP_COM;?>"/><?php echo $uprequire['pop'];?> |
    <img class="clock" src="img/x.gif" title="<?php echo DURATION;?>"/><?php echo $generator->getTimeFormat($uprequire['time']);?>
    <?php if (VillageGold::npcCan($village, $session) && $building->getTypeLevel(17) >= 1 && $village->atotal >= $total_required):?>
    | <a href="build.php?gid=17&t=3&r1=<?php echo $uprequire['wood'];?>&r2=<?php echo $uprequire['clay'];?>&r3=<?php echo $uprequire['iron'];?>&r4=<?php echo $uprequire['crop'];?>" title="<?php echo NPC_TRADE; ?>"><img class="npc" src="img/x.gif" alt="<?php echo NPC_TRADE; ?>"/></a>
    <?php endif;?>
    <br />
<?php
switch ($bindicate) {
    case 2:
        echo '<span class="none">'.WORKERS_ALREADY_WORK.'</span>';
        break;
    case 3:
        echo '<span class="none">'.WORKERS_ALREADY_WORK_WAITING.'</span>';
        break;
    case 4:
        echo '<span class="none">'.ENOUGH_FOOD_EXPAND_CROPLAND.'</span>';
        break;
    case 5:
        echo '<span class="none">'.UPGRADE_WAREHOUSE.'.</span>';
        break;
    case 6:
        echo '<span class="none">'.UPGRADE_GRANARY.'.</span>';
        break;
    case 7:
        if (!empty($uprequire['gold']) && $uprequire['gold'] > floor((float) $village->agold)) {
            // local redesign: the Treasury also needs gold
            echo '<span class="none">Not enough gold in this village (' . (int) $uprequire['gold'] . ' needed).</span>';
        } elseif ($village->allcrop - $village->pop - $technology->getUpkeep($village->unitall, 0) > 0) {
            $neededtime = $building->calculateAvaliable($id, $bid, 1 + $tzQueued);
            echo '<span class="none">'.ENOUGH_RESOURCES.' '.$neededtime[0].' at '.$neededtime[1].'</span>';
        } else {
            echo '<span class="none">'.YOUR_CROP_NEGATIVE.'</span>';
        }
        break;
    case 8:
    case 9:
        $href = $session->access == BANNED? 'banned.php' : (($id <= 18)? "dorf1.php?a=$id&c=$session->checker" : "dorf2.php?a=$id&c=$session->checker");
        $lvl = $nextLevel;
        echo '<a class="build" href="'.$href.'">'.UPGRADE_LEVEL.' '.$lvl.'.</a>';
        if ($bindicate == 9) echo ' <span class="none">'.WAITING.'</span>';
        break;
}

if (in_array($bindicate, [2,3,7]) && $session->goldclub == 1) {
    echo '<br/>';
    $masterHref = ($id <= 18? 'dorf1.php' : 'dorf2.php'). "?master=$bid&id=$id&c=$session->checker";
    if (VillageGold::masterCan($village, $session) && $village->master == 0) {
        echo '<a class="build" href="'.$masterHref.'">'.CONSTRUCTING_MASTER_BUILDER.'</a>';
    } else {
        echo '<span class="none">'.CONSTRUCTING_MASTER_BUILDER.'</span>';
    }
    echo ' <font color="#B3B3B3">('.COSTS.': '.VillageGold::priceTag($village, TZ_GOLD_PRICE_MASTER, 1).')</font>';
}
?>
</p>