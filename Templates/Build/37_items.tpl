<?php

#################################################################################
##              -= YOU MAY NOT REMOVE OR CHANGE THIS NOTICE =-                 ##
## --------------------------------------------------------------------------- ##
##  Filename       : HERO T4 ITEMS PAGE                                        ##
##  Type           : BUILDING TEMPLATE                                         ##
## --------------------------------------------------------------------------- ##
##  Created by     : Shadow                                                    ##
##  Designed by    : Shadow                                                    ##
## --------------------------------------------------------------------------- ##
##  Contact        : cata7007@gmail.com                                        ##
##  Project        : TravianZ                                                  ##
##  Test Server    : https://travianz.org                                      ##
##  GitHub         : https://github.com/Shadowss/TravianZ                      ##
## --------------------------------------------------------------------------- ##
##  License        : TravianZ Project                                          ##
##  Copyright      : TravianZ (c) 2010-2026. All rights reserved.              ##
## --------------------------------------------------------------------------- ##
#################################################################################

$t4Msg = '';

// Eroul poate schimba echipamentul doar cat timp e in sat (ca in Travian
// original). Motivul e calculat o singura data si folosit atat pentru mesaj,
// cat si pentru ascunderea butoanelor. Regula e impusa si in HeroItems, deci
// un POST trimis manual nu o poate ocoli.
$t4AwayReason = $t4HeroItems->heroAwayReason($session->uid);

$t4AwayText = '';
if ($t4AwayReason === 'nohero') {
    $t4AwayText = defined('HERO_LOCKED_NOHERO') ? HERO_LOCKED_NOHERO
        : 'You have no hero yet. Train one in the Hero\'s Mansion before equipping items.';
} elseif ($t4AwayReason === 'adventure') {
    $t4AwayText = defined('HERO_LOCKED_ADVENTURE') ? HERO_LOCKED_ADVENTURE
        : 'Your hero is on an adventure. Equipment can only be changed while the hero is in a village.';
} elseif ($t4AwayReason === 'attack') {
    $t4AwayText = defined('HERO_LOCKED_ATTACK') ? HERO_LOCKED_ATTACK
        : 'Your hero is on the move with the army. Equipment can only be changed while the hero is in a village.';
} elseif ($t4AwayReason === 'reinforcement') {
    $t4AwayText = defined('HERO_LOCKED_REINFORCEMENT') ? HERO_LOCKED_REINFORCEMENT
        : 'Your hero is reinforcing another village. Equipment can only be changed while the hero is in a village.';
}

if (isset($_POST['t4action'], $_POST['rowid'])) {
    $t4RowId = (int) $_POST['rowid'];

    switch ($_POST['t4action']) {
        case 'equip':
            $t4Msg = $t4HeroItems->equipItem($session->uid, $t4RowId)
                ? HERO_EQUIP_OK : HERO_EQUIP_FAIL;
            break;

        case 'unequip':
            $t4Msg = $t4HeroItems->unequipItem($session->uid, $t4RowId)
                ? HERO_UNEQUIP_OK : HERO_ITEM_USE_FAIL;
            break;

        case 'useitem':
            $t4Qty    = max(1, (int) ($_POST['qty'] ?? 1));
            $t4Result = $t4HeroItems->useItem($session->uid, $t4RowId, $t4Qty, $village->wid);
            if ($t4Result === HeroItems::USE_OK) {
                $t4Msg = HERO_ITEM_USED_OK;
            } elseif ($t4Result === HeroItems::USE_DEFERRED) {
                $t4Msg = HERO_ITEM_USE_BATTLE;
            } else {
                $t4Msg = HERO_ITEM_USE_FAIL;
            }
            break;

        case 'auction':
            // local redesign: list on the auction house without leaving the inventory
            $t4AucId = (new HeroAuction())->createAuction(
                $session->uid, $t4RowId, (int) ($_POST['qty'] ?? 1),
                (int) ($_POST['price'] ?? 0), (int) ($_POST['duration'] ?? 0)
            );
            $t4Msg = ($t4AucId > 0)
                ? 'Listed on the auction house. See it under <a href="build.php?id=' . (int) $id . '&amp;t4tab=auction">Auctions</a>.'
                : HERO_AUC_SELL_FAIL;
            break;

        case 'discard':
            // local redesign: throw away an unequipped item (or part of a stack)
            $t4Msg = 'That item could not be discarded.';
            foreach ($t4HeroItems->getInventory($session->uid) as $t4R) {
                if ((int) $t4R['id'] === $t4RowId && (int) $t4R['equipped'] === 0) {
                    $t4Qty = max(1, min((int) $t4R['quantity'], (int) ($_POST['qty'] ?? $t4R['quantity'])));
                    if ($t4HeroItems->removeItem($session->uid, $t4RowId, $t4Qty)) {
                        $t4Msg = 'Discarded ' . ($t4Qty > 1 ? $t4Qty . 'x ' : '') . $t4R['name'] . '.';
                    }
                    break;
                }
            }
            break;
    }
}

