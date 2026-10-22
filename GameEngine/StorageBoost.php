<?php
/**
 * Storage boost (local redesign): rent extra room for a day.
 *   Warehouse: "Hire storage carts"  - covered carts behind the warehouse hold the overflow
 *   Granary:   "Rent grain lofts"    - farmers' lofts around the village store extra grain
 * +TZ_BOOST_SHARE of the capacity for TZ_BOOST_DURATION; renewing adds another day.
 * Cost per level of the village's highest Warehouse / Granary: TZ_BOOST_WOOD_PER_LEVEL wood (the carts / lofts)
 * and TZ_BOOST_GOLD_PER_LEVEL gold (the hire). When it ends, what is above the normal capacity is lost.
 * Applied in Database::recalculateStorage() and Automation::updateStore(). Table tz_storage_boost.
 */
include_once __DIR__ . '/VillageGold.php';

if (!defined('TZ_BOOST_SHARE'))          define('TZ_BOOST_SHARE', 0.25);
if (!defined('TZ_BOOST_DURATION'))       define('TZ_BOOST_DURATION', 86400);
if (!defined('TZ_BOOST_WOOD_PER_LEVEL')) define('TZ_BOOST_WOOD_PER_LEVEL', 100);
if (!defined('TZ_BOOST_GOLD_PER_LEVEL')) define('TZ_BOOST_GOLD_PER_LEVEL', 10);

class StorageBoost
{
    private static $ready = false;

    public static function table($l)
    {
        $t = TB_PREFIX . 'tz_storage_boost';
        if (!self::$ready) {
            mysqli_query($l, "CREATE TABLE IF NOT EXISTS `$t` (`wid` INT NOT NULL, `kind` VARCHAR(8) NOT NULL,
                `until` INT NOT NULL DEFAULT 0, PRIMARY KEY (`wid`, `kind`)) ENGINE=InnoDB DEFAULT CHARSET=utf8");
            self::$ready = true;
        }
        return $t;
    }

    /** 'store' (Warehouse) or 'crop' (Granary) for a building type. */
    public static function kindOf($gid)
    {
        return ((int) $gid === 11 || (int) $gid === 39) ? 'crop' : 'store';
    }

    public static function name($kind)
    {
        return $kind === 'crop' ? 'Rent grain lofts' : 'Hire storage carts';
    }

    public static function story($kind)
    {
        return $kind === 'crop'
            ? 'Farmers around the village rent you their lofts for a day: room for extra grain.'
            : 'Covered carts are hired and parked behind the warehouse for a day: room for the overflow.';
    }

    /** End time of the village's boost (0 if none). */
    public static function until($db, $wid, $kind)
    {
        $t = self::table($db->dblink);
        $r = mysqli_query($db->dblink, "SELECT until FROM `$t` WHERE wid = " . (int) $wid . " AND kind = '" . ($kind === 'crop' ? 'crop' : 'store') . "'");
        $row = $r ? mysqli_fetch_row($r) : null;
        return $row ? (int) $row[0] : 0;
    }

    /** All running boosts: [wid => ['store' => factor, 'crop' => factor]] (for the periodic recount). */
    public static function activeMap($db)
    {
        $t = self::table($db->dblink);
        $out = [];
        $r = mysqli_query($db->dblink, "SELECT wid, kind FROM `$t` WHERE until > " . time());
        while ($r && ($row = mysqli_fetch_assoc($r))) $out[(int) $row['wid']][$row['kind']] = 1 + TZ_BOOST_SHARE;
        return $out;
    }

    /** Capacity factor for one village. */
    public static function factor($db, $wid, $kind)
    {
        return self::until($db, $wid, $kind) > time() ? 1 + TZ_BOOST_SHARE : 1;
    }

    public static function price($level)
    {
        $level = max(1, (int) $level);
        return ['wood' => $level * TZ_BOOST_WOOD_PER_LEVEL, 'gold' => $level * TZ_BOOST_GOLD_PER_LEVEL];
    }

    /** Hire / renew. $level: the village's highest Warehouse or Granary level. Returns '' or an error. */
    public static function start($db, $village, $uid, $kind, $level)
    {
        $kind = $kind === 'crop' ? 'crop' : 'store';
        if ((int) $level < 1) return 'Build it first.';
        if (!VillageGold::pays($village)) return 'This is paid partly with village gold, which is off.';
        $p = self::price($level);
        if ($p['wood'] > $village->awood) return 'Not enough wood for the ' . ($kind === 'crop' ? 'lofts' : 'carts') . '.';
        if (!$db->takeVillageGold($village->wid, $p['gold'])) return 'Not enough gold in this village.';
        $db->modifyResource($village->wid, $p['wood'], 0, 0, 0, 0);

        $t = self::table($db->dblink);
        $until = max(time(), self::until($db, $village->wid, $kind)) + TZ_BOOST_DURATION;
        mysqli_query($db->dblink, "REPLACE INTO `$t` (wid, kind, until) VALUES (" . (int) $village->wid . ", '$kind', $until)");
        $db->recalculateStorage($village->wid);
        $db->addGoldFinLog($village->wid, $uid, 'Storage boost', -$p['gold'], self::name($kind));
        return '';
    }
}
