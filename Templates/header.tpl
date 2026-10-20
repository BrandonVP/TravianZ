<?php
#################################################################################
##              -= YOU MAY NOT REMOVE OR CHANGE THIS NOTICE =-                 ##
## --------------------------------------------------------------------------- ##
##  Filename       header.tpl                                                  ##
##  Developed by:  Dzoki                                                       ##
##  Refactored by: Shadow Incremental Refactor 			                       ##
##  License:       TravianZ Project                                            ##
##  Copyright:     TravianZ (c) 2010-2025. All rights reserved.                ##
##                                                                             ##
##  Local redesign: text top bar (menu with unread counts, hero, gold, server  ##
##  time, account menu). The account links used to live in menu.tpl.          ##
##                                                                             ##
#################################################################################

if (!function_exists('safeHTML')) {
    function safeHTML($string)
    {
        return htmlspecialchars($string, ENT_QUOTES, 'UTF-8');
    }
}

/**
 * Guest/support account (id_user 1) sees a reduced bar
 */
$isRestrictedUser = (isset($_SESSION['id_user']) && (int)$_SESSION['id_user'] === 1);

$dorf1Link   = $isRestrictedUser ? '#' : 'dorf1.php';
$dorf2Link   = $isRestrictedUser ? '#' : 'dorf2.php';
$reportsLink = $isRestrictedUser ? '#' : 'berichte.php';

/**
 * Unread counts: messages ($message->unread) and reports ($message->nunread)
 */
$tzUnreadMessages = (int) $message->unread;
$tzUnreadReports  = (int) $message->nunread;

$tzPage = basename($_SERVER['SCRIPT_NAME']);
$tzNav = array(
    // short labels for the bar; the full names stay in the tooltips
    array('dorf1.php',       $dorf1Link,          defined('TZ_NAV_FIELDS')  ? TZ_NAV_FIELDS  : 'Fields',  1, 0, TZ_VILLAGE_OVERVIEW),
    array('dorf2.php',       $dorf2Link,          defined('TZ_NAV_VILLAGE') ? TZ_NAV_VILLAGE : 'Village', 2, 0, VILLAGE_CENTER),
    array('karte.php',       'karte.php',         MAP,                 3, 0),
    array('statistiken.php', 'statistiken.php',   STATISTICS,          4, 0),
    array('berichte.php',    $reportsLink,        REPORTS,             5, $tzUnreadReports),
    array('nachrichten.php', 'nachrichten.php',   MESSAGES,            6, $tzUnreadMessages),
    array('allianz.php',     'allianz.php',       ALLIANCE,            0, 0),
);

$tzIsAdmin = (isset($session->access) && $session->access == ADMIN);
$tzIsMH    = (isset($session->access) && $session->access == MULTIHUNTER);

/**
 * Plus active?
 */
$tzPlusActive = (
    isset($session->plus) && $session->plus == 1 &&
    isset($session->userinfo['plus']) && strtotime("NOW") <= $session->userinfo['plus']
);

if (!function_exists('tzCoinIcon')) {
    /** A stack of coins; $tone: gold, goldOff or silver */
    function tzCoinIcon($tone, $title)
    {
        return '<svg viewBox="0 0 24 24" class="tzCoinStack tzCoin-' . $tone . '" role="img">'
             . '<title>' . htmlspecialchars($title, ENT_QUOTES, 'UTF-8') . '</title>'
             . '<circle cx="12" cy="12" r="11" class="tzCoinBg" />'
             . '<ellipse cx="12" cy="16.1" rx="6.2" ry="2.3" class="tzCoinDisc" />'
             . '<ellipse cx="12" cy="13.1" rx="6.2" ry="2.3" class="tzCoinDisc" />'
             . '<ellipse cx="12" cy="10.1" rx="6.2" ry="2.3" class="tzCoinDisc" />'
             . '<ellipse cx="12" cy="10.1" rx="2.6" ry="0.9" class="tzCoinShine" />'
             . '</svg>';
    }
}
?>
<!-- ===================== TOP BAR ===================== -->
<div id="header" class="tzbar">
<div class="tzbar-inner">

    <a class="tzbar-logo" href="<?php echo $dorf1Link; ?>"><?php echo TZ_TRAVIANZ; ?></a>

    <nav class="tzbar-nav" aria-label="Main">
