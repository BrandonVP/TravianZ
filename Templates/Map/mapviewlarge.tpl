<?php

#################################################################################
##              -= YOU MAY NOT REMOVE OR CHANGE THIS NOTICE =-                 ##
## --------------------------------------------------------------------------- ##
##  Filename       : mapscroll2.tpl                      	                   ##
##  Type           : Karte Map Scroll Large Backend                            ##
## --------------------------------------------------------------------------- ##
##  Developed by   : Dzoki & Advocaite & Donnchadh                             ##
##  Refactored by  : Shadow & Ferywir									       ##
##  Redesign by    : Shadow                                                    ##
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

/* =========================
   WORLD CONFIG SHORTCUT
========================= */
$W = WORLD_MAX;

/* =========================
   COORDINATE INPUT HANDLING
========================= */
if (isset($_GET['z'])) {

    $currentcoor = $database->getCoor($_GET['z']);
    $y = $currentcoor['y'];
    $x = $currentcoor['x'];
    $bigmid = $_GET['z'];

} else if (isset($_POST['xp']) && isset($_POST['yp'])) {

    $x = $_POST['xp'];
    $y = $_POST['yp'];
    $bigmid = $generator->getBaseID($x, $y);

} else {

    $y = $village->coor['y'];
    $x = $village->coor['x'];
    $bigmid = $village->wid;
}

/* =========================
   RESET MOVEMENTS CACHE
========================= */
if (isset($_SESSION['troops_movement'])) {
    unset($_SESSION['troops_movement']);
}

/* =========================
   PLUS ACCOUNT ATTACK DATA
========================= */
if ($session->plus) {
    $session->populateAttacks();
}

/* =========================
   MAP SIZE (local redesign: 13, 15 or 17 tiles a side, picked by the
   popup from the window size; the geometry below is computed from it)
========================= */
$N = isset($_GET['n']) ? (int)$_GET['n'] : 13;
if (!in_array($N, array(13, 15, 17))) {
    $N = 13;
}
$R = ($N - 1) / 2;

/* =========================
   MAP COORDINATES CALCULATION
========================= */
$wrap = function ($v) use ($W) {
    if ($v < -$W) $v += 2 * $W + 1;
    if ($v > $W) $v -= 2 * $W + 1;
    return $v;
};

$xm1 = $wrap($x - 1); $xp1 = $wrap($x + 1);
$ym1 = $wrap($y - 1); $yp1 = $wrap($y + 1);
// page jumps (navibox) move a whole map width, like the JS does
$xmN = $wrap($x - $N); $xpN = $wrap($x + $N);
$ymN = $wrap($y - $N); $ypN = $wrap($y + $N);

/* =========================
   MAP GRID ARRAYS
========================= */
$xarray = array();
$yarray = array();
for ($k = -$R; $k <= $R; $k++) {
    $xarray[] = $wrap($x + $k);
    $yarray[] = $wrap($y + $k);
}

$maparray = '';
$maparray2 = '';

for ($xcount = 0; $xcount < $N; $xcount++) {
    for ($i = 0; $i < $N; $i++) {
        $id = $generator->getBaseID($xarray[$xcount], $yarray[$i]);

        $maparray  .= "'" . $id . "',";
        $maparray2 .= $id . ",";
    }
}

$maparray  = substr($maparray, 0, -1);
$maparray2 = substr($maparray2, 0, -1);

/* =========================
   MAIN MAP QUERY
========================= */
$query2 = "
SELECT
    " . TB_PREFIX . "wdata.id AS map_id,
    " . TB_PREFIX . "wdata.fieldtype AS map_fieldtype,
    " . TB_PREFIX . "wdata.oasistype AS map_oasis,
    " . TB_PREFIX . "wdata.x AS map_x,
    " . TB_PREFIX . "wdata.y AS map_y,
    " . TB_PREFIX . "wdata.occupied AS map_occupied,
    " . TB_PREFIX . "wdata.image AS map_image,

    " . TB_PREFIX . "odata.conqured AS oasis_conqured,
    info_user_oasis.username AS oasis_user,
    info_user_oasis.tribe AS oasis_tribe,
    info_alliance_oasis.tag AS oasis_alli_name,

    " . TB_PREFIX . "vdata.wref AS ville_id,
    " . TB_PREFIX . "vdata.owner AS ville_user,
    " . TB_PREFIX . "vdata.name AS ville_name,
    " . TB_PREFIX . "vdata.capital AS ville_capital,
    " . TB_PREFIX . "vdata.pop AS ville_pop,

    " . TB_PREFIX . "users.id AS user_id,
    " . TB_PREFIX . "users.username AS user_username,
    " . TB_PREFIX . "users.tribe AS user_tribe,
    " . TB_PREFIX . "users.alliance AS user_alliance,

    " . TB_PREFIX . "alidata.id AS aliance_id,
    " . TB_PREFIX . "alidata.tag AS aliance_name

