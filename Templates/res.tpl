<?php
#################################################################################
##              -= YOU MAY NOT REMOVE OR CHANGE THIS NOTICE =-                 ##
## --------------------------------------------------------------------------- ##
##  Filename       res.tpl                                                     ##
##  Developed by:  Dzoki                                                       ##
##  Refactored by: Shadow Incremental Refactor 			                       ##
##  License:       TravianZ Project                                            ##
##  Copyright:     TravianZ (c) 2010-2026. All rights reserved.                ##
##                                                                             ##
##  Incremental Refactor Notes:                                                ##
##  - Preserved original functionality                                         ##
##  - Added safety checks for legacy PHP                                       ##
##  - Reduced repeated property access                                         ##
##  - Improved readability                                                     ##
##  - Kept UI structure unchanged                                              ##
##                                                                             ##
#################################################################################

/**
 * ---------------------------------------------------------
 * Safety check (avoid undefined village context)
 * ---------------------------------------------------------
 */
if (!empty($village)) {

    /**
     * -----------------------------------------------------
     * Production values (rounded)
     * -----------------------------------------------------
     */
    $wood = round($village->getProd("wood"));
    $clay = round($village->getProd("clay"));
    $iron = round($village->getProd("iron"));
    $crop = round($village->getProd("crop"));

    /**
     * Total crop production capacity
     */
    $totalproduction = $village->allcrop;

    /**
     * Safely cache values to reduce repeated access
     */
    // floor, not round: stock is stored fractional (vdata float) and every
    // server-side check compares against the real value. Rounding up made the
    // header (and the JS ticker seeded from it) show 1 unit more than exists,
    // so "send max" on the marketplace failed with "Not enough resources".
    $woodStore = floor($village->awood);
    $clayStore = floor($village->aclay);
    $ironStore = floor($village->airon);
    $cropStore = floor($village->acrop);

    $maxStore  = $village->maxstore;
    $maxCrop   = $village->maxcrop;

    /**
     * Fill level per store as a CSS variable (--fill) on each cell; the
     * Travian Modern pack draws it as a bar, other packs ignore it.
     */
    $fill = function ($amount, $max) {
        $pct = $max > 0 ? max(0, min(100, $amount / $max * 100)) : 0;
        return '--fill:' . round($pct, 1) . '%';
    };
?>

<div id="res">
<div id="resWrap">

    <!-- ================= RESOURCES ================= -->
    <table cellpadding="1" cellspacing="1">
        <tr>

            <!-- Wood -->
            <td>
                <img src="img/x.gif" class="r1" alt="<?php echo LUMBER; ?>" title="<?php echo LUMBER; ?>" />
            </td>

            <td id="l4" style="<?php echo $fill($woodStore, $maxStore); ?>" title="<?php echo $wood; ?>">
                <?php echo $woodStore . "/" . $maxStore; ?>
            </td>

            <!-- Clay -->
            <td>
                <img src="img/x.gif" class="r2" alt="<?php echo CLAY; ?>" title="<?php echo CLAY; ?>" />
            </td>

            <td id="l3" style="<?php echo $fill($clayStore, $maxStore); ?>" title="<?php echo $clay; ?>">
                <?php echo $clayStore . "/" . $maxStore; ?>
            </td>

            <!-- Iron -->
            <td>
                <img src="img/x.gif" class="r3" alt="<?php echo IRON; ?>" title="<?php echo IRON; ?>" />
            </td>

            <td id="l2" style="<?php echo $fill($ironStore, $maxStore); ?>" title="<?php echo $iron; ?>">
                <?php echo $ironStore . "/" . $maxStore; ?>
            </td>

            <!-- Crop -->
            <td>
                <img src="img/x.gif" class="r4" alt="<?php echo CROP; ?>" title="<?php echo CROP; ?>" />
            </td>

            <?php if ($village->acrop > 0) { ?>
                <td id="l1" style="<?php echo $fill($cropStore, $maxCrop); ?>" title="<?php echo $crop; ?>">
                    <?php echo $cropStore . "/" . $maxCrop; ?>
                </td>
            <?php } else { ?>
                <td title="<?php echo $crop; ?>">
                    0/<?php echo $maxCrop; ?>
                </td>
            <?php } ?>

            <!-- Crop consumption -->
            <td>
                <img src="img/x.gif" class="r5" alt="<?php echo CROP_COM; ?>" title="<?php echo CROP_COM; ?>" />
            </td>

            <td>
                <?php echo ($village->pop + $technology->getUpkeep($village->unitall, 0)) . "/" . $totalproduction; ?>
            </td>

        </tr>
    </table>

</div>
</div>

<?php } ?>