<?php

#################################################################################
##              -= YOU MAY NOT REMOVE OR CHANGE THIS NOTICE =-                 ##
## --------------------------------------------------------------------------- ##
##  Filename       : TREASURY				                                   ##
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

?>

<body>
    <div id="build" class="gid27">
        <a href="#" onclick="return Popup(27,4);" class="build_logo"><img class="building g27" src="img/x.gif" alt="<?php echo TREASURY; ?>" title="<?php echo TREASURY; ?>"></a>

        <h1><?php echo TREASURY; ?> <span class="level"><?php echo LEVEL; ?> <?php echo $village->resarray['f'.$id] ?? 0; ?></span></h1>

        <p class="build_desc"><?php echo TREASURY_DESC; ?></p>
        <?php
        // Village gold (local redesign): the Treasury is also the gold vault
        if (!empty($village->goldActive)) {
            $tzVaultLevel = (int) ($village->resarray['f'.$id] ?? 0);
            $tzVaultNow = VillageGold::treasuryHolds($tzVaultLevel);
            $tzVaultNext = $tzVaultLevel < 20 ? VillageGold::treasuryHolds($tzVaultLevel + 1) : 0;
        ?>
        <div class="tz-vault">
            <svg class="tz-coin-sm" viewBox="0 0 24 24" aria-hidden="true"><circle cx="12" cy="12" r="10" fill="#e3b427" stroke="#9a7512" stroke-width="1.5"/><circle cx="12" cy="12" r="6.5" fill="none" stroke="#9a7512" stroke-width="1"/></svg>
            <b>Gold vault</b>:
            <?php if ($tzVaultNow > 0) { ?>
                holds and protects <b><?php echo number_format($tzVaultNow); ?></b> gold from raids.
            <?php } else { ?>
                stores no gold until it is built.
            <?php } ?>
            <?php if ($tzVaultNext > 0) { ?>
                Level <?php echo $tzVaultLevel + 1; ?>: <b><?php echo number_format($tzVaultNext); ?></b>.
            <?php } ?>
            <br><span class="tz-vault-note">A village always has room for <?php echo number_format(TZ_GOLD_CAP); ?> gold; gold outside the Treasury can be stolen by raids. The Treasury takes 1/<?php echo (int) TZ_GOLD_TREASURY_TOUGHNESS; ?> of normal catapult damage.</span>
        </div>
        <?php } ?>
        <?php     
        $treasuryLevel = $building->getTypeLevel(27) ?? 0;
        
        if($treasuryLevel > 0){
            include("27_menu.tpl");
            
            $show = (int)($_GET['show'] ?? 0);
            $t = (int)($_GET['t'] ?? 0);
            
            if($show > 0) {
                include("27_show.tpl");
            } else {
                if($t === 0 || $t === 1) {
                    include("27_1.tpl");
                } elseif($t === 2) {
                    include("27_2.tpl");
                } elseif($t === 3) {
                    include("27_3.tpl");
                } else {
                    include("27_1.tpl");
                }
            }       
        } else {
            echo '<b>'.TREASURY_COMMENCE.'</b><br>';
        }
        
        include("upgrade.tpl");
        ?>
    </div>