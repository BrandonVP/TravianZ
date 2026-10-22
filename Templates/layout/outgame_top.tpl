<?php
/**
 * Logged-out page frame, part 1 (local redesign): <head>, wood top bar, opens
 * <main>. Set before including:
 *   $ogTitle   page title (after the server name)
 *   $ogActive  'home' | 'tutorial' | 'manual' | 'login' | 'register' - highlights the nav link
 *   $ogHead    optional extra <head> markup (scripts)
 * Close with Templates/layout/outgame_bottom.tpl. Styles: css/outgame.css.
 */
$ogTitle  = isset($ogTitle) ? $ogTitle : '';
$ogActive = isset($ogActive) ? $ogActive : '';
$ogRegisterLabel = defined('REGISTER') ? REGISTER : 'Register';
$ogNav = [
    'home'     => ['index.php', defined('HOME') ? HOME : 'Homepage'],
    'tutorial' => ['tutorial.php', defined('TUTORIAL') ? TUTORIAL : 'Tutorial'],
    'manual'   => ['anleitung.php', defined('PUBLIC_MANUAL') ? PUBLIC_MANUAL : 'Manual'],
    'login'    => ['login.php', defined('LOGIN') ? LOGIN : 'Login'],
    'register' => ['anmelden.php', $ogRegisterLabel],
];
?>
<!DOCTYPE html>
<html lang="en">
<head>
	<meta charset="UTF-8" />
	<meta name="viewport" content="width=device-width, initial-scale=1" />
	<title><?php echo SERVER_NAME . ($ogTitle !== '' ? ' - ' . $ogTitle : ''); ?></title>
	<link rel="shortcut icon" href="favicon.ico" />
	<link rel="preconnect" href="https://fonts.googleapis.com" />
	<link href="https://fonts.googleapis.com/css2?family=Cinzel:wght@600;700&amp;family=Source+Sans+3:wght@400;600;700&amp;display=swap" rel="stylesheet" type="text/css" />
	<link href="css/outgame.css?v=<?php echo @filemtime(__DIR__ . '/../../css/outgame.css'); ?>" rel="stylesheet" type="text/css" />
	<script src="tzbuttons.js?v=<?php echo @filemtime(__DIR__ . '/../../tzbuttons.js'); ?>" type="text/javascript"></script>
	<?php echo isset($ogHead) ? $ogHead : ''; ?>
</head>
<body class="og">
<header class="og-bar">
	<div class="og-bar-inner">
		<a class="og-logo" href="index.php"><?php echo defined('TZ_TRAVIANZ') ? TZ_TRAVIANZ : 'TravianZ'; ?></a>
		<nav class="og-nav">
			<?php foreach ($ogNav as $ogKey => $ogItem): ?>
			<a href="<?php echo $ogItem[0]; ?>" class="<?php echo trim(($ogKey === $ogActive ? 'is-active ' : '') . ($ogKey === 'register' ? 'og-nav-cta' : '')); ?>"><?php echo $ogItem[1]; ?></a>
			<?php endforeach; ?>
		</nav>
	</div>
</header>
<main class="og-main">
