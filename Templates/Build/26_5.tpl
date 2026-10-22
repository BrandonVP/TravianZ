<?php
// local redesign: Festivities tab (Templates/Build/tz_festivities.tpl, GameEngine/Festivities.php)
global $village, $id;
$level = (int)$village->resarray['f'.$id];
?>
<div id="build" class="gid26">
    <h1><?php echo PALACE;?> <span class="level"><?php echo LEVEL;?> <?php echo $level;?></span></h1>
    <p class="build_desc">
        <a href="#" onClick="return Popup(26,4, 'gid');" class="build_logo">
            <img class="building g26" src="img/x.gif" alt="<?php echo PALACE; ?>" title="<?php echo PALACE;?>" />
        </a>
        <?php echo PALACE_DESC;?>
    </p>

    <?php include("26_menu.tpl"); ?>

    <?php include("tz_festivities.tpl"); ?>
</div>
