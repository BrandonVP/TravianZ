<?php

#################################################################################
##              -= YOU MAY NOT REMOVE OR CHANGE THIS NOTICE =-                 ##
## --------------------------------------------------------------------------- ##
##  Filename       : 3.tpl                                                     ##
##  Type           : Plus Functions - Purchase and Status Overview             ##
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

/**
 * TODO REZOLVAT: "Reduce this file by a lot, by using arrays".
 *
 * Cele patru bonusuri de productie erau scrise de mana, unul cate unul, aproape
 * identice - se schimbau doar coloana din baza, id-ul din link si eticheta.
 * Acum sunt un array parcurs intr-o bucla.
 *
 * Reparat pe parcurs:
 *   - uid-ul intra in SQL fara conversie ("WHERE id='$uid'");
 *   - "or die(mysqli_error())" arata jucatorului erori de baza de date;
 *   - blocul de lemn compara cu $datetime1 in loc de $tl_b1 (aceeasi valoare,
 *     dar inconsecvent - la o modificare viitoare devine bug);
 *   - expirarea abonamentului Plus se scria in baza IN TIMPUL randarii, adica
 *     un sablon facea modificari; a fost mutata inainte de afisare, ca sa fie
 *     clar ce se intampla.
 */

$plusUid = (int) $session->uid;

$plusRes = mysqli_query(
    $database->dblink,
    "SELECT gold, plus, b1, b2, b3, b4, goldclub FROM " . TB_PREFIX . "users WHERE id = " . $plusUid . " LIMIT 1"
);

$golds = $plusRes ? mysqli_fetch_assoc($plusRes) : null;

if (!$golds) {
    // Fara randul utilizatorului nu avem ce afisa. Nu aratam eroarea bazei de
    // date jucatorului; o lasam in log, unde ii e locul.
    error_log('[TravianZ] plus/3.tpl: nu am putut citi datele utilizatorului ' . $plusUid
        . ': ' . mysqli_error($database->dblink));

    $golds = array('gold' => 0, 'plus' => 0, 'b1' => 0, 'b2' => 0, 'b3' => 0, 'b4' => 0, 'goldclub' => 0);
}

include("Templates/Plus/pmenu.tpl");

// Village gold (local redesign, phase 3b): account features are bought with
// the CAPITAL's gold, at the capital; Finish now and the NPC merchant use the
// gold of the village you are in.
$tzVG = VillageGold::pays($village);
$tzAtCapital = !empty($village->capital) && (string) $village->capital !== '0';
$tzCapital = null;
if ($tzVG) {
    $tzCapRes = mysqli_query($database->dblink,
        "SELECT wref, name, gold FROM " . TB_PREFIX . "vdata WHERE owner = " . $plusUid . " AND capital = 1 LIMIT 1");
    $tzCapital = $tzCapRes ? mysqli_fetch_assoc($tzCapRes) : null;
    // at the capital its gold was just brought up to date
    $golds['gold'] = $tzAtCapital ? floor($village->agold) : ($tzCapital ? floor($tzCapital['gold']) : 0);
}
$tzPricePlus = $tzVG ? TZ_GOLD_PRICE_PLUS : 10;
$tzPriceProd = $tzVG ? TZ_GOLD_PRICE_PRODUCTION : 5;
$tzPriceClub = $tzVG ? TZ_GOLD_PRICE_GOLDCLUB : 100;
$tzPriceFinish = $tzVG ? TZ_GOLD_PRICE_FINISH : 2;
$tzPriceNpc = $tzVG ? VillageGold::npcPrice() : 3;
$tzHereGold = $tzVG ? floor($village->agold) : (int) $golds['gold'];
$tzCoin = $tzVG
    ? '<svg class="tz-coin-sm" viewBox="0 0 24 24" aria-label="Gold" role="img"><circle cx="12" cy="12" r="10" fill="#e3b427" stroke="#9a7512" stroke-width="1.5"/><circle cx="12" cy="12" r="6.5" fill="none" stroke="#9a7512" stroke-width="1"/></svg> '
    : '<img src="img/x.gif" class="gold" />';

$date2 = time();