FROM ((((((" . TB_PREFIX . "wdata
    LEFT JOIN " . TB_PREFIX . "vdata ON " . TB_PREFIX . "vdata.wref = " . TB_PREFIX . "wdata.id)
    LEFT JOIN " . TB_PREFIX . "odata ON " . TB_PREFIX . "odata.wref = " . TB_PREFIX . "wdata.id)
    LEFT JOIN " . TB_PREFIX . "users AS info_user_oasis ON info_user_oasis.id = " . TB_PREFIX . "odata.owner)
    LEFT JOIN " . TB_PREFIX . "alidata AS info_alliance_oasis ON info_alliance_oasis.id = info_user_oasis.alliance)
    LEFT JOIN " . TB_PREFIX . "users ON " . TB_PREFIX . "users.id = " . TB_PREFIX . "vdata.owner)
    LEFT JOIN " . TB_PREFIX . "alidata ON " . TB_PREFIX . "alidata.id = " . TB_PREFIX . "users.alliance)

WHERE " . TB_PREFIX . "wdata.id IN ($maparray)
ORDER BY FIND_IN_SET(" . TB_PREFIX . "wdata.id,'$maparray2')
";

$result2 = mysqli_query($database->dblink, $query2) or die(mysqli_error($database->dblink));

/* =========================
   OUTPUT PREPARATION
========================= */
$targetalliance = array();
$neutralarray = array();
$friendarray = array();
$enemyarray = array();

$i = 0;
$i2 = 0;

/* =========================
   OUTPUT VARS
========================= */
$yrow = 0;
$row = 0;
$coorindex = 0;

$map_js = '';
$map_content = '';
$map_gen = '';

/* =========================
   TILE GEOMETRY
   tile (row, i): left = 11 + 37*row + 36*i, top = T0 + 20*row - 20*i;
   the click area is the diamond in its lower part
========================= */
$T0 = 20 * ($N - 1) - 20;
$tileLeft = function ($row, $i) { return 11 + 37 * $row + 36 * $i; };
$tileTop = function ($row, $i) use ($T0) { return $T0 + 20 * $row - 20 * $i; };

$coorarray = array();
for ($r = 0; $r < $N; $r++) {
    for ($c = 0; $c < $N; $c++) {
        $L = $tileLeft($r, $c);
        $T = $tileTop($r, $c);
        $coorarray[] = ($L + 37) . ", " . ($T + 33) . ", " . ($L + 74) . ", " . ($T + 53) . ", " . ($L + 37) . ", " . ($T + 73) . ", " . $L . ", " . ($T + 53);
    }
}

/* frame sizes (13: map 971 x 550 inside a 1000 x 575 frame) */
$mapW = 73 * ($N - 1) + 95;
$mapH = 40 * ($N - 1) + 70;

/* the four scroll arrows sit just outside the middle of each diamond edge */
$dTop    = array(48 + 36 * ($N - 1), 13);
$dLeft   = array(11, 20 * ($N - 1) + 33);
$dRight  = array(85 + 73 * ($N - 1), 20 * ($N - 1) + 33);
$dBottom = array(48 + 37 * ($N - 1), 40 * ($N - 1) + 53);
$arrowAt = function ($a, $b, $dx, $dy) {
    return round(($a[0] + $b[0]) / 2 + $dx) . "," . round(($a[1] + $b[1]) / 2 + $dy) . ",30";
};

