<?php

#################################################################################
##              -= YOU MAY NOT REMOVE OR CHANGE THIS NOTICE =-                 ##
## --------------------------------------------------------------------------- ##
##  Filename       : Market.php                      	                       ##
##  Type           : Market System Backend                                     ##
## --------------------------------------------------------------------------- ##
##  Developed by   : Dzoki           			                               ##
##  Refactored by  : Shadow & Ferywir									       ##
##  Thanks to      : ronix, InCube, Akakori, Elmar & Kirilloid                 ##
## --------------------------------------------------------------------------- ##
##  Contact        : cata7007@gmail.com                                        ##
##  Project        : TravianZ                                                  ##
##  URLs:          : https://travianz.org                                      ##
##  GitHub         : https://github.com/Shadowss/TravianZ                      ##
## --------------------------------------------------------------------------- ##
##  License        : TravianZ Project                                          ##
##  Copyright      : TravianZ (c) 2010-2026. All rights reserved.              ##
## --------------------------------------------------------------------------- ##
#################################################################################

class Market
{
    public $onsale = [];
    public $onmarket = [];
    public $sending = [];
    public $recieving = [];
    public $return = [];

    public $maxcarry;
    public $merchant;
    public $used;
	
	/**
	* Internal request cache.
	* Safe legacy-compatible cache layer.
	*/
	
	private $cache = [];

    /**
     * Main market processor.
     */
    public function procMarket($post)
    {
        $this->loadMarket();

        if (isset($_SESSION['loadMarket'])) {
            $this->loadOnsale();
            unset($_SESSION['loadMarket']);
        }

        if (!isset($post['ft'])) {
            return;
        }

        switch ($post['ft']) {
            case 'mk1':
                $this->sendResource($post);
                break;

            case 'mk2':
                $this->addOffer($post);
                break;

            case 'mk3':
                $this->tradeResource($post);
                break;

            case 'mk5':
                $this->buyContract($post);
                break;
        }
    }

    /**
     * Remove / accept market actions.
     */
    public function procRemove($get)
    {
        global $database, $village, $session;

        if (isset($get['t']) && $get['t'] == 1) {
            $this->filterNeed($get);
        } elseif (
            isset($get['t'], $get['a'], $get['del']) &&
            $get['t'] == 2 &&
            $get['a'] == 5
        ) {
            // Get all fields from market
            $type = $database->getMarketField($village->wid, $get['del'], 'gtype');
            $amt  = $database->getMarketField($village->wid, $get['del'], 'gamt');

            if ((int) $type === 5) {
                // local redesign: held gold goes back (not cut to the cap)
                $database->query("UPDATE " . TB_PREFIX . "vdata SET gold = gold + " . (int) $amt . " WHERE wref = " . (int) $village->wid);
            } else {
                $database->getResourcesBack($village->wid, $type, $amt);
            }
            $database->addMarket($village->wid, $get['del'], 0, 0, 0, 0, 0, 0, 1);

            header('Location: build.php?id=' . $get['id'] . '&t=2');
            exit;
        }

        if (
            isset($get['t'], $get['a']) &&
            $get['t'] == 1 &&
            hash_equals((string) $session->mchecker, (string) ($get['a'] ?? '')) &&
            !isset($get['del'])
        ) {
            $session->changeChecker();
            $this->acceptOffer($get);
        }
    }

    /**
     * Available merchants.
     */
    public function merchantAvail()
    {
        return $this->merchant - $this->used;
    }
	
	/**
	* Remember cached value for current request.
	*/
	private function remember($key, callable $callback)
	{
    if (isset($this->cache[$key])) {
        return $this->cache[$key];
    }

    $this->cache[$key] = $callback();

    return $this->cache[$key];
	}

	/**
	* Forget cache entry or entire cache.
	*/
	private function forget($key = null)
	{
    if ($key === null) {
        $this->cache = [];
        return;
    }

    unset($this->cache[$key]);
	}

