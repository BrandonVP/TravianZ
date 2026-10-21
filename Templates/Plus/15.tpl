<?php

#################################################################################
##                -= YOU MAY NOT REMOVE OR CHANGE THIS NOTICE =-               ##
## --------------------------------------------------------------------------- ##
##  Filename       : 15.tpl                                                    ##
##  Type           : Plus - Activate Gold Club                                 ##
## --------------------------------------------------------------------------- ##
##  Developed by   : Shadow                                                    ##
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

// Gold Club activation – 100 gold, atomic
$uid = (int)$session->uid;
$wid = (int)$village->wid;
$now = time();
$cost = 100;

// PERMISIUNI SITTER: cumparaturile cu aur.
// Inlocuieste vechiul "$session->sit", care citea un flag din tabela online
// scris cu INSERT IGNORE - deci nu se actualiza daca randul exista deja.
// sitterCan() se bazeaza pe sesiune, deci e mereu corect.
if(!$session->sitterCan(SITTER_PERM_GOLD)) {
    header("Location: " . $tzBack); exit;
}

// Village gold (local redesign, phase 3b): paid with the capital's gold;
// the Plus-gold part of the UPDATE below then costs nothing
$tzPaid = VillageGold::capitalPayStart($database, $village, TZ_GOLD_PRICE_GOLDCLUB);
if ($tzPaid === false) { header("Location: " . $tzBack); exit; }
$tzLogCost = ($tzPaid !== null) ? $tzPaid : $cost;
if ($tzPaid !== null) $cost = 0;

// un singur query
mysqli_query($database->dblink,
    "UPDATE ".TB_PREFIX."users 
     SET goldclub = 1, gold = gold - $cost 
     WHERE id = $uid AND gold >= $cost AND goldclub = 0"
);
$tzGranted = (mysqli_affected_rows($database->dblink) == 1);

if(mysqli_affected_rows($database->dblink) == 1) {
    // update sesiune
    $session->gold -= $cost;
    $session->goldclub = 1;
    $_SESSION['gold'] = $session->gold;
    $_SESSION['goldclub'] = 1;
    
    if(isset($database->cache)) {
        $database->cache->delete('user:'.$uid);
    }
    
    // LOG pentru a2b2.php
    mysqli_query($database->dblink,
        "INSERT INTO ".TB_PREFIX."gold_fin_log 
         (uid, wid, action, gold, time, details) 
         VALUES ($uid, $wid, 'Buy Gold Club', -$tzLogCost, $now, 'Gold Club activated')"
    );
}

if (!empty($tzPaid) && empty($tzGranted)) VillageGold::capitalPayRefund($database, $village, $tzPaid);
header("Location: " . $tzBack);
exit;
?>