/**
 * Abonamentul Plus expirat se marcheaza ACUM, inainte de afisare.
 * Inainte, actualizarea se facea la mijlocul randarii tabelului.
 */
if ((int) $golds['plus'] > 0 && (int) $golds['plus'] <= $date2) {
    mysqli_query($database->dblink,
        "UPDATE " . TB_PREFIX . "users SET plus = 0 WHERE id = " . $plusUid . " LIMIT 1");

    $golds['plus'] = 0;
    $plusJustExpired = true;
} else {
    $plusJustExpired = false;
}

if (!function_exists('formatRemainingTime')) {
    function formatRemainingTime($endTimestamp, $nowTimestamp)
    {
        $remaining = (int) $endTimestamp - (int) $nowTimestamp;

        if ($remaining <= 0) {
            return '';
        }

        $days = intdiv($remaining, 86400); $remaining %= 86400;
        $hours = intdiv($remaining, 3600);  $remaining %= 3600;
        $mins = intdiv($remaining, 60);
        $secs = $remaining % 60;

        return 'Remaining: <b>' . $days . '</b> ' . DAYS
             . ' <b>' . $hours . '</b> ' . HOURS
             . ' <b>' . $mins . '</b> ' . MINS
             . ' <b>' . $secs . '</b> secs (until ' . date('H:i:s', (int) $endTimestamp) . ')';
    }
}

/**
 * Butonul de actiune, identic pentru toate randurile.
 *
 * @param int  $gold    aurul jucatorului
 * @param int  $cost    cat costa
 * @param int  $until   pana cand e activ bonusul (0 = inactiv)
 * @param int  $linkId  id-ul din plus.php?id=...
 * @param bool $banned  contul e blocat
 */
if (!function_exists('plusActionCell')) {
    function plusActionCell($gold, $cost, $until, $linkId, $banned = false)
    {
        $guard = 'onclick="if(this.dataset.c) return false; this.dataset.c=1;'
               . ' this.style.pointerEvents=\'none\'; this.style.opacity=\'0.5\';"';

        if ($banned) {
            return '<a href="banned.php"><span class="none">' . TOO_LITTLE_GOLD . '</span></a>';
        }

        global $tzVG, $tzAtCapital, $tzCapital;
        if ($tzVG) {
            // bought (and auto-bought) in the capital's Main Building
            return $tzCapital
                ? '<a href="build.php?newdid=' . (int) $tzCapital['wref'] . '&amp;gid=15"><span>Main Building</span></a>'
                : '<span class="none">Capital only</span>';
        }

        if ((int) $gold < (int) $cost) {
            return '<a href="plus.php?s=1"><span class="none">' . TOO_LITTLE_GOLD . '</span></a>';
        }

        // activ inca -> prelungeste; altfel -> activeaza
        $label = ((int) $until > time()) ? EXTEND : ACTIVATE;

        return '<a href="plus.php?id=' . (int) $linkId . '" ' . $guard . '><span>' . $label . '</span></a>';
    }
}

/**
 * Cele patru bonusuri de productie. Asta e tot ce se schimba intre ele.
 */
$plusBonuses = array(
    array('css' => 'r1', 'label' => TZ_PRODUCTION_LUMBER, 'field' => 'b1', 'id' => 9,  'popup' => 1),
    array('css' => 'r2', 'label' => TZ_PRODUCTION_CLAY,   'field' => 'b2', 'id' => 10, 'popup' => 2),
    array('css' => 'r3', 'label' => TZ_PRODUCTION_IRON,   'field' => 'b3', 'id' => 11, 'popup' => 3),
    array('css' => 'r4', 'label' => TZ_PRODUCTION_CROP,   'field' => 'b4', 'id' => 12, 'popup' => 4),
);

$plusIsBanned  = (defined('BANNED') && $session->access == BANNED);
$plusDuration  = (PLUS_PRODUCTION >= 86400)
    ? (PLUS_PRODUCTION / 86400) . ' Days'
    : (PLUS_PRODUCTION / 3600) . ' Hours';