    /**
     * Load market data.
     */
    private function loadMarket()
    {
        global $session, $building, $bid28, $bid17, $database, $village;

        $this->recieving = $database->getMovement(0, $village->wid, 1);
        $this->sending   = $database->getMovement(0, $village->wid, 0);
        $this->return    = $database->getMovement(2, $village->wid, 1);

        $this->merchant = ($building->getTypeLevel(17) > 0)
            ? $bid17[$building->getTypeLevel(17)]['attri']
            : 0;

        $this->used = $this->remember(
		'merchant_used_' . $village->wid,
		function () use ($database, $village) {
        return $database->totalMerchantUsed($village->wid);
		}
		);

        $this->onmarket = $this->remember(
		'market_' . $village->wid,
		function () use ($database, $village) {
        return $database->getMarket($village->wid, 0);
		}
		);

        // Merchant carry capacity
        // Capacitate negustor per trib: 1=500, 2=1000, 3=750, 6=500, 7=750, 8=500, 9=750
        $carrymap = array(1 => 500, 2 => 1000, 3 => 750, 6 => 500, 7 => 750, 8 => 500, 9 => 750);
        $this->maxcarry = isset($carrymap[$session->tribe]) ? $carrymap[$session->tribe] : 750;

        $this->maxcarry *= TRADER_CAPACITY;

        // Trade office bonus
        if ($building->getTypeLevel(28) != 0) {
            $this->maxcarry *= $bid28[$building->getTypeLevel(28)]['attri'] / 100;
        }

        // Bonusul de alianta "Commerce". Se inmulteste cu biroul comercial, ca
        // in T4: 750 de baza x 2.2 (Commerce 4) x 5 (birou 20) = 8250.
        // Se ia dupa PROPRIETARUL satului, nu dupa sesiune, ca sa dea acelasi
        // rezultat si cand codul ruleaza in alt context (sitter, automatizare).
        // Calea de repetare din AutomationMarket foloseste aceeasi regula.
        if (class_exists('AllianceBonus') && AllianceBonus::enabled()) {
            $carryOwner = isset($village->wid)
                ? (int) $database->getVillageField($village->wid, 'owner')
                : (int) $session->uid;

            if ($carryOwner > 0) {
                $this->maxcarry *= AllianceBonus::multiplier($carryOwner, AllianceBonus::COMMERCE);
            }
        }

        $this->maxcarry = floor($this->maxcarry);
    }

    /**
     * Send resources.
     */
    /**
     * Push-protection enforcement (Travian-Legends style).
     * Returns true when this send must be BLOCKED because the recipient has
     * reached the amount of resources it may receive from other players in the
     * rolling window (see PushProtection::remainingAllowance).
     *
     * No-ops (returns false) for: own-village transfers, system accounts, when
     * the PushProtection engine is absent, or when hard enforcement is globally
     * disabled via  define("PUSH_PROTECTION_ENFORCE", false);  in config.php
     * (the dashboard and logging keep working either way — default is ON).
     *
     * WW villages and manual "Exempt" overrides return an unlimited allowance
     * inside remainingAllowance(), so they are never blocked here.
     */
    private function exceedsPushLimit($database, $fromWid, $toWid, array $resource)
    {
        if (defined('PUSH_PROTECTION_ENFORCE') && !PUSH_PROTECTION_ENFORCE) {
            return false;
        }
        if (!class_exists('PushProtection')) {
            return false; // engine not deployed -> no enforcement
        }

        $fromOwner = (int) $database->getVillageField($fromWid, 'owner');
        $toOwner   = (int) $database->getVillageField($toWid, 'owner');

        // Own transfer or system account -> never limited.
        if ($fromOwner === $toOwner || $toOwner <= 3) {
            return false;
        }

        $sendTotal = (int) $resource[0] + (int) $resource[1] + (int) $resource[2] + (int) $resource[3];
        if ($sendTotal <= 0) {
            return false;
        }

        return $sendTotal > PushProtection::remainingAllowance($toOwner);
    }

