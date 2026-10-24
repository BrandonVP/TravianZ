<?php

#################################################################################
##                -= YOU MAY NOT REMOVE OR CHANGE THIS NOTICE =-               ##
## --------------------------------------------------------------------------- ##
##  Filename       : 2.tpl                                                     ##
##  Type           : Plus - Gold Purchase Packages                             ##
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

include("Templates/Plus/pmenu.tpl");
include_once __DIR__ . '/../../GameEngine/Data/festivities.php';
$tzCoin = '<svg class="tz-coin-sm" viewBox="0 0 24 24" aria-hidden="true"><circle cx="12" cy="12" r="10" fill="#e3b427" stroke="#9a7512" stroke-width="1.5"/><circle cx="12" cy="12" r="6.5" fill="none" stroke="#9a7512" stroke-width="1"/></svg>';

$plusFeatures = [
    ['title'=>'Waiting loop for constructions', 'img'=>'p1', 'text'=>'The waiting loop enables you to give your builders another order to raise or extend a second building. After completing their first task and a short break (60s), they will start to take care of this second job.'],
    ['title'=>'Larger map', 'img'=>'xxl_map', 'text'=>'You can enlarge the map to get a better overview. Instead of 7x7 fields you can have a map of 13x13 fields. Other alliances which are allied or have a non-aggression pact (NAP) with you are shown in special colours.'],
    ['title'=>'Archive function for reports and messages', 'img'=>'p5', 'text'=>'Important reports and messages can be archived and thereby be looked up faster. Additionally, you can choose several messages or reports and archive or delete them at once.'],
    ['title'=>'Sorting function for reports and messages', 'img'=>'sort', 'text'=>'By clicking the table heading "Sent" you can reverse the sorting of reports and messages. If you get many messages a day and need to look up older ones you are able to do so very fast with this function. It can also be used in the archives.'],
    ['title'=>'Sorting function for the marketplace', 'img'=>'p6', 'text'=>'To use the marketplace more efficiently, you can filter the offers for certain resources only. Additionally you can use a ratio filter to only see 1:1 offers.'],
    ['title'=>'Auto-completion', 'img'=>'autovv', 'text'=>'By using the auto-completion you can easily "write" a whole village name by using very few figures. Depending on your preferences you can use this function in any combination for own villages, villages of alliance members or villages of your surroundings.'],
    ['title'=>'Report filter', 'img'=>'bfilter', 'text'=>'Thanks to the report filter unwanted reports concerning marketplace transactions are a problem of the past. Depending on your personal preferences you can easily switch off reports concerning trades from/to other villages or between your own villages.'],
    ['title'=>'Freely definable direct links', 'img'=>'p7', 'text'=>'Thanks to these links, you can reach every page you want with just one click. Just create a link to every destination you want and get directly to your alliance\'s overview, to your barracks or to the tempting 1:1 biddings at the marketplace.'],
    ['title'=>'Graphical statistics', 'img'=>'st1', 'text'=>'These statistics show you the chronological development of your account, e.g. the ranking, your army\'s strength or your population\'s development.'],
    ['title'=>'Empire', 'img'=>'dorf3', 'text'=>'The <b>Empire</b> page (in the top bar) shows your whole realm at once: every village with its resources, production, storage, gold and troops (including troops away), plus totals for the empire. It replaces the old village overview tabs.'],
    ['title'=>'Notepad', 'img'=>'p8', 'text'=>'Paper and pencil aren\'t always at hand. In order to make you don\'t forget important things or if you simply want to make a few notes, use your notebook.'],
];