/* =========================
   MAIN LOOP (UNCHANGED LOGIC)
========================= */
while ($donnees = mysqli_fetch_assoc($result2)) {

    $targetalliance = $donnees["aliance_id"];

	$sessionAlliance = (int)$session->alliance;

	$allyCache = $database->getAllianceAlly($sessionAlliance, 1)?: [];
	$warCache = $database->getAllianceWar2($sessionAlliance)?: [];
	$neutralCache = $database->getAllianceAlly($sessionAlliance, 2)?: [];

	$target = (int)$donnees["aliance_id"];

    /* =========================
       RELATION STATUS
    ========================= */
	
	$friend = $war = $neutral = 0;

	if ($target && $sessionAlliance) {
    foreach ($allyCache as $ac) {
        if ((($ac['alli1']?? 0) == $target) || (($ac['alli2']?? 0) == $target)) { $friend = 1; break; }
    }
    foreach ($warCache as $wc) {
        if ((($wc['alli1']?? 0) == $target) || (($wc['alli2']?? 0) == $target)) { $war = 1; break; }
    }
    foreach ($neutralCache as $nc) {
        if ((($nc['alli1']?? 0) == $target) || (($nc['alli2']?? 0) == $target)) { $neutral = 1; break; }
    }
	}

    /* =========================
       IMAGE DECISION
    ========================= */
    $image = ($donnees['map_occupied'] == 1 && $donnees['map_fieldtype'] > 0)
        ? (($donnees['ville_user'] == $session->uid)
            ? ($donnees['ville_pop'] >= 100
                ? ($donnees['ville_pop'] >= 250
                    ? ($donnees['ville_pop'] >= 500 ? 'b30' : 'b20')
                    : 'b10')
                : 'b00')
            : (($targetalliance != 0)
                ? ($friend == 1
                    ? ($donnees['ville_pop'] >= 100
                        ? ($donnees['ville_pop'] >= 250
                            ? ($donnees['ville_pop'] >= 500 ? 'b31' : 'b21')
                            : 'b11')
                        : 'b01')
                    : ($war == 1
                        ? ($donnees['ville_pop'] >= 100
                            ? ($donnees['ville_pop'] >= 250
                                ? ($donnees['ville_pop'] >= 500 ? 'b32' : 'b22')
                                : 'b12')
                            : 'b02')
                        : ($neutral == 1
                            ? ($donnees['ville_pop'] >= 100
                                ? ($donnees['ville_pop'] >= 250
                                    ? ($donnees['ville_pop'] >= 500 ? 'b35' : 'b25')
                                    : 'b15')
                                : 'b05')
                            : ($targetalliance == $session->alliance
                                ? ($donnees['ville_pop'] >= 100
                                    ? ($donnees['ville_pop'] >= 250
                                        ? ($donnees['ville_pop'] >= 500 ? 'b33' : 'b23')
                                        : 'b13')
                                    : 'b03')
                                : ($donnees['ville_pop'] >= 100
                                    ? ($donnees['ville_pop'] >= 250
                                        ? ($donnees['ville_pop'] >= 500 ? 'b34' : 'b24')
                                        : 'b14')
                                    : 'b04')))))
                : ($donnees['ville_pop'] >= 100
                    ? ($donnees['ville_pop'] >= 250
                        ? ($donnees['ville_pop'] >= 500 ? 'b34' : 'b24')
                        : 'b14')
                    : 'b04')))
        : $donnees['map_image'];

    /* =========================
       ATTACK MARKERS
    ========================= */
    $att = "";

    if (isset($_SESSION['troops_movement'])) {

        if (isset($_SESSION['troops_movement']['attacks']) &&
            in_array($donnees['map_id'], $_SESSION['troops_movement']['attacks'])) {

            $att = '<span class=\'m3\' ></span>';

        } elseif (isset($_SESSION['troops_movement']['scouts']) &&
            in_array($donnees['map_id'], $_SESSION['troops_movement']['scouts'])) {

            $att = '<span class=\'m6\' ></span>';

        } elseif (isset($_SESSION['troops_movement']['enforcements']) &&
            in_array($donnees['map_id'], $_SESSION['troops_movement']['enforcements'])) {

            $att = '<span class=\'m9\' ></span>';
        }
    }

    /* =========================
       MAP CONTENT
    ========================= */
    $tileStyle = " style='left:" . $tileLeft($row, $i) . "px;top:" . $tileTop($row, $i) . "px;z-index:" . (max($row, $i) + 1) . "'";

    if ($donnees['ville_user'] == 3 && $donnees['ville_name'] == 'WW Buildingplan') {

        $map_content .= "<div id='i_" . $row . "_" . $i . "' class='o99'" . $tileStyle . ">$att</div>\r";

    } else {

        $map_content .= "<div id='i_" . $row . "_" . $i . "' class='" . $image . "'" . $tileStyle . ">$att</div>\r";
    }

    /* =========================
       AREA GENERATION
    ========================= */
    $map_gen .= "<area id='a_" . $row . "_" . $i . "' shape='poly' coords='" . $coorarray[$coorindex] . "' title='" . $donnees['ville_name'] . "' href='karte.php?d=" . $donnees['map_id'] . "&c=" . $generator->getMapCheck($donnees['map_id']) . "' target='_parent' />\n";

    /* =========================
       JS MAP DATA
    ========================= */
    if ($yrow != $N) {

        $map_js .= "[" . $donnees['map_x'] . "," . $donnees['map_y'] . "," . $donnees['map_fieldtype'] . "," . ((!empty($donnees['map_oasis'])) ? $donnees['map_oasis'] : 0) . ",\"d=" . $donnees['map_id'] . "&c=" . $generator->getMapCheck($donnees['map_id']) . "\",\"" . $image . "\",\"\"";

        if ($donnees['map_occupied']) {

            if ($donnees['map_fieldtype'] != 0) {

                $map_js .= ",\"" . $donnees['ville_name'] . "\",\"" . $donnees['user_username'] . "\",\"" . $donnees['ville_pop'] . "\",\"" . $donnees['aliance_name'] . "\",\"" . $donnees['user_tribe'] . "\"]\n";
            }

        } elseif ($donnees['map_oasis'] != 0) {

            if ($donnees['oasis_conqured'] != 0) {

                $map_js .= ",\"\",\"" . $donnees['oasis_user'] . "\",\"-\",\"" . $donnees['oasis_alli_name'] . "\",\"" . $donnees['oasis_tribe'] . "\"]";

            } else {

                $map_js .= "]";
            }

        } else {

            $map_js .= "]\n";
        }

        if ($i2 == $N - 1 && $yrow != $N - 1) {

            $i2 = -1;
            $yrow++;

            $map_js .= "],\n[";

        } else {

            $map_js .= ($yrow == $N - 1 && $i2 == $N - 1) ? "]\n" : ",";
        }

    } else {

        $map_js .= "]";
    }

    /* =========================
       LOOP CONTROL
    ========================= */
    if ($i == $N - 1 && $row <= $N - 2) {

        $row++;
        $i = -1;
    }

    $i++;
    $i2++;
    $coorindex++;
}
?>


