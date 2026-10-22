<?php

#################################################################################
##              -= YOU MAY NOT REMOVE OR CHANGE THIS NOTICE =-                 ##
## --------------------------------------------------------------------------- ##
##  Filename       : HeroAdventure.php                                         ##
##  Type           : T4 Hero port - adventures backend (Phase 3)               ##
## --------------------------------------------------------------------------- ##
##  Developed by   : Shadow 		                                           ##
##  Project        : TravianZ                                                  ##
##  GitHub         : https://github.com/Shadowss/TravianZ                      ##
## --------------------------------------------------------------------------- ##
##  License        : TravianZ Project                                          ##
##  Copyright      : TravianZ (c) 2010-2026. All rights reserved.              ##
## --------------------------------------------------------------------------- ##
#################################################################################
##                                                                             ##
##  Adventure lifecycle:                                                       ##
##    offer (status 0) -> running (status 1, movement sort_type 20)            ##
##    -> arrival processed by Automation (rewards + ntype 26 report,           ##
##       status 2, return movement sort_type 21 carrying resources)            ##
##    -> return processed by Automation (hero back in units.hero,              ##
##       resources credited)                                                   ##
##                                                                             ##
##  Death: if HP loss would drop health to 0, the hero dies AT the site        ##
##  (dead=1, health=0, loot forfeited, no return movement). units.hero was     ##
##  already decremented at send - identical end state to dying in battle,      ##
##  so the existing revive flow (37_revive.tpl + handleReviveCompletion)       ##
##  works unchanged.                                                           ##
##                                                                             ##
##  XP: only `experience` is incremented (with the helmet HB_XP% bonus).       ##
##  Level-up/points are intentionally NOT touched here - Automation's          ##
##  updateHero()/calculateLevelUp() already handles that every tick.           ##
##                                                                             ##
#################################################################################

class HeroAdventure
{
    /** Hero base speed on foot, fields/hour (T4 convention). */
    const BASE_HERO_SPEED = 7;

    /** Guaranteed item on the player's first adventure: tier-1 Riding Horse. */
    const FIRST_ADVENTURE_ITEM = 70;

    /** How far from the hero's village adventure sites are picked (tiles). */
    const SITE_MIN_RADIUS = 3;
    const SITE_MAX_RADIUS = 25;

    /** Max users to top-up with fresh offers per automation tick (bounded work). */
    const BATCH_LIMIT = 50;

    /** startAdventure() result codes */
    const START_OK            = 1;
    const START_INVALID       = 0;  // offer missing/expired/not yours/already running
    const START_NO_HERO       = -1; // no living hero
    const START_HERO_AWAY     = -2; // hero not at home village

    /** @var mysqli */
    private $db;

    public function __construct()
    {
        global $database;
        $this->db = $database->dblink;

        global $heroItemCatalog, $heroAdventureConfig;
        if (!isset($heroAdventureConfig)) {
            include_once __DIR__ . '/Data/hero_items.php';
        }
    }

    /* =========================================================================
     *  OFFERS
     * ===================================================================== */

    /** Non-expired, still-available offers for a user. */
    public function getOffers($uid)
    {
        $uid = (int) $uid; $now = time();
        $stmt = $this->db->prepare(
            "SELECT id, uid, wref, difficulty, type, restype, duration, created, expire, status, moveid
               FROM " . TB_PREFIX . "hero_adventure
              WHERE uid = ? AND status = 0 AND expire > ?
              ORDER BY difficulty ASC, duration ASC"
        );
        $stmt->bind_param('ii', $uid, $now);
        $stmt->execute();
        $res = $stmt->get_result();
        $out = array();
        while ($row = $res->fetch_assoc()) {
            $out[] = $row;
        }
        $stmt->close();
        return $out;
    }

    /** The adventure the hero is currently running, or null. */
    public function getRunning($uid)
    {
        $uid = (int) $uid;
        $stmt = $this->db->prepare(
            "SELECT a.id, a.wref, a.difficulty, a.moveid, m.endtime, m.sort_type
               FROM " . TB_PREFIX . "hero_adventure a
               JOIN " . TB_PREFIX . "movement m ON m.moveid = a.moveid
              WHERE a.uid = ? AND a.status = 1 AND m.proc = 0 LIMIT 1"
        );
        $stmt->bind_param('i', $uid);
        $stmt->execute();
        $res = $stmt->get_result();
        $row = $res->fetch_assoc();
        $stmt->close();
        return $row ?: null;
    }