    private function sendResource($post)
    {
        global $database, $village, $session, $generator, $logging, $form;

        $wtrans  = (isset($post['r1']) && !empty($post['r1'])) ? $post['r1'] : 0;
        $ctrans  = (isset($post['r2']) && !empty($post['r2'])) ? $post['r2'] : 0;
        $itrans  = (isset($post['r3']) && !empty($post['r3'])) ? $post['r3'] : 0;
        $crtrans = (isset($post['r4']) && !empty($post['r4'])) ? $post['r4'] : 0;

        // Prevent negative values
        $wtrans  = str_replace('-', '', $wtrans);
        $ctrans  = str_replace('-', '', $ctrans);
        $itrans  = str_replace('-', '', $itrans);
        $crtrans = str_replace('-', '', $crtrans);

        // Village gold (local redesign, phase 2): whole gold only; each takes
        // TZ_GOLD_MERCHANT_SPACE of merchant capacity (GameEngine/Data/gold.php)
        $gtrans = (isset($post['r5']) && !empty($village->goldActive)) ? max(0, (int) $post['r5']) : 0;
        $goldSpace = defined('TZ_GOLD_MERCHANT_SPACE') ? TZ_GOLD_MERCHANT_SPACE : 100;

        // Preload village data
        $database->getVillage($village->wid);

        $resourcesAvailable = $this->remember(
		'resources_' . $village->wid,
		function () use ($database, $village) {
        return [
            'wood' => $database->getWoodAvailable($village->wid),
            'clay' => $database->getClayAvailable($village->wid),
            'iron' => $database->getIronAvailable($village->wid),
            'crop' => $database->getCropAvailable($village->wid),
        ];
    }
	);

		$availableWood = $resourcesAvailable['wood'];
		$availableClay = $resourcesAvailable['clay'];
		$availableIron = $resourcesAvailable['iron'];
		$availableCrop = $resourcesAvailable['crop'];

        // Resource array
        $resource = [
            $wtrans,
            $ctrans,
            $itrans,
            $crtrans
        ];

        // NOTE:
        // Original code referenced $id before definition.
        // Keeping logic safe while preserving compatibility.
        $id = isset($post['getwref']) ? (int)$post['getwref'] : 0;

        /**
         * PERMISIUNI SITTER: "trimite resurse altor jucatori".
         *
         * Restrictia se aplica DOAR catre alte conturi. Mutarea resurselor
         * intre satele proprii ramane permisa - altfel un sitter n-ar mai putea
         * administra contul deloc, ceea ce nu e scopul.
         *
         * Verificam proprietarul satului tinta, nu numele lui: un jucator poate
         * avea oricate sate, iar comparatia pe uid e singura de incredere.
         */
        if ($id > 0 && isset($session) && is_object($session) && method_exists($session, 'sitterCan')) {

            $targetOwner = (int) $database->getVillageField($id, 'owner');

            if ($targetOwner > 0
                && $targetOwner !== (int) $session->uid
                && !$session->sitterCan(SITTER_PERM_RES)) {

                $form->addError('error', defined('SITTER_P_DENIED')
                    ? SITTER_P_DENIED
                    : 'Your sitter permissions do not allow this action.');

                /**
                 * "return", nu doar addError: mai jos urmeaza un lant
                 * if/elseif care ajunge la ramura de trimitere indiferent de
                 * erorile adaugate inainte. Fara iesire explicita, resursele
                 * ar fi plecat oricum, iar mesajul de eroare ar fi fost doar
                 * decorativ.
                 */
                return;
            }
        }

        /**
         * BUG PREEXISTENT: modul vacanta era doar semnalat, nu si blocat.
         *
         * Eroarea se adauga aici, dar mai jos urmeaza un lant if/elseif care
         * ajunge la ramura de trimitere indiferent de erorile de dinainte.
         * Rezultatul: mesajul "utilizatorul e in vacanta" aparea pe ecran, dar
         * resursele plecau oricum catre contul protejat. Iesim explicit.
         */
        if ($database->getvacmodexy($id)) {
            $form->addError('error', USER_ON_VACATION);
            return;
        }

        if (!$database->checkVilExist($post['getwref'])) {
            $form->addError('error', NO_COORDINATES_SELECTED);
        } elseif ($post['getwref'] == $village->wid) {
            $form->addError('error', CANNOT_SEND_RESOURCES);
        } elseif (
            $post['send3'] < 1 ||
            $post['send3'] > 3 ||
            ($post['send3'] > 1 && !$session->goldclub)
        ) {
            $form->addError('error', INVALID_MERCHANTS_REPETITION);
        } elseif (
            $this->exceedsPushLimit($database, $village->wid, $id, $resource)
        ) {
            // Push protection: recipient has reached its transfer limit for the
            // current window. Uses a language constant when available, else a
            // clear English fallback (add PUSH_PROTECTION_LIMIT to your Lang
            // files to localise).
            $form->addError('error', defined('PUSH_PROTECTION_LIMIT')
                ? PUSH_PROTECTION_LIMIT
                : 'This account has reached its resource-transfer limit for now and cannot receive that many resources. Send less, or wait for the limit to recover.');
        } elseif (
            $availableWood >= $wtrans &&
            $availableClay >= $ctrans &&
            $availableIron >= $itrans &&
            $availableCrop >= $crtrans &&
            $gtrans <= floor($village->agold)
        ) {
            // UM-D1: comparatia foloseste valorile curatate de semnul minus
            // ($wtrans/... in loc de $post['r1']/...). Inainte, comparatia se
            // facea pe POST-ul brut (potential negativ), dar deducerea se facea
            // pe valoarea pozitiva - un "r1" negativ trecea verificarea si scadea
            // resurse pozitive.
            $reqMerc = ceil((array_sum($resource) + $gtrans * $goldSpace - 0.1) / $this->maxcarry);

            // local redesign: express caravan (Trade Office) - own villages only,
            // single delivery, faster by expressSpeed(), paid per merchant
            $tzToLevel = VillageGold::tradeOfficeLevel();
            $tzExpress = !empty($post['express']) && $tzToLevel > 0 && !empty($village->goldActive)
                && (int) $post['send3'] === 1
                && (int) $database->getVillageField($id, 'owner') === (int) $session->uid;
            $tzExpressCost = $tzExpress ? (int) ($reqMerc * TZ_EXPRESS_GOLD_PER_MERCHANT) : 0;
            if ($tzExpress && $gtrans + $tzExpressCost > floor($village->agold)) {
                $form->addError('error', 'Not enough gold for the express caravan (' . $tzExpressCost . ' gold).');
                return;
            }

            // Acquire merchant lock to prevent race conditions
            $database->getMerchantLock($village->wid);

            $this->forget('merchant_used_' . $village->wid);

			$this->used = $this->remember(
			'merchant_used_' . $village->wid,
			function () use ($database, $village) {
			return $database->totalMerchantUsed($village->wid, false);
			}
			);

            if ($this->merchantAvail() > 0 && $reqMerc <= $this->merchantAvail()) {

                $coor = $database->getCoor($id);

                if ($database->getVillageState($id)) {

                    $timetaken = $generator->procDistanceTime(
                        $coor,
                        $village->coor,
                        $session->tribe,
                        0
                    );
                    if ($tzExpress) {
                        $timetaken = (int) ceil($timetaken / VillageGold::expressSpeed($tzToLevel));
                    }

                    $res = array_sum($resource) + $gtrans;

                    // gold is taken first, in one guarded UPDATE: if it was
                    // spent in the meantime nothing is sent
                    if ($res != 0 && $database->takeVillageGold($village->wid, $gtrans + $tzExpressCost)) {
                        if ($tzExpressCost > 0) {
                            $database->addGoldFinLog($village->wid, $session->uid, 'Express caravan', -$tzExpressCost, $reqMerc . ' merchant(s)');
                        }

                        $reference = $database->sendResource(
                            $resource[0],
                            $resource[1],
                            $resource[2],
                            $resource[3],
                            $reqMerc,
                            0,
                            $gtrans
                        );

                        $database->modifyResource(
                            $village->wid,
                            $resource[0],
                            $resource[1],
                            $resource[2],
                            $resource[3],
                            0
                        );

                        $database->addMovement(
                            0,
                            $village->wid,
                            $id,
                            $reference,
                            time(),
                            time() + $timetaken,
                            $post['send3']
                        );
						$this->forget();
                        $logging->addMarketLog(
                            $village->wid,
                            1,
                            [
                                $resource[0],
                                $resource[1],
                                $resource[2],
                                $resource[3],
                                $id
                            ]
                        );
                    }
                }

                $database->releaseMerchantLock($village->wid);

                header('Location: build.php?id=' . $post['id']);
                exit;
            } else {

                $database->releaseMerchantLock($village->wid);

                $form->addError('error', TOO_FEW_MERCHANTS);
            }
        } else {

            $form->addError('error', TOO_FEW_RESOURCES);
        }
    }

