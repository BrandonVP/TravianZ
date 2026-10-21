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
