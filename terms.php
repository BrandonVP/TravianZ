<?php

#################################################################################
##              -= YOU MAY NOT REMOVE OR CHANGE THIS NOTICE =-                 ##
## --------------------------------------------------------------------------- ##
##  Filename       : terms.php                      	                       ##
##  Type           : In Game Terms Page                                        ##
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
$ogTitle  = PUBLIC_TERMS_TITLE;
$ogActive = '';
include("Templates/layout/outgame_top.tpl");
?>
<section class="og-card og-doc">
            <h1><?php echo PUBLIC_TERMS_TITLE; ?></h1>

            <div class="terms-box">

                <h3 class="pop popgreen bold"><?php echo PUBLIC_TERMS_GENERAL_RULES; ?></h3>
                <p>
                    <?php echo PUBLIC_TERMS_PROJECT; ?>
                    <?php echo PUBLIC_TERMS_ACCEPTANCE; ?>
                </p>

                <br/>

                <h3 class="pop popgreen bold"><?php echo PUBLIC_TERMS_ACCOUNT_RESPONSIBILITY; ?></h3>
                <p>
                    <?php echo PUBLIC_TERMS_ACCOUNT_FULL_RESPONSIBILITY; ?>
                    <?php echo PUBLIC_TERMS_ACCOUNT_SHARING; ?>
                    Any abuse or exploitation of bugs is strictly forbidden.
                </p>

                <br/>

                <h3 class="pop popgreen bold">3. Fair Play</h3>
                <p>
                    <?php echo PUBLIC_TERMS_CHEATING; ?>
                    is not allowed and may result in permanent ban.
                </p>

                <br/>

                <h3 class="pop popgreen bold"><?php echo PUBLIC_TERMS_SERVER_STATUS; ?></h3>
                <p>
                    <?php echo PUBLIC_TERMS_AS_IS; ?>
                    <?php echo PUBLIC_TERMS_RESET; ?>
                </p>

                <br/>

                <h3 class="pop popgreen bold">5. Intellectual Property</h3>
                <p>
                    All trademarks mentioned belong to their respective owners.
                    <?php echo PUBLIC_TERMS_NO_AFFILIATION; ?>
                    The game engine is open-source software licensed under the GNU GPLv3; original artwork and content of Empires of Rome belong to the operators of Empires of Rome.
                </p>

                <br/>

                <h3 class="pop popgreen bold">6. Changes</h3>
                <p>
                    <?php echo PUBLIC_TERMS_UPDATES; ?>
                </p>

            </div>

            
</section>
<?php include("Templates/layout/outgame_bottom.tpl"); ?>