    /**
     * Add market offer.
     */
    private function addOffer($post)
    {
        global $database, $village, $session;

        // Invalid: same resource type
        if ($post['rid1'] == $post['rid2']) {

            header('Location: build.php?id=' . $post['id'] . '&t=2&e2');
            exit;
        }

        // Invalid values
        if (
            !isset($post['m1'], $post['m2']) ||
            $post['m1'] <= 0 ||
            $post['m2'] <= 0
        ) {

            header('Location: build.php?id=' . $post['id'] . '&t=2&e2');
            exit;
        }

        // local redesign: gold (type 5) counts as TZ_GOLD_MERCHANT_SPACE resources
        // for the ratio limits below (same as its merchant space)
        $tzGoldSpace = defined('TZ_GOLD_MERCHANT_SPACE') ? TZ_GOLD_MERCHANT_SPACE : 100;
        $tzV1 = $post['m1'] * ($post['rid1'] == 5 ? $tzGoldSpace : 1);
        $tzV2 = $post['m2'] * ($post['rid2'] == 5 ? $tzGoldSpace : 1);

        // Max 2:1 trade ratio
        if ($tzV1 > (2 * $tzV2)) {

            header('Location: build.php?id=' . $post['id'] . '&t=2&e2');
            exit;
        }

        // Min 1:2 trade ratio
        if ($tzV2 > (2 * $tzV1)) {

            header('Location: build.php?id=' . $post['id'] . '&t=2&e2');
            exit;
        }

        // Invalid resource ids
        if (
            $post['rid1'] < 1 ||
            $post['rid1'] > (!empty($village->goldActive) ? 5 : 4) ||
            $post['rid2'] < 1 ||
            $post['rid2'] > (!empty($village->goldActive) ? 5 : 4)
        ) {

            header('Location: build.php?id=' . $post['id'] . '&t=2&e2');
            exit;
        }

        // Offered resources
        $wood = ($post['rid1'] == 1) ? $post['m1'] : 0;
        $clay = ($post['rid1'] == 2) ? $post['m1'] : 0;
        $iron = ($post['rid1'] == 3) ? $post['m1'] : 0;
        $crop = ($post['rid1'] == 4) ? $post['m1'] : 0;
        $tzGoldOffered = ($post['rid1'] == 5) ? (int) $post['m1'] : 0;

        // Preload village data
        $database->getVillage($village->wid);

		$resourcesAvailable = $this->remember(
		'resources_' . $village->wid,
		function () use ($database, $village) {
        return [
            'wood' => $database->getWoodAvailable($village->wid),
            'clay' => $database->getClayAvailable($village->wid),
            'iron' => $database->getIronAvailable($village->wid),
            'crop' => $database->getCropAvailable($village->wid),
        ];
		}
		);

		$availableWood = $resourcesAvailable['wood'];
		$availableClay = $resourcesAvailable['clay'];
		$availableIron = $resourcesAvailable['iron'];
		$availableCrop = $resourcesAvailable['crop'];

        if (
            $availableWood >= $wood &&
            $availableClay >= $clay &&
            $availableIron >= $iron &&
            $availableCrop >= $crop &&
            $tzGoldOffered <= floor((float) $village->agold)
        ) {

            $totalRes = $wood + $clay + $iron + $crop + $tzGoldOffered * $tzGoldSpace;

            $reqMerc = 1;

            if ($totalRes > $this->maxcarry) {

                $reqMerc = round($totalRes / $this->maxcarry);

                if ($totalRes > ($this->maxcarry * $reqMerc)) {
                    $reqMerc += 1;
                }
            }

            // Acquire merchant lock
            $database->getMerchantLock($village->wid);

            $this->forget('merchant_used_' . $village->wid);

			$this->used = $this->remember(
			'merchant_used_' . $village->wid,
			function () use ($database, $village) {
			return $database->totalMerchantUsed($village->wid, false);
			}
		);

            if ($this->merchantAvail() > 0 && $reqMerc <= $this->merchantAvail()) {

                // offered gold is held while the offer is up (given back on cancel)
                if ($tzGoldOffered > 0 && !$database->takeVillageGold($village->wid, $tzGoldOffered)) {
                    $database->releaseMerchantLock($village->wid);
                    header('Location: build.php?id=' . $post['id'] . '&t=2&e1');
                    exit;
                }

                if (
                    $tzGoldOffered > 0 ||
                    $database->modifyResource(
                        $village->wid,
                        $wood,
                        $clay,
                        $iron,
                        $crop,
                        0
                    )
                ) {

                    $time = 0;

                    if (isset($_POST['d1'])) {
                        $time = $_POST['d2'] * 3600;
                    }

                    $alliance = (
                        isset($post['ally']) &&
                        $post['ally'] == 1
                    )
                        ? $session->userinfo['alliance']
                        : 0;

                    $database->addMarket(
                        $village->wid,
                        $post['rid1'],
                        $post['m1'],
                        $post['rid2'],
                        $post['m2'],
                        $time,
                        $alliance,
                        $reqMerc,
                        0
                    );
                }
				$this->forget();
                $database->releaseMerchantLock($village->wid);

                header('Location: build.php?id=' . $post['id'] . '&t=2');
                exit;
            }

            // Not enough merchants
            $database->releaseMerchantLock($village->wid);

            header('Location: build.php?id=' . $post['id'] . '&t=2&e3');
            exit;
        }

        // Not enough resources
        header('Location: build.php?id=' . $post['id'] . '&t=2&e1');
        exit;
    }