if ($tzVG) {
    echo '<p class="tz-plus-gold">' . $tzCoin . 'Plus features are bought with your <b>capital</b>\'s gold'
       . ($tzCapital ? ' (<b>' . htmlspecialchars($tzCapital['name']) . '</b> has <b>' . (int) $golds['gold'] . '</b> gold)' : '')
       . '. Finish now and the NPC merchant use the gold of the village you are in (<b>' . (int) $tzHereGold . '</b> here).'
       . ' Plus features are bought (and set to auto-buy) in your capital\'s <b>Main Building</b>.'
       . '</p>';
} elseif ((int) $golds['gold'] === 0) {
    echo "<p>You currently don't own gold.</p>";
} else {
    echo '<p>' . CURRENT_HAVE . ' <b>' . (int) $golds['gold'] . '</b> ' . GOLD . '</p>';
}
?>
<table class="plusFunctions" cellpadding="1" cellspacing="1">
    <thead>
        <tr><th colspan="5">Plus function</th></tr>
        <tr>
            <td></td>
            <td><?php echo DESCRIPTION; ?></td>
            <td><?php echo DURATION; ?></td>
            <td><?php echo GOLD; ?></td>
            <td><?php echo ACTION; ?></td>
        </tr>
    </thead>
    <tbody>

        <!-- CONT PLUS -->
        <tr>
            <td class="man"><a href="#" onClick="return Popup(0,6);"><img class="help" src="img/x.gif" alt="" /></a></td>
            <td class="desc">
                <b><font color="#71D000">P</font><font color="#FF6F0F">l</font><font color="#71D000">u</font><font color="#FF6F0F">s</font></b>
                <?php echo ACCOUNT; ?><br />
                <span class="run"><?php
                    if ($plusJustExpired) {
                        echo 'Your PLUS advantage has ended.<br>';
                    } elseif ((int) $golds['plus'] === 0) {
                        echo 'get PLUS<br>';
                    } else {
                        echo "<font color='#B3B3B3' size='1'>"
                           . formatRemainingTime($golds['plus'], $date2) . '</font>';
                    }
                ?></span>
            </td>
            <td class="dur"><?php
                echo (PLUS_TIME >= 86400) ? (PLUS_TIME / 86400) . ' Days' : (PLUS_TIME / 3600) . ' Hours';
            ?></td>
            <td class="cost"><?php echo $tzCoin . $tzPricePlus; ?></td>
            <td class="act"><?php
                echo plusActionCell($golds['gold'], $tzPricePlus, $golds['plus'], 8, false);
            ?></td>
        </tr>

        <tr><td colspan="5" class="empty"></td></tr>

        <?php foreach ($plusBonuses as $plusBonus) {
            $until = (int) $golds[$plusBonus['field']];
        ?>
        <tr>
            <td class="man"><a href="#" onClick="return Popup(<?php echo (int) $plusBonus['popup']; ?>,6);"><img class="help" src="img/x.gif" /></a></td>
            <td class="desc">
                +<b>25</b>% <img class="<?php echo $plusBonus['css']; ?>" src="img/x.gif" />
                <?php echo $plusBonus['label']; ?><br />
                <span class="run"><?php
                    if ($until >= $date2) {
                        echo "<font color='#B3B3B3' size='1'>"
                           . formatRemainingTime($until, $date2) . '</font>';
                    }
                ?></span>
            </td>
            <td class="dur"><?php echo $plusDuration; ?></td>
            <td class="cost"><?php echo $tzCoin . $tzPriceProd; ?></td>
            <td class="act"><span class="none"><?php
                echo plusActionCell($golds['gold'], $tzPriceProd, $until, $plusBonus['id'], $plusIsBanned);
            ?></span></td>
        </tr>
        <?php } ?>

        <!-- Finalizare instantanee a constructiilor -->
        <tr>
            <td class="man"><a href="#" onClick="return Popup(7,6);"><img class="help" src="img/x.gif" /></a></td>
            <td class="desc"><?php echo TZ_COMPLETE_CONSTRUCTION_ORDERS_AND_R; ?></td>
            <td class="dur"><?php echo NOW; ?></td>
            <td class="cost"><?php echo $tzCoin . $tzPriceFinish; ?></td>
            <td class="act"><span class="none"><?php
                if ($tzHereGold >= $tzPriceFinish) {
                    echo '<a href="plus.php?id=7" onclick="if(this.dataset.c) return false;'
                       . ' this.dataset.c=1; this.style.pointerEvents=\'none\';"><span>'
                       . GOLD_ON . '</span></a>';
                } else {
                    echo '<a href="plus.php?s=1"><span class="none">' . TOO_LITTLE_GOLD . '</span></a>';
                }
            ?></span></td>
        </tr>

        <!-- Negustorul NPC -->
        <tr>
            <td class="man"><a href="#" onClick="return Popup(8,6);"><img class="help" src="img/x.gif" /></a></td>
            <td class="desc"><?php echo TZ_N_1_1_TRADE_WITH_THE_NPC_MERCHANT; ?></td>
            <td class="dur"><?php echo NOW; ?></td>
            <td class="cost"><?php echo $tzCoin . $tzPriceNpc; ?></td>
            <td class="act"><span class="none"><?php
                if ($tzHereGold >= $tzPriceNpc) {
                    echo '<a href="build.php?gid=17&t=3"><span>' . NPC . '</span></a>';
                } else {
                    echo '<a href="plus.php?s=1"><span class="none">' . TOO_LITTLE_GOLD . '</span></a>';
                }
            ?></span></td>
        </tr>

    </tbody>
