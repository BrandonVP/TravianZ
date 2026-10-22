<?php
include_once("GameEngine/Generator.php");
$start_timer = $generator->pageLoadTimeStart();

#################################################################################
##              -= YOU MAY NOT REMOVE OR CHANGE THIS NOTICE =-                 ##
## --------------------------------------------------------------------------- ##
##  Filename       : a2b2.php                      	                           ##
##  Type           : In Game Account Gold Statement                            ##
## --------------------------------------------------------------------------- ##
##  Developed by   : Shadow						                               ##
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

use App\Utils\AccessLogger;
include_once("GameEngine/Village.php");
AccessLogger::logRequest();

$uid = (int)$session->uid;
$amount = (int)($_SESSION['amount'] ?? 0);

$packages = [
    199  => 1500,
    499  => 3000,
    999  => 9000,
    1999 => 25000,
    4999 => 50000
];

if (isset($_GET['newdid'])) {
    $_SESSION['wid'] = (int)$_GET['newdid'];
    header("Location: a2b2.php");
    exit;
}

$building->procBuild($_GET);

$transactionProcessed = false;
$oldBalance = 0;
$newBalance = 0;
$goldAdded = 0;

if (isset($packages[$amount]) && $amount > 0) {
    $goldAdded = $packages[$amount];

    // local redesign: package gold goes to the capital
    $oldBalance = VillageGold::playerGold($database, $uid);
    VillageGold::grant($database, $uid, $goldAdded, 'Gold package', 'Package of ' . $goldAdded . ' gold');
    $newBalance = VillageGold::playerGold($database, $uid);

    $transactionProcessed = true;
    $_SESSION['amount'] = 0;
}
?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html>
<head>
    <title><?php echo SERVER_NAME . ' - Account transactions'; ?></title>
	<?php include("Templates/layout/assets.tpl"); ?>
    <script type="text/javascript">window.addEvent('domready', start);</script>
