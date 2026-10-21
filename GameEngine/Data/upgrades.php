<?php
/**
 * Blacksmith / Armoury upgrades (local redesign).
 *
 * Upgrades belong to the whole account (civilization): finishing one raises
 * that unit's level in every village of the owner, and new or conquered
 * villages take the owner's levels. Any village with a Blacksmith / Armoury
 * can upgrade (its own building level is the cap), so two villages can work
 * in parallel.
 */
if (!defined('TZ_AB_ACCOUNT_WIDE')) define('TZ_AB_ACCOUNT_WIDE', true);

// cost and time of every Blacksmith / Armoury upgrade (time on top of the
// building's own speed-up). Applies to upgrades started from now on.
if (!defined('TZ_AB_COST_MULT')) define('TZ_AB_COST_MULT', 2);
if (!defined('TZ_AB_TIME_MULT')) define('TZ_AB_TIME_MULT', 1.5);
