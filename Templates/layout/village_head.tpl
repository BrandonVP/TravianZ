<?php
/**
 * Village header for dorf1 / dorf2 (local redesign): name, coordinates,
 * capital badge, loyalty, and tabs between the resource fields and the
 * village centre. Include from page scope inside #content.
 */
if (!function_exists('safeHTML')) {
    function safeHTML($string)
    {
        return htmlspecialchars($string, ENT_QUOTES, 'UTF-8');
    }
}

$tzOnCentre = (basename($_SERVER['SCRIPT_NAME']) === 'dorf2.php');
$tzLoyalty  = (int) floor($village->loyalty);
$tzCoordX   = isset($village->coor['x']) ? (int) $village->coor['x'] : 0;
$tzCoordY   = isset($village->coor['y']) ? (int) $village->coor['y'] : 0;
$tzLoyClass = $tzLoyalty < 100 ? ($tzLoyalty > 33 ? ' warn' : ' low') : '';
?>
<div class="tz-vhead">
    <div class="tz-vtitle">
        <h1><?php echo safeHTML($village->vname); ?></h1>
        <span class="tz-vcoords">(<?php echo $tzCoordX; ?>|<?php echo $tzCoordY; ?>)</span>
        <?php if ($village->capital != '0') { ?>
            <span class="tz-vbadge"><?php echo defined('TZ_CAPITAL_BADGE') ? TZ_CAPITAL_BADGE : 'Capital'; ?></span>
        <?php } ?>
        <span class="tz-vloyalty<?php echo $tzLoyClass; ?>"><?php echo LOYALTY; ?> <strong><?php echo $tzLoyalty; ?>%</strong></span>
    </div>
    <nav class="tz-vtabs" aria-label="Village views">
        <a href="dorf1.php"<?php echo $tzOnCentre ? '' : ' class="current" aria-current="page"'; ?>><?php echo defined('TZ_RESOURCE_FIELDS') ? TZ_RESOURCE_FIELDS : 'Resource fields'; ?></a>
        <a href="dorf2.php"<?php echo $tzOnCentre ? ' class="current" aria-current="page"' : ''; ?>><?php echo VILLAGE_CENTER; ?></a>
    </nav>
</div>
