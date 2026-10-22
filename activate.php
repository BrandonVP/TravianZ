<?php

#################################################################################
##              -= YOU MAY NOT REMOVE OR CHANGE THIS NOTICE =-                 ##
## --------------------------------------------------------------------------- ##
##  Filename       : activate.php                  	                           ##
##  Type           : In Game Activate File                                     ##
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

include('GameEngine/Account.php');
AccessLogger::logRequest();

$serverStartTimestamp = \App\Utils\DateTime::getServerStartTimestamp(START_DATE, START_TIME);
$serverHasStarted = $serverStartTimestamp !== null && time() >= $serverStartTimestamp;

?>
<?php
// local redesign: logged-out frame (Templates/layout/outgame_*.tpl, css/outgame.css)
$ogTitle  = 'Account Activation';
$ogActive = '';
include("Templates/layout/outgame_top.tpl");
?>
<div class="og-grid">
<section class="og-card og-doc og-classic">
<h1>Account activation</h1>
<?php

	if(isset($_GET['e']) && $serverHasStarted)
	{
		switch($_GET['e'])
		{
			case 1:
				include("Templates/activate/delete.tpl");
				break;
			case 2:
				include("Templates/activate/activated.tpl");
				break;
			case 3:
				include("Templates/activate/cantfind.tpl");
				break;
		}
	} else if(isset($_GET['id']) && isset($_GET['c'])) {
		$c=$database->getActivateField($_GET['id'],"email",0);
		if($_GET['c'] == $generator->encodeStr($c,5)){
			include("Templates/activate/delete.tpl");
		} else { include("Templates/activate/activate.tpl"); }
	} else {
	include("Templates/activate/activate.tpl");
	}

?>
</section>
<aside class="og-stack">
	<section class="og-card og-serverinfo">
		<h2>Server info</h2>
		<?php if (NEWSBOX1) { include("Templates/News/newsbox1.tpl"); } ?>
	</section>
</aside>
</div>
<?php include("Templates/layout/outgame_bottom.tpl"); ?>
