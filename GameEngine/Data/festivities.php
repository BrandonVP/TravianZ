<?php
/**
 * Local redesign: Residence/Palace "Festivities" (GameEngine/Festivities.php).
 * Costs are wood, clay, iron, crop, gold. Durations are real time except the
 * Monument's carving time, which follows the server speed like a celebration.
 */

// one use of each festivity per village per week
if (!defined('TZ_FEST_COOLDOWN')) define('TZ_FEST_COOLDOWN', 7 * 86400);

// Harvest Feast: +loyalty now, double loyalty regeneration for a day
if (!defined('TZ_FEAST_COST'))      define('TZ_FEAST_COST', [0, 0, 0, 6000, 150]);
if (!defined('TZ_FEAST_LOYALTY'))   define('TZ_FEAST_LOYALTY', 20);
if (!defined('TZ_FEAST_DURATION'))  define('TZ_FEAST_DURATION', 86400);

// Travelling Players: loyalty cap raised (and topped up) for 3 days
if (!defined('TZ_PLAYERS_COST'))     define('TZ_PLAYERS_COST', [5000, 2000, 0, 0, 200]);
if (!defined('TZ_PLAYERS_CAP'))      define('TZ_PLAYERS_CAP', 115);
if (!defined('TZ_PLAYERS_DURATION')) define('TZ_PLAYERS_DURATION', 3 * 86400);

// Patron of the Arts: the village's culture point production +50% for a week
if (!defined('TZ_PATRON_COST'))     define('TZ_PATRON_COST', [0, 3000, 2000, 0, 300]);
if (!defined('TZ_PATRON_BONUS'))    define('TZ_PATRON_BONUS', 0.5);
if (!defined('TZ_PATRON_DURATION')) define('TZ_PATRON_DURATION', 7 * 86400);

// Village Monument: carved for 12 h / SPEED, then culture points per Main Building level
if (!defined('TZ_MONUMENT_COST'))     define('TZ_MONUMENT_COST', [4000, 4000, 4000, 0, 200]);
if (!defined('TZ_MONUMENT_CARVE'))    define('TZ_MONUMENT_CARVE', 12 * 3600);
if (!defined('TZ_MONUMENT_CP_PER_MB')) define('TZ_MONUMENT_CP_PER_MB', 40);
