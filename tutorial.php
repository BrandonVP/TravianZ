<?php

#################################################################################
##              -= YOU MAY NOT REMOVE OR CHANGE THIS NOTICE =-                 ##
## --------------------------------------------------------------------------- ##
##  Filename       : tutorial.php                      	                       ##
##  Type           : In Game Tutorial Page                                     ##
## --------------------------------------------------------------------------- ##
##  Developed by   : Dzoki 						                               ##
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
$ogTitle  = TUTORIAL;
$ogActive = 'tutorial';
include("Templates/layout/outgame_top.tpl");
?>
<section class="og-card og-doc">
<h1><?php echo TUTORIAL; ?></h1>
					<?php
						if(!isset($_GET['s'])) {
						$_GET['s'] = ""; }
						if ($_GET['s'] == "") {
						include("Templates/Tutorial/1.tpl"); }
						if ($_GET['s'] == "1") {
						include("Templates/Tutorial/1.tpl"); }
						if ($_GET['s'] == "2") {
						include("Templates/Tutorial/2.tpl"); }
						if ($_GET['s'] == "3") {
						include("Templates/Tutorial/3.tpl"); }
						if ($_GET['s'] == "4") {
						include("Templates/Tutorial/4.tpl"); }
						if ($_GET['s'] == "5") {
						include("Templates/Tutorial/5.tpl"); }
					?>
</section>
<?php include("Templates/layout/outgame_bottom.tpl"); ?>
