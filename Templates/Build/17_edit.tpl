<?php

#################################################################################
##              -= YOU MAY NOT REMOVE OR CHANGE THIS NOTICE =-                 ##
## --------------------------------------------------------------------------- ##
##  Filename       : MARKETPLACE EDIT ROUTES                                   ##
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

global $database;

$routeid = isset($_POST['routeid'])? (int)$_POST['routeid'] : 0;
$edited_route = $database->getTradeRoute2($routeid);

$wood = (int)($edited_route['wood']??0);
$clay = (int)($edited_route['clay']??0);
$iron = (int)($edited_route['iron']??0);
$crop = (int)($edited_route['crop']??0);
$start = (int)($edited_route['start']??0);
$deliveries = (int)($edited_route['deliveries']??1);
// local redesign: gold, trigger, auto-renew
$tzRGold  = (int)($edited_route['gold']??0);
$tzRTrig  = (int)($edited_route['trig']??0) === 1;
$tzRPct   = (int)($edited_route['trig_pct']??90);
$tzRRenew = (int)($edited_route['autorenew']??0) === 1;
?>
<form action="build.php" method="post">
    <div class="boxes boxesColor gray"><div class="boxes-tl"></div><div class="boxes-tr"></div><div class="boxes-tc"></div><div class="boxes-ml"></div><div class="boxes-mr"></div><div class="boxes-mc"></div><div class="boxes-bl"></div><div class="boxes-br"></div><div class="boxes-bc"></div><div class="boxes-contents cf">
        <input type="hidden" name="action" value="editRoute2">
        <input type="hidden" name="routeid" value="<?php echo $routeid;?>">
        <table cellpadding="1" cellspacing="1" id="npc" class="transparent">
            <thead>
                <tr><th colspan="2"><?php echo EDIT_TRADE_ROUTES;?></th></tr>
            </thead>
            <tbody>
                <tr>
                    <th><?php echo RESOURCES;?>:</th>
                    <td>
                        <?php $res = [
                            ['r1', $wood, '1', LUMBER],
                            ['r2', $clay, '2', CLAY],
                            ['r3', $iron, '3', IRON],
                            ['r4', $crop, '4', CROP],
                        ];
                        foreach ($res as $r):?>
                            <img src="../../<?php echo GP_LOCATE;?>img/r/<?php echo $r[2];?>.gif" alt="<?php echo $r[3];?>" title="<?php echo $r[3];?>">
                            <input class="text" type="text" name="<?php echo $r[0];?>" id="<?php echo $r[0];?>" value="<?php echo $r[1];?>" maxlength="9" tabindex="1" style="width:50px;">
                        <?php endforeach;?>
                    </td>
                </tr>
                <?php if (!empty($village->goldActive)):?>
                <tr>
                    <th>Gold:</th>
                    <td>
                        <svg class="tz-coin-sm" viewBox="0 0 24 24" aria-label="Gold" role="img"><circle cx="12" cy="12" r="10" fill="#e3b427" stroke="#9a7512" stroke-width="1.5"/><circle cx="12" cy="12" r="6.5" fill="none" stroke="#9a7512" stroke-width="1"/></svg>
                        <input class="text" type="text" name="r5" value="<?php echo $tzRGold;?>" maxlength="7" style="width:50px;">
                        <span class="tz-route-hint">1 gold uses 100 merchant space</span>
                    </td>
                </tr>
                <?php endif;?>
                <tr>
                    <th>Send:</th>
                    <td class="tz-route-when">
                        <label><input type="radio" name="trig" value="time" <?php if (!($tzRTrig)) echo 'checked';?>>
                            every day at
                            <select name="start">
                                <?php for ($h = 0; $h < 24; $h++):?>
                                    <option value="<?php echo $h;?>" <?php if($h === ($start)) echo 'selected';?>><?php echo str_pad($h,2,'0',STR_PAD_LEFT);?>:00</option>
                                <?php endfor;?>
                            </select>
                        </label>
                        <label><input type="radio" name="trig" value="full" <?php if ($tzRTrig) echo 'checked';?>>
                            when storage is at least
                            <select name="trig_pct">
                                <?php for ($pc = 50; $pc <= 100; $pc += 5):?>
                                    <option value="<?php echo $pc;?>" <?php if($pc === ($tzRPct)) echo 'selected';?>><?php echo $pc;?>%</option>
                                <?php endfor;?>
                            </select>
                            full
                        </label>
                        <span class="tz-route-hint">"When full" sends as soon as any resource of this route reaches that level, then waits 15 minutes.</span>
                    </td>
                </tr>
                <tr>
                    <th>Auto-renew:</th>
                    <td><label><input type="checkbox" name="autorenew" value="1" <?php if ($tzRRenew) echo 'checked';?>>
                        pay <?php echo VillageGold::priceTag($village, TZ_GOLD_PRICE_ROUTE, 2);?> from this village and run 7 more days before it ends</label></td>
                </tr>
                <tr>
                    <th><?php echo DELIVERIES;?>:</th>
                    <td>
                        <select name="deliveries">
                            <?php for ($i = 1; $i <= 3; $i++):?>
                                <option value="<?php echo $i;?>" <?php if($i === $deliveries) echo 'selected';?>><?php echo $i;?></option>
                            <?php endfor;?>
                        </select>
                    </td>
                </tr>
            </tbody>
        </table>
    </div></div>
    <p><input type="image" value="1" name="save" id="btn_save" class="dynamic_img" src="img/x.gif" tabindex="8" alt="OK"/></p>
</form>