    /**
     * Top up a single user's offer list (expires stale ones first).
     * Respects max_offers and refresh_interval from $heroAdventureConfig.
     * Returns the number of offers created.
     */
    public function generateOffers($uid)
    {
        global $database, $heroAdventureConfig;
        $uid = (int) $uid; $now = time();

        // Living hero needed - offers are anchored to the hero's village.
        $hero = $this->getLivingHero($uid);
        if (!$hero) {
            return 0;
        }

        // Expire stale offers (kept as rows with status untouched would clutter
        // the uid_status index; a hard delete of expired *available* offers is safe).
        $stmt = $this->db->prepare(
            "DELETE FROM " . TB_PREFIX . "hero_adventure WHERE uid = ? AND status = 0 AND expire <= ?"
        );
        $stmt->bind_param('ii', $uid, $now);
        $stmt->execute();
        $stmt->close();

        // Respect refresh interval: don't regenerate too often.
        $stmt = $this->db->prepare(
            "SELECT COUNT(*) AS cnt, COALESCE(MAX(created), 0) AS latest
               FROM " . TB_PREFIX . "hero_adventure WHERE uid = ? AND status = 0"
        );
        $stmt->bind_param('i', $uid);
        $stmt->execute();
        $res  = $stmt->get_result();
        $info = $res->fetch_assoc();
        $stmt->close();

        $have   = (int) $info['cnt'];
        $latest = (int) $info['latest'];
        $max    = (int) $heroAdventureConfig['max_offers'];

        if ($have >= $max) {
            return 0;
        }
        if ($latest > 0 && ($now - $latest) < (int) $heroAdventureConfig['refresh_interval']) {
            return 0;
        }

        // Pick random unoccupied tiles around the hero's village.
        $coor = $database->getCoor($hero['wref']);
        if (!$coor) {
            return 0;
        }
        $x = (int) $coor['x']; $y = (int) $coor['y']; $r = self::SITE_MAX_RADIUS;

        $need = $max - $have;
        // Min radius enforced in SQL so LIMIT never undercounts (the bounding
        // box doesn't wrap around the map seam, so plain coordinate distance
        // is exact within it).
        $stmt = $this->db->prepare(
            "SELECT id, x, y, fieldtype, oasistype FROM " . TB_PREFIX . "wdata
              WHERE occupied = 0 AND id <> ?
                AND x BETWEEN ? AND ? AND y BETWEEN ? AND ?
                AND (POW(x - ?, 2) + POW(y - ?, 2)) >= ?
              ORDER BY RAND() LIMIT ?"
        );
        $wref = (int) $hero['wref'];
        $x1 = $x - $r; $x2 = $x + $r; $y1 = $y - $r; $y2 = $y + $r;
        $minSq = self::SITE_MIN_RADIUS * self::SITE_MIN_RADIUS;
        $stmt->bind_param('iiiiiiiii', $wref, $x1, $x2, $y1, $y2, $x, $y, $minSq, $need);
        $stmt->execute();
        $res   = $stmt->get_result();
        $tiles = array();
        while ($row = $res->fetch_assoc()) {
            $tiles[] = $row;
        }
        $stmt->close();

        $created = 0;
        foreach ($tiles as $tile) {
            $dist = $database->getDistance($x, $y, $tile['x'], $tile['y']);
            // Hard adventures ~30% of offers.
            $difficulty = (mt_rand(1, 100) <= 30) ? 1 : 0;
            $duration   = $this->travelSeconds($uid, $dist);
            $expire     = $now + (int) $heroAdventureConfig['offer_lifetime'];
            // local redesign: what kind of site it is (terrain-weighted)
            list($type, $restype) = $this->pickType($tile);

            $stmt = $this->db->prepare(
                "INSERT INTO " . TB_PREFIX . "hero_adventure
                        (uid, wref, difficulty, type, restype, duration, created, expire, status, moveid)
                 VALUES (?, ?, ?, ?, ?, ?, ?, ?, 0, 0)"
            );
            $tileId = (int) $tile['id'];
            $stmt->bind_param('iiiiiiii', $uid, $tileId, $difficulty, $type, $restype, $duration, $now, $expire);
            $stmt->execute();
            $stmt->close();
            $created++;
        }
        return $created;
    }

    /**
     * Batch top-up used by Automation: refresh offers for users with living,
     * at-home heroes that are below max_offers. Work bounded by BATCH_LIMIT.
     */
    public function generateOffersBatch()
    {
        global $heroAdventureConfig;
        $now = time();
        $threshold = $now - (int) $heroAdventureConfig['refresh_interval'];
        $max = (int) $heroAdventureConfig['max_offers'];
        $limit = self::BATCH_LIMIT;

        // Users with a living hero whose available-offer count is below max
        // and whose newest offer (if any) is older than the refresh interval.
        $stmt = $this->db->prepare(
            "SELECT h.uid
               FROM " . TB_PREFIX . "hero h
          LEFT JOIN " . TB_PREFIX . "hero_adventure a
                 ON a.uid = h.uid AND a.status = 0 AND a.expire > ?
              WHERE h.dead = 0
           GROUP BY h.uid
             HAVING COUNT(a.id) < ? AND COALESCE(MAX(a.created), 0) < ?
              LIMIT ?"
        );
        $stmt->bind_param('iiii', $now, $max, $threshold, $limit);
        $stmt->execute();
        $res  = $stmt->get_result();
        $uids = array();
        while ($row = $res->fetch_assoc()) {
            $uids[] = (int) $row['uid'];
        }
        $stmt->close();

        foreach ($uids as $uid) {
            $this->generateOffers($uid);
        }
        return count($uids);
    }

