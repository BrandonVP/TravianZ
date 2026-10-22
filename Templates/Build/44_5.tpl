<?php
// local redesign: Festivities tab (Templates/Build/tz_festivities.tpl, GameEngine/Festivities.php)
global $village, $id;
$level = (int)$village->resarray['f'.$id];
?>
<div id="build" class="gid44">
    <h1><?php echo COMMANDCENTER;?> <span class="level"><?php echo LEVEL;?> <?php echo $level;?></span></h1>
    <p class="build_desc">
        <a href="#" onClick="return Popup(44,4, 'gid');" class="build_logo">
            <img class="building g44" src="img/x.gif" alt="<?php echo COMMANDCENTER; ?>" title="<?php echo COMMANDCENTER;?>" />
        </a>
        <?php echo COMMANDCENTER_DESC;?>
    </p>

    <?php include("25_menu.tpl"); ?>

    <?php include("tz_festivities.tpl"); ?>
</div>
