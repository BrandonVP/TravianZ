<?php

#################################################################################
##              -= YOU MAY NOT REMOVE OR CHANGE THIS NOTICE =-                 ##
## --------------------------------------------------------------------------- ##
##  Filename       gold_1.php                                                  ##
##  Type           BACKEND                                                     ##
##  Developed by:  aggenkeech                                                  ##
##  Refactored by: Shadow                                                      ##
##  License:       TravianZ Project                                            ##
##  Copyright:     TravianZ (c) 2010-2025. All rights reserved.                ##
##                                                                             ##
#################################################################################

// #299: load CSRF helpers + admin_deny() before the access check below.
require_once(__DIR__ . '/../csrf.php');
if (!isset($_SESSION)) session_start();
if($_SESSION['access'] < 9) admin_deny('You must be signed in as an administrator to view this page. Your session may have expired — please return to the admin panel and sign in again.');

// Issue #139: this Mod is POSTed to directly, so it must verify the CSRF token
// itself (it does not go through admin.php's central csrf_verify()).
require_once(__DIR__ . '/../csrf.php');
csrf_verify();

include_once("../../config.php");
include_once("../../Database.php");

$admid  = (int)($_POST['admid'] ?? 0);
$id     = (int)($_POST['id'] ?? 0);
$amount = (int)($_POST['gold'] ?? 0);

if($id <= 0 || $amount == 0){
    header("Location: ../../../Admin/admin.php?p=usergold");
    exit;
}

// verificare admin
$check = mysqli_query($GLOBALS["link"], "SELECT access, username FROM ".TB_PREFIX."users WHERE id = $admid");
$acc = mysqli_fetch_assoc($check);
if(!$acc || $acc['access'] != 9) admin_deny('You must be signed in as an administrator to view this page. Your session may have expired — please return to the admin panel and sign in again.');

// 1. UPDATE GOLD
// Village gold (local redesign): into the player's capital; Plus gold only
// for a player without a capital (moved there once they have one)
mysqli_query($GLOBALS["link"], "UPDATE ".TB_PREFIX."vdata SET gold = GREATEST(gold + $amount, 0) WHERE owner = $id AND capital = 1") or die(mysqli_error($GLOBALS["link"]));
if (mysqli_affected_rows($GLOBALS["link"]) < 1 && $amount > 0) {
    mysqli_query($GLOBALS["link"], "UPDATE ".TB_PREFIX."users SET gold = gold + $amount WHERE id = $id") or die(mysqli_error($GLOBALS["link"]));
}

// 2. ADMIN LOG
$name = mysqli_fetch_assoc(mysqli_query($GLOBALS["link"], "SELECT username FROM ".TB_PREFIX."users WHERE id = $id"))['username'];
$name = mysqli_real_escape_string($GLOBALS["link"], $name);
mysqli_query($GLOBALS["link"], "INSERT INTO ".TB_PREFIX."admin_log VALUES (0, $admid, 'Added <b>$amount</b> gold to user <a href=\'admin.php?p=player&uid=$id\'>$name</a>', ".time().")");

// 3. GOLD_FIN_LOG (pentru a2b2.php)
$vill = mysqli_fetch_assoc(mysqli_query($GLOBALS["link"], "SELECT wref FROM ".TB_PREFIX."vdata WHERE owner = $id ORDER BY capital DESC LIMIT 1"));
$wid = (int)($vill['wref'] ?? 0);
$action = $amount > 0 ? 'Admin added Gold' : 'Admin removed Gold';
$adminName = $acc['username'];
$details = mysqli_real_escape_string($GLOBALS["link"], 'Admin gift by '.$adminName);
$now = time();

mysqli_query($GLOBALS["link"], "INSERT INTO ".TB_PREFIX."gold_fin_log (wid, uid, action, gold, time, details) VALUES ($wid, $id, '$action', $amount, $now, '$details')") or die(mysqli_error($GLOBALS["link"]));

header("Location: ../../../Admin/admin.php?p=usergold&g");
exit;
?>