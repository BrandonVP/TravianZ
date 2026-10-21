<?php
#################################################################################
##  Local redesign: Resource contracts - buy resources from the NPC with this  ##
##  village's gold (Market::buyContract). Rate and daily allowance:           ##
##  GameEngine/Data/gold.php (TZ_CONTRACT_*).                                  ##
#################################################################################

global $database, $session, $village, $building, $id;

if (!VillageGold::pays($village)) {
    header("Location: build.php?id=" . (int) $id);
    exit;
}

$tzRate = (int) TZ_CONTRACT_RES_PER_GOLD;
list($tzLimit, $tzUsed) = VillageGold::contractAllowance($database, $village->wid, $building->getTypeLevel(17));
$tzLeft = max(0, $tzLimit - $tzUsed);
$tzGold = (int) floor($village->agold);
$tzFree = [
    1 => max(0, (int) floor($village->maxstore - $village->awood)),
    2 => max(0, (int) floor($village->maxstore - $village->aclay)),
    3 => max(0, (int) floor($village->maxstore - $village->airon)),
    4 => max(0, (int) floor($village->maxcrop - $village->acrop)),
];
$tzNames = [1 => LUMBER, 2 => CLAY, 3 => IRON, 4 => CROP];
$tzErr = [1 => 'Contracts are paid with village gold, and your sitter permissions do not allow it.',
          2 => 'That does not fit in your storage. Buy less, or make room first.',
          3 => 'That is more than this village\'s daily contract allowance.',
          4 => 'Not enough gold in this village.'];
$tzCoin = '<svg class="tz-coin-sm" viewBox="0 0 24 24" aria-hidden="true"><circle cx="12" cy="12" r="10" fill="#e3b427" stroke="#9a7512" stroke-width="1.5"/><circle cx="12" cy="12" r="6.5" fill="none" stroke="#9a7512" stroke-width="1"/></svg>';
?>
<div id="build" class="gid17">
    <a href="#" onClick="return Popup(17,4);" class="build_logo">
        <img class="building g17" src="img/x.gif" alt="<?php echo MARKETPLACE; ?>" title="<?php echo MARKETPLACE;?>" />
    </a>
    <h1><?php echo MARKETPLACE;?> <span class="level"><?php echo LEVEL;?> <?php echo (int)$village->resarray['f'.$id];?></span></h1>
    <p class="build_desc"><?php echo MARKETPLACE_DESC;?></p>

    <?php include("17_menu.tpl");?>

    <p class="tz-contract-intro">
        Buy resources from the NPC merchant with this village's gold:
        <b><?php echo $tzCoin; ?> 1 gold = <?php echo $tzRate; ?> resources</b>, delivered at once.
        Each village can spend up to <b><?php echo number_format($tzLimit); ?></b> gold a day on contracts
        (Marketplace level &times; <?php echo (int) TZ_CONTRACT_GOLD_PER_LEVEL; ?>).
    </p>

    <?php if (isset($_GET['ok'])):?>
        <p class="tz-contract-ok">Contract signed: <?php echo $tzCoin . number_format((int) $_GET['ok']); ?> gold spent, resources delivered.</p>
    <?php elseif (isset($_GET['e'], $tzErr[(int) $_GET['e']])):?>
        <p class="error2"><?php echo $tzErr[(int) $_GET['e']]; ?></p>
    <?php endif;?>

    <form method="post" action="build.php" name="contract">
        <input type="hidden" name="ft" value="mk5">
        <input type="hidden" name="id" value="<?php echo (int) $id;?>">
        <table class="tz-contract" cellpadding="1" cellspacing="1">
            <thead>
                <tr><th></th><th>Resource</th><th>Buy</th><th>Room in storage</th></tr>
            </thead>
            <tbody>
            <?php for ($i = 1; $i <= 4; $i++):?>
                <tr>
                    <td><img class="r<?php echo $i;?>" src="img/x.gif" alt="" /></td>
                    <td class="tz-l"><?php echo $tzNames[$i];?></td>
                    <td><input class="text" type="text" name="r<?php echo $i;?>" id="cr<?php echo $i;?>" value="" maxlength="8" onkeyup="tzContract()"></td>
                    <td><a href="#" onclick="document.getElementById('cr<?php echo $i;?>').value = <?php echo $tzFree[$i];?>; tzContract(); return false;"><?php echo number_format($tzFree[$i]);?></a></td>
                </tr>
            <?php endfor;?>
            </tbody>
            <tfoot>
                <tr>
                    <td colspan="4">
                        Cost: <b><?php echo $tzCoin; ?><span id="tzContractCost">0</span></b> gold
                        &middot; this village has <?php echo $tzCoin . number_format($tzGold); ?>
                        &middot; allowance left today: <?php echo $tzCoin . number_format($tzLeft); ?>
                    </td>
                </tr>
            </tfoot>
        </table>
        <p><button type="submit" class="tz-btn" id="tzContractBtn">Sign contract</button></p>
    </form>
</div>
<script type="text/javascript">
function tzContract() {
    var total = 0;
    for (var i = 1; i <= 4; i++) {
        var v = parseInt(document.getElementById('cr' + i).value, 10);
        if (!isNaN(v) && v > 0) total += v;
    }
    var cost = Math.ceil(total / <?php echo $tzRate; ?>);
    document.getElementById('tzContractCost').textContent = cost;
    document.getElementById('tzContractBtn').disabled = (cost <= 0 || cost > <?php echo (int) min($tzGold, $tzLeft); ?>);
}
tzContract();
</script>
