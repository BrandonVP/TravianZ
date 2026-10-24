<?php
use App\Utils\AccessLogger;

#################################################################################
##              -= YOU MAY NOT REMOVE OR CHANGE THIS NOTICE =-                 ##
## --------------------------------------------------------------------------- ##
##  Filename       : index.php                      	                       ##
##  Type           : In Game Index Page                                        ##
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

if(!file_exists('var/installed') && @opendir('install')) {
    header("Location: install/");
    exit;
}

include_once("GameEngine/config.php");
/*
if($_SERVER['HTTP_HOST'] != '.SERVER.')
{
    header('location: '.SERVER.'');
    exit;
}
*/

// delete the /* and the */ if you not use localhost.

error_reporting(E_ALL || E_NOTICE);

if(file_exists('Security/Security.class.php'))
{
    require 'Security/Security.class.php';
    Security::instance();
}
else
{
    die('Security: Please activate security class!');
}

include_once "GameEngine/Database.php";
require_once __DIR__ . "/GameEngine/Lang/loader.php";
tz_load_language(LANG);

AccessLogger::logRequest();

// ---- player counts (same queries as before) ----
$ogCount = function ($where) use ($link) {
	$r = mysqli_query($link, "SELECT COUNT(*) AS Total FROM " . TB_PREFIX . "users WHERE tribe IN(1, 2, 3, 6, 7, 8, 9)" . $where);
	return $r ? (int) mysqli_fetch_assoc($r)['Total'] : 0;
};
$users  = $ogCount('');
$active = $ogCount(" AND timestamp > " . (time() - 3600 * 24));
$online = $ogCount(" AND timestamp > " . (time() - 60 * 10));

// ---- screenshots: thumbnail, full picture, title + text ----
$ogShots = [];
foreach ([[1, 1], [2, 2], [3, 1], [4, 4]] as $s) {
	$ogShots[] = [
		'thumb' => 'img/eor/s' . $s[0] . 's.jpg',
		'img'   => 'img/eor/s' . $s[0] . '.jpg',
		'hl'    => $lang['screenshots']['title' . $s[1]] ?? '',
		'desc'  => $lang['screenshots']['desc' . $s[1]] ?? '',
	];
}

// local redesign: logged-out frame (Templates/layout/outgame_*.tpl, css/outgame.css)
$ogTitle  = '';
$ogActive = 'home';
include("Templates/layout/outgame_top.tpl");
$ogReg = REG_OPEN ? ($lang['register'] ?? 'Register') : 'Coming soon';
?>
<div class="og-hero">
	<img class="og-hero-art" src="img/eor/landing.jpg" alt="" />
	<div class="og-hero-title">
		<h1><?php echo defined('TZ_TRAVIANZ') ? TZ_TRAVIANZ : 'TravianZ'; ?></h1>
		<p>Free browser strategy game - build, trade and conquer</p>
	</div>
	<a class="og-hero-sign" href="anmelden.php"><?php echo $ogReg; ?><small><?php echo REG_OPEN ? 'Free to play' : 'Registration closed'; ?></small></a>
</div>

<div class="og-grid">
	<div class="og-stack">
		<section class="og-card og-about">
			<h2><?php echo $lang['index'][0][4]; ?></h2>
			<p><?php echo $lang['index'][0][5]; ?></p>
			<h2><?php echo $lang['index'][0][10]; ?></h2>
			<ul>
				<li><?php echo $lang['index'][0][11]; ?></li>
				<li><?php echo $lang['index'][0][12]; ?></li>
				<li><?php echo $lang['index'][0][13]; ?></li>
			</ul>
			<div class="og-btn-row">
				<a class="og-btn og-btn-gold" href="anmelden.php"><?php echo $ogReg; ?></a>
				<a class="og-btn" href="login.php"><?php echo LOGIN; ?></a>
			</div>
		</section>

		<section class="og-card">
			<h2><?php echo SCREENSHOTS; ?></h2>
			<div class="og-shots">
				<?php foreach ($ogShots as $k => $s): ?>
				<a href="<?php echo $s['img']; ?>" data-shot="<?php echo $k; ?>" title="<?php echo htmlspecialchars(strip_tags($s['hl']), ENT_QUOTES, 'UTF-8'); ?>"><img src="<?php echo $s['thumb']; ?>" alt="Screenshot" loading="lazy" /></a>
				<?php endforeach; ?>
			</div>
		</section>
	</div>

	<aside class="og-stack">
		<section class="og-card">
			<h2><?php echo PLAYERS; ?></h2>
			<table class="og-stats">
				<tr><th><?php echo $lang['index'][0][7]; ?></th><td><?php echo $users; ?></td></tr>
				<tr><th><?php echo $lang['index'][0][8]; ?></th><td><?php echo $active; ?></td></tr>
				<tr><th><?php echo $lang['index'][0][9]; ?></th><td><?php echo $online; ?></td></tr>
			</table>
		</section>
		<section class="og-card og-news">
			<h2><?php echo NEWS; ?></h2>
			<?php include("Templates/indexnews.tpl"); ?>
		</section>
	</aside>
</div>

<div class="og-lightbox" id="og-lightbox" hidden>
	<div class="og-lightbox-box">
		<button type="button" class="og-lightbox-close" aria-label="Close">&times;</button>
		<h3 id="og-lb-hl"></h3>
		<img id="og-lb-img" src="" alt="Screenshot" />
		<div id="og-lb-desc" class="og-muted"></div>
		<div class="og-btn-row">
			<button type="button" class="og-btn" data-step="-1">&laquo;</button>
			<button type="button" class="og-btn" data-step="1">&raquo;</button>
		</div>
	</div>
</div>
<script>
(function () {
	var shots = <?php echo json_encode($ogShots); ?>, cur = 0;
	var box = document.getElementById('og-lightbox');
	function show(i) {
		cur = (i + shots.length) % shots.length;
		document.getElementById('og-lb-img').src = shots[cur].img;
		document.getElementById('og-lb-hl').innerHTML = shots[cur].hl;
		document.getElementById('og-lb-desc').innerHTML = shots[cur].desc;
		box.hidden = false;
	}
	document.querySelectorAll('[data-shot]').forEach(function (a) {
		a.addEventListener('click', function (e) { e.preventDefault(); show(+a.getAttribute('data-shot')); });
	});
	box.addEventListener('click', function (e) {
		if (e.target === box || e.target.classList.contains('og-lightbox-close')) box.hidden = true;
		var step = e.target.getAttribute('data-step');
		if (step) show(cur + (+step));
	});
	document.addEventListener('keydown', function (e) {
		if (box.hidden) return;
		if (e.key === 'Escape') box.hidden = true;
		if (e.key === 'ArrowRight') show(cur + 1);
		if (e.key === 'ArrowLeft') show(cur - 1);
	});
	<?php if (isset($_GET['signup'])): ?>location.replace('anmelden.php');<?php endif; ?>
	<?php if (isset($_GET['login'])): ?>location.replace('login.php');<?php endif; ?>
	<?php if (isset($_GET['screenshots'])): ?>show(0);<?php endif; ?>
})();
</script>
<?php include("Templates/layout/outgame_bottom.tpl"); ?>