</head>
<?php include("Templates/layout/page_top.tpl"); ?>
        <?php include("Templates/Plus/pmenu.tpl"); ?>

        <h1>Account transactions</h1>
        
        <div id="products">
            <?php if ($transactionProcessed) { ?>
                <p>Thank you for your purchase here at <?php echo SERVER_NAME; ?>.</p>
                <p>Below you see the entry record. Out of it, you can observe your old as well as your new account balance.</p>
                
                <table class="plusFunctions" cellpadding="1" cellspacing="1">
                <thead>
                <tr><th colspan="5" height="20">Record of <?php echo date('d.m.Y'); ?></th></tr>
                <tr>
                    <td align="center">Description</td>
                    <td align="center"><svg class="tz-coin-sm" viewBox="0 0 24 24" aria-hidden="true"><circle cx="12" cy="12" r="10" fill="#e3b427" stroke="#9a7512" stroke-width="1.5"/><circle cx="12" cy="12" r="6.5" fill="none" stroke="#9a7512" stroke-width="1"/></svg></td>
                    <td align="center">Action</td>
                    <td align="center"><svg class="tz-coin-sm" viewBox="0 0 24 24" aria-hidden="true"><circle cx="12" cy="12" r="10" fill="#e3b427" stroke="#9a7512" stroke-width="1.5"/><circle cx="12" cy="12" r="6.5" fill="none" stroke="#9a7512" stroke-width="1"/></svg></td>
                    <td align="center">Date</td>
                </tr>
                </thead>
                <tbody>
                <tr>
                    <td class="desc"><b>&nbsp;&nbsp;Account Balance (old)</b></td>
                    <td class="desc"><div style="text-align:center"><?php echo $oldBalance; ?></div></td>
                    <td class="desc"><div style="text-align:center">&nbsp;</div></td>
                    <td class="desc"><div style="text-align:center">&nbsp;</div></td>
                    <td class="act"><div style="text-align:center">&nbsp;</div></td>
                </tr>
                <tr>
                    <td class="desc"><div style="text-align:center">&nbsp;</div></td>
                    <td class="desc"><div style="text-align:center">&nbsp;</div></td>
                    <td class="desc"><div style="text-align:center"><b><font color="#71D000">Package</font></b></div></td>
                    <td class="desc"><div style="text-align:center"><?php echo $goldAdded; ?> Gold</div></td>
                    <td class="act"><div style="text-align:center">&nbsp;</div></td>
                </tr>
                <tr>
                    <td class="desc"><b>&nbsp;&nbsp;Account Balance (new)</b></td>
                    <td class="desc"><div style="text-align:center">&nbsp;</div></td>
                    <td class="desc"><div style="text-align:center">&nbsp;</div></td>
                    <td class="desc"><div style="text-align:center"><?php echo $newBalance; ?></div></td>
                    <td class="act"><div style="text-align:center"><?php echo date('d.m.Y H:i:s'); ?></div></td>
                </tr>
                </tbody>
                </table>

                <p>Please verify the information.<br>It will let us know if the data is incorrect.</p>
                <p>Please mail your username, package, order time and email used to 
                <a href="mailto:<?php echo defined('PAYPAL_EMAIL') ? PAYPAL_EMAIL : 'novgorodschi@icloud.com'; ?>">our billing address</a>.</p>

            <?php } else { 
                // --- ISTORIC NORMAL CU FILTRU ---
                $result = mysqli_query($database->dblink, "SELECT gold FROM ".TB_PREFIX."users WHERE id = $uid LIMIT 1");
                $golds = mysqli_fetch_assoc($result);
// local redesign: the balance is the capital's gold
$golds['gold'] = VillageGold::playerGold($database, $uid);

                $stats = mysqli_fetch_assoc(mysqli_query($database->dblink, "
                    SELECT 
                        SUM(CASE WHEN gold > 0 THEN gold ELSE 0 END) as received,
                        SUM(CASE WHEN gold < 0 THEN -gold ELSE 0 END) as spent 
                    FROM ".TB_PREFIX."gold_fin_log WHERE uid = $uid
                "));
                $received = (int)($stats['received'] ?? 0);
                $spent    = (int)($stats['spent'] ?? 0);

                // FILTRU + PAGINARE
                $perPage = 25;
                $page = isset($_GET['p']) ? max(1,(int)$_GET['p']) : 1;
                $offset = ($page-1)*$perPage;
                $f = $_GET['f'] ?? 'all';

                $where = "l.uid = $uid";
                if($f==='in') $where .= " AND l.gold > 0";
                elseif($f==='out') $where .= " AND l.gold < 0";
                elseif($f==='gift') $where .= " AND (l.action LIKE '%Gift%' OR l.details LIKE '%gift%' OR l.details LIKE '%Admin%')";

                $countRes = mysqli_query($database->dblink, "SELECT COUNT(*) as c FROM ".TB_PREFIX."gold_fin_log l WHERE $where");
                $totalRows = (int)mysqli_fetch_assoc($countRes)['c'];
                $totalPages = max(1, ceil($totalRows / $perPage));
            ?>
                <!-- local redesign: filters and pages in the theme; gold now lives in the villages, so no account balance here -->
                <div class="tz-statement-bar">
                    <div class="tz-statement-filters">
                        <a href="a2b2.php?f=all" class="<?php echo $f=='all' ? 'is-on' : ''; ?>">All</a>
                        <a href="a2b2.php?f=in" class="tz-in <?php echo $f=='in' ? 'is-on' : ''; ?>">+ Incoming</a>
                        <a href="a2b2.php?f=out" class="tz-out <?php echo $f=='out' ? 'is-on' : ''; ?>">&minus; Outgoing</a>
                        <a href="a2b2.php?f=gift" class="tz-gift <?php echo $f=='gift' ? 'is-on' : ''; ?>">Gifts</a>
                    </div>
                    <form method="get" class="tz-statement-page">
                        <input type="hidden" name="f" value="<?php echo htmlspecialchars($f); ?>">
                        <select name="p" onchange="this.form.submit()">
                            <?php for($i=1;$i<=$totalPages;$i++){ echo '<option value="'.$i.'"'.($i==$page?' selected':'').'>Page '.$i.' / '.$totalPages.'</option>'; } ?>
                        </select>
                    </form>
                </div>
                <table class="plusFunctions" cellpadding="1" cellspacing="1">
                <thead>
                <tr><th colspan="5" height="20">Gold history (<?php echo $totalRows; ?>)</th></tr>
                <tr>
                    <td align="center">Date & Time</td>
                    <td align="center">Village</td>
                    <td align="center">Action</td>
                    <td align="center">Details</td>
                    <td align="center"><svg class="tz-coin-sm" viewBox="0 0 24 24" aria-hidden="true"><circle cx="12" cy="12" r="10" fill="#e3b427" stroke="#9a7512" stroke-width="1.5"/><circle cx="12" cy="12" r="6.5" fill="none" stroke="#9a7512" stroke-width="1"/></svg></td>
                </tr>
                </thead>
                <tbody>
                <?php
                $q = mysqli_query($database->dblink,
                    "SELECT l.*, v.name as vname
                     FROM ".TB_PREFIX."gold_fin_log l
                     LEFT JOIN ".TB_PREFIX."vdata v ON v.wref = l.wid
                     WHERE $where
                     ORDER BY l.time DESC
                     LIMIT $offset, $perPage");

                $sumBefore = 0;
                if($offset > 0){
                    $sumRes = mysqli_query($database->dblink,
                        "SELECT COALESCE(SUM(gold),0) as s FROM (
                            SELECT gold FROM ".TB_PREFIX."gold_fin_log l WHERE $where ORDER BY l.time DESC LIMIT $offset
                        ) t");
                    $sumBefore = (int)mysqli_fetch_assoc($sumRes)['s'];
                }
                $balance = (int)$golds['gold'] - $sumBefore;

                if(mysqli_num_rows($q) > 0){
                    while($r = mysqli_fetch_assoc($q)){
                        $date = date('d.m.Y H:i:s', $r['time']);
                        $villageName = !empty($r['vname']) ? htmlspecialchars($r['vname'], ENT_QUOTES, 'UTF-8') : '-';
                        $action = htmlspecialchars($r['action'], ENT_QUOTES, 'UTF-8');
                        $details = htmlspecialchars(($r['details'] ?? ''), ENT_QUOTES, 'UTF-8');
                        $gold = (int)$r['gold'];

                        if(stripos($details,'Mass gift')!==false){ $action='Admin Gift (All)'; $details=str_replace('Mass gift by ','by ',$details); }
                        elseif(stripos($details,'gift by')!==false){ $action='Admin Gift'; }

                        $cls = $gold < 0 ? 'tz-st-out' : 'tz-st-in';
                        $sign = $gold > 0 ? '+' : '';

                        echo '<tr>';
                        echo '<td class="desc"><div style="text-align:center">'.$date.'</div></td>';
                        echo '<td class="desc"><div style="text-align:center">'.$villageName.'</div></td>';
                        echo '<td class="desc"><div style="text-align:center"><b>'.$action.'</b></div></td>';
                        echo '<td class="desc tz-st-details">'.$details.'</td>';
                        echo '<td class="desc '.$cls.'"><b>'.$sign.$gold.'</b></td>';
                        echo '</tr>';
                        $balance -= $gold;
                    }
                } else {
                    echo '<tr><td colspan="5" class="desc"><div style="text-align:center;padding:8px;">No transactions yet.</div></td></tr>';
                }
                ?>
                </tbody>
                </table>


            <?php } ?>
        </div>
    </div>

    <br /><br /><br /><br />
    <?php include("Templates/layout/page_bottom.tpl"); ?>