<?php foreach ($tzNav as $tzNavItem) {
    // tz-prefixed: this runs before the page content, so plain names
    // ($key, $file, $count, ...) could overwrite the page's own variables
    list($tzFile, $tzHref, $tzLabel, $tzKey, $tzCount) = $tzNavItem;
    $tzTip = isset($tzNavItem[5]) ? $tzNavItem[5] : '';
    $tzCurrent = ($tzPage === $tzFile);
    echo '        <a href="' . safeHTML($tzHref) . '"'
       . ($tzTip !== '' ? ' title="' . safeHTML($tzTip) . '"' : '')
       . ($tzKey ? ' accesskey="' . $tzKey . '"' : '')
       . ($tzCurrent ? ' class="current" aria-current="page"' : '') . '>'
       . safeHTML($tzLabel)
       . ($tzCount > 0 ? ' <span class="tzbar-count" title="' . $tzCount . ' unread">' . $tzCount . '</span>' : '')
       . "</a>\n";
} ?>
    </nav>

    <div class="tzbar-right">

        <span class="tzbar-time"><?php echo safeHTML(rtrim(SERVER_TIME, ': ')); ?> <span id="tp1" class="b"><?php echo date('H:i:s'); ?></span></span>

<?php if (!$isRestrictedUser && isset($session->gold)) {
        $goldLabel = defined('GOLD') ? GOLD : 'Gold';
        $goldValue = (int) $session->gold;
        $goldTone  = ($goldValue <= 1) ? 'goldOff' : 'gold';
?>
        <a id="goldHeader" class="tzbar-coins" href="plus.php" title="<?php echo safeHTML(PLUS_MENU); ?>">
            <?php
            echo '<span id="goldHeaderRow" class="tzCoinRow tzCoinRow-' . $goldTone . '">'
               . tzCoinIcon($goldTone, $goldValue . ' ' . $goldLabel)
               . '<span class="tzCoinValue">' . $goldValue . '</span></span>';

            if (defined('NEW_FUNCTIONS_HERO_T4') && NEW_FUNCTIONS_HERO_T4 && class_exists('HeroItems')) {
                if (!isset($GLOBALS['t4SilverValue'])) {
                    $t4SilverItems = new HeroItems();
                    $GLOBALS['t4SilverValue'] = (int) $t4SilverItems->getSilver($session->uid);
                }
                $t4SilverLabel = defined('HERO_SILVER') ? HERO_SILVER : 'Silver';
                $t4SilverValue = (int) $GLOBALS['t4SilverValue'];
                echo '<span id="silverHeader" class="tzCoinRow tzCoinRow-silver">'
                   . tzCoinIcon('silver', $t4SilverValue . ' ' . $t4SilverLabel)
                   . '<span class="tzCoinValue">' . $t4SilverValue . '</span></span>';
            }
            ?>
        </a>
<?php } ?>



        <details class="tzbar-account">
            <summary><?php echo safeHTML(isset($session->username) ? $session->username : ''); ?></summary>
            <div class="tzbar-menu">
                <a href="spieler.php?uid=<?php echo (int) $session->uid; ?>"><?php echo PROFILE; ?></a>
                <a href="#" onclick="return Popup(0,0,1);"><?php echo $lang['index'][0][2]; ?></a>
<?php
            // The forum lives in an alliance: without one (and not admin) the page
            // only lists other alliances' public forums, with nothing to do there.
            if ((isset($session->alliance) && $session->alliance > 0) || $tzIsAdmin) { ?>
                <a href="allianz.php?s=2"><?php echo FORUM; ?></a>
<?php } ?>
<?php if (!$isRestrictedUser) { ?>
                <a href="plus.php?id=3"<?php echo $tzPlusActive ? ' class="plus-active"' : ''; ?>><?php echo TZ_TRAVIANZ; ?> <b><span class="plus_g">P</span><span class="plus_o">l</span><span class="plus_g">u</span><span class="plus_o">s</span></b></a>
                <a href="spieler.php?uid=1"><?php echo SUPPORT; ?></a>
<?php } ?>
                <a href="https://discord.gg/Bg9w8w9ft" target="_blank" rel="noopener noreferrer">Discord</a>
                <a href="<?php echo HOMEPAGE; ?>"><?php echo HOME; ?></a>
<?php if ($tzIsMH) { ?>
                <a href="Admin/admin.php" class="staff"><?php echo MH_PANEL; ?></a>
<?php } ?>
<?php if ($tzIsAdmin) { ?>
                <a href="Admin/admin.php" class="staff"><?php echo ADMIN_PANEL; ?></a>
                <a href="build_croppers.php"><?php echo TZ_BUILD_CROPPER; ?></a>
<?php } ?>
                <a href="logout.php" class="logout"><?php echo LOGOUT; ?></a>
            </div>
        </details>
        <script type="text/javascript">
        // close the account menu on any click outside it
        document.addEventListener('click', function (e) {
            var d = document.querySelector('details.tzbar-account[open]');
            if (d && !d.contains(e.target)) d.removeAttribute('open');
        });
        </script>

    </div>

</div>
</div>
