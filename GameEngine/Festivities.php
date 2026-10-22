<?php
/**
 * Festivities (local redesign): four village events in the Residence/Palace
 * (and the Huns' Command Center), each once a week per village.
 *
 *   feast     Harvest Feast        loyalty +20 now, loyalty regenerates twice as fast for a day
 *   players   Travelling Players   loyalty cap 115 for 3 days, topped up to it
 *   patron    Patron of the Arts   the village's culture point production +50% for a week
 *   monument  Village Monument     carved for 12 h / SPEED, then 40 culture points per Main Building level
 *
 * The loyalty ones cannot start while an enemy attack is on its way to the village.
 * Settings: GameEngine/Data/festivities.php. Table tz_festivities (one row per village and event).
 * Effects: Automation loyaltyRegeneration() (regenMultiplier/loyaltyCap), culturePoints() (patronBonus)
 * and Festivities::tick() for what happens over time.
 */
include_once __DIR__ . '/Data/festivities.php';
include_once __DIR__ . '/VillageGold.php';

class Festivities
{
    private static $ready = false;
    private static $cache = [];

    public static function table($l)
    {
        $t = TB_PREFIX . 'tz_festivities';
        if (!self::$ready) {
            mysqli_query($l, "CREATE TABLE IF NOT EXISTS `$t` (`wid` INT NOT NULL, `kind` VARCHAR(16) NOT NULL,
                `started` INT NOT NULL DEFAULT 0, `until` INT NOT NULL DEFAULT 0, `amount` INT NOT NULL DEFAULT 0,
                `done` TINYINT NOT NULL DEFAULT 0, PRIMARY KEY (`wid`, `kind`)) ENGINE=InnoDB DEFAULT CHARSET=utf8");
            self::$ready = true;
        }
        return $t;
    }

    /** Event definitions, in page order. */
    public static function defs()
    {
        return [
            'feast' => [
                'name' => 'Harvest Feast', 'cost' => TZ_FEAST_COST, 'kind' => 'loyalty',
                'story' => 'Long tables in the square, bread, roast and ale for everyone. The villagers drink to their leader.',
                'effect' => 'Loyalty +' . TZ_FEAST_LOYALTY . ' now, and loyalty regenerates twice as fast for 24 hours.',
                'use' => 'Recovery after a Senator or Chief attack, or for a newly conquered village.',
            ],
            'players' => [
                'name' => 'Travelling Players', 'cost' => TZ_PLAYERS_COST, 'kind' => 'loyalty',
                'story' => 'A troupe of players performs on a stage built in the square. The village is devoted to you while they stay.',
                'effect' => 'For 3 days the loyalty cap is ' . TZ_PLAYERS_CAP . ' instead of 100, and loyalty is topped up to it.',
                'use' => 'Preparation: an attacker needs an extra Senator or Chief hit to take the village.',
            ],
            'patron' => [
                'name' => 'Patron of the Arts', 'cost' => TZ_PATRON_COST, 'kind' => 'culture',
                'story' => 'A wealthy patron sponsors painters from your Academy. Their work draws visitors and learned people.',
                'effect' => 'This village produces ' . round(TZ_PATRON_BONUS * 100) . '% more culture points for 7 days.',
                'use' => 'Best in a village that already has many buildings.',
            ],
            'monument' => [
                'name' => 'Village Monument', 'cost' => TZ_MONUMENT_COST, 'kind' => 'culture',
                'story' => 'Master carvers raise a statue of the village\'s founder in the square.',
                'effect' => 'When it is unveiled: ' . TZ_MONUMENT_CP_PER_MB . ' culture points per Main Building level.',
                'use' => 'A one-off gift of culture points, bigger in villages with a high Main Building.',
            ],
        ];
    }

    /** Time the Monument takes to carve. */
    public static function carveTime()
    {
        $speed = defined('SPEED') ? max(1, (float) SPEED) : 1;
        return max(3600, (int) round(TZ_MONUMENT_CARVE / $speed));
    }

    /** Rows of a village, by kind. */
    public static function state($db, $wid)
    {
        $t = self::table($db->dblink);
        $out = [];
        $r = mysqli_query($db->dblink, "SELECT * FROM `$t` WHERE wid = " . (int) $wid);
        while ($r && ($row = mysqli_fetch_assoc($r))) $out[$row['kind']] = $row;
        return $out;
    }

    /** True while the event's effect lasts. */
    public static function active($db, $wid, $kind)
    {
        $key = (int) $wid . ':' . $kind;
        if (!array_key_exists($key, self::$cache)) {
            $t = self::table($db->dblink);
            $r = mysqli_query($db->dblink, "SELECT until FROM `$t` WHERE wid = " . (int) $wid . " AND kind = '" . $kind . "'");
            $row = $r ? mysqli_fetch_row($r) : null;
            self::$cache[$key] = $row ? (int) $row[0] : 0;
        }
        return self::$cache[$key] > time();
    }