    /**
     * Accept market offer.
     */
    private function acceptOffer($get)
    {
        global $database, $village, $session, $logging, $generator;

        $infoarray = $database->getMarketInfo($get['g']);

        // local redesign: gold (type 5) takes TZ_GOLD_MERCHANT_SPACE per gold
        $tzGoldSpace = defined('TZ_GOLD_MERCHANT_SPACE') ? TZ_GOLD_MERCHANT_SPACE : 100;
        $tzWantLoad = $infoarray['wamt'] * ((int) $infoarray['wtype'] === 5 ? $tzGoldSpace : 1);
        $reqMerc = max(1, (int) ceil($tzWantLoad / $this->maxcarry));

        $villageResources = [
            $village->awood,
            $village->aclay,
            $village->airon,
            $village->acrop,
            floor((float) $village->agold)
        ];

        // Not enough resources
        if (
            $infoarray['wamt'] >
            $villageResources[$infoarray['wtype'] - 1]
        ) {

            header('Location: build.php?id=' . $get['id'] . '&t=1&e1');
            exit;
        }

        // Invalid offer
        if (
            ($infoarray['vref'] == $village->wid) ||
            (
                $infoarray['alliance'] > 0 &&
                $infoarray['alliance'] != $session->alliance
            ) ||
            (
                $infoarray['maxtime'] > 0 &&
                ($infoarray['maxtime'] * 3600) <
                $generator->procDistanceTime(
                    $database->getCoor($infoarray['vref']),
                    $village->coor,
                    $session->tribe,
                    0
                )
            )
        ) {

            header('Location: build.php?id=' . $get['id'] . '&t=1&e2');
            exit;
        }

        // Not enough merchants
        if ($reqMerc > $this->merchantAvail()) {

            header('Location: build.php?id=' . $get['id'] . '&t=1&e3');
            exit;
        }

        // Acquire merchant lock
        $database->getMerchantLock($village->wid);

        $this->forget('merchant_used_' . $village->wid);

		$this->used = $this->remember(
		'merchant_used_' . $village->wid,
		function () use ($database, $village) {
        return $database->totalMerchantUsed($village->wid, false);
		}
		);

        // Double-check after lock
        if ($reqMerc > $this->merchantAvail()) {
			$this->forget();
            $database->releaseMerchantLock($village->wid);

            header('Location: build.php?id=' . $get['id'] . '&t=1&e3');
            exit;
        }

        // wanted gold leaves the buyer's village first (guarded)
        if ((int) $infoarray['wtype'] === 5 && !$database->takeVillageGold($village->wid, (int) $infoarray['wamt'])) {
            $this->forget();
            $database->releaseMerchantLock($village->wid);
            header('Location: build.php?id=' . $get['id'] . '&t=1&e1');
            exit;
        }

        // Prepare resources (index 5 = gold)
        $myresource = [1 => 0, 0, 0, 0, 0];
        $hisresource = [1 => 0, 0, 0, 0, 0];

        $myresource[$infoarray['wtype']] = $infoarray['wamt'];

        $mysendid = $database->sendResource(
            $myresource[1],
            $myresource[2],
            $myresource[3],
            $myresource[4],
            $reqMerc,
            0,
            $myresource[5] > 0 ? $myresource[5] : null
        );

        $hisresource[$infoarray['gtype']] = $infoarray['gamt'];

        $hissendid = $database->sendResource(
            $hisresource[1],
            $hisresource[2],
            $hisresource[3],
            $hisresource[4],
            $infoarray['merchant'],
            0,
            $hisresource[5] > 0 ? $hisresource[5] : null
        );

        $hiscoor = $database->getCoor($infoarray['vref']);

        $mytime = $generator->procDistanceTime(
            $hiscoor,
            $village->coor,
            $session->tribe,
            0
        );

        $targettribe = $database->getUserField(
            $database->getVillageField($infoarray['vref'], 'owner'),
            'tribe',
            0
        );

        $histime = $generator->procDistanceTime(
            $village->coor,
            $hiscoor,
            $targettribe,
            0
        );

        $timestamp = time();

        $database->addMovement(
            [0, 0],
            [$village->wid, $infoarray['vref']],
            [$infoarray['vref'], $village->wid],
            [$mysendid, $hissendid],
            [$timestamp, $timestamp],
            [$mytime + $timestamp, $histime + $timestamp]
        );

        $resource = [1 => 0, 0, 0, 0, 0];
        $resource[$infoarray['wtype']] = $infoarray['wamt'];

        $database->modifyResource(
            $village->wid,
            $resource[1],
            $resource[2],
            $resource[3],
            $resource[4],
            0
        );

        $database->setMarketAcc($get['g']);
        $database->removeAcceptedOffer($get['g']);

        $logging->addMarketLog(
            $village->wid,
            2,
            [$infoarray['vref'], $get['g']]
        );

        $database->releaseMerchantLock($village->wid);

        header('Location: build.php?id=' . $get['id']);
        exit;
    }

