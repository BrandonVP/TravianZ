<?php
/**
 * War games (local redesign): the Tournament Square (gid 14) runs a paid
 * exercise. When it is over, the next attack or raid sent from that village
 * within TZ_WARGAMES_WINDOW seconds fights with +TZ_WARGAMES_BONUS_L1..L20 %
 * attack. One exercise per TZ_WARGAMES_COOLDOWN per village.
 * Settings: GameEngine/Data/gold.php (TZ_WARGAMES_*). Table tz_wargames.
 * The bonus is stored on the attack (attacks.tzwar, %) when it is sent and
 * applied in Battle::computeAttackerForces() through Battle::$tzWarBonus.
 */
include_once __DIR__ . '/VillageGold.php';

class WarGames
{
    private static $ready = false;

    private static function table($l)
    {
        $t = TB_PREFIX . 'tz_wargames';
        if (!self::$ready) {
            mysqli_query($l, "CREATE TABLE IF NOT EXISTS `$t` (`wid` INT NOT NULL PRIMARY KEY, `started` INT NOT NULL DEFAULT 0, `ready` INT NOT NULL DEFAULT 0, `until` INT NOT NULL DEFAULT 0, `bonus` INT NOT NULL DEFAULT 0, `used` TINYINT NOT NULL DEFAULT 0) ENGINE=InnoDB DEFAULT CHARSET=utf8");
            self::$ready = true;
        }
        return $t;
    }

    /** Attack bonus in % for a Tournament Square level (L1 5 % .. L20 15 %). */
    public static function bonusFor($level)
    {
        $level = max(1, min(20, (int) $level));
        return (int) round(TZ_WARGAMES_BONUS_L1 + ($level - 1) * (TZ_WARGAMES_BONUS_L20 - TZ_WARGAMES_BONUS_L1) / 19);
    }

    /** Price of an exercise: wood, clay, iron, crop, gold. */
    public static function cost($level)
    {
        $level = max(1, (int) $level);
        $r = (int) TZ_WARGAMES_RES_PER_LEVEL * $level;
        return ['wood' => $r, 'clay' => $r, 'iron' => $r, 'crop' => (int) ($r / 2),
                'gold' => (int) TZ_WARGAMES_GOLD_BASE + (int) TZ_WARGAMES_GOLD_PER_LEVEL * $level];
    }

    /** How long the exercise itself takes (server speed applies). */
    public static function duration()
    {
        $speed = defined('SPEED') ? max(1, (float) SPEED) : 1;
        return max(600, (int) round(TZ_WARGAMES_DURATION / $speed));
    }

    /** The village's record, or null. */
    public static function state($db, $wid)
    {
        $t = self::table($db->dblink);
        $r = mysqli_query($db->dblink, "SELECT * FROM `$t` WHERE wid = " . (int) $wid);
        return $r ? mysqli_fetch_assoc($r) : null;
    }

    /**
     * What the village's war games are doing now:
     * 'idle' (can start), 'training' (exercise running), 'ready' (bonus waiting
     * for an attack), 'cooldown' (used or expired, next one at $s['started'] + cooldown).
     */
    public static function phase($s)
    {
        $now = time();
        if (!$s || $now >= (int) $s['started'] + TZ_WARGAMES_COOLDOWN) return 'idle';
        if ((int) $s['used'] === 0 && $now < (int) $s['ready']) return 'training';
        if ((int) $s['used'] === 0 && $now < (int) $s['until']) return 'ready';
        return 'cooldown';
    }

    /** Start an exercise: pays resources + gold. Returns '' or an error message. */
    public static function start($db, $village, $uid, $level)
    {
        if ((int) $level < 1) return 'Build a Tournament Square first.';
        if (self::phase(self::state($db, $village->wid)) !== 'idle') return 'War games are not available yet.';

        $c = self::cost($level);
        if ($c['wood'] > $village->awood || $c['clay'] > $village->aclay || $c['iron'] > $village->airon || $c['crop'] > $village->acrop) {
            return 'Not enough resources in this village.';
        }
        if (!$db->takeVillageGold($village->wid, $c['gold'])) return 'Not enough gold in this village.';
        $db->modifyResource($village->wid, $c['wood'], $c['clay'], $c['iron'], $c['crop'], 0);

        $now = time();
        $ready = $now + self::duration();
        $t = self::table($db->dblink);
        mysqli_query($db->dblink, "REPLACE INTO `$t` (wid, started, ready, `until`, bonus, used) VALUES ("
            . (int) $village->wid . ", $now, $ready, " . ($ready + (int) TZ_WARGAMES_WINDOW) . ", " . self::bonusFor($level) . ", 0)");
        $db->addGoldFinLog($village->wid, $uid, 'War games', -$c['gold'], 'Tournament Square exercise (+' . self::bonusFor($level) . '% attack)');
        return '';
    }

    /**
     * An attack/raid leaves the village: if a finished exercise is waiting, it is
     * used up and its bonus (%) is written on the attack. Returns the bonus or 0.
     */
    public static function claim($db, $wid, $attackId)
    {
        $t = self::table($db->dblink);
        $now = time();
        $s = self::state($db, $wid);
        if (!$s) return 0;
        mysqli_query($db->dblink, "UPDATE `$t` SET used = 1 WHERE wid = " . (int) $wid . " AND used = 0 AND ready <= $now AND `until` > $now");
        if (mysqli_affected_rows($db->dblink) <= 0) return 0;
        $bonus = (int) $s['bonus'];
        mysqli_query($db->dblink, "UPDATE " . TB_PREFIX . "attacks SET tzwar = $bonus WHERE id = " . (int) $attackId);
        return $bonus;
    }
}
