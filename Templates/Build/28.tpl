<?php

#################################################################################
##              -= YOU MAY NOT REMOVE OR CHANGE THIS NOTICE =-                 ##
## --------------------------------------------------------------------------- ##
##  Filename       : TRADEOFFICE    		                                   ##
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

global $village, $building, $bid28, $id, $loopsame, $doublebuild, $master;

include("next.tpl");

$level = (int)$village->resarray['f'.$id];
$current = $level > 0 ? (int)$bid28[$level]['attri'] : 100;
?>
<div id="build" class="gid28">
    <a href="#" onClick="return Popup(28,4);" class="build_logo">
        <img class="building g28" src="img/x.gif" alt="<?php echo TRADEOFFICE; ?>" title="<?php echo TRADEOFFICE;?>" />
    </a>
    <h1><?php echo TRADEOFFICE;?> <span class="level"><?php echo LEVEL;?> <?php echo $level;?></span></h1>
    <p class="build_desc"><?php echo TRADEOFFICE_DESC;?></p>

    <table cellpadding="1" cellspacing="1" id="build_value">
        <tr>
            <th><?php echo CURRENT_MERCHANT;?></th>
            <td><b><?php echo $current;?></b> <?php echo PERCENT;?></td>
        </tr>
        <tr>
            <?php if (!$building->isMax($village->resarray['f'.$id.'t'], $id)):
                $next = $level + 1 + $loopsame + $doublebuild + $master;
                $next = $next > 20 ? 20 : $next;
            ?>
            <th><?php echo MERCHANT_LEVEL;?> <?php echo $next;?>:</th>
            <td><b><?php echo (int)$bid28[$next]['attri'];?></b> <?php echo PERCENT;?></td>
            <?php endif;?>
        </tr>
        <?php if (class_exists('VillageGold') && !empty($village->goldActive)):
            // local redesign: express caravans and a cheaper NPC trade
            $tzNext = min(20, $level + 1); ?>
        <tr>
            <th>Express caravan speed:</th>
            <td><b>&times;<?php echo round(VillageGold::expressSpeed($level), 1);?></b>
                <?php if ($level < 20):?><span class="none">(level <?php echo $tzNext;?>: &times;<?php echo round(VillageGold::expressSpeed($tzNext), 1);?>)</span><?php endif;?></td>
        </tr>
        <tr>
            <th>NPC trade price:</th>
            <td><b><?php echo max(1, TZ_GOLD_PRICE_NPC - $level * TZ_NPC_DISCOUNT_PER_LEVEL);?></b> gold
                <?php if ($level < 20):?><span class="none">(level <?php echo $tzNext;?>: <?php echo max(1, TZ_GOLD_PRICE_NPC - $tzNext * TZ_NPC_DISCOUNT_PER_LEVEL);?>)</span><?php endif;?></td>
        </tr>
        <?php endif;?>
    </table>
    <?php if (class_exists('VillageGold') && !empty($village->goldActive)):?>
    <p class="tz-to-note">Express caravans: on the Marketplace's Send Resources tab, tick "Express caravan" to send to one of your own villages faster, for <?php echo (int) TZ_EXPRESS_GOLD_PER_MERCHANT;?> gold per merchant.</p>
    <?php endif;?>

    <?php include("upgrade.tpl");?>
</div>