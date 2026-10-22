<?php
include_once("GameEngine/Generator.php");
$start_timer = $generator->pageLoadTimeStart();

#################################################################################
##              -= YOU MAY NOT REMOVE OR CHANGE THIS NOTICE =-                 ##
## --------------------------------------------------------------------------- ##
##  Filename       : logout.php                      	                       ##
##  Type           : In Game Logout Page                                       ##
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

include("GameEngine/Account.php");
AccessLogger::logRequest();

?>
<?php
// local redesign: logged-out frame (Templates/layout/outgame_*.tpl, css/outgame.css)
$ogTitle  = 'Logged Out';
$ogActive = '';
include("Templates/layout/outgame_top.tpl");
?>
<div class="og-grid">
<section class="og-card og-doc og-classic">
<h1><?php echo PUBLIC_LOGOUT_SUCCESS_TITLE; ?></h1>
<p><?php echo PUBLIC_LOGOUT_THANKS; ?></p>

		<p><?php echo PUBLIC_DELETE_COOKIES_NOTICE; ?><br /><a href="login.php?del_cookie">&raquo; <?php echo PUBLIC_DELETE_COOKIES; ?></a></p>
<div class="og-btn-row">
	<a class="og-btn og-btn-gold" href="login.php"><?php echo LOGIN; ?></a>
	<a class="og-btn" href="index.php"><?php echo defined('HOME') ? HOME : 'Homepage'; ?></a>
</div>
</section>
<aside class="og-stack">
	<section class="og-card og-serverinfo">
		<h2>Server info</h2>
		<?php if (NEWSBOX1) { include("Templates/News/newsbox1.tpl"); } ?>
	</section>
</aside>
</div>
<?php include("Templates/layout/outgame_bottom.tpl"); ?>
