<?php
#################################################################################
##              -= YOU MAY NOT REMOVE OR CHANGE THIS NOTICE =-                 ##
## --------------------------------------------------------------------------- ##
##  Filename       field.tpl                                                   ##
##  Developed by:  Dzoki                                                       ##
##  Refactored by: Shadow Incremental Refactor 			                       ##
##  License:       TravianZ Project                                            ##
##  Copyright:     TravianZ (c) 2010-2026. All rights reserved.                ##
##                                                                             ##
##  Refactor notes:                                                            ##
##  - păstrată logica originală 100%                                           ##
##  - compatibil PHP 5.6+ / 7+                                                 ##
##  - redus cod duplicat                                                       ##
##  - optimizat verificarea upgrade-urilor                                     ##
##  - output HTML mai sigur                                                    ##
##  - comentarii adăugate                                                      ##
##                                                                             ##
#################################################################################

/**
 * Escape HTML compatibil PHP vechi
 */
if (!function_exists('safeHTML')) {
    function safeHTML($string)
    {
        return htmlspecialchars($string, ENT_QUOTES, 'UTF-8');
    }
}

/**
 * Coordonatele câmpurilor de resurse
 * Format:
 * fieldId => coords
 */
$coorarray = array(
    1  => "101,33,28",
    2  => "165,32,28",
    3  => "224,46,28",
    4  => "46,63,28",
    5  => "138,74,28",
    6  => "203,94,28",
    7  => "262,86,28",
    8  => "31,117,28",
    9  => "83,110,28",
    10 => "214,142,28",
    11 => "269,146,28",
    12 => "42,171,28",
    13 => "93,164,28",
    14 => "160,184,28",
    15 => "239,199,28",
    16 => "87,217,28",
    17 => "140,231,28",
    18 => "190,232,28"
);

/**
 * Shortcut către resarray
 */
$arrayVillage = $village->resarray;

/**
 * Tipuri câmpuri resurse
 */
$fieldNames = array(
    1 => 'Woodcutter Level',
    2 => 'Clay Pit Level',
    3 => 'Iron Mine Level',
    4 => 'Cropland Level'
);
?>

<!-- ===================== RESOURCE FIELD MAP ===================== -->
<?php

/**
 * Upgrades in progress: fieldId => highest queued target level
 */
$jobs = $database->getJobs($village->wid);
$activeFields = array();

if (!empty($jobs) && is_array($jobs)) {
    foreach ($jobs as $job) {
        if (isset($job['type']) && (int)$job['type'] <= 4) {
            $fid = (int)$job['field'];
            $to  = isset($job['level']) ? (int)$job['level'] : 0;
            $activeFields[$fid] = max(isset($activeFields[$fid]) ? $activeFields[$fid] : 0, $to);
        }
    }
}

/**
 * Field type => CSS modifier (ring colour)
 */
$fieldKinds = array(1 => 'wood', 2 => 'clay', 3 => 'iron', 4 => 'crop');

/**
 * Upscaled, transparent map art (img/fieldmap/f<type>.webp). The medallions sit on
 * the art's badge spots, placed in % of the 300x264 design so they scale with it.
 */
$mapType = (int)$village->type;
if (!is_file(__DIR__ . '/../img/fieldmap/f' . $mapType . '.webp')) {
    $mapType = 3;
}
?>
<div id="village_map" class="fieldmap">
    <img class="fm-art" src="img/fieldmap/f<?php echo $mapType; ?>.webp?v=1" alt="" />
<?php
for ($i = 1; $i <= 18; $i++) {

    $fieldType  = isset($arrayVillage['f'.$i.'t']) ? (int)$arrayVillage['f'.$i.'t'] : 0;
    $fieldLevel = isset($arrayVillage['f'.$i])     ? (int)$arrayVillage['f'.$i]     : 0;

    if ($fieldType == 0) {
        continue;
    }

    list($cx, $cy) = array_map('intval', explode(',', $coorarray[$i]));
    $left = round($cx / 300 * 100, 2);
    $top  = round($cy / 264 * 100, 2);

    $kind  = isset($fieldKinds[$fieldType]) ? $fieldKinds[$fieldType] : 'wood';
    $title = Building::procResType($fieldType) . ' Level ' . $fieldLevel;
    $label = (string)$fieldLevel;
    $class = 'fm-field fm-' . $kind;

    if (isset($activeFields[$i])) {
        $class .= ' fm-active';
        $title .= ' (upgrade in progress)';
        if ($activeFields[$i] > $fieldLevel) {
            $label = $fieldLevel . '&rarr;' . $activeFields[$i];
        }
    }

    echo '<a href="build.php?id=' . $i . '" class="' . $class . '"'
       . ' style="left:' . $left . '%;top:' . $top . '%"'
       . ' title="' . safeHTML($title) . '">' . $label . '</a>' . "\r\n";
}
?>
    <a href="dorf2.php" class="fm-center" style="left:48%;top:49.62%" title="<?php echo safeHTML(VILLAGE_CENTER); ?>"><?php echo VILLAGE_CENTER; ?></a>
</div>
