<?php 

#################################################################################
##              -= YOU MAY NOT REMOVE OR CHANGE THIS NOTICE =-                 ##
## --------------------------------------------------------------------------- ##
##  Project:       TravianZ      					       		 		  	   ##
##  Version:       06.05.2026 						       	 				   ##
##  Filename       preference.tpl                                              ##
##  Refactored by  Shadow					                                   ##
##  License:       TravianZ Project                                            ##
##  Copyright:     TravianZ (c) 2010-2026. All rights reserved.                ##
##  URLs:          http://travianz.org						       	 		   ##
##  Source code:   http://github.com/Shadowss/TravianZ/         	       	   ##
##                                                                             ##
#################################################################################

// =========================
// DELETE LINK ACTION
// =========================
if (isset($_GET['del']) && is_numeric($_GET['del'])) {

    $delId = (int)$_GET['del'];

    // remove user link safely (owner check handled inside function)
    $database->removeLinks($delId, $session->uid);

    header("Location: spieler.php?s=2");
    exit;
}

// =========================
// LEGACY EARLY EXIT
// =========================
if (isset($_POST['ft']) && $_POST['ft'] == 'p3') {
    return;
}

// =========================
// SAVE / UPDATE LINKS
// =========================
if (
    isset($_POST['nr0']) ||
    isset($_POST['id0']) ||
    isset($_POST['linkname0']) ||
    isset($_POST['linkziel0'])
) {

    $links = [];

    // =========================
    // PARSE POST DATA
    // =========================
    foreach ($_POST as $key => $value) {

        $value = trim($value);

        // position field
        if (strpos($key, 'nr') === 0) {
            $i = substr($key, 2);
            $links[$i]['nr'] = (int)$value;
        }

        // id field
        if (strpos($key, 'id') === 0) {
            $i = substr($key, 2);
            $links[$i]['id'] = (int)$value;
        }

        // link name (escaped for SQL safety)
        if (strpos($key, 'linkname') === 0) {
            $i = substr($key, 8);
            $links[$i]['linkname'] = mysqli_real_escape_string($database->dblink, $value);
        }

        // link url (escaped for SQL safety)
        if (strpos($key, 'linkziel') === 0) {
            $i = substr($key, 8);
            $links[$i]['linkziel'] = mysqli_real_escape_string($database->dblink, $value);
        }
    }

    // =========================
    // PROCESS LINKS (ADD / UPDATE / DELETE)
    // =========================
    foreach ($links as $link) {

        $nr   = isset($link['nr']) ? (int)$link['nr'] : 0;
        $id   = isset($link['id']) ? (int)$link['id'] : 0;
        $name = isset($link['linkname']) ? trim($link['linkname']) : '';
        $url  = isset($link['linkziel']) ? trim($link['linkziel']) : '';

        // =========================
        // ADD NEW LINK
        // =========================
        if ($nr !== 0 && $name !== '' && $url !== '' && $id === 0) {

            $userid = (int)$session->uid;

            mysqli_query(
                $database->dblink,
                "INSERT INTO `" . TB_PREFIX . "links`
                (`userid`, `name`, `url`, `pos`)
                VALUES
                ($userid, '$name', '$url', $nr)"
            );

        // =========================
        // UPDATE EXISTING LINK
        // =========================
        } elseif ($nr !== 0 && $name !== '' && $url !== '' && $id > 0) {

            $id = (int)$id;

            $query = mysqli_query(
                $database->dblink,
                "SELECT userid FROM `" . TB_PREFIX . "links` WHERE id = $id"
            );

            $data = mysqli_fetch_assoc($query);

            // ownership check
            if ($data && (int)$data['userid'] === (int)$session->uid) {

                mysqli_query(
                    $database->dblink,
                    "UPDATE `" . TB_PREFIX . "links`
                     SET name='$name', url='$url', pos=$nr
                     WHERE id=$id"
                );
            }

        // =========================
        // DELETE EMPTY ENTRY
        // =========================
        } elseif ($nr === 0 && $name === '' && $url === '' && $id > 0) {

            $id = (int)$id;

            $query = mysqli_query(
                $database->dblink,
                "SELECT userid FROM `" . TB_PREFIX . "links` WHERE id = $id"
            );

            $data = mysqli_fetch_assoc($query);

            // ownership check
            if ($data && (int)$data['userid'] === (int)$session->uid) {

                mysqli_query(
                    $database->dblink,
                    "DELETE FROM `" . TB_PREFIX . "links` WHERE id = $id"
                );
            }
        }
    }

    // legacy refresh behavior
    echo '<meta http-equiv="refresh" content="0">';
}