    /**
     * Load onsale offers.
     */
    private function loadOnsale()
    {
        global $database, $village, $session, $multisort, $generator;

        $displayarray = $database->getMarket($village->wid, 1);

        $holderarray = [];

        foreach ($displayarray as $value) {

            $targetcoor = $database->getCoor($value['vref']);

            $duration = $generator->procDistanceTime(
                $targetcoor,
                $village->coor,
                $session->tribe,
                0
            );

            if (
                $duration <= ($value['maxtime'] * 3600) ||
                $value['maxtime'] == 0
            ) {

                $value['duration'] = $duration;

                $holderarray[] = $value;
            }
        }

        $this->onsale = $multisort->sorte(
            $holderarray,
            'duration',
            true,
            2
        );
    }

    /**
     * Filter market offers.
     */
    private function filterNeed($get)
    {
        if (
            !isset($get['v']) &&
            !isset($get['s']) &&
            !isset($get['b'])
        ) {

            $this->loadOnsale();
            return;
        }

        $holder  = [];
        $holder2 = [];

        // 1:1 trades
        if (isset($get['v']) && $get['v'] == '1:1') {

            foreach ($this->onsale as $equal) {

                if ($equal['wamt'] <= $equal['gamt']) {
                    $holder[] = $equal;
                }
            }
        } else {

            $holder = $this->onsale;
        }

        foreach ($holder as $sale) {

            if (isset($get['s']) && isset($get['b'])) {

                if (
                    $sale['gtype'] == $get['s'] &&
                    $sale['wtype'] == $get['b']
                ) {
                    $holder2[] = $sale;
                }
            } elseif (isset($get['s']) && !isset($get['b'])) {

                if ($sale['gtype'] == $get['s']) {
                    $holder2[] = $sale;
                }
            } elseif (isset($get['b']) && !isset($get['s'])) {

                if ($sale['wtype'] == $get['b']) {
                    $holder2[] = $sale;
                }
            } else {

                $holder2 = $holder;
            }
        }

        $this->onsale = $holder2;
    }

