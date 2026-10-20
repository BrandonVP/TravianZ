<?php
/**
 * Shared page frame, part 2: right column, footer, resource bar and render
 * time, closing #mid and the document. Page timer: $start_timer, or the
 * $pagestart some pages use. The village list lives in the left column
 * (menu.tpl) and the server clock in the top bar (header.tpl).
 */
$layoutTimerStart = isset($start_timer) ? $start_timer : (isset($pagestart) ? $pagestart : $generator->pageLoadTimeStart());
?>
<div id="side_info">
<?php
// page-specific cards for the top of the right column (dorf1: build queue,
// troops, movements), captured by the page before including this file
if (!empty($layoutRightTop)) {
	echo '<div class="tz-cards">' . $layoutRightTop . '</div>';
}
include(__DIR__ . "/../news.tpl");
if(!NEW_FUNCTIONS_DISPLAY_LINKS) {
	echo "<br><br><br><br>";
	include(__DIR__ . "/../links.tpl");
}
?>
</div>
<div class="clear"></div>
</div>
<div class="footer-stopper"></div>
<div class="clear"></div>

<?php
include(__DIR__ . "/../footer.tpl");
include(__DIR__ . "/../res.tpl");
?>
<div id="stime" class="tz-rendertime">
<?php echo CALCULATED_IN;?> <b><?php
echo round(($generator->pageLoadTimeEnd()-$layoutTimerStart)*1000);
?></b> ms
</div>

<div id="ce"></div>
</body>
</html>
