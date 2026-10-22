<?php

#################################################################################
##                -= YOU MAY NOT REMOVE OR CHANGE THIS NOTICE =-               ##
## --------------------------------------------------------------------------- ##
##  Filename       : 4.tpl                                                     ##
##  Type           : Plus - Payment Confirmation                               ##
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
// local redesign: FAQ for village gold
$tzFaq = [
    ['Where does gold come from?',
     'Every village produces gold over time: a little by itself, more with Main Building and Marketplace levels, and some from the hero in its home village. '
     . 'Quests, inviting friends (' . number_format(TZ_GOLD_INVITE_REWARD) . ' gold each), gold codes and gold packages from the <a href="plus.php">gold shop</a> add more; those always go to your capital.'],
    ['Is gold per village?',
     'Yes. Each village has its own gold, shown in the gold card at the top. Merchants can carry gold between villages (one gold takes the room of ' . TZ_GOLD_MERCHANT_SPACE . ' resources), and trade routes can move it automatically.'],
    ['How much gold can a village hold?',
     'Up to 8,000 without a Treasury. A Treasury raises that limit to a tenth of what a Warehouse of the same level holds (80,000 at level 20). Gold above the limit stops growing.'],
    ['Can gold be stolen?',
     'Raiders can carry off gold that is not protected by a Treasury, and a Treasury takes only a quarter of catapult damage. Gold inside the Treasury is safe.'],
    ['Where do I buy Plus and the production bonuses?',
     'In your capital\'s Main Building, with the capital\'s gold. Each can be set to renew automatically when it runs out.'],
    ['What else can I spend gold on?',
     'Finish now, the Master Builder, resource contracts and express caravans in the Trade Office, trade routes, hero services, war games, festivities in the Residence, rented storage, '
     . 'and the gold part of the Treasury and of Warehouse/Granary levels 21-25. The <a href="plus.php?id=2">Advantages</a> page lists them all with prices.'],
    ['Why can\'t I finish some buildings?',
     'A Residence, Palace or World Wonder cannot be finished early, and jobs waiting in the queue (not yet started) cannot be finished either.'],
    ['Where can I see what I spent?',
     'In the <a href="a2b2.php">Account Statement</a>: every gold movement, with the village it happened in.'],
];
?>
<div class="tz-faq">
<?php foreach ($tzFaq as $tzQ): ?>
    <p class="tz-faq-q"><?php echo $tzQ[0]; ?></p>
    <p class="tz-faq-a"><?php echo $tzQ[1]; ?></p>
<?php endforeach; ?>
</div>
</div>