    /* =========================================================================
     *  START
     * ===================================================================== */

    /**
     * Send the hero on an available adventure offer.
     * Returns one of the START_* class constants.
     */
    public function startAdventure($uid, $adventureId)
    {
        $uid = (int) $uid; $adventureId = (int) $adventureId; $now = time();

        $hero = $this->getLivingHero($uid);
        if (!$hero) {
            return self::START_NO_HERO;
        }
        // Only one adventure at a time.
        if ($this->getRunning($uid)) {
            return self::START_INVALID;
        }

        // Load the offer (must be this user's, available, not expired).
        $stmt = $this->db->prepare(
            "SELECT id, wref, difficulty, duration FROM " . TB_PREFIX . "hero_adventure
              WHERE id = ? AND uid = ? AND status = 0 AND expire > ? LIMIT 1"
        );
        $stmt->bind_param('iii', $adventureId, $uid, $now);
        $stmt->execute();
        $res   = $stmt->get_result();
        $offer = $res->fetch_assoc();
        $stmt->close();
        if (!$offer) {
            return self::START_INVALID;
        }

        // Hero must be AT HOME: race-safe conditional decrement of units.hero.
        $homeWref = (int) $hero['wref'];
        $stmt = $this->db->prepare(
            "UPDATE " . TB_PREFIX . "units SET hero = hero - 1 WHERE vref = ? AND hero >= 1 LIMIT 1"
        );
        $stmt->bind_param('i', $homeWref);
        $stmt->execute();
        $atHome = $stmt->affected_rows > 0;
        $stmt->close();
        if (!$atHome) {
            return self::START_HERO_AWAY;
        }

        // Claim the offer atomically; if someone double-clicked and a parallel
        // request claimed it first, put the hero back and bail out.
        $stmt = $this->db->prepare(
            "UPDATE " . TB_PREFIX . "hero_adventure SET status = 1 WHERE id = ? AND status = 0 LIMIT 1"
        );
        $stmt->bind_param('i', $adventureId);
        $stmt->execute();
        $claimed = $stmt->affected_rows > 0;
        $stmt->close();
        if (!$claimed) {
            $stmt = $this->db->prepare(
                "UPDATE " . TB_PREFIX . "units SET hero = hero + 1 WHERE vref = ? LIMIT 1"
            );
            $stmt->bind_param('i', $homeWref);
            $stmt->execute();
            $stmt->close();
            return self::START_INVALID;
        }

        // Movement out: from = home village, to = adventure tile, ref = adventure id.
        // Recompute duration now (equipment may have changed since the offer was made).
        global $database;
        $coorHome = $database->getCoor($homeWref);
        $coorSite = $database->getCoor((int) $offer['wref']);
        $dist     = $database->getDistance($coorHome['x'], $coorHome['y'], $coorSite['x'], $coorSite['y']);
        $duration = $this->travelSeconds($uid, $dist);
        $endtime  = $now + $duration;

        $stmt = $this->db->prepare(
            "INSERT INTO " . TB_PREFIX . "movement
                    (sort_type, `from`, `to`, ref, ref2, starttime, endtime, proc, send, wood, clay, iron, crop, marker)
             VALUES (?, ?, ?, ?, 0, ?, ?, 0, 1, 0, 0, 0, 0, 0)"
        );
        $sortType = MOVEMENT_ADVENTURE_OUT; $siteWref = (int) $offer['wref'];
        $stmt->bind_param('iiiiii', $sortType, $homeWref, $siteWref, $adventureId, $now, $endtime);
        $stmt->execute();
        $moveid = (int) $stmt->insert_id;
        $stmt->close();

        $stmt = $this->db->prepare(
            "UPDATE " . TB_PREFIX . "hero_adventure SET moveid = ? WHERE id = ? LIMIT 1"
        );
        $stmt->bind_param('ii', $moveid, $adventureId);
        $stmt->execute();
        $stmt->close();

        return self::START_OK;
    }

    /* =========================================================================
     *  AUTOMATION PROCESSORS
     * ===================================================================== */

