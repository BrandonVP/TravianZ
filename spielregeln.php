<?php

#################################################################################
##              -= YOU MAY NOT REMOVE OR CHANGE THIS NOTICE =-                 ##
## --------------------------------------------------------------------------- ##
##  Project:       TravianZ                                                    ##
##  Filename       spieleregeln.php                                            ##
##  Developed by:  Dzoki                                                       ##
##  License:       TravianZ Project                                            ##
##  Copyright:     TravianZ (c) 2010-2026. All rights reserved.                ##
##  URLs:          http://travian.shadowss.ro                		           ##
##  Source code:   https://github.com/Shadowss/TravianZ		                   ##
##                                                                             ##
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
$ogTitle  = PUBLIC_RULES_TITLE;
$ogActive = '';
include("Templates/layout/outgame_top.tpl");
?>
<section class="og-card og-doc">
<h1><?php echo PUBLIC_RULES_TITLE; ?></h1>

<p class="submenu">

<?php echo PUBLIC_RULES_INTRO_1; ?>
<br /><br />
<?php echo PUBLIC_RULES_INTRO_2; ?>
</p>
<ul class="rules">
 <li><strong style="color: #2A720B">&sect;1 Password, Registration &amp; ownership</strong><br />
<?php echo PUBLIC_RULES_ONE_ACCOUNT; ?>
<ul>
<li><strong style="color: #3BAE18">&sect;1.1 Registration</strong><br />
<?php echo PUBLIC_RULES_EMAIL_OWNER; ?>
</li>
<li><strong style="color: #3BAE18"><?php echo PUBLIC_RULES_SECTION_1_2; ?></strong><br />
<?php echo PUBLIC_RULES_PASSWORD_SAME_WORLD; ?>
<br /><br />
<?php echo PUBLIC_RULES_PASSWORD_OTHER_WORLD; ?>
<br /><br />
<?php echo PUBLIC_RULES_PASSWORD_DAMAGE; ?>
</li>
<li><strong style="color: #3BAE18"><?php echo PUBLIC_RULES_SECTION_1_3; ?></strong><br />
<?php echo PUBLIC_RULES_EMAIL_CHANGE; ?>
</li>
<li><strong style="color: #3BAE18">&sect;1.4 Switching accounts</strong><br />
<?php echo PUBLIC_RULES_SAME_WORLD_TRANSFER; ?>
<ol>
<li><?php echo PUBLIC_RULES_WORLD_NAME; ?></li>
<li><?php echo PUBLIC_RULES_ACCOUNT_NICKNAME; ?></li>
<li><?php echo PUBLIC_RULES_NEW_OWNER_EMAIL; ?> </li>
</ol>
<?php echo PUBLIC_RULES_PASSWORD_REQUEST_AFTER_TRANSFER; ?>
</li>
</ul>
</li>
<li><strong style="color: #2A720B">&sect;2 Sitting &amp; same pc usage</strong><br />
<ul>
<li><strong style="color: #3BAE18">&sect;2.1 Sitting</strong><br />
<?php echo PUBLIC_RULES_SITTERS; ?>
<br />
<?php echo PUBLIC_RULES_SITTER_LOGIN; ?>
<br />
<?php echo PUBLIC_RULES_SITTER_DAMAGE; ?>
</li>
<li><strong style="color: #3BAE18">&sect;2.2 Same pc usage</strong><br />
<?php echo PUBLIC_RULES_SHARED_COMPUTER; ?>
</li>
</ul>
</li>
<li><strong style="color: #2A720B">&sect;3 Use of externals</strong><br />
<?php echo PUBLIC_RULES_BROWSER; ?>
</li>
<li><strong style="color: #2A720B"><?php echo PUBLIC_RULES_PROGRAM_ERRORS_HEADING; ?></strong><br />
<?php echo PUBLIC_RULES_BUGS; ?>
</li>
<li><strong style="color: #2A720B">&sect;5 Money transactions</strong><br />
<?php echo PUBLIC_RULES_REAL_MONEY; ?>
</li>
<li><strong style="color: #2A720B">&sect;6 Netiquette</strong><br />
<?php echo PUBLIC_RULES_POLITE_COMMUNICATION; ?>
<ol>
<li><?php echo PUBLIC_RULES_BEHAVIOUR_INTRO; ?> <br />
<?php echo PUBLIC_RULES_LANGUAGE; ?>
<br />
Participation in abusive, defamatory, sexist, racist or profane language; disparaging any religion, race, nation, gender, age group, or sexual orientation; threatening persons with actions in real life.
<br />
Posting or transmission of any material not suitable for underage persons.
<br />
<?php echo PUBLIC_RULES_BLACKMAIL; ?>
<br />
Displaying battle reports or messages in public without consent of both concerned persons.
</li>
<li>No real world politics are allowed in names, messages and descriptions. </li>
<li>Impersonation of officials or official positions is illegal in any way.
</li>
<li><?php echo PUBLIC_RULES_ADVERTISING; ?> </li>
</ol>
</li>
<li><strong style="color: #2A720B">&sect;7 Punishments</strong><br />
<?php echo PUBLIC_RULES_PUNISHMENT; ?>
<br />
<?php echo PUBLIC_RULES_NO_REPLACEMENT; ?>
<br />
<?php echo PUBLIC_RULES_NO_SPECIAL_TREATMENT; ?>
<br /><br />
<?php echo PUBLIC_RULES_APPEALS; ?>
<br />
<?php echo PUBLIC_RULES_OWNER_INFORMATION; ?>
<br /><br />
<?php echo PUBLIC_RULES_MULTI_DELETE; ?>
</li>
<li><strong style="color: #2A720B"><?php echo PUBLIC_RULES_SECTION_8; ?></strong><br />
<?php echo PUBLIC_RULES_CHANGE_ANY_TIME; ?>
</li>
<li><strong style="color: #2A720B">&sect;9 Correction clause</strong><br />
<?php echo PUBLIC_RULES_SEVERABILITY; ?>
</li>
</ul>
	
</section>
<?php include("Templates/layout/outgame_bottom.tpl"); ?>
