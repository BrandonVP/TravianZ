<?php
/**
 * Shared page frame, part 2: right column, footer, resource bar and server
 * time, closing #mid and the document. Page timer: $start_timer, or the
 * $pagestart some pages use.
 */
$layoutTimerStart = isset($start_timer) ? $start_timer : (isset($pagestart) ? $pagestart : $generator->pageLoadTimeStart());
?>
<div id="side_info">
<?php
include(__DIR__ . "/../multivillage.tpl");
include(__DIR__ . "/../quest.tpl");
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
<div id="stime">
<div id="ltime">
<div id="ltimeWrap">
<?php echo CALCULATED_IN;?> <b><?php
echo round(($generator->pageLoadTimeEnd()-$layoutTimerStart)*1000);
?></b> ms

<br /><?php echo SERVER_TIME;?> <span id="tp1" class="b"><?php echo date('H:i:s'); ?></span>
</div>
	</div>
</div>

<div id="ce"></div>
</body>
</html>
