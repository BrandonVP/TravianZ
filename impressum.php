<?php
#################################################################################
##              -= YOU MAY NOT REMOVE OR CHANGE THIS NOTICE =-                 ##
## --------------------------------------------------------------------------- ##
##  Filename       : impressum.php                                             ##
## --------------------------------------------------------------------------- ##
##  Refactored by  : Shadow                                                    ##
## --------------------------------------------------------------------------- ##
##  Project        : TravianZ                                                  ##
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
$ogTitle  = 'Impressum';
$ogActive = '';
include("Templates/layout/outgame_top.tpl");
?>
<section class="og-card og-doc">
            <h1>Impressum</h1>

            <p class="submenu">

                <b>Project:</b><br/>
                TravianZ by Shadow<br/><br/>

                <b>Initiator & Lead Developer:</b><br/>
                Shadow (Catalin Novgorodschi)<br/><br/>

                <b><?php echo PUBLIC_ABOUT_PROJECT; ?></b><br/>
                Open-source Travian 3.6 engine modernization project focused on performance,
                stability and gameplay preservation.<br/><br/>

                <b><?php echo PUBLIC_MAIN_GOALS; ?></b><br/>
                - Preserve classic Travian gameplay<br/>
                - Refactor legacy codebase<br/>
                - Improve performance and stability<br/>
                <?php echo PUBLIC_ADD_TRIBES; ?><br/>
                - Maintain community-driven development<br/><br/>

                <b>Source Code:</b><br/>
                <a href="https://github.com/Shadowss/TravianZ" target="_blank">
                    https://github.com/Shadowss/TravianZ
                </a><br/><br/>

                <b>Disclaimer:</b><br/>
                <?php echo PUBLIC_UNOFFICIAL_PROJECT; ?><br/><br/>

                © 2010-<?php echo date('Y'); ?> TravianZ Project

            </p>

            
</section>
<?php include("Templates/layout/outgame_bottom.tpl"); ?>
