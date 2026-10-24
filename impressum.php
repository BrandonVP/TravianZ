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
$ogTitle  = 'Contact';
$ogActive = '';
include("Templates/layout/outgame_top.tpl");
?>
<section class="og-card og-doc">
            <h1>Contact</h1>

            <p class="submenu">

                <b>Who runs this game:</b><br/>
                Empires of Rome is a free, non-commercial browser strategy game run by the Empires of Rome team.<br/><br/>

                <b>Contact:</b><br/>
                <a href="mailto:contact@empiresofrome.com">contact@empiresofrome.com</a><br/>
                For account questions, data or deletion requests (see our <a href="privacy.php">Privacy Policy</a>) and anything else.<br/><br/>

                <b>Source Code:</b><br/>
                Built on the open-source TravianZ engine, licensed under the GNU GPLv3.<br/>
                <a href="https://github.com/BrandonVP/TravianZ" target="_blank" rel="noopener">
                    https://github.com/BrandonVP/TravianZ
                </a><br/><br/>

                <b>Disclaimer:</b><br/>
                <?php echo PUBLIC_UNOFFICIAL_PROJECT; ?><br/><br/>

                &copy; <?php echo date('Y'); ?> Empires of Rome

            </p>

            
</section>
<?php include("Templates/layout/outgame_bottom.tpl"); ?>
