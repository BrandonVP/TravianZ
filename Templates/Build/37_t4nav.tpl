<?php

#################################################################################
##              -= YOU MAY NOT REMOVE OR CHANGE THIS NOTICE =-                 ##
## --------------------------------------------------------------------------- ##
##  Filename       : HERO T4 NAV BAR                                           ##
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


$t4HeroItems  = new HeroItems();
$t4Silver     = $t4HeroItems->getSilver($session->uid);
$t4Tabs = [
    'hero'       => ['label' => HERO_T4_TAB_HERO,       'url' => 'build.php?id=' . $id],
    // Oaze: pagina foloseste parametrul "land", nu "t4tab" (flux mai vechi).
    'land'       => ['label' => defined('HERO_T4_TAB_OASIS') ? HERO_T4_TAB_OASIS : 'Oasis',
                     'url'   => 'build.php?id=' . $id . '&land'],
    'items'      => ['label' => HERO_T4_TAB_ITEMS,      'url' => 'build.php?id=' . $id . '&t4tab=items'],
    // local redesign: consumables for village gold
    'shop'       => ['label' => 'Shop',                 'url' => 'build.php?id=' . $id . '&t4tab=shop'],
    'adventures' => ['label' => HERO_T4_TAB_ADVENTURES, 'url' => 'build.php?id=' . $id . '&t4tab=adventures'],
    'auction'    => ['label' => HERO_T4_TAB_AUCTION,    'url' => 'build.php?id=' . $id . '&t4tab=auction'],
];
?>
<link rel="stylesheet" href="css/hero_items.css" type="text/css">
<div class="heroT4Nav tz-hero-nav">
    <div class="tz-hero-tabs">
    <?php foreach ($t4Tabs as $key => $tab) { ?>
        <a href="<?php echo $tab['url']; ?>"<?php echo $key === $t4tab ? ' class="on"' : ''; ?>><?php echo $tab['label']; ?></a>
    <?php } ?>
    </div>
    <?php if (class_exists('VillageGold') && VillageGold::auctionUsesGold()) { $t4NavCap = VillageGold::capitalOf($database, $session->uid); ?>
    <span class="tz-hero-gold" title="Auction bids are paid from your capital">Capital gold <b><?php echo number_format($t4NavCap ? floor($t4NavCap['gold']) : 0); ?></b></span>
    <?php } else { ?>
    <span class="tz-hero-gold"><?php echo HERO_SILVER; ?> <b><?php echo number_format($t4Silver); ?></b></span>
    <?php } ?>
</div>