    /**
     * Local redesign: resource contract - buy resources from the NPC with this
     * village's gold (TZ_CONTRACT_RES_PER_GOLD per gold), within a daily
     * allowance of Trade Office level x TZ_CONTRACT_GOLD_PER_LEVEL gold.
     * Signed in the Trade Office (gid 28), from level TZ_CONTRACT_MIN_LEVEL.
     */
    private function buyContract($post)
    {
        global $session, $database, $village, $building;

        $back = 'Location: build.php?id=' . (int) $post['id'];
        $tzOffice = (int) $building->getTypeLevel(28);
        if ($tzOffice < TZ_CONTRACT_MIN_LEVEL) {
            header($back . '&e=5');
            exit;
        }
        if (!VillageGold::pays($village)
            || (isset($session) && method_exists($session, 'sitterCan') && !$session->sitterCan(SITTER_PERM_GOLD))) {
            header($back . '&e=1');
            exit;
        }

        $want = [];
        foreach ([1 => 'wood', 2 => 'clay', 3 => 'iron', 4 => 'crop'] as $i => $k) {
            $want[$k] = max(0, (int) ($post['r' . $i] ?? 0));
        }
        $total = array_sum($want);
        if ($total <= 0) {
            header($back);
            exit;
        }

        // must fit in storage now (bought resources are not thrown away)
        $have = ['wood' => $village->awood, 'clay' => $village->aclay, 'iron' => $village->airon, 'crop' => $village->acrop];
        foreach ($want as $k => $n) {
            $cap = ($k === 'crop') ? $village->maxcrop : $village->maxstore;
            if ($n > max(0, floor($cap - $have[$k]))) {
                header($back . '&e=2');
                exit;
            }
        }

        $gold = (int) ceil($total / TZ_CONTRACT_RES_PER_GOLD);
        list($limit, $used) = VillageGold::contractAllowance($database, $village->wid, $tzOffice);
        if ($used + $gold > $limit) {
            header($back . '&e=3');
            exit;
        }
        if (!$database->takeVillageGold($village->wid, $gold)) {
            header($back . '&e=4');
            exit;
        }

        $database->modifyResource($village->wid, $want['wood'], $want['clay'], $want['iron'], $want['crop'], 1);
        VillageGold::contractUse($database, $village->wid, $gold);
        $database->addGoldFinLog($village->wid, $session->uid, 'Resource contract', -$gold, number_format($total) . ' resources');
        $this->forget();

        header($back . '&ok=' . $gold);
        exit;
    }

