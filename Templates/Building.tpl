<?php
#################################################################################
##              -= YOU MAY NOT REMOVE OR CHANGE THIS NOTICE =-                 ##
## --------------------------------------------------------------------------- ##
##  Filename       Building.tpl                                                ##
##  Developed by:  Dzoki                                                       ##
##  Refactored by: Shadow Incremental Refactor 			                       ##
##  License:       TravianZ Project                                            ##
##  Copyright:     TravianZ (c) 2010-2025. All rights reserved.                ##
##                                                                             ##
##  Refactor notes:                                                            ##
##  - păstrată logica originală 100%                                           ##
##  - compatibil PHP 5.6+ / 7+                                                 ##
##  - redus cod duplicat                                                       ##
##  - output HTML mai sigur                                                    ##
##  - comentarii adăugate                                                      ##
##  - redirect securizat                                                       ##
##                                                                             ##
#################################################################################

// Încarcă datele pentru clădire/construcții
$building->loadBuilding();

/**
 * Escape HTML compatibil PHP vechi
 * Previne probleme XSS pe output
 */
if (!function_exists('safeHTML')) {
    function safeHTML($string)
    {
        return htmlspecialchars($string, ENT_QUOTES, 'UTF-8');
    }
}
?>

<?php if ($building->NewBuilding) {
    /**
     * Local redesign: each job shows a progress bar (start = finish - build
     * time, from the same getBuildingTime() the game uses when queuing), a
     * countdown and "done at"; a "Finish now" button replaces the clock icon.
     * tzres.js moves the bars every second (data-tz-start / data-tz-end).
     */
    $tzNow = time();
?>

<table cellpadding="1" cellspacing="1" id="building_contract" class="tz-jobs">

    <thead>
        <tr>
            <th colspan="3"><?php echo BUILDING_UPGRADING; ?></th>
        </tr>
    </thead>

    <tbody>

    <?php
    if (!empty($building->buildArray) && is_array($building->buildArray)) {

        foreach ($building->buildArray as $jobs) {

            $jobId     = isset($jobs['id']) ? (int)$jobs['id'] : 0;
            $fieldId   = isset($jobs['field']) ? (int)$jobs['field'] : 0;
            $type      = isset($jobs['type']) ? (int)$jobs['type'] : 0;
            $level     = isset($jobs['level']) ? (int)$jobs['level'] : 0;
            $timestamp = isset($jobs['timestamp']) ? (int)$jobs['timestamp'] : $tzNow;
            $master    = isset($jobs['master']) ? (int)$jobs['master'] : 0;
            $loopcon   = isset($jobs['loopcon']) ? (int)$jobs['loopcon'] : 0;

            $buildingName  = Building::procResType($type);
            $remainingTime = max(0, $timestamp - $tzNow);

            // build time of this level -> when the job started (or starts)
            $currentLevel = isset($village->resarray['f'.$fieldId]) ? (int)$village->resarray['f'.$fieldId] : 0;
            $plus = max(1, $level - $currentLevel);
            $duration = ($master == 0)
                ? (int)$database->getBuildingTime($fieldId, $type, $plus, $village->wid, $village->resarray)
                : 0;
            $start  = $timestamp - $duration;
            $queued = ($loopcon == 1 || $start > $tzNow);
            $pct    = ($duration > 0) ? max(0, min(100, ($tzNow - $start) / $duration * 100)) : 0;
    ?>

        <tr class="tz-job<?php echo $queued ? ' tz-job-queued' : ''; ?>">

            <td class="ico">
                <a href="?d=<?php echo $jobId; ?>&amp;a=0&amp;c=<?php echo safeHTML($session->checker); ?>">
                    <img src="img/x.gif" class="del" title="<?php echo CANCEL; ?>" alt="<?php echo CANCEL; ?>" />
                </a>
            </td>

            <td class="tz-job-main">
                <a href="build.php?id=<?php echo $fieldId; ?>"><?php echo safeHTML($buildingName); ?></a>
                <span class="tz-job-to">&rarr; <?php echo LEVEL.' '.$level; ?></span>

                <?php if ($master == 0) { ?>
                    <?php if (!$queued) { ?>
                        <div class="tz-job-bar"><span style="width:<?php echo round($pct, 1); ?>%" data-tz-start="<?php echo $start; ?>" data-tz-end="<?php echo $timestamp; ?>" data-tz-now="<?php echo $tzNow; ?>"></span></div>
                        <div class="tz-job-sub"><?php echo ucfirst(DONE_AT).' '.date('H:i', $timestamp); ?></div>
                    <?php } else { ?>
                        <div class="tz-job-sub">Starts <?php echo date('H:i', $start); ?> &middot; <?php echo DONE_AT.' '.date('H:i', $timestamp); ?></div>
                    <?php } ?>
                <?php } else { ?>
                    <div class="tz-job-sub">(<?php echo CONSTRUCTING_MASTER_BUILDER; ?>)</div>
                <?php } ?>
            </td>

            <td class="tz-job-time">
                <?php if ($master == 0 && !$queued) { ?>
                    <span id="timer<?php echo ++$session->timer; ?>"><?php echo $generator->getTimeFormat($remainingTime); ?></span>
                    <?php if ($building->canFinishJob($jobs)) {
                        $tzFinTxt = $building->finishJobConfirmText($buildingName, $level); ?>
                    <a class="tz-btn tz-btn-sm tz-job-finish" href="?finishJob=<?php echo $jobId; ?>&amp;c=<?php echo safeHTML($session->checker); ?>"
                       onclick="return confirm('<?php echo safeHTML(addslashes($tzFinTxt)); ?>');"
                       title="<?php echo safeHTML($tzFinTxt); ?>">Finish now &middot; <?php echo safeHTML($building->finishPriceLabel()); ?></a>
                    <?php } ?>
                <?php } elseif ($master == 0) { ?>
                    <span class="tz-job-wait">Queued</span>
                    <span id="timer<?php echo ++$session->timer; ?>" class="tz-job-hidden"><?php echo $generator->getTimeFormat($remainingTime); ?></span>
                <?php } ?>
            </td>

        </tr>

    <?php
        }
    }
    ?>

    </tbody>


</table>

<!-- JS original păstrat -->
<script type="text/javascript">
var bld=[{"stufe":1,"gid":"1","aid":"3"}];
</script>

<?php
} else {

    /**
     * Redirect securizat
     * Evită folosirea directă a REQUEST_URI fără validare minimă
     */

    $protocol = (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off')
        ? 'https://'
        : 'http://';

    $host = isset($_SERVER['HTTP_HOST'])
        ? $_SERVER['HTTP_HOST']
        : 'localhost';

    $requestUri = isset($_SERVER['REQUEST_URI'])
        ? $_SERVER['REQUEST_URI']
        : '/';

    // Elimină caractere invalide pentru header
    $requestUri = str_replace(array("\r", "\n"), '', $requestUri);

    $redirectUrl = $protocol . $host . $requestUri;

    header('Location: ' . $redirectUrl);
    exit;
}
?>