$goldFeatures = [
    // local redesign: everything village gold buys today (prices from GameEngine/Data/*.php)
    ['title'=>'Plus and production bonuses', 'img'=>'p1_25', 'text'=>'Plus (' . TZ_GOLD_PRICE_PLUS . ' gold), +25% lumber, clay, iron or crop (' . TZ_GOLD_PRICE_PRODUCTION . ' gold each) and the Gold Club (' . TZ_GOLD_PRICE_GOLDCLUB . ' gold) are bought with your <b>capital</b>\'s gold, in its Main Building, where they can also renew automatically.'],
    ['title'=>'Finish now', 'img'=>'bau0', 'text'=>'Finish one running construction for ' . TZ_GOLD_PRICE_FINISH . ' gold, paid by the village it is in.'],
    ['title'=>'Master Builder', 'img'=>null, 'text'=>'Queue a construction beyond the normal queue for ' . TZ_GOLD_PRICE_MASTER . ' gold; it starts by itself when its lane has room.'],
    ['title'=>'Resource contracts', 'img'=>null, 'text'=>'In the Trade Office (level ' . TZ_CONTRACT_MIN_LEVEL . '+): buy resources from the NPC at ' . TZ_CONTRACT_RES_PER_GOLD . ' per gold, up to ' . TZ_CONTRACT_GOLD_PER_LEVEL . ' gold a day per Trade Office level.'],
    ['title'=>'Express caravans', 'img'=>null, 'text'=>'With a Trade Office: send resources to your own villages much faster for ' . TZ_EXPRESS_GOLD_PER_MERCHANT . ' gold per merchant.'],
    ['title'=>'NPC Merchant', 'img'=>'npc', 'text'=>'Exchange resources 1:1 for ' . TZ_GOLD_PRICE_NPC . ' gold. Deliberately expensive - contracts are the better deal.'],
    ['title'=>'Trade routes', 'img'=>null, 'text'=>'Automatic Marketplace shipments for ' . TZ_GOLD_PRICE_ROUTE . ' gold per route, with optional auto-renew and a "send when storage is full" trigger.'],
    ['title'=>'Hero services', 'img'=>null, 'text'=>'In the Hero\'s Mansion: finish a revive, heal your hero (' . TZ_HERO_HEAL_GOLD_PER_HP . ' gold per missing %) or find new quests (' . TZ_HERO_REROLL_GOLD . ' gold).'],
    ['title'=>'War games', 'img'=>null, 'text'=>'In the Tournament Square: an exercise that gives the next attack or raid from the village +5% to +15% attack.'],
    ['title'=>'Festivities', 'img'=>null, 'text'=>'In the Residence or Palace: Harvest Feast and Travelling Players for loyalty, Patron of the Arts and the Village Monument for culture points - each once a week.'],
    ['title'=>'Rented storage', 'img'=>null, 'text'=>'On the Warehouse and Granary pages: hire storage carts or grain lofts for +25% room for a day (wood for the carts, plus gold).'],
    ['title'=>'Treasury and big storage', 'img'=>null, 'text'=>'The Treasury and Warehouse/Granary levels 21-25 cost gold on top of their resources. The Treasury holds and protects village gold from raids.'],
    ['title'=>'Gold Club evasion', 'img'=>null, 'text'=>'With the Gold Club, troops evade attacks for ' . TZ_GOLD_PRICE_EVASION . ' gold per evasion, paid by the evading village.'],
];
?>
<table id="plus_features" class="features" cellpadding="1" cellspacing="1">
<thead><tr><th colspan="2"><?php echo TZ_FEATURES_OF_TRAVIAN; ?> <span class="plus_g">P</span><span class="plus_o">l</span><span class="plus_g">u</span><span class="plus_o">s</span></th></tr></thead>
<tbody>
<tr><td colspan="2" class="empty"></td></tr>
<?php foreach($plusFeatures as $f): ?>
<tr><th colspan="2"><?= $f['title'] ?></th></tr>
<tr>
    <td class="preview"><a href="plus.php?id=3"><img class="<?= $f['img'] ?>" src="img/x.gif" alt="<?= $f['title'] ?>" /></a></td>
    <td class="text"><?= $f['text'] ?></td>
</tr>
<tr><td colspan="2" class="empty"></td></tr>
<?php endforeach; ?>
</tbody></table>

<table id="gold_features" class="features" cellpadding="1" cellspacing="1">
<thead><tr><th colspan="2">What village gold buys</th></tr></thead>
<tbody>
<tr><td colspan="2" class="empty"></td></tr>
<?php foreach($goldFeatures as $f): ?>
<tr><th colspan="2"><?= $f['title'] ?></th></tr>
<tr>
    <td class="preview"><?php if ($f['img']): ?><a href="plus.php?id=3"><img class="<?= $f['img'] ?>" src="img/x.gif" alt="<?= $f['title'] ?>" /></a><?php else: ?><span class="tz-plus-coin"><?= $tzCoin ?></span><?php endif; ?></td>
    <td class="text"><?= $f['text'] ?></td>
</tr>
<tr><td colspan="2" class="empty"></td></tr>
<?php endforeach; ?>
</tbody></table>
</div>