    /**
     * Process heroes ARRIVING at adventure sites (sort_type 20).
     * Rolls rewards, applies HP loss/XP/silver/items, files the ntype 26
     * report, and creates the return movement carrying the resource loot.
     */
    public function processArrivals()
    {
        global $database, $heroAdventureConfig;
        $now = time();

        $q = "SELECT m.moveid, m.`from`, m.`to`, m.ref, m.endtime,
                     a.id AS advid, a.uid, a.difficulty, a.type, a.restype
                FROM " . TB_PREFIX . "movement m
                JOIN " . TB_PREFIX . "hero_adventure a ON a.id = m.ref
               WHERE m.sort_type = " . (int) MOVEMENT_ADVENTURE_OUT . "
                 AND m.proc = 0 AND m.endtime < $now";
        $rows = $database->query_return($q);
        if (!$rows || !count($rows)) {
            return 0;
        }

        $processed = 0;
        foreach ($rows as $data) {
            if (!$this->claimMovement($data['moveid'])) {
                continue;
            }

            $uid  = (int) $data['uid'];
            $hero = $this->getLivingHero($uid);
            $cfg  = $heroAdventureConfig[(int) $data['difficulty']];

            // Hero vanished/died meanwhile (edge case): close the adventure quietly.
            if (!$hero) {
                $this->finishAdventure($data['advid']);
                continue;
            }

            /* ---- Roll rewards (local redesign: see rollOutcome) ---- */
            $o = $this->rollOutcome($uid, $hero, $data);
            $exp = $o['exp']; $silver = $o['silver']; $hpLoss = $o['hp']; $heal = $o['heal'];
            $wood = $o['wood']; $clay = $o['clay']; $iron = $o['iron']; $crop = $o['crop'];
            $itemId = $o['itemId']; $itemQty = $o['itemQty']; $story = $o['story'];

            $health    = (float) $hero['health'];
            $newHealth = min(100, $health - $hpLoss + $heal);

            if ($newHealth <= 0) {
                /* ---- Hero dies at the site: loot forfeited, no return trip. ---- */
                $stmt = $this->db->prepare(
                    "UPDATE " . TB_PREFIX . "hero SET dead = 1, health = 0, lastupdate = ? WHERE heroid = ? LIMIT 1"
                );
                $heroid = (int) $hero['heroid'];
                $stmt->bind_param('ii', $now, $heroid);
                $stmt->execute();
                $stmt->close();

                /**
                 * Eroul trebuie scos si din units.hero, nu doar marcat mort in
                 * tabela "hero". Altfel ramane vizibil in sat si in punctul de
                 * adunare, desi Conacul il arata mort.
                 *
                 * Aceeasi scapare exista in KillMyHero(), reassignHero() si in
                 * Battle::applyHeroBattleDamage() - toate reparate.
                 */
                $heroOwner = (int) $uid;

                if ($heroOwner > 0) {
                    mysqli_query($this->db,
                        "UPDATE " . TB_PREFIX . "units u
                           JOIN " . TB_PREFIX . "vdata v ON v.wref = u.vref
                            SET u.hero = 0
                          WHERE v.owner = " . $heroOwner . " AND u.hero > 0");

                    mysqli_query($this->db,
                        "UPDATE " . TB_PREFIX . "enforcement e
                           JOIN " . TB_PREFIX . "vdata v ON v.wref = e.`from`
                            SET e.hero = 0
                          WHERE v.owner = " . $heroOwner . " AND e.hero > 0");
                }

                $payload = 'difficulty=' . (int) $data['difficulty'] . '&type=' . (int) $data['type'] . '&died=1&hp=' . $hpLoss;
                $database->addNotice($uid, (int) $data['from'], 0, NTYPE_ADVENTURE_REPORT,
                    'Hero fell on an adventure', $payload, $now);

                $this->finishAdventure($data['advid']);
                $processed++;
                continue;
            }

            /* ---- Hero survives: apply rewards ---- */
            // Completed adventures are retained (including deaths). Use player
            // history rather than inventory so selling a horse or retraining a
            // hero cannot grant the introductory reward again. Available/expired
            // offers do not count as adventures the player has undertaken.
            $stmt = $this->db->prepare(
                "SELECT id FROM " . TB_PREFIX . "hero_adventure
                  WHERE uid = ? AND status = 2 LIMIT 1"
            );
            $stmt->bind_param('i', $uid);
            $stmt->execute();
            $previousAdventure = $stmt->get_result()->fetch_assoc();
            $stmt->close();
            if (!$previousAdventure) {
                // Replace the random item, keeping the one-item reward limit.
                $itemId = self::FIRST_ADVENTURE_ITEM;
                $itemQty = 1;
            }

            $heroItems = new HeroItems();

            // XP with helmet bonus; level-up handled by Automation::updateHero().
            $bonuses = $heroItems->getBonuses($uid);
            $xpGain  = (int) floor($exp * (100 + (int) $bonuses[HB_XP]) / 100);
            $database->modifyHeroXp('experience', $xpGain, (int) $hero['heroid']);

            // Health loss.
            $stmt = $this->db->prepare(
                "UPDATE " . TB_PREFIX . "hero SET health = ? WHERE heroid = ? LIMIT 1"
            );
            $heroid = (int) $hero['heroid'];
            $stmt->bind_param('di', $newHealth, $heroid);
            $stmt->execute();
            $stmt->close();

            // Silver + item drop.
            if ($silver > 0) {
                $heroItems->addSilver($uid, $silver);
            }
            if ($itemId > 0) {
                $heroItems->addItem($uid, $itemId, $itemQty);
            }

            /* ---- Return movement carries the resource loot home ---- */
            // Same travel time back as out: reuse the adventure's stored one-way duration.
            $legDuration    = $this->travelLegDuration($data);
            $stmt = $this->db->prepare(
                "INSERT INTO " . TB_PREFIX . "movement
                        (sort_type, `from`, `to`, ref, ref2, starttime, endtime, proc, send, wood, clay, iron, crop, marker)
                 VALUES (?, ?, ?, ?, 0, ?, ?, 0, 1, ?, ?, ?, ?, 0)"
            );
            $sortType = MOVEMENT_ADVENTURE_BACK;
            $fromSite = (int) $data['to']; $toHome = (int) $data['from'];
            $advid    = (int) $data['advid'];
            $end      = $now + $legDuration;
            $stmt->bind_param('iiiiiiiiii', $sortType, $fromSite, $toHome, $advid, $now, $end, $wood, $clay, $iron, $crop);
            $stmt->execute();
            $stmt->close();

            /* ---- Report (ntype 26) ---- */
            $payload = 'difficulty=' . (int) $data['difficulty']
                     . '&type=' . (int) $data['type'] . '&story=' . $story . '&heal=' . $heal
                     . '&exp=' . $xpGain . '&silver=' . $silver . '&hp=' . $hpLoss
                     . '&wood=' . $wood . '&clay=' . $clay . '&iron=' . $iron . '&crop=' . $crop;
            if ($itemId > 0) {
                $payload .= '&itemid=' . $itemId . '&itemqty=' . $itemQty;
            }
            $database->addNotice($uid, $toHome, 0, NTYPE_ADVENTURE_REPORT,
                'Hero returned from an adventure', $payload, $now);

            $this->finishAdventure($data['advid']);
            $processed++;
        }
        return $processed;
    }

    /**
     * Process heroes RETURNING home (sort_type 21): hero re-enters units.hero,
     * resource loot is credited to the village.
     */
    public function processReturns()
    {
        global $database;
        $now = time();

        $q = "SELECT moveid, `from`, `to`, wood, clay, iron, crop
                FROM " . TB_PREFIX . "movement
               WHERE sort_type = " . (int) MOVEMENT_ADVENTURE_BACK . "
                 AND proc = 0 AND endtime < $now";
        $rows = $database->query_return($q);
        if (!$rows || !count($rows)) {
            return 0;
        }

        $processed = 0;
        foreach ($rows as $data) {
            if (!$this->claimMovement($data['moveid'])) {
                continue;
            }

            $home = (int) $data['to'];

            // Hero is home again.
            $stmt = $this->db->prepare(
                "UPDATE " . TB_PREFIX . "units SET hero = hero + 1 WHERE vref = ? LIMIT 1"
            );
            $stmt->bind_param('i', $home);
            $stmt->execute();
            $stmt->close();

            // Credit the loot (same pattern as returnunitsComplete).
            if ($data['wood'] + $data['clay'] + $data['iron'] + $data['crop'] > 0) {
                $database->modifyResource($home, $data['wood'], $data['clay'], $data['iron'], $data['crop'], 1);
                $database->addStarvationData($home);
            }
            $processed++;
        }
        return $processed;
    }

    /**
     * Roll one random piece of EQUIPMENT. Universal gear (helmets, armors,
     * boots, horses, left-hand) drops for everyone; right-hand WEAPONS only
     * drop for the owner's own tribe (T4 behavior - a Roman never finds a
     * Teuton club). Tier picked by 'equip_tier_weights' (T1 common, T3 very
     * rare), then a uniform pick inside that tier. Returns an itemid, or 0
     * if the rolled tier happens to be empty (defensive; never true with
     * the shipped catalog).
     */
    public function rollEquipment($uid = 0, $weights = null)
    {
        global $database, $heroItemCatalog, $heroAdventureConfig;

        $tribe = ((int) $uid > 0) ? (int) $database->getUserField((int) $uid, 'tribe', 0) : 0;

        if (!is_array($weights) || !$weights) {
            $weights = $heroAdventureConfig['equip_tier_weights'];
        }
        $roll = mt_rand(1, 100); $acc = 0; $tier = 1;
        foreach ($weights as $t => $w) {
            $acc += (int) $w;
            if ($roll <= $acc) { $tier = (int) $t; break; }
        }

        $pool = array();
        foreach ($heroItemCatalog as $iid => $def) {
            if ((int) $def['slot'] === HSLOT_BAG || (int) $def['tier'] !== $tier) {
                continue;
            }
            $itemTribe = heroItemTribe($iid);
            if ($itemTribe !== 0 && $tribe > 0 && $itemTribe !== $tribe) {
                continue; // foreign-tribe weapon
            }
            $pool[] = $iid;
        }
        return count($pool) ? (int) $pool[array_rand($pool)] : 0;
    }


    /* =========================================================================
     *  SITE TYPES AND REWARD PROFILE (local redesign)
     * ===================================================================== */

    /**
     * Pick a site type for a tile. Oases and tiles next to one favour beast
     * lairs; croppers favour caravans (of crop). Returns [type, restype],
     * restype 1-4 = wood/clay/iron/crop for single-resource sites.
     */
    public function pickType($tile)
    {
        global $heroAdventureConfig;
        $types = $heroAdventureConfig['types'];

        $fieldtype = (int) ($tile['fieldtype'] ?? 0);
        $oasis = (int) ($tile['oasistype'] ?? 0) > 0;
        if (!$oasis && isset($tile['x'], $tile['y'])) {
            $x = (int) $tile['x']; $y = (int) $tile['y'];
            $r = mysqli_query($this->db, "SELECT 1 FROM " . TB_PREFIX . "wdata
                  WHERE x BETWEEN " . ($x - 1) . " AND " . ($x + 1) . "
                    AND y BETWEEN " . ($y - 1) . " AND " . ($y + 1) . " AND oasistype > 0 LIMIT 1");
            $oasis = $r && mysqli_num_rows($r) > 0;
        }
        $cropper = in_array($fieldtype, array(1, 6), true);

        $weights = array();
        foreach ($types as $id => $def) {
            $w = (int) ($def['weight'] ?? 0);
            if ($id === 3 && $oasis)   $w *= 2;  // beast lair
            if ($id === 4 && $cropper) $w *= 2;  // lost caravan
            if ($w > 0) $weights[$id] = $w;
        }
        $roll = mt_rand(1, max(1, array_sum($weights))); $acc = 0; $type = 1;
        foreach ($weights as $id => $w) {
            $acc += $w;
            if ($roll <= $acc) { $type = (int) $id; break; }
        }

        $restype = 0;
        if (!empty($types[$type]['single_res'])) {
            // the resource the valley is richest in (croppers: crop)
            $fields = array(1 => array(3, 3, 3, 9), 2 => array(3, 4, 5, 6), 3 => array(4, 4, 4, 6), 4 => array(4, 5, 3, 6),
                            5 => array(5, 3, 4, 6), 6 => array(1, 1, 1, 15), 7 => array(4, 4, 3, 7), 8 => array(3, 4, 4, 7),
                            9 => array(4, 3, 4, 7), 10 => array(3, 5, 4, 6), 11 => array(4, 3, 5, 6), 12 => array(5, 4, 3, 6));
            if ($cropper) {
                $restype = 4;
            } elseif (isset($fields[$fieldtype])) {
                $f = array_slice($fields[$fieldtype], 0, 3);
                $best = array_keys($f, max($f));
                $restype = $best[array_rand($best)] + 1;
            } else {
                $restype = mt_rand(1, 4);
            }
        }
        return array($type, $restype);
    }

    /**
     * Hero fighting strength for adventures: offence + average defence of the
     * hero's unit with its attribute points, plus fighting-strength gear.
     * 'ref' is the same for a hero of this level that put half its points
     * into attack/defence - the baseline the site's danger is tuned to.
     */
    public function strength($uid, $hero)
    {
        $unit = (int) ($hero['unit'] ?? 0);
        $hd = isset($GLOBALS['h' . $unit]) ? $GLOBALS['h' . $unit] : null;
        if (!$hd) {
            include __DIR__ . '/Data/unitdata.php';
            $var = 'h' . $unit;
            $hd = isset($$var) ? $$var : null;
        }
        if (!$hd) {
            return array('power' => 1, 'ref' => 1, 'reduce' => 0);
        }
        $calc = function ($atkPts, $defPts) use ($hd) {
            $atk = $hd['atk'] + 5 * floor($atkPts * $hd['atkp'] / 5);
            $di  = $hd['di']  + 5 * floor($defPts * $hd['dip'] / 5);
            $dc  = $hd['dc']  + 5 * floor($defPts * $hd['dcp'] / 5);
            return $atk + ($di + $dc) / 2;
        };
        $bon = (new HeroItems())->getBonuses((int) $uid);
        $half = (int) round(1.25 * ((int) $hero['level'] + 1));
        return array(
            'power'  => $calc((int) ($hero['attack'] ?? 0), (int) ($hero['defence'] ?? 0)) + (int) ($bon[HB_FIGHT] ?? 0),
            'ref'    => $calc($half, $half),
            'reduce' => (int) ($bon[HB_DMG_REDUCE] ?? 0),
        );
    }

    /**
     * Everything an adventure can give, as ranges, for this hero and trip.
     * Used both for the offer list and for the roll on arrival, so what the
     * page shows is what can happen. XP excludes the helmet bonus (applied
     * on arrival).
     */
    public function profile($uid, $hero, $difficulty, $type, $restype, $dist)
    {
        global $heroAdventureConfig;
        $C   = $heroAdventureConfig;
        $cfg = $C[$difficulty] ?? $C[0];
        $T   = $C['types'][$type] ?? $C['types'][0];
        $L   = (int) ($hero['level'] ?? 0);

        $d = ($dist - self::SITE_MIN_RADIUS) / max(1, self::SITE_MAX_RADIUS - self::SITE_MIN_RADIUS);
        $d = max(0, min(1, $d));
        $xpMul   = (float) $T['xp'] * (1 + $C['level_xp'] * $L) * (1 + $C['dist_bonus'] * $d);
        $resMul  = (float) $T['res'] * (1 + $C['level_res'] * $L) * (1 + $C['dist_bonus'] * $d);
        $itemMul = 1 + $C['dist_item_bonus'] * $d;

        $res = array();
        $r = array((int) round($cfg['resources'][0] * $resMul), (int) round($cfg['resources'][1] * $resMul));
        for ($k = 1; $k <= 4; $k++) {
            if (!empty($T['single_res'])) {
                $res[] = ($k === (int) $restype) ? $r : array(0, 0);
            } else {
                $res[] = $r;
            }
        }

        $heal = array(0, 0); $hp = array(0, 0); $factor = 1;
        if (!empty($T['heal'])) {
            $heal = $T['heal'][$difficulty] ?? $T['heal'][0];
        } else {
            $s = $this->strength($uid, $hero);
            $factor = $s['ref'] / max(1, $s['power']);
            $factor = max($C['strength_clamp'][0], min($C['strength_clamp'][1], $factor));
            foreach (array(0, 1) as $k) {
                $hp[$k] = max(0, (int) round($cfg['hp_loss'][$k] * (float) $T['hp'] * $factor) - $s['reduce']);
            }
        }

        return array(
            'exp'     => array(max(1, (int) round($cfg['exp'][0] * $xpMul)), max(1, (int) round($cfg['exp'][1] * $xpMul))),
            'res'     => $res,
            'hp'      => $hp,
            'heal'    => $heal,
            'factor'  => $factor,
            'gear'    => min(90, (int) round($cfg['equip_chance'] * (float) $T['gear'] * $itemMul)),
            'cons'    => min(90, (int) round($cfg['item_chance'] * (float) $T['cons'] * $itemMul)),
            'pool'    => $T['pool'] ?? $cfg['consumable'],
            'tiers'   => $T['tiers'] ?? ($cfg['tier_weights'] ?? $C['equip_tier_weights']),
            'stories' => count($T['story'] ?? array()),
            'name'    => $T['name'],
            'hint'    => $T['hint'],
        );
    }

    /**
     * Roll an arrival inside the site's profile (type, hero level, distance,
     * hero strength). No database writes - processArrivals applies it.
     */
    public function rollOutcome($uid, $hero, $data)
    {
        global $database, $heroAdventureConfig;
        $cfg = $heroAdventureConfig[(int) $data['difficulty']] ?? $heroAdventureConfig[0];
        $cHome = $database->getCoor((int) $data['from']);
        $cSite = $database->getCoor((int) $data['to']);
        $dist  = ($cHome && $cSite) ? $database->getDistance($cHome['x'], $cHome['y'], $cSite['x'], $cSite['y']) : self::SITE_MIN_RADIUS;
        $prof  = $this->profile($uid, $hero, (int) $data['difficulty'], (int) $data['type'], (int) $data['restype'], $dist);

        $exp    = mt_rand($prof['exp'][0], $prof['exp'][1]);
        $silver = mt_rand($cfg['silver'][0], $cfg['silver'][1]);
        // local redesign: hero silver is switched off (GameEngine/Data/gold.php)
        include_once __DIR__ . '/Data/gold.php';
        if (!TZ_SILVER_ENABLED) $silver = 0;
        $hpLoss = mt_rand($prof['hp'][0], $prof['hp'][1]);
        $heal   = mt_rand($prof['heal'][0], $prof['heal'][1]);
        $loot   = array();
        foreach ($prof['res'] as $k => $range) {
            $loot[$k] = ($range[1] > 0) ? mt_rand($range[0], $range[1]) : 0;
        }
        list($wood, $clay, $iron, $crop) = $loot;

        // Item drop: gear first (rarer, tier-weighted toward T1), and only
        // if no gear dropped, roll the consumable pool. One item max.
        $itemId = 0; $itemQty = 0;
        if (mt_rand(1, 100) <= $prof['gear']) {
            $itemId  = $this->rollEquipment($uid, $prof['tiers']);
            $itemQty = ($itemId > 0) ? 1 : 0;
        }
        if ($itemId === 0 && mt_rand(1, 100) <= $prof['cons']) {
            $pool    = $prof['pool'];
            $itemId  = (int) $pool[array_rand($pool)];
            $itemQty = 1;
        }
        $story = mt_rand(0, max(0, $prof['stories'] - 1));

        return array('exp' => $exp, 'silver' => $silver, 'hp' => $hpLoss, 'heal' => $heal,
                     'wood' => $wood, 'clay' => $clay, 'iron' => $iron, 'crop' => $crop,
                     'itemId' => $itemId, 'itemQty' => $itemQty, 'story' => $story);
    }

    /** Hero row for the offer list (same columns the arrival roll uses). */
    public function livingHero($uid)
    {
        return $this->getLivingHero($uid);
    }

    /* =========================================================================
     *  INTERNALS
     * ===================================================================== */

    /**
     * Travel time in seconds for a given distance, honoring equipment:
     * horse replaces the on-foot base speed, spurs add on top (only with a
     * horse - already enforced inside HeroItems::getBonuses()).
     */
    public function travelSeconds($uid, $distance)
    {
        $heroItems = new HeroItems();
        $bonuses   = $heroItems->getBonuses((int) $uid);

        $speed = ((int) $bonuses[HB_HORSE_SPEED] > 0)
            ? (int) $bonuses[HB_HORSE_SPEED] + (int) $bonuses[HB_MOUNT_SPEED]
            : self::BASE_HERO_SPEED;

        $increase = defined('INCREASE_SPEED') ? max(1, (int) INCREASE_SPEED) : 1;
        return max(60, (int) round($distance / $speed * 3600 / $increase));
    }

    /** Duration of the just-finished leg (endtime - starttime is not selected; use stored offer duration). */
    private function travelLegDuration($data)
    {
        // The return leg mirrors the outbound one. We recompute from the
        // adventure's stored one-way duration to avoid drift when Automation
        // runs late (endtime long in the past).
        $stmt = $this->db->prepare(
            "SELECT duration FROM " . TB_PREFIX . "hero_adventure WHERE id = ? LIMIT 1"
        );
        $advid = (int) $data['advid'];
        $stmt->bind_param('i', $advid);
        $stmt->execute();
        $stmt->bind_result($duration);
        $found = $stmt->fetch();
        $stmt->close();
        return $found ? max(60, (int) $duration) : 3600;
    }

    /** Same claim pattern as Automation::claimMovementRecord (race-safe). */
    private function claimMovement($moveid)
    {
        $moveid = (int) $moveid;
        if ($moveid <= 0) {
            return false;
        }
        $stmt = $this->db->prepare(
            "UPDATE " . TB_PREFIX . "movement SET proc = 1 WHERE moveid = ? AND proc = 0 LIMIT 1"
        );
        $stmt->bind_param('i', $moveid);
        $stmt->execute();
        $ok = $stmt->affected_rows === 1;
        $stmt->close();
        return $ok;
    }

    private function finishAdventure($advid)
    {
        $advid = (int) $advid;
        $stmt  = $this->db->prepare(
            "UPDATE " . TB_PREFIX . "hero_adventure SET status = 2 WHERE id = ? LIMIT 1"
        );
        $stmt->bind_param('i', $advid);
        $stmt->execute();
        $stmt->close();
    }

    private function getLivingHero($uid)
    {
        $uid  = (int) $uid;
        $stmt = $this->db->prepare(
            "SELECT heroid, uid, unit, wref, level, experience, health, dead, attack, defence
               FROM " . TB_PREFIX . "hero WHERE uid = ? AND dead = 0 LIMIT 1"
        );
        $stmt->bind_param('i', $uid);
        $stmt->execute();
        $res = $stmt->get_result();
        $row = $res->fetch_assoc();
        $stmt->close();
        return $row ?: null;
    }
}
