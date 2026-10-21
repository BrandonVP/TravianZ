<?php
/**
 * Village gold (local redesign, phase 1): production of the in-game gold
 * stored per village in vdata.gold. Settings: GameEngine/Data/gold.php.
 *
 * Used by Village::processProduction() (the village being viewed) and by
 * AutomationVillageUpkeep::updateRes() (a village brought up to date before
 * a battle), so gold accrues over exactly the same intervals as resources.
 *
 * Until the vdata.gold column exists every method is a no-op.
 */
include_once __DIR__ . '/Data/gold.php';

class VillageGold
{
    /** True when the feature is on and the village row has the gold column. */
    public static function active($villageRow)
    {
        return TZ_GOLD_ENABLED && is_array($villageRow) && array_key_exists('gold', $villageRow);
    }

    /** Village purchases are paid with this village's gold (else Plus gold). */
    public static function pays($village)
    {
        return defined('TZ_GOLD_PAYS_VILLAGE') && TZ_GOLD_PAYS_VILLAGE && is_object($village) && !empty($village->goldActive);
    }

    /** The village has at least $price whole gold. */
    public static function canAfford($village, $price)
    {
        return is_object($village) && floor(max(0, (float) $village->agold)) >= (int) $price;
    }

    /**
     * Account purchases are paid at the capital (local redesign, phase 3b).
     * null: village gold is off (use Plus gold); false: not at the capital or
     * not enough gold; else the price, already taken (guarded UPDATE).
     */
    public static function capitalPayStart($db, $village, $price)
    {
        if (!self::pays($village)) {
            return null;
        }
        if (empty($village->capital) || (string) $village->capital === '0') {
            return false;
        }
        if (!self::canAfford($village, $price)) {
            return false;
        }
        return $db->takeVillageGold($village->wid, $price) ? (int) $price : false;
    }

    /** Spending uses village gold (no village object needed, e.g. automation). */
    public static function villageMode()
    {
        return TZ_GOLD_ENABLED && defined('TZ_GOLD_PAYS_VILLAGE') && TZ_GOLD_PAYS_VILLAGE;
    }

    /** The auction house trades in capital gold instead of hero silver. */
    public static function auctionUsesGold()
    {
        return !TZ_SILVER_ENABLED && self::villageMode();
    }

    /** Take gold from a player's capital (guarded). */
    public static function takeFromCapital($db, $uid, $amount)
    {
        $cap = self::capitalOf($db, $uid);
        return $cap ? $db->takeVillageGold((int) $cap['wref'], (int) $amount) : false;
    }

    /**
     * Give gold to a player's capital (refunds, sales). Not cut to the cap:
     * gold already owed is never lost; above the cap the village just stops growing.
     */
    public static function giveToCapital($db, $uid, $amount)
    {
        $cap = self::capitalOf($db, $uid);
        if (!$cap || $amount <= 0) {
            return false;
        }
        mysqli_query($db->dblink, "UPDATE " . TB_PREFIX . "vdata SET gold = gold + " . (int) $amount . " WHERE wref = " . (int) $cap['wref']);
        return true;
    }