    /**
     * NPC merchant trade.
     */
    private function tradeResource($post)
    {
        global $session, $database, $village;

        $wwvillage = $database->getResourceLevel($village->wid);

        // Prevent WW villages
        if ($wwvillage['f99t'] == 40) {
            return;
        }

        // Not enough gold (village gold when it pays, else 3 Plus gold)
        $tzNpcVillage = VillageGold::pays($village);
        if ($tzNpcVillage
            ? !VillageGold::canAfford($village, VillageGold::npcPrice())
            : $session->userinfo['gold'] < 3) {

            header('Location: build.php?id=' . $post['id'] . '&t=3');
            exit;
        }

        /**
         * PERMISIUNI SITTER: schimbul NPC costa 3 aur.
         *
         * Gardul TREBUIE sa fie aici, nu langa plata de la finalul functiei:
         * redistribuirea resurselor (setVillageField) se executa INAINTE de
         * scaderea aurului, deci un garda pus doar pe plata ar fi oferit
         * sitterului NPC gratuit.
         */
        if (isset($session) && method_exists($session, 'sitterCan')
            && !$session->sitterCan(SITTER_PERM_GOLD)) {

            header('Location: build.php?id=' . $post['id'] . '&t=3');
            exit;
        }

        // Sanitize the requested distribution: never negative, never above the
        // warehouse / granary capacity. Guards against a forged or NaN-corrupted
        // POST (issue #211: NPC distribution).
        $maxstore = (int) $village->maxstore;
        $maxcrop  = (int) $village->maxcrop;

        $m2 = [
            max(0, min($maxstore, (int)($post['m2'][0] ?? 0))),
            max(0, min($maxstore, (int)($post['m2'][1] ?? 0))),
            max(0, min($maxstore, (int)($post['m2'][2] ?? 0))),
            max(0, min($maxcrop,  (int)($post['m2'][3] ?? 0))),
        ];

        $newTotal = $m2[0] + $m2[1] + $m2[2] + $m2[3];

        $current = [
            round($village->awood),
            round($village->aclay),
            round($village->airon),
            round($village->acrop),
        ];
        $currentTotal = array_sum($current);

        // Local fix: the player distributes the stock shown when the page was
        // loaded (posted back as m1[]). The village keeps producing (or spending)
        // meanwhile, so the trade is checked against that snapshot and the change
        // since then is carried over per resource - nothing is lost or created.
        $m1 = [];
        for ($i = 0; $i < 4; $i++) {
            $m1[$i] = max(0, (int)($post['m1'][$i] ?? $current[$i]));
        }
        $snapTotal = array_sum($m1);

        // The snapshot cannot be more than the village has now (+ rounding), the
        // new distribution cannot be more than the snapshot, and it must not
        // throw resources away (up to 1 per resource for browser rounding).
        if ($snapTotal > $currentTotal + 4 || $newTotal > $snapTotal || $newTotal < $snapTotal - 4) {

            header('Location: build.php?id=' . $post['id'] . '&t=3');
            exit;
        }

        for ($i = 0; $i < 4; $i++) {
            $m2[$i] += $current[$i] - $m1[$i];
            if ($m2[$i] < 0) {
                // more was spent meanwhile than this trade leaves: start over
                header('Location: build.php?id=' . $post['id'] . '&t=3');
                exit;
            }
            $m2[$i] = min($i < 3 ? $maxstore : $maxcrop, $m2[$i]);
        }

        // village gold is taken first, in one guarded UPDATE
        if ($tzNpcVillage && !$database->takeVillageGold($village->wid, VillageGold::npcPrice())) {

            header('Location: build.php?id=' . $post['id'] . '&t=3');
            exit;
        }

        $database->setVillageField(
            $village->wid,
            ['wood', 'clay', 'iron', 'crop'],
            [
                $m2[0],
                $m2[1],
                $m2[2],
                $m2[3]
            ]
        );
		$this->forget();

        // permisiunea a fost verificata la intrarea in functie
        if (!$tzNpcVillage) {
            $database->spendGold($session->uid, 3, 'NPC merchant');
        }

        header('Location: build.php?id=' . $post['id'] . '&t=3&c');
        exit;
    }
}

$market = new Market;
?>