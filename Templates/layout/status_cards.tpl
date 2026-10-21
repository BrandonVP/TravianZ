<?php
/**
 * Status cards for the top of the right column on dorf1 and dorf2: build
 * queue (when something is building), troops and troop movements. Appends to $layoutRightTop, which
 * Templates/layout/page_bottom.tpl prints. Include from page scope.
 */
if (!isset($layoutRightTop)) {
	$layoutRightTop = '';
}

if ($building->NewBuilding) {
	ob_start();
	include(__DIR__ . "/../Building.tpl");
	$layoutRightTop .= '<div class="tz-card tz-card-build">' . ob_get_clean() . '</div>';
}

ob_start();
include(__DIR__ . "/../troops.tpl");
$layoutRightTop .= '<div class="tz-card tz-card-troops">' . ob_get_clean() . '</div>';

ob_start();
include(__DIR__ . "/../movement.tpl");
$tzMoves = ob_get_clean();
if (strpos($tzMoves, '<table') === false) {
	// nothing on the way: say so, like the mockup
	$tzMoves = '<table id="movements" cellpadding="1" cellspacing="1"><thead><tr><th>' . rtrim(TROOP_MOVEMENTS, ': ')
	         . '</th></tr></thead><tbody><tr><td class="tz-calm">No incoming attacks</td></tr></tbody></table>';
}
$layoutRightTop .= '<div class="tz-card tz-card-moves">' . $tzMoves . '</div>';
