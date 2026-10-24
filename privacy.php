<?php
/**
 * Empires of Rome - Privacy Policy (logged-out page, outgame layout).
 */

use App\Utils\AccessLogger;

include_once("GameEngine/config.php");
include_once("GameEngine/Database.php");
require_once __DIR__ . "/GameEngine/Lang/loader.php";
tz_load_language(LANG);

AccessLogger::logRequest();

$ogTitle  = 'Privacy Policy';
$ogActive = '';
include("Templates/layout/outgame_top.tpl");
?>
<section class="og-card og-doc">
	<h1>Privacy Policy</h1>
	<p><b>Effective date:</b> October 23, 2026</p>

	<p>Empires of Rome ("we", "us") is a free browser strategy game run by an individual in the United States. This policy explains what information we collect, why, and the choices you have. Questions: <a href="mailto:contact@empiresofrome.com">contact@empiresofrome.com</a>.</p>

	<h3>1. Information we collect</h3>
	<ul>
		<li><b>Account details:</b> your username, e-mail address and password. Passwords are stored only as a secure one-way hash (bcrypt); we cannot read your password.</li>
		<li><b>IP address and technical data:</b> your IP address, browser type and login times, recorded when you visit or log in.</li>
		<li><b>Game data:</b> your villages, troops, messages, alliance activity, reports and other actions inside the game.</li>
		<li><b>Cookies:</b> a session cookie that keeps you logged in. It is required for the game to work.</li>
	</ul>
	<p>We do not currently use advertising trackers or third-party analytics.</p>

	<h3>2. Why we use it</h3>
	<ul>
		<li>To create and run your account and let you play the game.</li>
		<li>To enforce the game rules, including detecting cheating, bots and multiple accounts (this is why IP addresses and login data are checked).</li>
		<li>To keep the game and its players secure and to prevent abuse.</li>
		<li>To contact you about your account (for example account activation or password resets).</li>
	</ul>

	<h3>3. Service providers</h3>
	<p>We use Cloudflare as a hosting, network and security provider. All traffic to the game passes through Cloudflare, which processes it (including IP addresses) to deliver the site and protect it from attacks. Cloudflare handles this data under its own privacy policy.</p>

	<h3>4. We do not sell your data</h3>
	<p>We do not sell, rent or trade your personal information. We only share it when required by law or to protect the game and its players.</p>

	<h3>5. Retention and deletion</h3>
	<p>We keep your account and game data while your account exists. Accounts are not deleted automatically for inactivity. Some game data is removed automatically: unarchived battle reports after 14 days and chat messages after 7 days.</p>
	<p>When a game round ends, accounts are kept until the administrators reset the world. A world reset permanently erases all player accounts, villages, messages, reports and login history.</p>
	<p>You can delete your account at any time from your profile settings. Deletion takes effect after a 72-hour waiting period, during which you can cancel it. Deleting your account also removes your login records. You can also ask us to delete your account by e-mailing <a href="mailto:contact@empiresofrome.com">contact@empiresofrome.com</a> from your registered address.</p>
	<p>We keep a limited record of login IP addresses and browser information for security and to enforce our multi-account rules. IP addresses and browser/login records are automatically deleted after 12 months, sooner if the game world is reset or your account is deleted, except where we keep them longer because they relate to a ban or abuse investigation. Our hosting and security providers (such as Cloudflare) also keep their own technical logs under their own policies.</p>

	<h3>6. Children</h3>
	<p>Empires of Rome is not intended for children under 13, and they may not create an account. We do not knowingly collect information from children under 13. If you believe a child under 13 has an account, contact us and we will delete it.</p>

	<h3>7. Users in the EU and UK</h3>
	<p>If you are in the European Union or United Kingdom, you have the right to access, correct or delete your personal data, and to object to or restrict how we use it. We process your data to provide the game you signed up for and for our legitimate interest in keeping it fair and secure. To use these rights, e-mail <a href="mailto:contact@empiresofrome.com">contact@empiresofrome.com</a>. You may also complain to your local data protection authority.</p>

	<h3>8. Changes to this policy</h3>
	<p>We may update this policy from time to time. Changes will be posted on this page with a new effective date.</p>
</section>
<?php include("Templates/layout/outgame_bottom.tpl"); ?>
