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
            $db->addVillageGold($wref, $amount, TZ_GOLD_CAP);
        }
        return $amount;
    }
}
