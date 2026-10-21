<?php
/**
 * Hero services (local redesign): spend village gold in the Hero's Mansion.
 *   - finish a revive now (price by hero level)
 *   - heal to full health (price per missing health %)
 *   - new adventure offers (replace the current ones)
 * Prices: GameEngine/Data/gold.php (TZ_HERO_*). Paid by the village you are in.
 */
include_once __DIR__ . '/VillageGold.php';

class HeroServices
{
    /** Gold to finish a revive of a hero of this level. */
    public static function revivePrice($level)
    {
        return (int) TZ_HERO_REVIVE_GOLD_BASE + (int) $level * (int) TZ_HERO_REVIVE_GOLD_PER_LEVEL;
    }

    /** Gold to heal the hero from $health % to 100 %. */
    public static function healPrice($health)
    {
        return (int) ceil(max(0, 100 - (float) $health) * TZ_HERO_HEAL_GOLD_PER_HP);
    }

    /** Gold for a new set of adventure offers. */
    public static function rerollPrice()
    {
        return (int) TZ_HERO_REROLL_GOLD;
    }

    /** Valid request: gold is on here, the sitter may spend gold, the form token matches. */
    public static function allowed($village, $session, $token)
    {
        if (!VillageGold::pays($village)) return false;
        if (method_exists($session, 'sitterCan') && !$session->sitterCan(SITTER_PERM_GOLD)) return false;
        return hash_equals((string) $session->checker, (string) $token);
    }

    private static function hero($db, $uid)
    {
        $r = mysqli_query($db->dblink, "SELECT * FROM " . TB_PREFIX . "hero WHERE uid = " . (int) $uid . " ORDER BY heroid DESC LIMIT 1");
        return $r ? mysqli_fetch_assoc($r) : null;
    }

    private static function log($db, $village, $uid, $what, $gold)
    {
        $db->addGoldFinLog($village->wid, $uid, 'Hero service', -$gold, $what);
    }

    /** The revive running in this village finishes now (Automation completes it). */
    public static function finishRevive($db, $uid, $village)
    {
        $h = self::hero($db, $uid);
        if (!$h || (int) $h['inrevive'] !== 1 || (int) $h['trainingtime'] <= time() || (int) $h['wref'] !== (int) $village->wid) {
            return false;
        }
        $price = self::revivePrice($h['level']);
        if (!$db->takeVillageGold($village->wid, $price)) return false;
        mysqli_query($db->dblink, "UPDATE " . TB_PREFIX . "hero SET trainingtime = UNIX_TIMESTAMP() - 1 WHERE heroid = " . (int) $h['heroid'] . " AND inrevive = 1");
        self::log($db, $village, $uid, 'Finish hero revive', $price);
        return true;
    }

    /** Living hero back to 100 % health. */
    public static function heal($db, $uid, $village)
    {
        $h = self::hero($db, $uid);
        if (!$h || (int) $h['dead'] !== 0 || (float) $h['health'] >= 100) return false;
        $price = self::healPrice($h['health']);
        if ($price <= 0 || !$db->takeVillageGold($village->wid, $price)) return false;
        mysqli_query($db->dblink, "UPDATE " . TB_PREFIX . "hero SET health = 100 WHERE heroid = " . (int) $h['heroid'] . " AND dead = 0");
        self::log($db, $village, $uid, 'Heal hero', $price);
        return true;
    }

    /** Replace the available adventure offers with a new set. */
    public static function reroll($db, $uid, $village)
    {
        $h = self::hero($db, $uid);
        if (!$h || (int) $h['dead'] !== 0) return false;
        $price = self::rerollPrice();
        if (!$db->takeVillageGold($village->wid, $price)) return false;
        mysqli_query($db->dblink, "DELETE FROM " . TB_PREFIX . "hero_adventure WHERE uid = " . (int) $uid . " AND status = 0");
        $adv = new HeroAdventure();
        if ($adv->generateOffers($uid) <= 0) {
            // nothing new could be found: give the gold back
            $db->addVillageGold($village->wid, $price, VillageGold::capOf($village));
            return false;
        }
        self::log($db, $village, $uid, 'New hero adventures', $price);
        return true;
    }

    /** Small inline form button (POST, with the session token). */
    public static function button($action, $label, $price, $confirm)
    {
        global $session;
        $coin = '<svg class="tz-coin-sm" viewBox="0 0 24 24" aria-hidden="true"><circle cx="12" cy="12" r="10" fill="#e3b427" stroke="#9a7512" stroke-width="1.5"/><circle cx="12" cy="12" r="6.5" fill="none" stroke="#9a7512" stroke-width="1"/></svg>';
        return '<form method="post" action="" class="tz-hero-svc" onsubmit="return confirm(\'' . htmlspecialchars(addslashes($confirm), ENT_QUOTES) . '\');">'
             . '<input type="hidden" name="tzhero" value="' . htmlspecialchars($action) . '">'
             . '<input type="hidden" name="c" value="' . htmlspecialchars((string) $session->checker) . '">'
             . '<button type="submit" class="tz-btn tz-btn-sm">' . $label . ' &middot; ' . $coin . ' ' . number_format($price) . '</button>'
             . '</form>';
    }
}