// =========================
// LOAD LINKS
// =========================
$query = mysqli_query(
    $database->dblink,
    "SELECT * FROM `" . TB_PREFIX . "links`
     WHERE userid = " . (int)$session->uid . "
     ORDER BY pos ASC"
) or die(mysqli_error($database->dblink));

$links = [];
while ($data = mysqli_fetch_assoc($query)) {
    $links[] = $data;
}

// =========================
// USER SETTINGS SAVE
// =========================
if (isset($_POST['v1']) || isset($_POST['v2']) || isset($_POST['timezone']) || isset($_POST['lang'])) {

    $v1 = isset($_POST['v1']) ? 1 : 0;
    $v2 = isset($_POST['v2']) ? 1 : 0;
    $v3 = isset($_POST['v3']) ? 1 : 0;
    $map = isset($_POST['map']) ? 1 : 0;
    $v4 = isset($_POST['v4']) ? 1 : 0;
    $v5 = isset($_POST['v5']) ? 1 : 0;
    $v6 = isset($_POST['v6']) ? 1 : 0;

    $timezone = isset($_POST['timezone']) ? (int)$_POST['timezone'] : 1;
    $tformat  = isset($_POST['tformat']) ? (int)$_POST['tformat'] : 0;

// =========================
// LANGUAGE
// =========================

$lang = LANG;
if(isset($_POST['lang']))
{
    $allowedLangs = ['en','fr','it','ro','zh'];
    $selectedLang = strtolower(trim($_POST['lang']));
    if(in_array($selectedLang, $allowedLangs))
    {
        $lang = $selectedLang;
    }
}

    // update user preferences
    $database->query("
        UPDATE " . TB_PREFIX . "users SET
        v1=$v1,
        v2=$v2,
        v3=$v3,
        map=$map,
        v4=$v4,
        v5=$v5,
        v6=$v6,
        timezone=$timezone,
        tformat=$tformat,
        lang='$lang'
        WHERE id=" . (int)$session->uid . "
    ");

    // schimbare instant în sesiune
    $_SESSION['lang'] = $lang;

    header("Location: spieler.php?s=2");
    exit;
}
?>

<!-- =========================
     PAGE HEADER
========================= -->
<h1><?php echo PLAYER_PROFILE; ?></h1>

<?php include("menu.tpl"); ?>

<!-- =========================
     DIRECT LINKS TABLE
========================= -->
<form action="spieler.php?s=2" method="POST">
<input type="hidden" name="ft" value="p2">
<?php
// local redesign: say why a direct link was not saved (GameEngine/Profile.php)
if (!empty($_SESSION['tz_link_error'])) {
    echo '<p class="tz-link-error">' . htmlspecialchars($_SESSION['tz_link_error'], ENT_QUOTES, 'UTF-8') . '</p>';
    unset($_SESSION['tz_link_error']);
}
?>
<div class="tz-prof-card">
<h3><?php echo DIRECT_LINKS; ?></h3>
<p class="tz-link-help">Direct links appear in the side column for quick access (Plus).
    Target: a game page such as <b>build.php?gid=17</b> (Marketplace), <b>build.php?gid=16&amp;t=99</b> (Rally Point Gold Club)
    or <b>karte.php</b>, or a web address starting with http://. End the target with <b>*</b> to open it in a new tab.</p>

<table cellpadding="0" cellspacing="0" id="links" class="tz-prof-table tz-prof-links">
    <thead>
        <tr>
            <th></th>
            <th><?php echo TZ_NO; ?></th>
            <th><?php echo LINK_NAME; ?></th>
            <th><?php echo LINK_TARGET; ?></th>
        </tr>
    </thead>

    <tbody>
    <?php
    $i = 0;
    $last_pos = 0;

    foreach ($links as $link):
        $last_pos = (int)$link['pos'];
    ?>

        <tr>
            <td>
                <a href="spieler.php?del=<?php echo (int)$link['id']; ?>&s=2">
                    <img class="del" src="img/x.gif" alt="<?php echo DELETE; ?>" title="<?php echo DELETE; ?>">
                </a>
            </td>

            <td class="nr">
                <input <?php if (!$session->plus) echo "disabled"; ?>
                       class="text"
                       type="text"
                       name="nr<?php echo $i; ?>"
                       value="<?php echo (int)$link['pos']; ?>"
                       size="1"
                       maxlength="3" />

                <input type="hidden"
                       name="id<?php echo $i; ?>"
                       value="<?php echo (int)$link['id']; ?>" />
            </td>

            <td class="nam">
                <input <?php if (!$session->plus) echo "disabled"; ?>
                       class="text"
                       type="text"
                       name="linkname<?php echo $i; ?>"
                       value="<?php echo htmlspecialchars($link['name'], ENT_QUOTES, 'UTF-8'); ?>"
                       maxlength="30" />
            </td>

            <td class="txt">
                <input <?php if (!$session->plus) echo "disabled"; ?>
                       class="text"
                       type="text"
                       name="linkziel<?php echo $i; ?>"
                       value="<?php echo htmlspecialchars($link['url'], ENT_QUOTES, 'UTF-8'); ?>"
                       maxlength="255" />
            </td>
        </tr>

    <?php
    $i++;
    endforeach;
    ?>

        <!-- NEW EMPTY ROW -->
        <tr>
            <td></td>
            <td class="nr">
                <input <?php if (!$session->plus) echo "disabled"; ?>
                       class="text"
                       type="text"
                       name="nr<?php echo $i; ?>"
                       value="<?php echo ($last_pos + 1); ?>"
                       size="1"
                       maxlength="3">
            </td>

            <td class="nam">
                <input <?php if (!$session->plus) echo "disabled"; ?>
                       class="text"
                       type="text"
                       name="linkname<?php echo $i; ?>"
                       value=""
                       maxlength="30">
            </td>

            <td class="txt">
                <input <?php if (!$session->plus) echo "disabled"; ?>
                       class="text"
                       type="text"
                       name="linkziel<?php echo $i; ?>"
                       value=""
                       maxlength="255">
            </td>
        </tr>

    </tbody>
</table>
</div>

<?php
// local redesign: settings as cards (same field names as before)
$tzU = $session->userinfo;
$tzCheck = function ($name, $label, $on, $value = '1') {
    return '<label class="tz-prof-check"><input class="check" type="checkbox" name="' . $name . '"' . ($value !== null ? ' value="' . $value . '"' : '') . ($on ? ' checked' : '') . '> <span>' . $label . '</span></label>';
};
?>
<div class="tz-prof-grid">
    <div class="tz-prof-card">
        <h3><?php echo AUTO_COMPL; ?></h3>
        <p class="tz-prof-note"><?php echo TZ_USED_FOR_RALLY_POINT_AND_MARKETPLA; ?></p>
        <?php echo $tzCheck('v1', OWN_VILLAGES, $tzU['v1']); ?>
        <?php echo $tzCheck('v2', VILLAGES_NEAR, $tzU['v2']); ?>
        <?php echo $tzCheck('v3', VILLAGES_ALLI_PLAYERS, $tzU['v3']); ?>
    </div>
    <div class="tz-prof-card">
        <h3><?php echo REPORT_FILTER; ?></h3>
        <?php echo $tzCheck('v4', TZ_NO_REPORTS_FOR_TRANSFERS_TO_OWN_VI, $tzU['v4']); ?>
        <?php echo $tzCheck('v5', TZ_NO_REPORTS_FOR_TRANSFERS_TO_FOREIG, $tzU['v5']); ?>
        <?php echo $tzCheck('v6', TZ_NO_REPORTS_FOR_TRANSFERS_FROM_FORE, $tzU['v6']); ?>
        <h3 class="tz-prof-h3b"><?php echo LARGE_MAP; ?></h3>
        <?php echo $tzCheck('map', TZ_SHOW_THE_LARGE_MAP_IN_AN_EXTRA_WIN, $tzU['map'], null); ?>
    </div>
</div>

<div class="tz-prof-grid">
    <div class="tz-prof-card">
        <h3><?php echo TZ_TIME_PREFERENCE; ?></h3>
        <p class="tz-prof-note"><?php echo TZ_HERE_YOU_CAN_CHANGE_TRAVIAN_S_DISP; ?></p>
        <div class="tz-prof-form">
            <label><?php echo TZ_TIME_ZONES; ?></label>
            <select name="timezone" class="dropdown">
                <optgroup label="local time zones">
                <?php foreach ([495 => TIME_ZONE_L1, 99 => TIME_ZONE_L2, 492 => TIME_ZONE_L3, 328 => TIME_ZONE_L4, 345 => TIME_ZONE_L5, 257 => TIME_ZONE_L6, 189 => TIME_ZONE_L7, 474 => TIME_ZONE_L8] as $v => $l) { ?>
                    <option value="<?php echo $v; ?>" <?php if ($tzU['timezone'] == $v) echo 'selected'; ?>><?php echo $l; ?></option>
                <?php } ?>
                </optgroup>
                <optgroup label="general time zones">
                <?php foreach ([12 => TZ_UTC_11_2, 13 => TZ_UTC_10_2, 14 => TZ_UTC_9_2, 15 => TZ_UTC_8_2, 16 => TZ_UTC_7_2, 17 => TZ_UTC_6_2, 18 => TZ_UTC_5_2, 19 => TZ_UTC_4_2, 20 => TZ_UTC_3_2, 21 => TZ_UTC_2_2, 22 => TZ_UTC_1_2, 23 => 'UTC',
                               0 => TZ_UTC_1, 1 => TZ_UTC_2, 2 => TZ_UTC_3, 3 => TZ_UTC_4, 4 => TZ_UTC_5, 5 => TZ_UTC_6, 6 => TZ_UTC_7, 7 => TZ_UTC_8, 8 => TZ_UTC_9, 9 => TZ_UTC_10, 10 => TZ_UTC_11, 11 => TZ_UTC_12] as $v => $l) { ?>
                    <option value="<?php echo $v; ?>" <?php if ($tzU['timezone'] == $v) echo 'selected'; ?>><?php echo $l; ?></option>
                <?php } ?>
                </optgroup>
            </select>
            <label><?php echo DATE; ?></label>
            <div class="tz-prof-radios tz-prof-stack">
            <?php foreach ([0 => TZ_EU_DD_MM_YY_24H, 1 => TZ_US_MM_DD_YY_12H, 2 => TZ_UK_DD_MM_YY_12H, 3 => TZ_ISO_YY_MM_DD_24H] as $v => $l) { ?>
                <label><input class="radio" type="radio" name="tformat" value="<?php echo $v; ?>" <?php if ($tzU['tformat'] == $v) echo 'checked'; ?>> <?php echo $l; ?></label>
            <?php } ?>
            </div>
        </div>
    </div>
    <div class="tz-prof-card">
        <h3><?php echo TZ_LANGUAGE_SETTINGS; ?></h3>
        <div class="tz-prof-form">
            <label><?php echo TZ_GAME_LANGUAGE; ?></label>
            <select name="lang" class="dropdown">
            <?php foreach (['en' => TZ_ENGLISH, 'ro' => TZ_ROMANIAN, 'zh' => TZ_CHINESE, 'fr' => TZ_FRENCH, 'it' => TZ_ITALIAN, 'es' => TZ_SPANISH] as $v => $l) { ?>
                <option value="<?php echo $v; ?>" <?php if ($tzU['lang'] == $v) echo 'selected'; ?>><?php echo $l; ?></option>
            <?php } ?>
            </select>
        </div>
    </div>
</div>
<!-- =========================
     SAVE BUTTON
========================= -->
<p class="btn">
<input type="image" value="" name="s1" id="btn_ok" class="dynamic_img" src="img/x.gif" alt="OK" />
</p>

</form>

