<?php

#################################################################################
##                -= YOU MAY NOT REMOVE OR CHANGE THIS NOTICE =-               ##
## --------------------------------------------------------------------------- ##
##  Filename       : 10.tpl                                                    ##
##  Type           : Plus - Activate Clay Bonus                                ##
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

// Village gold (local redesign): bought in the capital's Main Building, so go back there
$tzBack = (class_exists('VillageGold') && VillageGold::pays($village)) ? 'build.php?gid=15#plus' : 'plus.php?id=3';

// PERMISIUNI SITTER: cumparaturile cu aur.
// Inlocuieste vechiul "$session->sit", care citea un flag din tabela online
// scris cu INSERT IGNORE - deci nu se actualiza daca randul exista deja.
// sitterCan() se bazeaza pe sesiune, deci e mereu corect.
if($session->sitterCan(SITTER_PERM_GOLD)) {
    $uid  = (int)$session->uid;
    $wid  = (int)$village->wid;
    $now  = time();
    $cost = 5;

    // Village gold (local redesign, phase 3b): paid with the capital's gold;
    // the Plus-gold part of the UPDATE below then costs nothing
    $tzPaid = VillageGold::capitalPayStart($database, $village, TZ_GOLD_PRICE_PRODUCTION);
    if ($tzPaid === false) { header("Location: " . $tzBack); exit; }
    $tzLogCost = ($tzPaid !== null) ? $tzPaid : $cost;
    if ($tzPaid !== null) $cost = 0;

    // UPDATE atomic: scade gold și prelungește b2
    $sql = "UPDATE ".TB_PREFIX."users 
            SET gold = gold - $cost,
                b2 = IF(b2 > $now, b2 + ".PLUS_PRODUCTION.", $now + ".PLUS_PRODUCTION.")
            WHERE id = $uid AND gold >= $cost";

    mysqli_query($database->dblink, $sql);
    $tzGranted = (mysqli_affected_rows($database->dblink) == 1);

    if(mysqli_affected_rows($database->dblink) == 1) {
        // update sesiune
        $session->gold -= $cost;
        $_SESSION['gold'] = $session->gold;
        // Interogarea de mai sus a prelungit deja b2 in baza de date, atomic.
        // Aici doar marcam bonusul ca activ in sesiune, ca pagina sa arate
        // corect imediat, fara sa mai citim o data din baza.
        //
        // Session NU are proprietatea ->b2 (momentul expirarii sta in
        // userarray, care e privat). Are insa ->bonus2, indicatorul public
        // 0/1 pe care il foloseste restul interfetei.
        $session->bonus2 = 1;

        // LOG pentru a2b2.php
        mysqli_query($database->dblink,
            "INSERT INTO ".TB_PREFIX."gold_fin_log 
             (uid, wid, action, gold, time, details) 
             VALUES ($uid, $wid, 'Buy +25% Clay', -$tzLogCost, $now, '+25% Production: Clay')"
        );

        // curăță cache
        if(method_exists($database, 'clearUserCache')) {
            $database->clearUserCache($uid);
        }
    }
}
if (!empty($tzPaid) && empty($tzGranted)) VillageGold::capitalPayRefund($database, $village, $tzPaid);
header("Location: " . $tzBack);
exit;
?>