$t4Inventory = $t4HeroItems->getInventory($session->uid);
$t4Equipped  = $t4HeroItems->getEquipped($session->uid);
?>

<?php
// local redesign: suggested auction start price (gear by tier, consumables by shop price)
$t4ShopPrices = defined('TZ_HERO_SHOP') ? TZ_HERO_SHOP : array();
$t4Suggest = function ($row) use ($t4ShopPrices) {
    if ((int) $row['def']['slot'] === HSLOT_BAG) {
        $each = isset($t4ShopPrices[(int) $row['itemid']]) ? (int) ceil($t4ShopPrices[(int) $row['itemid']] * 0.6) : 5;
        return max(1, $each);
    }
    $byTier = array(1 => 30, 2 => 100, 3 => 300);
    return $byTier[(int) $row['def']['tier']] ?? 30;
};
?>
<div class="tz-hero">
<?php if ($t4AwayText !== '') { ?>
    <p class="tz-hero-flash warn"><?php echo $t4AwayText; ?></p>
<?php } ?>
<?php if ($t4Msg !== '') { ?>
    <p class="tz-hero-flash"><?php echo $t4Msg; ?></p>
<?php } ?>

<h3 class="tz-hero-h"><?php echo HERO_ITEMS_EQUIPPED; ?></h3>
<div class="tz-hero-grid">
<?php for ($t4Slot = 1; $t4Slot <= 6; $t4Slot++) {
    $t4Row = $t4Equipped[$t4Slot] ?? null; ?>
    <div class="tz-hero-card<?php echo $t4Row ? '' : ' tz-hero-empty'; ?>">
        <div class="tz-hero-slot"><?php echo constant('HERO_SLOT_' . $t4Slot); ?></div>
        <?php if ($t4Row) { $t4Bonus = heroItemBonusText((int) $t4Row['itemid']); ?>
        <div class="tz-hero-cardtop">
            <span class="heroT4Item item<?php echo (int) $t4Row['itemid']; ?>"></span>
            <div>
                <div class="tz-hero-iname"><?php echo $t4Row['name']; ?> <span class="tz-hero-tier t<?php echo (int) $t4Row['def']['tier']; ?>">T<?php echo (int) $t4Row['def']['tier']; ?></span></div>
                <?php if ($t4Bonus !== '') { ?><div class="tz-hero-ibonus"><?php echo htmlspecialchars($t4Bonus, ENT_QUOTES, 'UTF-8'); ?></div><?php } ?>
            </div>
        </div>
        <?php if ($t4AwayReason === '') { ?>
        <form action="" method="POST" class="tz-hero-actions">
            <input type="hidden" name="t4action" value="unequip">
            <input type="hidden" name="rowid" value="<?php echo (int) $t4Row['id']; ?>">
            <button type="submit" class="tz-btn tz-btn-sm"><?php echo HERO_UNEQUIP; ?></button>
        </form>
        <?php } ?>
        <?php } else { ?>
        <div class="tz-hero-none">Nothing equipped</div>
        <?php } ?>
    </div>
<?php } ?>
</div>

