<?php
#################################################################################
##  Local redesign: Hero's Mansion shop - consumables for village gold.        ##
##  Prices: GameEngine/Data/gold.php (TZ_HERO_SHOP). Paid by this village.     ##
#################################################################################

include_once __DIR__ . '/../../GameEngine/HeroServices.php';
global $heroItemCatalog;

$tzShop = HeroServices::shop();
$tzShopMsg = '';
$tzShopErr = false;
if (isset($_POST['tzshop'], $_POST['itemid'])) {
    if (!HeroServices::allowed($village, $session, $_POST['c'] ?? '')) {
        $tzShopMsg = 'Buying with gold is not possible here.';
        $tzShopErr = true;
    } else {
        $tzBought = HeroServices::buy($database, $session->uid, $village, (int) $_POST['itemid'], (int) ($_POST['qty'] ?? 1));
        if ($tzBought > 0) {
            $tzShopMsg = 'Bought ' . $tzBought . 'x ' . heroItemName((int) $_POST['itemid']) . '. It is in your inventory.';
        } else {
            $tzShopMsg = 'That did not work - not enough gold in this village, or an invalid amount (1-' . (int) TZ_HERO_SHOP_MAX . ').';
            $tzShopErr = true;
        }
    }
}
$tzVillGold = (int) floor((float) $database->getVillageField($village->wid, 'gold'));
$tzOwned = array();
foreach ($t4HeroItems->getInventory($session->uid) as $tzRow) {
    if ((int) $tzRow['def']['slot'] === HSLOT_BAG) $tzOwned[(int) $tzRow['itemid']] = (int) $tzRow['quantity'];
}
$tzCoin = '<svg class="tz-coin-sm" viewBox="0 0 24 24" aria-hidden="true"><circle cx="12" cy="12" r="10" fill="#e3b427" stroke="#9a7512" stroke-width="1.5"/><circle cx="12" cy="12" r="6.5" fill="none" stroke="#9a7512" stroke-width="1"/></svg>';
?>
<div class="tz-hero">
<?php if ($tzShopMsg !== '') { ?><p class="tz-hero-flash<?php echo $tzShopErr ? ' err' : ''; ?>"><?php echo htmlspecialchars($tzShopMsg); ?></p><?php } ?>
<p class="tz-hero-intro">Consumables for your hero, paid with this village's gold (<?php echo $tzCoin; ?> <b><?php echo number_format($tzVillGold); ?></b> here). Use them from the <a href="build.php?id=<?php echo $id; ?>&amp;t4tab=items">Inventory</a>.</p>
<?php if (!VillageGold::pays($village)) { ?>
    <p class="tz-hero-flash err">Gold is not active in this village yet.</p>
<?php } ?>
<div class="tz-hero-grid">
<?php foreach ($tzShop as $tzId => $tzPrice) { if (!isset($heroItemCatalog[$tzId])) continue; ?>
    <div class="tz-hero-card tz-shop-card">
        <div class="tz-hero-cardtop">
            <span class="heroT4Item item<?php echo (int) $tzId; ?>"></span>
            <div>
                <div class="tz-hero-iname"><?php echo heroItemName($tzId); ?></div>
                <div class="tz-hero-ibonus"><?php echo htmlspecialchars(heroItemBonusText($tzId)); ?></div>
                <?php if (!empty($tzOwned[$tzId])) { ?><div class="tz-hero-owned">You have <?php echo $tzOwned[$tzId]; ?></div><?php } ?>
            </div>
        </div>
        <form method="post" action="" class="tz-shop-form" onsubmit="var q=parseInt(this.qty.value,10)||0;return confirm('Buy '+q+'x <?php echo htmlspecialchars(addslashes(heroItemName($tzId)), ENT_QUOTES); ?> for '+(q*<?php echo (int) $tzPrice; ?>)+' gold?');">
            <input type="hidden" name="tzshop" value="1">
            <input type="hidden" name="itemid" value="<?php echo (int) $tzId; ?>">
            <input type="hidden" name="c" value="<?php echo htmlspecialchars((string) $session->checker); ?>">
            <span class="tz-shop-price"><?php echo $tzCoin; ?> <?php echo number_format($tzPrice); ?> <small>each</small></span>
            <input type="number" name="qty" value="1" min="1" max="<?php echo (int) TZ_HERO_SHOP_MAX; ?>" class="tz-hero-num">
            <button type="submit" class="tz-btn tz-btn-sm">Buy</button>
        </form>
    </div>
<?php } ?>
</div>
</div>
