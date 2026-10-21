<?php
/**
 * Village gold (local redesign, phase 1): an in-game currency produced per
 * village, stored in vdata.gold like a resource. Separate from the account
 * "Plus gold" (users.gold), which is phased out as purchases move over.
 *
 * Production per village per hour, multiplied by SPEED:
 *   base + Main Building level * per_mb + Marketplace level * per_market
 *        + hero level * per_hero   (hero's home village only)
 *
 * Every value can be overridden by defining the constant in config.php.
 */

if (!defined('TZ_GOLD_ENABLED'))    define('TZ_GOLD_ENABLED', true);
if (!defined('TZ_GOLD_BASE'))       define('TZ_GOLD_BASE', 1.0);
if (!defined('TZ_GOLD_PER_MB'))     define('TZ_GOLD_PER_MB', 0.5);
if (!defined('TZ_GOLD_PER_MARKET')) define('TZ_GOLD_PER_MARKET', 0.5);
if (!defined('TZ_GOLD_PER_HERO'))   define('TZ_GOLD_PER_HERO', 0.2);

// Storage: the starting capacity every resource has, until the Treasury exists.
if (!defined('TZ_GOLD_CAP'))        define('TZ_GOLD_CAP', STORAGE_BASE);

// Phase 2: merchants carry gold; one gold takes this much merchant capacity.
if (!defined('TZ_GOLD_MERCHANT_SPACE')) define('TZ_GOLD_MERCHANT_SPACE', 100);

// Phase 3: what village gold pays for. Village purchases are paid from the
// village where they happen; account purchases (later) from the capital.
if (!defined('TZ_GOLD_PAYS_VILLAGE'))        define('TZ_GOLD_PAYS_VILLAGE', true);
if (!defined('TZ_GOLD_PRICE_FINISH'))        define('TZ_GOLD_PRICE_FINISH', 50);   // was 2 Plus gold
if (!defined('TZ_GOLD_PRICE_FINISH_MASTER')) define('TZ_GOLD_PRICE_FINISH_MASTER', 75); // with Master Builder jobs, was 3
if (!defined('TZ_GOLD_PRICE_NPC'))           define('TZ_GOLD_PRICE_NPC', 250);

// Phase 3b: account purchases, paid with the CAPITAL's gold (buy at the capital)
if (!defined('TZ_GOLD_PRICE_PLUS'))       define('TZ_GOLD_PRICE_PLUS', 1500);       // Plus, was 10
if (!defined('TZ_GOLD_PRICE_PRODUCTION')) define('TZ_GOLD_PRICE_PRODUCTION', 1000); // +25% one resource, was 5
if (!defined('TZ_GOLD_PRICE_GOLDCLUB'))   define('TZ_GOLD_PRICE_GOLDCLUB', 5000);   // Gold Club, was 100
if (!defined('TZ_GOLD_PRICE_ROUTE'))      define('TZ_GOLD_PRICE_ROUTE', 50);        // create/extend a trade route (this village), was 2

// Treasury (gid 27) as the gold vault: holds and protects this share of what a
// Warehouse of the same level holds (level 20: 80,000 gold). The village keeps
// at least TZ_GOLD_CAP of room; only gold inside the Treasury is safe from raids.
if (!defined('TZ_GOLD_TREASURY_SHARE'))     define('TZ_GOLD_TREASURY_SHARE', 0.1);
// catapult damage against a Treasury is divided by this (one of the toughest buildings)
if (!defined('TZ_GOLD_TREASURY_TOUGHNESS')) define('TZ_GOLD_TREASURY_TOUGHNESS', 4);

// Raids: survivors of an attack/raid on a village carry off gold kept outside
// the Treasury. Each gold takes TZ_GOLD_MERCHANT_SPACE of carry capacity, and
// gold may fill at most this share of the raiders' capacity (rest = resources).
if (!defined('TZ_GOLD_RAID_SHARE')) define('TZ_GOLD_RAID_SHARE', 0.25);

// Former Plus gold features, at the conversion rate (x25), paid by the village
if (!defined('TZ_GOLD_PRICE_MASTER'))      define('TZ_GOLD_PRICE_MASTER', 25);       // Master Builder, per job, was 1
if (!defined('TZ_GOLD_PRICE_DEMOLISH'))    define('TZ_GOLD_PRICE_DEMOLISH', 250);    // instant complete demolition, was 10
if (!defined('TZ_GOLD_PRICE_ALLY_TRIPLE')) define('TZ_GOLD_PRICE_ALLY_TRIPLE', 75);  // triple an alliance donation, was 3

// Hero silver is switched off (kept in the code for later): adventures give no
// silver, the exchange office is hidden, and the auction house uses the
// capital's village gold (1 silver price = 1 gold).
if (!defined('TZ_SILVER_ENABLED')) define('TZ_SILVER_ENABLED', false);

// There is only one gold. users.gold is just a holding balance for a player
// without a capital yet (e.g. starting gold, granted before the first village
// exists); Automation moves it 1:1 into the capital (VillageGold::sweepPlusGold).
if (!defined('TZ_GOLD_PLUS_RATE')) define('TZ_GOLD_PLUS_RATE', 1);

// Rewards (old Plus amounts x25 so they keep their value)
if (!defined('TZ_GOLD_QUEST_SMALL'))   define('TZ_GOLD_QUEST_SMALL', 375);    // was 15
if (!defined('TZ_GOLD_QUEST_BIG'))     define('TZ_GOLD_QUEST_BIG', 500);      // was 20
if (!defined('TZ_GOLD_INVITE_REWARD')) define('TZ_GOLD_INVITE_REWARD', 1250); // was 50
