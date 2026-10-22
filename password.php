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

if (!isset($_REQUEST['npw'])) {
    header("Location: login.php");
    exit;
}
?>
<?php
// local redesign: logged-out frame (Templates/layout/outgame_*.tpl, css/outgame.css)
$ogTitle  = 'Forgotten Password';
$ogActive = '';
include("Templates/layout/outgame_top.tpl");
?>
<div class="og-grid">
<section class="og-card og-doc og-classic">
<h1>Forgotten password</h1>
    <h1><img src="img/x.gif" class="passwort" alt="new password" /></h1>
    <h5><img src="img/x.gif" class="img_u22" alt="forgotten password" /></h5>

<?php

// User submitted email address
if (isset($_POST['email']) && isset($_POST['npw'])) {

    $uid = (int)$_POST['npw'];
    $submittedEmail = trim($_POST['email']);

    // Mesaj generic pentru a evita user enumeration
    $genericMessage =
        '<p>If the account information is valid, a password reset email has been sent.</p>';

    if ($uid <= 0 || $submittedEmail === '') {

        echo $genericMessage;

    } else {

        $email = $database->getUserField($uid, 'email', 0);
        $username = $database->getUserField($uid, 'username', 0);

        // Verifică dacă utilizatorul există și emailul corespunde
        if (
            !is_string($email) ||
            $email === '' ||
            !is_string($username) ||
            $username === '' ||
            !hash_equals($email, $submittedEmail)
        ) {

            echo $genericMessage;

        } else {

            // Generate password and confirmation code
            $npw = $generator->generateRandStr(7);
            $cpw = $generator->generateRandStr(10);

            $database->addPassword($uid, $npw, $cpw);

            // Send password email
            $mailer->sendPassword($email, $uid, $username, $npw, $cpw);

            // Escape output to prevent XSS
            echo '<p>Password was sent to: ' .
                 htmlspecialchars($submittedEmail, ENT_QUOTES, 'UTF-8') .
                 '</p>';
        }
    }

// User clicked confirmation link from email
} elseif (isset($_GET['cpw']) && isset($_GET['npw'])) {

    $uid = (int)$_GET['npw'];
    $cpw = preg_replace('#[^a-zA-Z0-9]#', '', $_GET['cpw']);

    if (!$database->resetPassword($uid, $cpw)) {
        echo '<p>The password has not been changed. Perhaps the activation code has already been used.</p>';
    } else {
        echo '<p>The password has been successfully changed.</p>';
    }

// Display form
} else {
?>

    <p>
        Before you can request a new password you have to enter the email
        address that has been used to register the account.
        <br /><br />
        Afterwards you will receive an e-mail with a new password.
        The password will only work after confirming it, though.
    </p>

    <form action="password.php" method="post">
        <p>
            <b>Email</b><br />
            <input type="hidden"
                   name="npw"
                   value="<?php echo (int)$_GET['npw']; ?>" />
            <input class="text"
                   type="text"
                   name="email"
                   maxlength="50" />
        </p>

        <p>
            <button value="ok"
                    name="s1"
                    class="trav_buttons"
                    id="btn_ok"
                    alt="OK">
                Send
            </button>
        </p>
    </form>

<?php } ?>
</section>
<aside class="og-stack">
	<section class="og-card og-serverinfo">
		<h2>Server info</h2>
		<?php if (NEWSBOX1) { include("Templates/News/newsbox1.tpl"); } ?>
	</section>
</aside>
</div>
<?php include("Templates/layout/outgame_bottom.tpl"); ?>
