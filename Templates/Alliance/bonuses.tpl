<?php

#################################################################################
##                -= YOU MAY NOT REMOVE OR CHANGE THIS NOTICE =-               ##
## --------------------------------------------------------------------------- ##
##  Filename       : bonuses.tpl                                               ##
##  Type           : Alliance Bonuses and Donations                            ##
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

if (!class_exists('AllianceBonus')) {
    include_once('GameEngine/AllianceBonus.php');
}

// -------------------------------------------------
// ID-UL ALIANTEI SI DATELE EI
// -------------------------------------------------
// Fiecare pagina de alianta si le incarca singura (vezi chat.tpl, option.tpl),
// pentru ca allianz.php nu le pune la dispozitie global.
if (!isset($aid)) {
    $aid = (int) $session->alliance;
}

$allianceinfo = $database->getAlliance($aid);

// Titlul si bara de taburi, exact ca in celelalte pagini de alianta.
// Fara ele, intrarea pe tabul de bonusuri facea sa dispara navigatia si nu
// mai aveai cum sa te intorci la Overview.
echo "<h1>"
    . htmlspecialchars($allianceinfo['tag'], ENT_QUOTES, 'UTF-8')
    . " - "
    . htmlspecialchars($allianceinfo['name'], ENT_QUOTES, 'UTF-8')
    . "</h1>";

include("alli_menu.tpl");

$abEngine  = new AllianceBonus();
$abMessage = '';
$abError   = false;

/* ---------------------------------------------------------------- donatie */
if (isset($_POST['ab_donate'])) {

    $abType   = (int) ($_POST['ab_type'] ?? 0);
    $abTriple = isset($_POST['ab_triple']) && $_POST['ab_triple'] === '1';

    $abAmounts = array(
        (float) ($_POST['ab_wood'] ?? 0),
        (float) ($_POST['ab_clay'] ?? 0),
        (float) ($_POST['ab_iron'] ?? 0),
        (float) ($_POST['ab_crop'] ?? 0),
    );

    $abResult = $abEngine->donate($session->uid, $village->wid, $abType, $abAmounts, $abTriple);

    switch ($abResult) {
        case AllianceBonus::DONATE_OK:
            $abMessage = defined('ALLYBONUS_MSG_OK') ? ALLYBONUS_MSG_OK : 'Resources donated.';
            break;
        case AllianceBonus::DONATE_UPGRADING:
            $abMessage = defined('ALLYBONUS_MSG_UPGRADING') ? ALLYBONUS_MSG_UPGRADING
                : 'This bonus is currently being unlocked; donations are paused.';
            $abError = true;
            break;
        case AllianceBonus::DONATE_LIMIT:
            $abMessage = defined('ALLYBONUS_MSG_LIMIT') ? ALLYBONUS_MSG_LIMIT
                : 'That would exceed your daily donation limit.';
            $abError = true;
            break;
        case AllianceBonus::DONATE_RESOURCES:
            $abMessage = defined('ALLYBONUS_MSG_RESOURCES') ? ALLYBONUS_MSG_RESOURCES
                : 'Not enough resources in this village.';
            $abError = true;
            break;
        case AllianceBonus::DONATE_OVER_MAX:
            // La ultimul nivel surplusul ar ramane blocat, deci spunem exact
            // cat se mai poate dona.
            $abMessage = sprintf(
                defined('ALLYBONUS_MSG_OVERMAX') ? ALLYBONUS_MSG_OVERMAX
                    : 'This is the final level: you can donate at most %s more resources.',
                number_format(AllianceBonus::$overMaxAllowed)
            );
            $abError = true;
            break;
        case AllianceBonus::DONATE_NO_GOLD:
            $abMessage = defined('ALLYBONUS_MSG_NOGOLD') ? ALLYBONUS_MSG_NOGOLD
                : 'Not enough gold to triple this donation.';
            $abError = true;
            break;
        case AllianceBonus::DONATE_NO_ALLIANCE:
            $abMessage = defined('ALLYBONUS_MSG_NOALLY') ? ALLYBONUS_MSG_NOALLY
                : 'You are not in an alliance.';
            $abError = true;
            break;
        default:
            $abMessage = defined('ALLYBONUS_MSG_INVALID') ? ALLYBONUS_MSG_INVALID
                : 'Invalid donation.';
            $abError = true;
    }
}

