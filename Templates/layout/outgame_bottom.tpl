<?php
/**
 * Logged-out page frame, part 2 (local redesign): closes <main>, footer.
 */
?>
</main>
<footer class="og-footer">
	<div class="og-footer-inner">
		<div class="og-footer-links">
			<a href="spielregeln.php"><?php echo defined('SPIELREGELN') ? SPIELREGELN : 'Game Rules'; ?></a>
			<a href="agb.php"><?php echo defined('AGB') ? AGB : 'Terms and Conditions'; ?></a>
			<a href="privacy.php">Privacy</a>
			<a href="impressum.php">Contact</a>
			<a href="https://github.com/BrandonVP/TravianZ">Built on the open-source TravianZ engine (GPLv3)</a>
		</div>
		<div>&copy; 2010-<?php echo date('Y'); ?> <?php echo defined('TZ_TRAVIANZ') ? TZ_TRAVIANZ : 'Empires of Rome'; ?></div>
	</div>
</footer>
</body>
</html>
