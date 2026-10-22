<?php

#################################################################################
##              -= YOU MAY NOT REMOVE OR CHANGE THIS NOTICE =-                 ##
## --------------------------------------------------------------------------- ##
##  Filename       : anleitung.php                      	                   ##
##  Type           : In Game Part of Main Page                                 ##
## --------------------------------------------------------------------------- ##
##  Developed by   : Dzoki & Advocaite & Donnchadh                             ##
##  Refactored by  : Shadow                                                    ##
##  Redesign by    : Shadow                                                    ##
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

use App\Utils\AccessLogger;

include_once("GameEngine/config.php");
include_once("GameEngine/Database.php");
require_once __DIR__ . "/GameEngine/Lang/loader.php";
tz_load_language(LANG);
AccessLogger::logRequest();
?>
<?php
// local redesign: logged-out frame (Templates/layout/outgame_*.tpl, css/outgame.css)
$ogTitle  = PUBLIC_MANUAL;
$ogActive = 'manual';
include("Templates/layout/outgame_top.tpl");
?>
<section class="og-card og-doc">
<h1><?php echo PUBLIC_MANUAL; ?></h1>



<p class="submenu">

<a href="anleitung.php"><?php echo PUBLIC_TRIBES; ?></a> |

<a href="anleitung.php?s=1"><?php echo BUILDINGS; ?></a> |

<a href="anleitung.php?s=3"><?php echo MANUAL_FAQ; ?></a>

</p>



<?php
if(!isset($_GET['s'])) {
$_GET['s'] = ""; }
if ($_GET['s'] == "") {
include("Templates/Anleitung/0.tpl"); }
if ($_GET['s'] == "1") {
include("Templates/Anleitung/1.tpl"); }
if ($_GET['s'] == "3") {
include("Templates/Anleitung/3.tpl"); }
if ($_GET['s'] == "4") {
include("Templates/Anleitung/4.tpl"); }
?>
</section>
<?php include("Templates/layout/outgame_bottom.tpl"); ?>
