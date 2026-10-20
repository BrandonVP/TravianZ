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
<div id="mid">
<?php include(__DIR__ . "/../menu.tpl"); ?>
