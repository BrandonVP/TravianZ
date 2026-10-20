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
if (!defined('TZ_GOLD_PRICE_NPC'))           define('TZ_GOLD_PRICE_NPC', 75);      // was 3
