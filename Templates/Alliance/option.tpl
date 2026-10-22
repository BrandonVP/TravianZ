<?php

#################################################################################
##                -= YOU MAY NOT REMOVE OR CHANGE THIS NOTICE =-               ##
## --------------------------------------------------------------------------- ##
##  Filename       : option.tpl                                                ##
##  Type           : Alliance Settings Overview                                ##
## --------------------------------------------------------------------------- ##
##  Developed by   : Shadow                                                    ##
## --------------------------------------------------------------------------- ##
##  Contact        : cata7007@gmail.com                                        ##
##  Project        : TravianZ                                                  ##
##  URLs:          : https://travianz.org                                      ##
##  GitHub         : https://github.com/Shadowss/TravianZ                      ##
## --------------------------------------------------------------------------- ##
##  License        : TravianZ Project                                          ##
##  Copyright      : TravianZ (c) 2010-2026. All rights reserved.              ##
## --------------------------------------------------------------------------- ##
#################################################################################

// -------------------------------------------------
// SAFE ALLIANCE ID
// -------------------------------------------------

$aid = isset($aid) ? (int)$aid : (int)$session->alliance;

// -------------------------------------------------
// LOAD DATA
// -------------------------------------------------

$allianceinfo = $database->getAlliance($aid);

// -------------------------------------------------
// HEADER
// -------------------------------------------------

echo "<h1>" .
    htmlspecialchars($allianceinfo['tag'], ENT_QUOTES, 'UTF-8') .
    " - " .
    htmlspecialchars($allianceinfo['name'], ENT_QUOTES, 'UTF-8') .
    "</h1>";

include_once("alli_menu.tpl");
?>

<!-- ERROR OUTPUT -->
<p class="error">
    <?php echo $form->getError("perm"); ?>
</p>

<?php
// local redesign: grouped action tiles instead of a radio list + OK.
// Each tile posts o=<option> exactly like the old form did.
$perm = $alliance->userPermArray;
$tzOptGroups = [
    'Members' => [
        4 => ['opt4', 'Invite a player', 'Send an invitation to join the alliance.'],
        1 => ['opt1', 'Positions & rights', 'Give members a title and choose what they may do.'],
        2 => ['opt2', 'Kick a player', 'Remove a member from the alliance.'],
    ],
    'Alliance profile' => [
        3 => ['opt3', 'Description', 'Edit the description and notice board on the overview.'],
        100 => ['opt3', 'Name & tag', 'Rename the alliance or change its tag.'],
        5 => ['opt5', 'Forum link', 'Link an external forum from the overview.'],
    ],
    'Diplomacy' => [
        6 => ['opt6', 'Diplomacy', 'Offer or answer alliances, non-aggression pacts and wars.'],
    ],
];
?>
<form method="POST" action="allianz.php" class="tz-opts">
<input type="hidden" name="s" value="5">
<?php foreach ($tzOptGroups as $tzGroup => $tzItems) {
    $tzShown = array_filter($tzItems, function ($it) use ($perm) { return !empty($perm[$it[0]]) && $perm[$it[0]] == 1; });
    if (!$tzShown) continue; ?>
    <h3 class="tz-opts-h"><?php echo $tzGroup; ?></h3>
    <div class="tz-opts-grid">
    <?php foreach ($tzShown as $tzVal => $it) { ?>
        <button type="submit" name="o" value="<?php echo (int) $tzVal; ?>" class="tz-opt">
            <span class="tz-opt-t"><?php echo $it[1]; ?></span>
            <span class="tz-opt-d"><?php echo $it[2]; ?></span>
        </button>
    <?php } ?>
    </div>
<?php } ?>
    <h3 class="tz-opts-h">Leave</h3>
    <div class="tz-opts-grid">
        <button type="submit" name="o" value="11" class="tz-opt tz-opt-danger">
            <span class="tz-opt-t"><?php echo TZ_QUIT_ALLIANCE; ?></span>
            <span class="tz-opt-d">Leave this alliance. You confirm it with your password.</span>
        </button>
    </div>
</form>