<h3 class="tz-hero-h"><?php echo HERO_ITEMS_BAG; ?></h3>
<div class="tz-hero-grid">
<?php
$t4HasUnequipped = false;
foreach ($t4Inventory as $t4Row) {
    if ($t4Row['equipped'] == 1 || $t4Row['orphan']) {
        continue;
    }
    $t4HasUnequipped = true;
    $t4IsBag = ((int) $t4Row['def']['slot'] === HSLOT_BAG);
    $t4Bonus = heroItemBonusText((int) $t4Row['itemid']);
    $t4Qty   = (int) $t4Row['quantity'];
    $t4Name  = htmlspecialchars(addslashes(strip_tags($t4Row['name'])), ENT_QUOTES, 'UTF-8');
?>
    <div class="tz-hero-card">
        <div class="tz-hero-slot"><?php echo constant('HERO_SLOT_' . (int) $t4Row['def']['slot']); ?></div>
        <div class="tz-hero-cardtop">
            <span class="heroT4Item item<?php echo (int) $t4Row['itemid']; ?>"></span>
            <div>
                <div class="tz-hero-iname"><?php echo $t4Row['name']; ?>
                    <?php if ($t4IsBag) { ?><span class="tz-hero-qty"><?php echo $t4Qty; ?>x</span>
                    <?php } else { ?><span class="tz-hero-tier t<?php echo (int) $t4Row['def']['tier']; ?>">T<?php echo (int) $t4Row['def']['tier']; ?></span><?php } ?>
                </div>
                <?php if ($t4Bonus !== '') { ?><div class="tz-hero-ibonus"><?php echo htmlspecialchars($t4Bonus, ENT_QUOTES, 'UTF-8'); ?></div><?php } ?>
            </div>
        </div>
        <div class="tz-hero-actions">
            <?php if ($t4IsBag) { ?>
            <form action="" method="POST" class="tz-hero-inline">
                <input type="hidden" name="rowid" value="<?php echo (int) $t4Row['id']; ?>">
                <input type="hidden" name="t4action" value="useitem">
                <input type="number" name="qty" value="1" min="1" max="<?php echo $t4Qty; ?>" class="tz-hero-num" title="How many to use">
                <button type="submit" class="tz-btn tz-btn-sm"><?php echo HERO_USE_ITEM; ?></button>
            </form>
            <?php } elseif ($t4AwayReason === '') { ?>
            <form action="" method="POST" class="tz-hero-inline">
                <input type="hidden" name="t4action" value="equip">
                <input type="hidden" name="rowid" value="<?php echo (int) $t4Row['id']; ?>">
                <button type="submit" class="tz-btn tz-btn-sm"><?php echo HERO_EQUIP; ?></button>
            </form>
            <?php } ?>
            <button type="button" class="tz-btn tz-btn-sm" onclick="var f=this.parentNode.parentNode.querySelector('.tz-hero-auc');f.style.display=f.style.display==='block'?'none':'block';">Auction</button>
            <form action="" method="POST" class="tz-hero-inline"
                  onsubmit="return confirm('Discard <?php echo $t4Name; ?>? This cannot be undone.');">
                <input type="hidden" name="rowid" value="<?php echo (int) $t4Row['id']; ?>">
                <input type="hidden" name="t4action" value="discard">
                <?php if ($t4IsBag && $t4Qty > 1) { ?><input type="hidden" name="qty" value="<?php echo $t4Qty; ?>"><?php } ?>
                <button type="submit" class="tz-btn tz-btn-sm tz-hero-danger">Discard</button>
            </form>
        </div>
        <form action="" method="POST" class="tz-hero-auc">
            <input type="hidden" name="t4action" value="auction">
            <input type="hidden" name="rowid" value="<?php echo (int) $t4Row['id']; ?>">
            <?php if ($t4IsBag) { ?>
            <label>Amount <input type="number" name="qty" value="<?php echo $t4Qty; ?>" min="1" max="<?php echo $t4Qty; ?>" class="tz-hero-num"></label>
            <?php } else { ?>
            <input type="hidden" name="qty" value="1">
            <?php } ?>
            <label>Start price <input type="number" name="price" value="<?php echo $t4Suggest($t4Row) * ($t4IsBag ? $t4Qty : 1); ?>" min="1" class="tz-hero-num tz-hero-numw"></label>
            <label>Runs <select name="duration"><option value="14400">4h</option><option value="28800" selected>8h</option><option value="86400">24h</option></select></label>
            <button type="submit" class="tz-btn tz-btn-sm">List item</button>
            <span class="tz-hero-hint">Sales pay out to your capital, minus a 10% fee.</span>
        </form>
    </div>
<?php } ?>
<?php if (!$t4HasUnequipped) { ?>
    <div class="tz-hero-card tz-hero-empty"><div class="tz-hero-none"><?php echo HERO_ITEMS_EMPTY; ?></div></div>
<?php } ?>
</div>
</div>
