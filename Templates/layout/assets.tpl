	<link rel="shortcut icon" href="favicon.ico"/>
	<meta http-equiv="cache-control" content="max-age=0" />
	<meta http-equiv="pragma" content="no-cache" />
	<meta http-equiv="expires" content="0" />
	<meta http-equiv="imagetoolbar" content="no" />
	<meta http-equiv="content-type" content="text/html; charset=UTF-8" />
	<script src="mt-full.js?0faab" type="text/javascript"></script>
	<script src="unx.js?f4b7m" type="text/javascript"></script>
	<script src="new.js?0faab" type="text/javascript"></script>
	<script src="tzres.js?v=<?php echo @filemtime(__DIR__ . '/../../tzres.js'); ?>" type="text/javascript"></script>
	<link href="<?php echo GP_LOCATE; ?>lang/en/compact.css?f4b7i" rel="stylesheet" type="text/css" />
	<link href="<?php echo GP_LOCATE; ?>lang/en/lang.css?e21d2" rel="stylesheet" type="text/css" />
	<link href="<?php echo GP_LOCATE; ?>travian.css?e21d2" rel="stylesheet" type="text/css" />
	<link href="<?php echo GP_LOCATE; ?>lang/en/lang.css?e21d2" rel="stylesheet" type="text/css" />
	<link rel="preconnect" href="https://fonts.googleapis.com" />
	<link href="https://fonts.googleapis.com/css2?family=Cinzel:wght@600;700&amp;family=Source+Sans+3:wght@400;600;700&amp;display=swap" rel="stylesheet" type="text/css" />
	<link href="css/layout.css?v=<?php echo @filemtime(__DIR__ . '/../../css/layout.css'); ?>" rel="stylesheet" type="text/css" />
<?php
	// A pack's own theme layer (e.g. Travian Modern's modern.css), versioned by
	// file time so browsers pick up every change instead of a 30-day cache.
	$tzPackTheme = __DIR__ . '/../../' . GP_LOCATE . 'modern.css';
	if (is_file($tzPackTheme)) {
		echo "\t<link href=\"" . GP_LOCATE . 'modern.css?v=' . filemtime($tzPackTheme) . "\" rel=\"stylesheet\" type=\"text/css\" />\n";
	}
?>
