<?php
/**
 * Shared page frame, part 1: everything from <body> to the left menu.
 * The page prints its own <head>, then includes this, then its #content,
 * then Templates/layout/page_bottom.tpl.
 */
?>
<body class="v35 ie ie8">
<div class="wrapper">
<img style="filter:chroma();" src="img/x.gif" id="msfilter" alt="" />
<div id="dynamic_header">
	</div>
<?php include(__DIR__ . "/../header.tpl"); ?>
<?php
// Resource cards. Included from a function on purpose: res.tpl's loop
// variables ($id, $wood, ...) used to leak into the page (a2b.php read $id
// and opened the found-new-village form).
if (!function_exists('tz_print_resource_cards')) {
	function tz_print_resource_cards()
	{
		global $village, $technology, $session, $database, $generator;
		include __DIR__ . "/../res.tpl";
	}
}
tz_print_resource_cards();
?>
<div id="mid">
<?php include(__DIR__ . "/../menu.tpl"); ?>
