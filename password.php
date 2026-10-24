<?php

#################################################################################
##              -= YOU MAY NOT REMOVE OR CHANGE THIS NOTICE =-                 ##
## --------------------------------------------------------------------------- ##
##  Filename       : password.php                                              ##
##  Type           : In Game Password Page                                     ##
## --------------------------------------------------------------------------- ##
##  Developed by   : Dzoki                                                     ##
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

if (!file_exists('var/installed') && @opendir('install')) {
    header("Location: install/");
    exit;
}

include_once("GameEngine/config.php");
require_once __DIR__ . "/GameEngine/Lang/loader.php";
tz_load_language(LANG);
include_once("GameEngine/Database.php");
include_once("GameEngine/Mailer.php");
include_once("GameEngine/Generator.php");

AccessLogger::logRequest();

/**
 * Local security fix (Empires of Rome): reset by one-time link
 * (GameEngine/PasswordReset.php). The old flow mailed a plain-text password.
 *   GET            -> ask for the e-mail address
 *   POST email     -> send a link (same answer whether or not the address exists)
 *   GET  ?token=   -> choose a new password
 *   POST token+pw  -> set it; every session of the account ends
 */
header('Referrer-Policy: no-referrer');
header('Cache-Control: no-store');

$tzToken  = (string) ($_POST['token'] ?? $_GET['token'] ?? '');
$tzState  = 'ask';
$tzError  = '';

if ($tzToken !== '') {
    if (!PasswordReset::check($tzToken)) {
        $tzState = 'invalid';
    } elseif (isset($_POST['pw1'])) {
        $tzError = PasswordReset::complete($tzToken, $_POST['pw1'], $_POST['pw2'] ?? '');
        $tzState = ($tzError === '') ? 'done' : ($tzError === 'invalid' ? 'invalid' : 'choose');
    } else {
        $tzState = 'choose';
    }
} elseif (isset($_GET['cpw'])) {
    $tzState = 'invalid';                       // links from the old e-mails
} elseif ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['email'])) {
    PasswordReset::request($_POST['email']);
    $tzState = 'sent';
}

$tzEsc = function ($s) { return htmlspecialchars((string) $s, ENT_QUOTES, 'UTF-8'); };

// local redesign: logged-out frame (Templates/layout/outgame_*.tpl, css/outgame.css)
$ogTitle  = 'Forgotten Password';
$ogActive = '';
include("Templates/layout/outgame_top.tpl");
?>
<div class="og-grid">
<section class="og-card og-doc og-classic">
<h1>Forgotten password</h1>

<?php if ($tzState === 'sent'): ?>
    <p>If an account uses that address, we have sent it a link to choose a new password.
       The link works once and expires after one hour.</p>
    <p class="og-muted">No e-mail? Check your spam folder, or try again in a few minutes.</p>
    <p><a class="og-btn" href="login.php">Back to login</a></p>

<?php elseif ($tzState === 'invalid'): ?>
    <p class="og-error">This link is invalid, has already been used, or has expired.</p>
    <p><a class="og-btn og-btn-gold" href="password.php">Request a new link</a></p>

<?php elseif ($tzState === 'choose'): ?>
    <p>Choose a new password for your account. Afterwards you will be logged out everywhere.</p>
    <?php if ($tzError !== ''): ?><p class="og-error"><?php echo $tzEsc($tzError); ?></p><?php endif; ?>
    <form action="password.php" method="post" autocomplete="off">
        <input type="hidden" name="token" value="<?php echo $tzEsc($tzToken); ?>" />
        <div class="og-form">
            <label for="tz-pw1">New password</label>
            <input id="tz-pw1" class="text" type="password" name="pw1" maxlength="100" autocomplete="new-password" autofocus />
            <label for="tz-pw2">Repeat new password</label>
            <input id="tz-pw2" class="text" type="password" name="pw2" maxlength="100" autocomplete="new-password" />
        </div>
        <div class="og-btn-row">
            <button type="submit" class="og-btn og-btn-gold">Save password</button>
        </div>
    </form>

<?php elseif ($tzState === 'done'): ?>
    <p>Your password has been changed. You can log in with it now.</p>
    <p><a class="og-btn og-btn-gold" href="login.php">Log in</a></p>

<?php else: ?>
    <p>Enter the e-mail address of your account. We will send you a link to choose a new password.</p>
    <form action="password.php" method="post">
        <div class="og-form">
            <label for="tz-email">E-mail</label>
            <input id="tz-email" class="text" type="email" name="email" maxlength="100" autocomplete="email" autofocus />
        </div>
        <div class="og-btn-row">
            <button type="submit" class="og-btn og-btn-gold">Send link</button>
            <a class="og-btn" href="login.php">Back to login</a>
        </div>
    </form>
<?php endif; ?>
</section>
<aside class="og-stack">
	<section class="og-card og-serverinfo">
		<h2>Server info</h2>
		<?php if (NEWSBOX1) { include("Templates/News/newsbox1.tpl"); } ?>
	</section>
</aside>
</div>
<?php include("Templates/layout/outgame_bottom.tpl"); ?>