    /** Loyalty regeneration factor (Harvest Feast doubles it). */
    public static function regenMultiplier($db, $wid)
    {
        return self::active($db, $wid, 'feast') ? 2 : 1;
    }

    /** Loyalty cap (Travelling Players raise it). */
    public static function loyaltyCap($db, $wid)
    {
        return self::active($db, $wid, 'players') ? TZ_PLAYERS_CAP : 100;
    }

    /** An enemy attack, raid or conquest is on its way to the village. */
    public static function underThreat($db, $wid, $uid)
    {
        $wid = (int) $wid;
        $uid = (int) $uid;
        $q = "SELECT COUNT(*) FROM " . TB_PREFIX . "movement m JOIN " . TB_PREFIX . "attacks a ON a.id = m.ref
              WHERE m.`to` = $wid AND m.sort_type = 3 AND m.proc = 0 AND a.attack_type IN (3, 4)
                AND m.`from` NOT IN (SELECT wref FROM " . TB_PREFIX . "vdata WHERE owner = $uid)";
        $r = mysqli_query($db->dblink, $q);
        return $r && (int) mysqli_fetch_row($r)[0] > 0;
    }

    /**
     * Why the event cannot start now ('' = it can). $levels: ['res' => Residence/Palace level,
     * 'academy' => Academy level, 'mb' => Main Building level].
     */
    public static function blocker($db, $village, $uid, $kind, $levels, $row = null)
    {
        $defs = self::defs();
        if (!isset($defs[$kind])) return 'Unknown festivity.';
        if (!VillageGold::pays($village)) return 'Festivities are paid partly with village gold, which is off.';
        if ($row && time() < (int) $row['started'] + TZ_FEST_COOLDOWN) {
            return 'Available again on ' . date('d.m.Y H:i', (int) $row['started'] + TZ_FEST_COOLDOWN) . '.';
        }
        if ($kind === 'monument' && $row && (int) $row['done'] === 0 && (int) $row['until'] > time()) {
            return 'The carvers are still at work.';
        }
        switch ($kind) {
            case 'feast':
            case 'players':
                if ($levels['res'] < 5) return 'Needs the Residence or Palace at level 5.';
                if (self::underThreat($db, $village->wid, $uid)) return 'Not while an enemy attack is on its way here.';
                break;
            case 'patron':
                if ($levels['res'] < 10) return 'Needs the Residence or Palace at level 10.';
                if ($levels['academy'] < 1) return 'Needs an Academy (the painters come from there).';
                break;
            case 'monument':
                if ($levels['mb'] < 10) return 'Needs the Main Building at level 10.';
                break;
        }
        $c = $defs[$kind]['cost'];
        if ($c[0] > $village->awood || $c[1] > $village->aclay || $c[2] > $village->airon || $c[3] > $village->acrop) {
            return 'Not enough resources in this village.';
        }
        if ($c[4] > floor((float) $village->agold)) return 'Not enough gold in this village.';
        return '';
    }

