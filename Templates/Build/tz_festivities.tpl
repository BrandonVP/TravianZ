<?php
/**
 * Local redesign: Festivities tab of the Residence / Palace / Command Center
 * (GameEngine/Festivities.php). Included by 25_5.tpl, 26_5.tpl and 44_5.tpl.
 */
global $village, $database, $session, $building, $generator, $id;
include_once __DIR__ . '/../../GameEngine/Festivities.php';

$tzLevels = [
    'res'     => (int) $village->resarray['f' . $id],
    'academy' => (int) $building->getTypeLevel(22),
    'mb'      => (int) $building->getTypeLevel(15),
];
$tzMsg = '';
$tzOk = false;
if (isset($_POST['tzfest']) && hash_equals((string) $session->checker, (string) ($_POST['c'] ?? ''))
    && (!method_exists($session, 'sitterCan') || $session->sitterCan(SITTER_PERM_GOLD))) {
    $tzErr = Festivities::start($database, $village, $session->uid, (string) $_POST['tzfest'], $tzLevels);
    $tzOk = ($tzErr === '');
    $defs = Festivities::defs();
    $tzMsg = $tzOk ? ($defs[$_POST['tzfest']]['name'] . ' has begun.') : $tzErr;
    if ($tzOk) {
        // the page above was drawn before paying: show the new amounts
        $village->awood -= $defs[$_POST['tzfest']]['cost'][0];
        $village->aclay -= $defs[$_POST['tzfest']]['cost'][1];
        $village->airon -= $defs[$_POST['tzfest']]['cost'][2];
        $village->acrop -= $defs[$_POST['tzfest']]['cost'][3];
        $village->agold -= $defs[$_POST['tzfest']]['cost'][4];
    }
}

$tzRows = Festivities::state($database, $village->wid);
$tzLoyalty = floor((float) $database->getVillageField($village->wid, 'loyalty'));
$tzCap = Festivities::loyaltyCap($database, $village->wid);
$tzCoin = '<svg class="tz-coin-sm" viewBox="0 0 24 24" aria-hidden="true"><circle cx="12" cy="12" r="10" fill="#e3b427" stroke="#9a7512" stroke-width="1.5"/><circle cx="12" cy="12" r="6.5" fill="none" stroke="#9a7512" stroke-width="1"/></svg>';
$tzResIcons = ['<img class="r1" src="img/x.gif" alt="Lumber" title="Lumber" />', '<img class="r2" src="img/x.gif" alt="Clay" title="Clay" />',
               '<img class="r3" src="img/x.gif" alt="Iron" title="Iron" />', '<img class="r4" src="img/x.gif" alt="Crop" title="Crop" />', $tzCoin];
?>
<div class="tz-fest">
    <p class="tz-fest-intro">Once a week each of these can be held in this village. Loyalty now
        <b><?php echo $tzLoyalty; ?></b><?php echo $tzCap > 100 ? ' (cap ' . $tzCap . ' while the players stay)' : ''; ?>.</p>
    <?php if ($tzMsg !== ''): ?>
        <p class="<?php echo $tzOk ? 'tz-fest-ok' : 'tz-fest-err'; ?>"><?php echo htmlspecialchars($tzMsg); ?></p>
    <?php endif; ?>

    <?php foreach (['loyalty' => 'Loyalty', 'culture' => 'Culture'] as $tzGroup => $tzTitle): ?>
    <h3 class="tz-fest-group"><?php echo $tzTitle; ?></h3>
    <div class="tz-fest-grid">
        <?php foreach (Festivities::defs() as $tzKind => $tzDef): if ($tzDef['kind'] !== $tzGroup) continue;
            $tzRow = $tzRows[$tzKind] ?? null;
            $tzNow = time();
            $tzRunning = $tzRow && (int) $tzRow['until'] > $tzNow;
            $tzBlock = Festivities::blocker($database, $village, $session->uid, $tzKind, $tzLevels, $tzRow);
            $tzCost = [];
            foreach ($tzDef['cost'] as $i => $n) if ($n > 0) $tzCost[] = $tzResIcons[$i] . number_format($n);
        ?>
        <div class="tz-fest-card<?php echo $tzRunning ? ' is-on' : ''; ?>">
            <h4><?php echo htmlspecialchars($tzDef['name']); ?></h4>
            <p class="tz-fest-story"><?php echo htmlspecialchars($tzDef['story']); ?></p>
            <p class="tz-fest-effect"><?php echo htmlspecialchars($tzDef['effect']); ?></p>
            <p class="tz-fest-use"><?php echo htmlspecialchars($tzDef['use']); ?></p>
            <?php if ($tzKind === 'monument'): ?>
                <p class="tz-fest-use">Carving time <?php echo $generator->getTimeFormat(Festivities::carveTime()); ?>;
                    here worth <b><?php echo $tzLevels['mb'] * TZ_MONUMENT_CP_PER_MB; ?></b> culture points.</p>
            <?php endif; ?>
            <div class="tz-fest-cost"><?php echo implode(' | ', $tzCost); ?></div>
            <?php if ($tzRunning): ?>
                <p class="tz-fest-state"><?php echo $tzKind === 'monument' ? 'Being carved - unveiled' : 'Under way until'; ?>
                    <?php echo date('d.m. H:i', (int) $tzRow['until']); ?>
                    (<span id="timer<?php echo ++$session->timer; ?>"><?php echo $generator->getTimeFormat((int) $tzRow['until'] - $tzNow); ?></span>)</p>
            <?php elseif ($tzBlock !== ''): ?>
                <p class="tz-fest-blocked"><?php echo htmlspecialchars($tzBlock); ?></p>
            <?php else: ?>
                <form method="post" action="build.php?id=<?php echo (int) $id; ?>&amp;s=5"
                      onsubmit="return confirm('<?php echo htmlspecialchars(addslashes('Hold the ' . $tzDef['name'] . ' now?'), ENT_QUOTES); ?>');">
                    <input type="hidden" name="tzfest" value="<?php echo $tzKind; ?>">
                    <input type="hidden" name="c" value="<?php echo htmlspecialchars((string) $session->checker); ?>">
                    <button type="submit" class="tz-btn tz-btn-sm">Hold the <?php echo htmlspecialchars($tzDef['name']); ?></button>
                </form>
            <?php endif; ?>
        </div>
        <?php endforeach; ?>
    </div>
    <?php endforeach; ?>
</div>
