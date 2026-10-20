<?php

#################################################################################
##                -= YOU MAY NOT REMOVE OR CHANGE THIS NOTICE =-               ##
## --------------------------------------------------------------------------- ##
##  Filename       : 8.tpl                                                     ##
##  Type           : Plus - Activate Plus Account                              ##
## --------------------------------------------------------------------------- ##
##  Developed by   : alq0rsan & evader & Shadow                                ##
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

// PERMISIUNI SITTER: cumparaturile cu aur.
// Inlocuieste vechiul "$session->sit", care citea un flag din tabela online
// scris cu INSERT IGNORE - deci nu se actualiza daca randul exista deja.
// sitterCan() se bazeaza pe sesiune, deci e mereu corect.
if($session->sitterCan(SITTER_PERM_GOLD)) {
    $now  = time();
    $uid  = (int)$session->uid;
    $wid  = (int)$village->wid;
    $cost = 10;

    // Village gold (local redesign, phase 3b): paid with the capital's gold;
    // the Plus-gold part of the UPDATE below then costs nothing
    $tzPaid = VillageGold::capitalPayStart($database, $village, TZ_GOLD_PRICE_PLUS);
    if ($tzPaid === false) { header("Location: plus.php?id=3"); exit; }
    $tzLogCost = ($tzPaid !== null) ? $tzPaid : $cost;
    if ($tzPaid !== null) $cost = 0;

    // 1. scade gold și prelungește plus-ul ATOMIC
    $sql = "UPDATE ".TB_PREFIX."users 
            SET gold = gold - $cost,
                plus = IF(plus > $now, plus + ".PLUS_TIME.", $now + ".PLUS_TIME.")
            WHERE id = $uid AND gold >= $cost";

    mysqli_query($database->dblink, $sql);
    $tzGranted = (mysqli_affected_rows($database->dblink) == 1);

    if(mysqli_affected_rows($database->dblink) == 1) {
        // 2. update sesiune
        $session->gold -= $cost;
        $_SESSION['gold'] = $session->gold;
        $session->plus = ($session->plus > $now ? $session->plus : $now) + PLUS_TIME;

        // 3. LOG pentru a2b2.php
        $vname = mysqli_real_escape_string($database->dblink, $village->vname);
		mysqli_query($database->dblink,
		"INSERT INTO ".TB_PREFIX."gold_fin_log 
		(uid, wid, action, gold, time, details) 
		VALUES ($uid, $wid, 'Buy Travian Plus', -$tzLogCost, $now, 'Buy Travian Plus')"
		);

        // 4. curăță cache
        if(method_exists($database, 'clearUserCache')) {
            $database->clearUserCache($uid);
        }
    }
}
if (!empty($tzPaid) && empty($tzGranted)) VillageGold::capitalPayRefund($database, $village, $tzPaid);
header("Location: plus.php?id=3");
exit;
?>