    /** Start an event: pays, records it and applies what happens at once. Returns '' or an error. */
    public static function start($db, $village, $uid, $kind, $levels)
    {
        $rows = self::state($db, $village->wid);
        $err = self::blocker($db, $village, $uid, $kind, $levels, $rows[$kind] ?? null);
        if ($err !== '') return $err;

        $defs = self::defs();
        $c = $defs[$kind]['cost'];
        if (!$db->takeVillageGold($village->wid, $c[4])) return 'Not enough gold in this village.';
        $db->modifyResource($village->wid, $c[0], $c[1], $c[2], $c[3], 0);

        $now = time();
        $wid = (int) $village->wid;
        $until = $now;
        $amount = 0;
        switch ($kind) {
            case 'feast':
                $until = $now + TZ_FEAST_DURATION;
                break;
            case 'players':
                $until = $now + TZ_PLAYERS_DURATION;
                break;
            case 'patron':
                $until = $now + TZ_PATRON_DURATION;
                break;
            case 'monument':
                $until = $now + self::carveTime();
                $amount = (int) $levels['mb'] * TZ_MONUMENT_CP_PER_MB;
                break;
        }
        $t = self::table($db->dblink);
        mysqli_query($db->dblink, "REPLACE INTO `$t` (wid, kind, started, `until`, amount, done)
            VALUES ($wid, '$kind', $now, $until, $amount, 0)");
        self::$cache = [];

        if ($kind === 'feast') {
            // never above the current cap (the Players may have raised it)
            $cap = self::loyaltyCap($db, $wid);
            mysqli_query($db->dblink, "UPDATE " . TB_PREFIX . "vdata SET loyalty = LEAST($cap, GREATEST(loyalty, LEAST(loyalty + " . (int) TZ_FEAST_LOYALTY . ", $cap))) WHERE wref = $wid");
        } elseif ($kind === 'players') {
            mysqli_query($db->dblink, "UPDATE " . TB_PREFIX . "vdata SET loyalty = " . (int) TZ_PLAYERS_CAP . ", lastupdate2 = $now WHERE wref = $wid");
        }
        $db->addGoldFinLog($wid, $uid, 'Festivity', -$c[4], $defs[$kind]['name']);
        return '';
    }

    /**
     * Patron of the Arts: extra culture points for the window updateVSumField() is about to count
     * (same formula and the same users.lastupdate window, so it must run just before it).
     */
    public static function patronBonus($db)
    {
        $t = self::table($db->dblink);
        $durDay = max(3600, 86400 / SPEED);
        $now = time();
        $q = "UPDATE " . TB_PREFIX . "users AS u
              JOIN (SELECT v.owner, SUM(v.cp) AS cp FROM " . TB_PREFIX . "vdata v
                    JOIN `$t` f ON f.wid = v.wref AND f.kind = 'patron' AND f.`until` > $now
                    WHERE v.natar = 0 GROUP BY v.owner) p ON p.owner = u.id
              SET u.cp = u.cp + p.cp * " . (float) TZ_PATRON_BONUS . " * (UNIX_TIMESTAMP() - u.lastupdate) / $durDay
              WHERE u.lastupdate < (UNIX_TIMESTAMP() - 600)";
        mysqli_query($db->dblink, $q);
    }

    /** Over time: unveil finished Monuments, keep the Players' extra loyalty topped up, end it afterwards. */
    public static function tick($db)
    {
        self::$cache = []; // effects may have started or ended since the last lookup
        $t = self::table($db->dblink);
        $now = time();
        $l = $db->dblink;

        // Monuments: culture points to the owner, once
        $r = mysqli_query($l, "SELECT f.wid, f.amount, v.owner FROM `$t` f JOIN " . TB_PREFIX . "vdata v ON v.wref = f.wid
                               WHERE f.kind = 'monument' AND f.done = 0 AND f.`until` <= $now");
        while ($r && ($row = mysqli_fetch_assoc($r))) {
            mysqli_query($l, "UPDATE `$t` SET done = 1 WHERE wid = " . (int) $row['wid'] . " AND kind = 'monument' AND done = 0");
            if (mysqli_affected_rows($l) > 0) {
                mysqli_query($l, "UPDATE " . TB_PREFIX . "users SET cp = cp + " . (int) $row['amount'] . " WHERE id = " . (int) $row['owner']);
            }
        }

        // Travelling Players: loyalty between 100 and the raised cap regenerates too
        // (the normal regeneration only looks at villages below 100)
        $r = mysqli_query($l, "SELECT v.wref, v.loyalty, v.lastupdate2 FROM `$t` f JOIN " . TB_PREFIX . "vdata v ON v.wref = f.wid
                               WHERE f.kind = 'players' AND f.`until` > $now AND v.loyalty >= 100 AND v.loyalty < " . (int) TZ_PLAYERS_CAP);
        while ($r && ($row = mysqli_fetch_assoc($r))) {
            $level = 0;
            foreach ([25, 26, 44] as $gid) {
                $lv = self::typeLevel($db, (int) $row['wref'], $gid);
                if ($lv > 0) { $level = $lv; break; }
            }
            if ($level <= 0) continue;
            $mult = self::regenMultiplier($db, (int) $row['wref']);
            $new = min(TZ_PLAYERS_CAP, (float) $row['loyalty'] + $level * $mult * ($now - (int) $row['lastupdate2']) / 3600);
            mysqli_query($l, "UPDATE " . TB_PREFIX . "vdata SET loyalty = $new, lastupdate2 = $now WHERE wref = " . (int) $row['wref']);
        }

        // the Players have left: loyalty back within the normal cap
        mysqli_query($l, "UPDATE " . TB_PREFIX . "vdata v JOIN `$t` f ON f.wid = v.wref AND f.kind = 'players'
                          SET v.loyalty = 100 WHERE f.`until` <= $now AND v.loyalty > 100");
    }

    private static function typeLevel($db, $wid, $gid)
    {
        $f = $db->getResourceLevel($wid);
        $best = 0;
        for ($i = 19; $i <= 40; $i++) {
            if ((int) ($f['f' . $i . 't'] ?? 0) === $gid) $best = max($best, (int) $f['f' . $i]);
        }
        return $best;
    }
}
