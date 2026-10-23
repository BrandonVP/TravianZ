<?php
/**
 * Logged-out page frame, part 2 (local redesign): closes <main>, footer.
 */
?>
</main>
<footer class="og-footer">
	<div class="og-footer-inner">
		<div class="og-footer-links">
			<a href="anleitung.php?s=3"><?php echo defined('FAQ') ? FAQ : 'FAQ'; ?></a>
			<a href="spielregeln.php"><?php echo defined('SPIELREGELN') ? SPIELREGELN : 'Game Rules'; ?></a>
			<a href="agb.php"><?php echo defined('AGB') ? AGB : 'Terms and Conditions'; ?></a>
			<a href="impressum.php"><?php echo defined('IMPRINT') ? IMPRINT : 'Imprint'; ?></a>
			<a href="https://github.com/BrandonVP/TravianZ">Built on TravianZ (GPLv3)</a>
		</div>
		<div>&copy; 2010-<?php echo date('Y'); ?> <?php echo defined('TZ_TRAVIANZ') ? TZ_TRAVIANZ : 'TravianZ'; ?> &middot; <?php echo defined('TZ_BRAND_TAGLINE') ? TZ_BRAND_TAGLINE : ''; ?></div>
	</div>
</footer>
</body>
</html>