<?php
$bg = ($N != 13) ? "background-image:url(img/tz/mapl" . $N . ".gif);" : "";
?>
<div id="map_content">
	<div id="mbig" style="width:<?php echo $mapW + 29; ?>px;height:<?php echo $mapH + 25; ?>px">
		<div id="lightframe" style="width:<?php echo $mapW + 8; ?>px;height:<?php echo $mapH + 4; ?>px">
			<div id="darkframe" style="width:<?php echo $mapW + 4; ?>px;height:<?php echo $mapH; ?>px"><a id="map_popclose" href="#" title="<?php echo CLOSE_MAP; ?>" onClick="var pb=null;try{pb=(window.parent!==window?window.parent:window).document.getElementById('drag2');}catch(e){}if(pb!=null){pb.innerHTML='';}else{window.close();};return false;"><img src="img/x.gif" alt="<?php echo CLOSE_MAP; ?>" title="<?php echo CLOSE_MAP; ?>"></a>
				<h1>Map(<span id="x"><?php echo $x;?></span>|<span id="y"><?php echo $y;?></span>)</h1>
				<div id="map" style="width:<?php echo $mapW + 4; ?>px;height:<?php echo $mapH; ?>px;<?php echo $bg; ?>">
					<script type="text/javascript">
						var text_k = {}
						text_k.details = '<?php echo DETAIL;?>';
						text_k.spieler = '<?php echo PLAYER;?>';
						text_k.einwohner = '<?php echo POP;?>';
						text_k.allianz = '<?php echo ALLIANCE;?>';
						text_k.verlassenes_tal = '<?php echo ABANDVALLEY;?>';
						text_k.besetztes_tal = '<?php echo OCCUOASIS;?>';
						text_k.freie_oase = '<?php echo UNOCCUOASIS;?>';
						var text_x = {}
						text_x.r1 = '<?php echo LUMBER;?>';
						text_x.r2 = '<?php echo CLAY;?>';
						text_x.r3 = '<?php echo IRON;?>';
						text_x.r4 = '<?php echo CROP;?>';
					</script>
					<div id="map_content" style="width:<?php echo $mapW; ?>px;height:<?php echo $mapH; ?>px">
						<?php echo $map_content;?>
						
					</div>
					<div id="map_rulers" style="width:<?php echo $mapW; ?>px;height:<?php echo $mapH; ?>px"><?php
						for($i=0;$i<$N;$i++){
						echo "<div id=\"mx".$i."\" style=\"left:".(4+36*$i)."px;top:".round($T0+68+20.08*$i)."px\">".$xarray[$i]."</div>\n";
						echo "<div id=\"my".$i."\" style=\"left:".(4+36*$i)."px;top:".round($T0+24-20.08*$i)."px\">".$yarray[$i]."</div>\n";
						}?>
					</div>
					<map id="map_overlay_large" name="map_overlay_large"> 
						<?php echo $map_gen;?>
						<area id="ma_n1" href="karte2.php?n=<?php echo $N; ?>&amp;z=<?php echo $generator->getBaseID($x,$yp1);?>" coords="<?php echo $arrowAt($dTop, $dRight, 42, -28); ?>" shape="circle" title="<?php echo NORTH; ?>"/>
						<area id="ma_n2" href="karte2.php?n=<?php echo $N; ?>&amp;z=<?php echo $generator->getBaseID($xp1,$y);?>" coords="<?php echo $arrowAt($dRight, $dBottom, 44, 27); ?>" shape="circle" title="<?php echo EAST; ?>"/>
						<area id="ma_n3" href="karte2.php?n=<?php echo $N; ?>&amp;z=<?php echo $generator->getBaseID($x,$ym1);?>" coords="<?php echo $arrowAt($dBottom, $dLeft, -41, 27); ?>" shape="circle" title="<?php echo SOUTH; ?>"/>
						<area id="ma_n4" href="karte2.php?n=<?php echo $N; ?>&amp;z=<?php echo $generator->getBaseID($xm1,$y);?>" coords="<?php echo $arrowAt($dLeft, $dTop, -45, -28); ?>" shape="circle" title="<?php echo WEST; ?>"/>
					</map>
					<img id="map_links" src="img/x.gif" usemap="#map_overlay_large" style="width:<?php echo $mapW; ?>px;height:<?php echo $mapH; ?>px">
					<script type="text/javascript">
						m_c.az = {"n1":<?php echo $generator->getBaseID($x,$yp1) ?>,"n1p7":<?php echo $generator->getBaseID($x,$ypN) ?>,"n2":<?php echo $generator->getBaseID($xp1,$y) ?>,"n2p7":<?php echo $generator->getBaseID($xmN,$y) ?>,"n3":<?php echo $generator->getBaseID($x,$ym1) ?>,"n3p7":<?php echo $generator->getBaseID($x,$ymN) ?>,"n4":<?php echo $generator->getBaseID($xm1,$y) ?>,"n4p7":<?php echo $generator->getBaseID($xpN,$y) ?>};
						m_c.ad = [[<?php echo $map_js?>];
						m_c.z = {"x":<?php echo $x ?>,"y":<?php echo $y ?>};
						m_c.size = <?php echo $N; ?>;
						m_c.world_max = <?php echo WORLD_MAX; ?>;
						var mdim = {"x":<?php echo $N; ?>,"y":<?php echo $N; ?>,"rad":<?php echo $R; ?>}
						var mmode = 0;
						function init_local(){map_init();}
					</script>
					<img id="map_navibox" src="img/x.gif" usemap="#map_navibox"/>
					<map name="map_navibox">
						<area id="ma_n1p7" href="karte2.php?n=<?php echo $N; ?>&amp;z=<?php echo $generator->getBaseID($x,$ypN) ?>" coords="51,15,73,3,95,15,73,27" shape="poly" title="<?php echo NORTH; ?>"/>
						<area id="ma_n2p7" href="karte2.php?n=<?php echo $N; ?>&amp;z=<?php echo $generator->getBaseID($xmN,$y) ?>" coords="51,41,73,29,95,41,73,53" shape="poly" title="<?php echo EAST; ?>"/>
						<area id="ma_n3p7" href="karte2.php?n=<?php echo $N; ?>&amp;z=<?php echo $generator->getBaseID($x,$ymN) ?>" coords="4,41,26,29,48,41,26,53" shape="poly" title="<?php echo SOUTH; ?>"/>
						<area id="ma_n4p7" href="karte2.php?n=<?php echo $N; ?>&amp;z=<?php echo $generator->getBaseID($xpN,$y) ?>" coords="4,15,26,3,48,15,26,27" shape="poly" title="<?php echo WEST; ?>"/>
					</map>
					<div id="map_coords">
						<form name="map_coords" method="post" >
							<span>x </span><input id="mcx" class="text" name="xp" value="<?php echo $x ?>" maxlength="4"/>
							<span>y </span><input id="mcy" class="text" name="yp" value="<?php echo $y ?>" maxlength="4"/>
							<input type="image" id="btn_ok" class="dynamic_img" value="ok" name="s1" src="img/x.gif" alt="OK" />
						</form>
					</div>
					<table cellpadding="1" cellspacing="1" id="map_infobox" class="default"><thead><tr><th colspan="2"><?php echo DETAIL;?></th></tr></thead><tbody><tr><th><?php echo PLAYER;?></th><td>-</td></tr><tr><th><?php echo POP;?></th><td>-</td></tr><tr><th><?php echo ALLIANCE;?></th><td></td></tr></tbody></table>
				</div>
			</div>
		</div>
	</div>
</div>