/* ------------------------------------------------------------------ stare */
$abAid     = $aid;
$abState   = $abEngine->getState($abAid);
$abHighest = $abEngine->highestLevel($abAid);
$abLimit   = AllianceBonus::dailyLimit($abHighest);
$abUsed    = $abEngine->donatedToday($session->uid);
$abLeft    = max(0, $abLimit - $abUsed);
$abTypes   = AllianceBonus::types();
$abGpack   = defined('GP_LOCATE') ? GP_LOCATE : 'gpack/travian_default/';
?>

<style>
/* Prefix "ab-" ca stilurile sa nu atinga restul paginilor de alianta.
   local redesign: theme colours (css/layout.css variables) */
.ab-wrap{font-size:12px;color:var(--tz-ink)}
.ab-msg{padding:7px 10px;margin-bottom:10px;border:1px solid #b9cf8f;border-radius:8px;background:#eef5dd;color:#2f5220}
.ab-msg.err{border-color:#d9a99a;background:#f8e3dc;color:#8a2f1c}
.ab-allow{margin:0 0 12px;color:#6b5a45}
.ab-allow b{color:var(--tz-ink)}
.ab-grid{display:flex;flex-wrap:wrap;gap:10px;margin-bottom:10px}
.ab-card{flex:1 1 250px;border:1px solid var(--tz-line);border-radius:10px;background:var(--tz-panel);padding:10px;box-shadow:0 1px 2px rgba(60,40,10,.08)}
.ab-head{display:flex;align-items:flex-start;gap:8px;margin-bottom:8px}
.ab-head img{width:44px;height:44px}
.ab-name{font-family:"Cinzel",Georgia,serif;font-weight:700;font-size:14px;color:var(--tz-ink)}
.ab-lvl{color:#6b5a45;font-size:11px}
/* descrierea sta in dreapta numelui si ocupa spatiul ramas */
.ab-desc{flex:1;color:#6b5a45;font-size:11px;line-height:1.35;padding-left:4px}
.ab-eff{color:#3f7a2a;font-weight:bold}
.ab-wait{color:#9a5a12;font-size:10px}
.ab-bar{background:var(--tz-cream);border:1px solid var(--tz-line);border-radius:999px;height:10px;overflow:hidden;margin:4px 0}
.ab-bar i{display:block;height:100%;background:linear-gradient(#e3b84a,#b8861f)}
.ab-num{font-size:11px;color:#6b5a45}
.ab-form{margin-top:8px}
.ab-res{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:4px 10px;margin-bottom:6px}
.ab-res label{display:flex;align-items:center;gap:5px}
.ab-form input.ab-in{width:100%;min-width:0;box-sizing:border-box;padding:3px 6px;border:1px solid var(--tz-line);border-radius:6px;background:#fffdf7;color:var(--tz-ink);font:inherit}
.ab-form input.ab-in:focus{outline:none;border-color:var(--tz-gold);box-shadow:0 0 0 2px rgba(201,151,46,.25)}
.ab-triple{display:flex;align-items:center;gap:5px;font-size:11px;color:#6b5a45;margin-bottom:6px}
.ab-status{font-size:11px;color:#9a5a12;font-weight:bold}
.ab-tbl{width:100%;border-collapse:separate;border-spacing:0;font-size:12px;border:1px solid var(--tz-line);border-radius:8px;overflow:hidden;background:var(--tz-panel)}
.ab-wrap table.ab-tbl th{background:var(--tz-cream);color:var(--tz-ink);text-align:left;padding:5px 8px;border:0;border-bottom:1px solid var(--tz-line)}
.ab-wrap table.ab-tbl td{background:transparent;padding:5px 8px;border:0;border-top:1px solid var(--tz-cream-2);text-align:left}
.ab-wrap table.ab-tbl th.ab-r,.ab-wrap table.ab-tbl td.ab-r{text-align:right}
.ab-note{color:#6b5a45;font-size:11px;margin-top:4px}
.ab-wrap h4{font-family:"Cinzel",Georgia,serif;margin:14px 0 6px}
</style>

<div class="ab-wrap">

<?php if ($abMessage !== '') { ?>
    <div class="ab-msg<?php echo $abError ? ' err' : ''; ?>"><?php echo $abMessage; ?></div>
<?php } ?>

<p class="ab-allow">
    <?php echo defined('ALLYBONUS_DAILY_LEFT') ? ALLYBONUS_DAILY_LEFT : 'Your donation allowance left today'; ?>:
    <b><?php echo number_format($abLeft); ?></b>
    / <?php echo number_format($abLimit); ?>
</p>

<div class="ab-grid">
<?php
    foreach ($abTypes as $abT => $abInfo) {
        $abRow   = $abState[$abT];
        $abLevel = (int) $abRow['level'];
        $abNext  = $abLevel + 1;
        $abCost  = AllianceBonus::costFor($abLevel);
        $abPool  = (float) $abRow['pool'];
        $abBusy  = $abRow['upgrade_end'] > time();
        $abPct   = ($abCost > 0) ? max(0, min(100, $abPool / $abCost * 100)) : 100;
        $abName  = defined($abInfo['lang']) ? constant($abInfo['lang']) : ucfirst($abInfo['key']);
?>
    <div class="ab-card">
        <div class="ab-head">
            <img src="<?php echo $abGpack; ?>img/ally/bonus<?php echo ucfirst($abInfo['key']); ?>.png"
                 alt="<?php echo $abName; ?>" title="<?php echo $abName; ?>" />
            <span>
                <span class="ab-name"><?php echo $abName; ?></span><br>
                <span class="ab-lvl">
                    <?php echo defined('ALLYBONUS_LEVEL') ? ALLYBONUS_LEVEL : 'Level'; ?>
                    <?php echo $abLevel; ?> / <?php echo AllianceBonus::MAX_LEVEL; ?>
                    <?php
                        // Nivelul de care beneficiezi TU poate fi mai mic decat cel
                        // al aliantei: membrii noi capata acces treptat. Aratam
                        // amandoua valorile, altfel bonusul pare ca nu se aplica.
                        $abMine = $abEngine->effectiveLevel($session->uid, $abT);
                        $abWait = $abEngine->waitingFor($session->uid, $abT);
                    ?>
                    &nbsp;<span class="ab-eff">+<?php echo (int) AllianceBonus::percentFor($abT, $abMine); ?>%</span>
                    <?php if ($abMine < $abLevel) { ?>
                        <br><span class="ab-wait">
                            <?php echo defined('ALLYBONUS_YOURLEVEL') ? ALLYBONUS_YOURLEVEL : 'Your level'; ?>:
                            <b><?php echo $abMine; ?></b>
                            <?php if ($abWait > 0) { ?>
                                &ndash; <?php echo defined('ALLYBONUS_UNLOCKS_IN') ? ALLYBONUS_UNLOCKS_IN : 'next in'; ?>
                                <?php echo $generator->getTimeFormat($abWait); ?>
                            <?php } ?>
                        </span>
                    <?php } ?>
                </span>
            </span>
            <span class="ab-desc"><?php
                // descrierea bonusului, langa nume si nivel
                $abDescKey = strtoupper($abInfo['key']) . '_DESC';
                $abDescKey = 'ALLYBONUS_' . $abDescKey;
                echo defined($abDescKey) ? constant($abDescKey) : '';
            ?></span>
        </div>

        <?php if ($abLevel >= AllianceBonus::MAX_LEVEL) { ?>
            <div class="ab-status"><?php echo defined('ALLYBONUS_MAXED') ? ALLYBONUS_MAXED : 'Fully unlocked'; ?></div>
        <?php } elseif ($abBusy) { ?>
            <div class="ab-bar"><i style="width:100%"></i></div>
            <div class="ab-status">
                <?php echo defined('ALLYBONUS_UNLOCKING') ? ALLYBONUS_UNLOCKING : 'Unlocking level'; ?>
                <?php echo $abNext; ?> &ndash;
                <?php echo $generator->getTimeFormat($abRow['upgrade_end'] - time()); ?>
            </div>
        <?php } else { ?>
            <div class="ab-bar"><i style="width:<?php echo (int) $abPct; ?>%"></i></div>
            <div class="ab-num">
                <?php echo number_format($abPool); ?> / <?php echo number_format($abCost); ?>
                &nbsp;(<?php echo defined('ALLYBONUS_NEXT') ? ALLYBONUS_NEXT : 'next'; ?>:
                +<?php echo (int) AllianceBonus::percentFor($abT, $abNext); ?>%)
            </div>

            <form class="ab-form" action="allianz.php?s=7" method="POST">
                <input type="hidden" name="ab_donate" value="1">
                <input type="hidden" name="ab_type" value="<?php echo $abT; ?>">
                <div class="ab-res">
                    <label><img class="r1" src="img/x.gif" alt="" title="<?php echo LUMBER; ?>" /><input class="ab-in" type="text" name="ab_wood" value="0" size="7"></label>
                    <label><img class="r2" src="img/x.gif" alt="" title="<?php echo CLAY; ?>" /><input class="ab-in" type="text" name="ab_clay" value="0" size="7"></label>
                    <label><img class="r3" src="img/x.gif" alt="" title="<?php echo IRON; ?>" /><input class="ab-in" type="text" name="ab_iron" value="0" size="7"></label>
                    <label><img class="r4" src="img/x.gif" alt="" title="<?php echo CROP; ?>" /><input class="ab-in" type="text" name="ab_crop" value="0" size="7"></label>
                </div>
                <label class="ab-triple">
                    <input type="checkbox" name="ab_triple" value="1">
                    <?php echo defined('ALLYBONUS_TRIPLE') ? ALLYBONUS_TRIPLE : 'Triple this donation'; ?>
                    <?php if (class_exists('VillageGold') && VillageGold::villageMode()) { ?>
                    (<?php echo TZ_GOLD_PRICE_ALLY_TRIPLE; ?> gold from this village)
                    <?php } else { ?>
                    (<?php echo defined('ALLIANCE_BONUS_TRIPLE_GOLD') ? (int) ALLIANCE_BONUS_TRIPLE_GOLD : 3; ?>
                    <?php echo defined('GOLD') ? GOLD : 'gold'; ?>)
                    <?php } ?>
                </label>
                <button type="submit" class="tz-btn"><?php echo defined('ALLYBONUS_DONATE') ? ALLYBONUS_DONATE : 'Donate'; ?></button>
            </form>
        <?php } ?>
    </div>
<?php } ?>
</div>

<div class="ab-note">
    <?php echo defined('ALLYBONUS_NEWMEMBER') ? ALLYBONUS_NEWMEMBER
        : 'New members gain access to higher levels gradually: level 2 after 24 hours in the alliance, level 3 after 48 hours, and so on.'; ?>
</div>

<div class="ab-note">
    <?php echo defined('ALLYBONUS_HINT') ? ALLYBONUS_HINT
        : 'The resource type does not matter, only the total amount. While a level is unlocking, that bonus cannot receive donations.'; ?>
</div>

<?php
    $abTop = $abEngine->contributions($abAid, 20);

    if ($abTop) {
?>
<h4><?php echo defined('ALLYBONUS_CONTRIBUTORS') ? ALLYBONUS_CONTRIBUTORS : 'Contributions'; ?></h4>
<table class="ab-tbl">
    <tr>
        <th><?php echo defined('ALLYBONUS_MEMBER') ? ALLYBONUS_MEMBER : 'Member'; ?></th>
        <th class="ab-r" style="width:140px;"><?php echo defined('ALLYBONUS_TOTAL') ? ALLYBONUS_TOTAL : 'Donated'; ?></th>
    </tr>
    <?php foreach ($abTop as $abC) { ?>
    <tr>
        <td><a href="spieler.php?uid=<?php echo (int) $abC['uid']; ?>"><?php echo htmlspecialchars($abC['username'], ENT_QUOTES, 'UTF-8'); ?></a></td>
        <td class="ab-r"><?php echo number_format($abC['total']); ?></td>
    </tr>
    <?php } ?>
</table>
<?php } ?>

</div>
