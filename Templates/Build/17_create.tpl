<?php

#################################################################################
##              -= YOU MAY NOT REMOVE OR CHANGE THIS NOTICE =-                 ##
## --------------------------------------------------------------------------- ##
##  Filename       : MARKETPLACE CREATE ROUTE                                  ##
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

global $database, $session, $village;

$villages = $session->villages?? [];
$firstSelect = ($villages[0]?? 0) == $village->wid? 1 : 0;
?>
<form action="build.php" method="post">
    <div class="boxes boxesColor gray"><div class="boxes-tl"></div><div class="boxes-tr"></div><div class="boxes-tc"></div><div class="boxes-ml"></div><div class="boxes-mr"></div><div class="boxes-mc"></div><div class="boxes-bl"></div><div class="boxes-br"></div><div class="boxes-bc"></div><div class="boxes-contents cf">
        <input type="hidden" name="action" value="addRoute">
        <table cellpadding="1" cellspacing="1" id="npc" class="transparent">
            <thead>
                <tr><th colspan="2"><?php echo CREATE_TRADE_ROUTE;?></th></tr>
            </thead>
            <tbody>
                <tr>
                    <th><?php echo TARGET_VILLAGE;?>:</th>
                    <td>
                        <select id="tvillage" name="tvillage">
                            <?php
                            $idx = 0;
                            foreach ($villages as $vid) {
                                $vid = (int)$vid;
                                if ($vid === (int)$village->wid) continue;
                                $coor = $database->getCoor($vid);
                                $name = htmlspecialchars($database->getVillageField($vid, 'name'));
                                $selected = ($idx === $firstSelect)? 'selected' : '';
                                echo '<option value="'.$vid.'" '.$selected.'>'.$name.' ('.(int)$coor['x'].'|'.(int)$coor['y'].')</option>';
                                $idx++;
                            }
                           ?>
                        </select>
                    </td>
                </tr>
                <tr>
                    <th><?php echo RESOURCES;?>:</th>
                    <td>
                        <?php $icons = [1=>'1',2=>'2',3=>'3',4=>'4']; $names = [1=>LUMBER,2=>CLAY,3=>IRON,4=>CROP];
                        foreach ($icons as $i => $img):?>
                            <img src="../../<?php echo GP_LOCATE;?>img/r/<?php echo $img;?>.gif" alt="<?php echo $names[$i];?>" title="<?php echo $names[$i];?>">
                            <input class="text" type="text" name="r<?php echo $i;?>" id="r<?php echo $i;?>" value="" maxlength="9" tabindex="1" style="width:50px;">
                        <?php endforeach;?>
                    </td>
                </tr>
                <?php if (!empty($village->goldActive)):?>
                <tr>
                    <th>Gold:</th>
                    <td>
                        <svg class="tz-coin-sm" viewBox="0 0 24 24" aria-label="Gold" role="img"><circle cx="12" cy="12" r="10" fill="#e3b427" stroke="#9a7512" stroke-width="1.5"/><circle cx="12" cy="12" r="6.5" fill="none" stroke="#9a7512" stroke-width="1"/></svg>
                        <input class="text" type="text" name="r5" value="<?php echo '';?>" maxlength="7" style="width:50px;">
                        <span class="tz-route-hint">1 gold uses 100 merchant space</span>
                    </td>
                </tr>
                <?php endif;?>
                <tr>
                    <th>Send:</th>
                    <td class="tz-route-when">
                        <label><input type="radio" name="trig" value="time" <?php if (!(false)) echo 'checked';?>>
                            every day at
                            <select name="start">
                                <?php for ($h = 0; $h < 24; $h++):?>
                                    <option value="<?php echo $h;?>" <?php if($h === (0)) echo 'selected';?>><?php echo str_pad($h,2,'0',STR_PAD_LEFT);?>:00</option>
                                <?php endfor;?>
                            </select>
                        </label>
                        <label><input type="radio" name="trig" value="full" <?php if (false) echo 'checked';?>>
                            when storage is at least
                            <select name="trig_pct">
                                <?php for ($pc = 50; $pc <= 100; $pc += 5):?>
                                    <option value="<?php echo $pc;?>" <?php if($pc === (90)) echo 'selected';?>><?php echo $pc;?>%</option>
                                <?php endfor;?>
                            </select>
                            full
                        </label>
                        <span class="tz-route-hint">"When full" sends as soon as any resource of this route reaches that level, then waits 15 minutes.</span>
                    </td>
                </tr>
                <tr>
                    <th>Auto-renew:</th>
                    <td><label><input type="checkbox" name="autorenew" value="1" <?php if (false) echo 'checked';?>>
                        pay <?php echo VillageGold::priceTag($village, TZ_GOLD_PRICE_ROUTE, 2);?> from this village and run 7 more days before it ends</label></td>
                </tr>
                <tr>
                    <th><?php echo DELIVERIES;?>:</th>
                    <td>
                        <select name="deliveries">
                            <?php for ($d = 1; $d <= 3; $d++):?>
                                <option value="<?php echo $d;?>" <?php if($d===1) echo 'selected';?>><?php echo $d;?></option>
                            <?php endfor;?>
                        </select>
                    </td>
                </tr>
                <tr>
                    <th><?php echo COSTS;?>:</th>
                    <td><?php echo VillageGold::priceTag($village, TZ_GOLD_PRICE_ROUTE, 2);?></td>
                </tr>
                <tr>
                    <th><?php echo DURATION;?>:</th>
                    <td><b>7</b> <?php echo DAYS;?></td>
                </tr>
            </tbody>
        </table>
    </div></div>
    <p><input type="image" value="1" name="save" id="btn_save" class="dynamic_img" src="img/x.gif" tabindex="8" alt="OK"/></p>
</form>