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
// local redesign: village gold now comes from Gold Mines only (resource field,
// gid 51). Gold per hour per mine at 1x speed, by level (times SPEED in game).
// The older sources above (base, Main Building, Marketplace, hero) are no longer
// used by VillageGold::rate().
if (!defined('TZ_GOLDMINE_GOLD')) define('TZ_GOLDMINE_GOLD', [
    0, 1, 1.5, 2, 2.5, 3, 3.5, 4, 5, 5.5, 6,          // levels 0-10
    7, 7.5, 8, 9, 10, 11, 12, 13, 14, 15,              // levels 11-20
]);

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
if (!defined('TZ_GOLD_INVITE_REWARD')) define('TZ_GOLD_INVITE_REWARD', 1000); // was 50 (Plus gold)

// Trade routes (local redesign): a "when storage is full" route waits this long
// after sending before it can fire again; auto-renew pays this long before expiry
if (!defined('TZ_ROUTE_FULL_COOLDOWN')) define('TZ_ROUTE_FULL_COOLDOWN', 900);
if (!defined('TZ_ROUTE_RENEW_BEFORE'))  define('TZ_ROUTE_RENEW_BEFORE', 3600);

// Resource contracts (Marketplace tab): buy resources from the NPC with village
// gold. Daily allowance per village = Marketplace level x TZ_CONTRACT_GOLD_PER_LEVEL.
if (!defined('TZ_CONTRACT_RES_PER_GOLD'))   define('TZ_CONTRACT_RES_PER_GOLD', 40);
if (!defined('TZ_CONTRACT_GOLD_PER_LEVEL')) define('TZ_CONTRACT_GOLD_PER_LEVEL', 200); // 4,000 gold a day at Marketplace 20

// Trade Office: express caravans between your own villages (speed x2 at level 1
// up to x5 at level 20, paid per merchant). TZ_NPC_DISCOUNT_PER_LEVEL can make NPC
// trades cheaper per Trade Office level; 0 = off.
if (!defined('TZ_EXPRESS_SPEED_L1'))            define('TZ_EXPRESS_SPEED_L1', 2);
if (!defined('TZ_EXPRESS_SPEED_L20'))           define('TZ_EXPRESS_SPEED_L20', 5);
if (!defined('TZ_EXPRESS_GOLD_PER_MERCHANT'))   define('TZ_EXPRESS_GOLD_PER_MERCHANT', 5);
if (!defined('TZ_NPC_DISCOUNT_PER_LEVEL'))      define('TZ_NPC_DISCOUNT_PER_LEVEL', 0);   // NPC trade stays expensive (contracts are the alternative)

// Hero services (Hero's Mansion): finish a revive now, heal, new adventures
if (!defined('TZ_HERO_REVIVE_GOLD_BASE'))      define('TZ_HERO_REVIVE_GOLD_BASE', 100);
if (!defined('TZ_HERO_REVIVE_GOLD_PER_LEVEL')) define('TZ_HERO_REVIVE_GOLD_PER_LEVEL', 10);
if (!defined('TZ_HERO_HEAL_GOLD_PER_HP'))      define('TZ_HERO_HEAL_GOLD_PER_HP', 6);   // 600 gold from 0 % to 100 %
if (!defined('TZ_HERO_REROLL_GOLD'))           define('TZ_HERO_REROLL_GOLD', 50);
// Hero's Mansion shop: consumables for village gold (itemid => price per piece).
// Ointment replaces the old "Heal now" service (5 gold per 1 % health vs 6).
// Artwork stays an adventure-only find (ancient ruins).
if (!defined('TZ_HERO_SHOP')) define('TZ_HERO_SHOP', [
    200 => 5,    // Ointment: +1 % health
    201 => 15,   // Scroll: +10 XP
    206 => 10,   // Small Bandage: heals 25 % of the hero's army
    207 => 20,   // Bandage: heals 33 % of the hero's army
    208 => 15,   // Cage: traps 1 oasis animal
    203 => 15,   // Law Tablet: +1 % loyalty
    202 => 250,  // Bucket of Water: instant revive
    204 => 500,  // Book of Wisdom: reset attribute points
]);
if (!defined('TZ_HERO_SHOP_MAX')) define('TZ_HERO_SHOP_MAX', 100);   // pieces per purchase

// Building with gold: the Treasury also costs gold (on top of its resources),
// TZ_TREASURY_GOLD_PER_LEVEL x the level being built (level 20: 500)
if (!defined('TZ_TREASURY_GOLD_PER_LEVEL')) define('TZ_TREASURY_GOLD_PER_LEVEL', 25);

// War games (Tournament Square): a paid exercise; when it is over, the next attack
// or raid sent from the village within the window gets +L1..L20 % attack
if (!defined('TZ_WARGAMES_BONUS_L1'))        define('TZ_WARGAMES_BONUS_L1', 5);      // % at level 1
if (!defined('TZ_WARGAMES_BONUS_L20'))       define('TZ_WARGAMES_BONUS_L20', 15);    // % at level 20
if (!defined('TZ_WARGAMES_RES_PER_LEVEL'))   define('TZ_WARGAMES_RES_PER_LEVEL', 500); // wood/clay/iron each (crop half) x level
if (!defined('TZ_WARGAMES_GOLD_BASE'))       define('TZ_WARGAMES_GOLD_BASE', 50);
if (!defined('TZ_WARGAMES_GOLD_PER_LEVEL'))  define('TZ_WARGAMES_GOLD_PER_LEVEL', 10); // level 20: 250 gold
if (!defined('TZ_WARGAMES_DURATION'))        define('TZ_WARGAMES_DURATION', 7200);   // exercise length (divided by SPEED)
if (!defined('TZ_WARGAMES_WINDOW'))          define('TZ_WARGAMES_WINDOW', 8 * 3600); // send the attack within 8 h
if (!defined('TZ_WARGAMES_COOLDOWN'))        define('TZ_WARGAMES_COOLDOWN', 7 * 86400); // one exercise a week

// Resource contracts live in the Trade Office: unlocked at this level; the daily
// allowance is Trade Office level x TZ_CONTRACT_GOLD_PER_LEVEL (level 20: 4,000)
if (!defined('TZ_CONTRACT_MIN_LEVEL')) define('TZ_CONTRACT_MIN_LEVEL', 10);

// Gold Club evasion (Rally Point): paid by the village whose troops evade
if (!defined('TZ_GOLD_PRICE_EVASION')) define('TZ_GOLD_PRICE_EVASION', 50);

// Warehouse/Granary levels 21-25 also cost gold: base + per level above 20 (21: 100 ... 25: 300)
if (!defined('TZ_STORAGE_GOLD_BASE'))      define('TZ_STORAGE_GOLD_BASE', 50);
if (!defined('TZ_STORAGE_GOLD_PER_LEVEL')) define('TZ_STORAGE_GOLD_PER_LEVEL', 50);