    /**
     * Automation safety net: Plus gold (users.gold) granted by any old code path
     * moves into the player's capital at TZ_GOLD_PLUS_RATE, never cut to the cap.
     * Players without a capital keep it until they have one.
     */
    public static function sweepPlusGold($db)
    {
        if (!self::villageMode()) {
            return;
        }
        $l = $db->dblink;
        $p = TB_PREFIX;
        $r = mysqli_query($l, "SELECT u.id, u.gold, v.wref FROM {$p}users u
            JOIN {$p}vdata v ON v.owner = u.id AND v.capital = 1
            WHERE u.gold > 0 AND u.id > 3");
        if (!$r) {
            return;
        }
        $now = time();
        while ($row = mysqli_fetch_assoc($r)) {
            $plus = (int) $row['gold'];
            // claim exactly what was read (a grant landing meanwhile is caught next run)
            mysqli_query($l, "UPDATE {$p}users SET gold = gold - $plus WHERE id = " . (int) $row['id'] . " AND gold >= $plus");
            if (mysqli_affected_rows($l) != 1) {
                continue;
            }
            $gold = $plus * (int) TZ_GOLD_PLUS_RATE;
            mysqli_query($l, "UPDATE {$p}vdata SET gold = gold + $gold WHERE wref = " . (int) $row['wref']);
            mysqli_query($l, "INSERT INTO {$p}gold_fin_log (uid, wid, action, gold, time, details)
                VALUES (" . (int) $row['id'] . ", " . (int) $row['wref'] . ", 'Plus gold to capital', $gold, $now, '$plus Plus gold x " . (int) TZ_GOLD_PLUS_RATE . "')");
            if (method_exists($db, 'clearUserCache')) {
                $db->clearUserCache((int) $row['id']);
            }
        }
    }

    /** Whole gold a village has right now in the database. */
    public static function goldOf($db, $wref)
    {
        $row = $db->getVillageFields($wref, 'gold', false);
        return (is_array($row) && isset($row['gold'])) ? (int) floor((float) $row['gold']) : 0;
    }

    /** NPC trade shortcut next to costs (village gold, else 3 Plus gold). */
    public static function npcCan($village, $session)
    {
        return self::pays($village)
            ? self::canAfford($village, TZ_GOLD_PRICE_NPC)
            : (int) $session->userinfo['gold'] >= 3;
    }

    /** Master Builder (village gold, else 1 Plus gold); paid when the job starts. */
    public static function masterCan($village, $session)
    {
        return self::pays($village)
            ? self::canAfford($village, TZ_GOLD_PRICE_MASTER)
            : $session->gold >= 1;
    }

    /** Can this village pay for a trade route (village gold, else 2 Plus gold)? */
    public static function routeCanPay($village, $session)
    {
        return self::pays($village)
            ? self::canAfford($village, TZ_GOLD_PRICE_ROUTE)
            : $session->gold >= 2;
    }

    /** Price tag: coin + village gold price, or the old Plus gold icon + price. */
    public static function priceTag($village, $villagePrice, $plusPrice)
    {
        if (self::pays($village)) {
            return '<svg class="tz-coin-sm" viewBox="0 0 24 24" aria-label="Gold" role="img"><circle cx="12" cy="12" r="10" fill="#e3b427" stroke="#9a7512" stroke-width="1.5"/><circle cx="12" cy="12" r="6.5" fill="none" stroke="#9a7512" stroke-width="1"/></svg> <b>' . (int) $villagePrice . '</b>';
        }
        return '<img src="img/x.gif" class="gold" alt="Gold" title="Gold" /><b>' . (int) $plusPrice . '</b>';
    }

    /** Give back a capital payment whose purchase could not be granted. */
    public static function capitalPayRefund($db, $village, $paid)
    {
        if ($paid > 0) {
            $db->addVillageGold($village->wid, $paid, self::capOf($village));
        }
    }

    /** Treasury (gid 27) level in a village (0 = none). */
    public static function treasuryLevel($resArray)
    {
        $level = 0;
        for ($i = 19; $i <= 40; $i++) {
            if (isset($resArray['f' . $i . 't']) && (int) $resArray['f' . $i . 't'] == 27) {
                $level = max($level, (int) $resArray['f' . $i]);
            }
        }
        return $level;
    }

    /** Gold a Treasury of this level holds and protects (share of a Warehouse). */
    public static function treasuryHolds($level)
    {
        static $warehouse = null;
        $level = min(20, max(0, (int) $level));
        if ($level == 0) {
            return 0;
        }
        if ($warehouse === null) {
            if (isset($GLOBALS['bid10'])) {
                $warehouse = $GLOBALS['bid10'];
            } else {
                include __DIR__ . '/Data/buidata.php';
                $warehouse = $bid10;
            }
        }
        $mult = defined('STORAGE_MULTIPLIER') ? (float) STORAGE_MULTIPLIER : 1;
        return (int) floor($warehouse[$level]['attri'] * $mult * TZ_GOLD_TREASURY_SHARE);
    }

    /** Most gold the village can hold: the Treasury, but never below TZ_GOLD_CAP. */
    public static function cap($resArray)
    {
        return max((int) TZ_GOLD_CAP, self::treasuryHolds(self::treasuryLevel($resArray)));
    }

    /** Cap of a village object (set by Village::processProduction), else the base cap. */
    public static function capOf($village)
    {
        return (is_object($village) && !empty($village->goldCap)) ? $village->goldCap : TZ_GOLD_CAP;
    }

    /** Cap of a village by id (reads its building levels). */
    public static function capFor($db, $wref)
    {
        return self::cap($db->getResourceLevel($wref));
    }

    /**
     * Gold raiders with $carry capacity can take from a village: what lies
     * outside the Treasury, limited to TZ_GOLD_RAID_SHARE of the capacity.
     */
    public static function raidable($db, $wref, $carry)
    {
        if (!TZ_GOLD_ENABLED || $carry <= 0) {
            return 0;
        }
        $row = $db->getVillageFields($wref, 'gold', false);
        if (!is_array($row) || !isset($row['gold'])) {
            return 0;
        }
        $outside = floor((float) $row['gold']) - self::treasuryHolds(self::treasuryLevel($db->getResourceLevel($wref, false)));
        $space = defined('TZ_GOLD_MERCHANT_SPACE') ? TZ_GOLD_MERCHANT_SPACE : 100;
        $byCarry = floor($carry * TZ_GOLD_RAID_SHARE / $space);
        return (int) max(0, min($outside, $byCarry));
    }

    /**
     * A player's capital for crediting gold: array('wref', 'name', 'gold', 'cap'),
     * or null when village gold is off or there is no capital.
     */
    public static function capitalOf($db, $uid)
    {
        if (!TZ_GOLD_ENABLED || !isset($db->dblink)) {
            return null;
        }
        $r = mysqli_query($db->dblink, "SELECT wref, name, gold FROM " . TB_PREFIX . "vdata WHERE owner = " . (int) $uid . " AND capital = 1 LIMIT 1");
        $row = $r ? mysqli_fetch_assoc($r) : null;
        if (!$row || !array_key_exists('gold', $row)) {
            return null;
        }
        $row['cap'] = self::capFor($db, (int) $row['wref']);
        return $row;
    }

    /**
     * The 7-day Plus features bought with capital gold (Main Building), keyed
     * by the auto-buy name: users column, plus.php id, price, duration, bit.
     */
    public static function plusFeatures()
    {
        $res = function ($css, $const, $name) {
            return '+25% <img class="' . $css . '" src="img/x.gif" alt="" /> ' . $name;
        };
        $prod = defined('PLUS_PRODUCTION') ? PLUS_PRODUCTION : 604800;
        return array(
            'plus' => array('field' => 'plus', 'id' => 8,  'price' => TZ_GOLD_PRICE_PLUS,       'duration' => defined('PLUS_TIME') ? PLUS_TIME : 604800, 'bit' => 1,
                            'label' => '<b><font color="#71D000">P</font><font color="#FF6F0F">l</font><font color="#71D000">u</font><font color="#FF6F0F">s</font></b> account', 'log' => 'Travian Plus'),
            'b1'   => array('field' => 'b1',   'id' => 9,  'price' => TZ_GOLD_PRICE_PRODUCTION, 'duration' => $prod, 'bit' => 2,  'label' => $res('r1', '', 'Lumber'), 'log' => '+25% Lumber'),
            'b2'   => array('field' => 'b2',   'id' => 10, 'price' => TZ_GOLD_PRICE_PRODUCTION, 'duration' => $prod, 'bit' => 4,  'label' => $res('r2', '', 'Clay'),     'log' => '+25% Clay'),
            'b3'   => array('field' => 'b3',   'id' => 11, 'price' => TZ_GOLD_PRICE_PRODUCTION, 'duration' => $prod, 'bit' => 8,  'label' => $res('r3', '', 'Iron'),     'log' => '+25% Iron'),
            'b4'   => array('field' => 'b4',   'id' => 12, 'price' => TZ_GOLD_PRICE_PRODUCTION, 'duration' => $prod, 'bit' => 16, 'label' => $res('r4', '', 'Crop'),     'log' => '+25% Crop'),
        );
    }

    /** Auto-buy switches live in their own small table (created on first use). */
    private static function autoTable($db)
    {
        static $done = false;
        if (!$done) {
            mysqli_query($db->dblink, "CREATE TABLE IF NOT EXISTS `" . TB_PREFIX . "tz_autobuy` (
                `uid` int(11) NOT NULL, `mask` int(11) NOT NULL DEFAULT 0, PRIMARY KEY (`uid`)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8");
            $done = true;
        }
        return TB_PREFIX . 'tz_autobuy';
    }

    /** Bitmask of the features a player auto-buys (see plusFeatures()). */
    public static function autoBuyMask($db, $uid)
    {
        $r = mysqli_query($db->dblink, "SELECT mask FROM " . self::autoTable($db) . " WHERE uid = " . (int) $uid);
        $row = $r ? mysqli_fetch_row($r) : null;
        return $row ? (int) $row[0] : 0;
    }

    /** Turn auto-buy for one feature on or off. */
    public static function setAutoBuy($db, $uid, $key, $on)
    {
        $features = self::plusFeatures();
        if (!isset($features[$key])) {
            return;
        }
        $bit = (int) $features[$key]['bit'];
        $t = self::autoTable($db);
        mysqli_query($db->dblink, $on
            ? "INSERT INTO $t (uid, mask) VALUES (" . (int) $uid . ", $bit) ON DUPLICATE KEY UPDATE mask = mask | $bit"
            : "UPDATE $t SET mask = mask & ~$bit WHERE uid = " . (int) $uid);
    }

    /**
     * Automation: renew auto-bought features that end within 5 minutes (or
     * have ended), paid from the capital. Not enough gold: tried again later.
     */
    public static function runAutoBuy($db)
    {
        if (!TZ_GOLD_ENABLED || !TZ_GOLD_PAYS_VILLAGE) {
            return;
        }
        $t = self::autoTable($db);
        $now = time();
        $soon = $now + 300;
        $features = self::plusFeatures();
        $r = mysqli_query($db->dblink, "SELECT a.uid, a.mask, u.plus, u.b1, u.b2, u.b3, u.b4, v.wref
            FROM $t a
            JOIN " . TB_PREFIX . "users u ON u.id = a.uid
            JOIN " . TB_PREFIX . "vdata v ON v.owner = a.uid AND v.capital = 1
            WHERE a.mask > 0" . (defined('BANNED') ? " AND u.access <> " . (int) BANNED : ""));
        if (!$r) {
            return;
        }
        while ($row = mysqli_fetch_assoc($r)) {
            $changed = false;
            foreach ($features as $f) {
                if (!((int) $row['mask'] & $f['bit']) || (int) $row[$f['field']] > $soon) {
                    continue;
                }
                $price = (int) $f['price'];
                if (!$db->takeVillageGold((int) $row['wref'], $price)) {
                    continue;
                }
                $field = $f['field'];
                mysqli_query($db->dblink, "UPDATE " . TB_PREFIX . "users SET `$field` = GREATEST(`$field`, $now) + " . (int) $f['duration'] . " WHERE id = " . (int) $row['uid']);
                mysqli_query($db->dblink, "INSERT INTO " . TB_PREFIX . "gold_fin_log (uid, wid, action, gold, time, details)
                    VALUES (" . (int) $row['uid'] . ", " . (int) $row['wref'] . ", 'Auto-buy " . $f['log'] . "', -$price, $now, 'Auto-buy with capital gold')");
                $changed = true;
            }
            if ($changed && method_exists($db, 'clearUserCache')) {
                $db->clearUserCache((int) $row['uid']);
            }
        }
    }

    /** Highest Main Building (gid 15) and Marketplace (gid 17) level in a village. */
    public static function buildingLevels($resArray)
    {
        $mb = 0;
        $market = 0;
        for ($i = 19; $i <= 40; $i++) {
            $type = isset($resArray['f' . $i . 't']) ? (int) $resArray['f' . $i . 't'] : 0;
            $level = isset($resArray['f' . $i]) ? (int) $resArray['f' . $i] : 0;
            if ($type == 15) $mb = max($mb, $level);
            if ($type == 17) $market = max($market, $level);
        }
        return array($mb, $market);
    }

    /**
     * Gold per hour for a village, with the breakdown:
     * array('base', 'mb', 'market', 'hero', 'total'), all already times SPEED.
     */
    public static function rate($db, $wref, $resArray)
    {
        list($mb, $market) = self::buildingLevels($resArray);

        $heroLevel = 0;
        if (method_exists($db, 'getHeroForVillage')) {
            $hero = $db->getHeroForVillage($wref);
            if (is_array($hero) && isset($hero['level'])) {
                $heroLevel = (int) $hero['level'];
            }
        }

        $speed = (float) SPEED;
        $out = array(
            'base'   => TZ_GOLD_BASE * $speed,
            'mb'     => $mb * TZ_GOLD_PER_MB * $speed,
            'market' => $market * TZ_GOLD_PER_MARKET * $speed,
            'hero'   => $heroLevel * TZ_GOLD_PER_HERO * $speed,
        );
        $out['total'] = $out['base'] + $out['mb'] + $out['market'] + $out['hero'];
        return $out;
    }

    /**
     * Add the gold produced over $seconds (clamped to the cap).
     * Returns the amount added, or 0 when inactive.
     */
    public static function accrue($db, $wref, $villageRow, $resArray, $seconds)
    {
        if (!self::active($villageRow) || $seconds <= 0) {
            return 0;
        }
        $rate = self::rate($db, $wref, $resArray);
        $amount = $rate['total'] / 3600 * $seconds;
        if ($amount > 0) {
            $db->addVillageGold($wref, $amount, self::cap($resArray));
        }
        return $amount;
    }
}