</table>

<?php
// Gold shop: promo-code redemption box (sits between Plus function and Gold Club).
if (class_exists('GoldShop')):
    $__promoMsg = isset($promoMsg) ? $promoMsg : '';
    $__promoOk  = isset($promoOk)  ? $promoOk  : false;
    $__action   = htmlspecialchars($_SERVER['REQUEST_URI'] ?? 'plus.php?id=1', ENT_QUOTES, 'UTF-8');
?>
<table class="plusFunctions" cellpadding="1" cellspacing="1">
    <thead><tr><th colspan="5">Redeem a gold code</th></tr></thead>
    <tbody>
        <tr>
            <td class="tz-redeem">
                <?php if ($__promoMsg !== ''): ?>
                    <div class="<?php echo $__promoOk ? 'tz-redeem-ok' : 'tz-redeem-err'; ?>"><?php echo htmlspecialchars($__promoMsg, ENT_QUOTES, 'UTF-8'); ?></div>
                <?php endif; ?>
                <form method="post" action="<?php echo $__action; ?>" class="tz-redeem-form">
                    <input type="text" name="redeem_code" maxlength="64" placeholder="Enter code" class="text" required>
                    <button type="submit" class="tz-btn tz-btn-sm">Redeem</button>
                </form>
                <p class="tz-redeem-note">Gold from codes is paid into your capital.</p>
            </td>
        </tr>
    </tbody>
</table>
<?php endif; ?>

<table class="plusFunctions" cellpadding="1" cellspacing="1">
    <thead>
        <tr><th colspan="5"><?php echo TZ_TRAVIAN_GOLD_CLUB; ?></th></tr>
        <tr>
            <td></td>
            <td><?php echo DESCRIPTION; ?></td>
            <td><?php echo DURATION; ?></td>
            <td><?php echo GOLD; ?></td>
            <td><?php echo ACTION; ?></td>
        </tr>
    </thead>
    <tbody>
        <tr>
            <td class="man"><a href="#" onClick="return Popup(9,6);"><img class="help" src="img/x.gif" /></a></td>
            <td class="desc"><b><?php echo GOLD_CLUB; ?></b></td>
            <td class="dur"><?php echo FOR_GAME_SERVER; ?></td>
            <td class="cost"><?php echo $tzCoin . $tzPriceClub; ?></td>
            <td class="act"><?php
                if ((int) $golds['goldclub'] === 0) {
                    echo plusActionCell($golds['gold'], $tzPriceClub, 0, 15, false);
                } else {
                    echo '<a href="plus.php?id=3"><span class="none">' . GOLD_ON . '</span></a>';
                }
            ?></td>
        </tr>
    </tbody>
</table>
</div>
