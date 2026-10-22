<?php

#################################################################################
##              -= YOU MAY NOT REMOVE OR CHANGE THIS NOTICE =-                 ##
## --------------------------------------------------------------------------- ##
##  Filename       : login.php                      	                       ##
##  Type           : In Game Login Page                                        ##
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

if(!file_exists('var/installed') && @opendir('install')) {
    header("Location: install/");
    exit;
}

include("GameEngine/Account.php");
AccessLogger::logRequest();

if(isset($_GET['del_cookie'])) {
	setcookie("COOKUSR","",time()-3600*24,"/");
	header("Location: login.php");
	exit;
}
if(!isset($_COOKIE['COOKUSR'])) {
	$_COOKIE['COOKUSR'] = "";
}

if ( $_SERVER[ 'REQUEST_METHOD' ] == 'POST' ) {
    if ( !isset( $_SESSION[ 'csrf' ] ) || $_SESSION[ 'csrf' ] !== $_POST[ 'csrf' ] )
        throw new RuntimeException( 'CSRF attack' );
}
$key                = sha1( microtime() );
$_SESSION[ 'csrf' ] = $key;

?>
<?php
// local redesign: logged-out frame (Templates/layout/outgame_*.tpl, css/outgame.css)
$ogTitle  = defined('LOGIN') ? LOGIN : 'Login';
$ogActive = 'login';
include("Templates/layout/outgame_top.tpl");
$time = time();
$stime = strtotime(date('m/d/Y H:i', strtotime(START_DATE . ' ' . START_TIME)));
?>
<div class="og-grid">
	<section class="og-card og-login">
		<h1><?php echo defined('LOGIN') ? LOGIN : 'Login'; ?></h1>
<?php if (COMMENCE > $time): ?>
		<p class="og-error"><?php echo NOT_OPENED_YET; ?></p>
<?php elseif ($stime > $time): ?>
		<p>The server starts in:</p>
		<div class="og-countdown" id="cntdwn" data-start="<?php echo (int) $stime; ?>"></div>
		<script>
		(function () {
			var el = document.getElementById('cntdwn'), end = +el.getAttribute('data-start') * 1000;
			function pad(n) { return (n < 10 ? '0' : '') + n; }
			function tick() {
				var s = Math.max(0, Math.floor((end - Date.now()) / 1000));
				if (s <= 0) { el.textContent = 'START NOW'; return; }
				el.textContent = pad(Math.floor(s / 3600)) + ':' + pad(Math.floor(s / 60) % 60) + ':' + pad(s % 60);
				setTimeout(tick, 1000);
			}
			tick();
		})();
		</script>
<?php else: ?>
		<p class="og-muted"><?php echo COOKIES; ?></p>
<?php
if ($form->getError("pw") == LOGIN_PW_ERROR) {
	echo '<div class="og-error"><b>' . PW_FORGOTTEN . '</b><br>' . PW_REQUEST . '<br>'
		. '<a href="password.php?npw=' . $database->getUserField($form->getValue('user'), 'id', 1) . '">' . PW_GENERATE . '</a></div>';
}
if ($form->getError("activate") != "") {
	echo '<div class="og-error"><b>' . EMAIL_NOT_VERIFIED . '</b><br>' . EMAIL_FOLLOW . '<br>'
		. '<a href="activate.php?usr=' . urlencode($form->getError("activate")) . '">' . VERIFY_EMAIL . '</a></div>';
}
if ($form->getError("vacation") != "") {
	echo '<div class="og-error">' . $form->getError("vacation") . '</div>';
}
?>
		<form method="post" name="snd" action="login.php">
			<input type="hidden" name="ft" value="a4" />
			<div class="og-form">
				<label for="og-user"><?php echo NAME; ?></label>
				<input id="og-user" class="text" type="text" name="user" value="<?php echo htmlspecialchars($form->getDiff("user", $_COOKIE['COOKUSR'])); ?>" maxlength="30" autocomplete="username" autofocus />
				<span class="error"><?php echo $form->getError("user"); ?></span>
				<label for="og-pw"><?php echo PASSWORD; ?></label>
				<input id="og-pw" class="text" type="password" name="pw" value="<?php echo htmlspecialchars($form->getValue("pw"), ENT_QUOTES, 'UTF-8'); ?>" maxlength="100" autocomplete="current-password" />
				<span class="error"><?php echo $form->getError("pw"); ?></span>
			</div>
			<div class="og-btn-row">
				<button type="submit" value="login" name="s1" id="btn_login" class="og-btn og-btn-gold"><?php echo defined('LOGIN') ? LOGIN : 'Login'; ?></button>
				<a class="og-btn" href="anmelden.php">No account yet? Register</a>
			</div>
		</form>
<?php endif; ?>
	</section>
	<aside class="og-stack">
		<section class="og-card og-serverinfo">
			<h2>Server info</h2>
			<?php if (NEWSBOX1) { include("Templates/News/newsbox1.tpl"); } ?>
		</section>
		<?php if (NEWSBOX2 || NEWSBOX3): ?>
		<section class="og-card og-serverinfo">
			<?php if (NEWSBOX2) { include("Templates/News/newsbox2.tpl"); } ?>
			<?php if (NEWSBOX3) { include("Templates/News/newsbox3.tpl"); } ?>
		</section>
		<?php endif; ?>
	</aside>
</div>
<?php include("Templates/layout/outgame_bottom.tpl"); ?>
