<?php
#################################################################################
##                                                                             ##
##              -= YOU MUST NOT REMOVE OR CHANGE THIS NOTICE =-                ##
##                                                                             ##
## --------------------------------------------------------------------------- ##
##                                                                             ##
##  Project:       TravianZ                                                    ##
##  Version:       2011.11.06                                                  ##
##  Filename:      Templates/Travian/3.6/Tutorial/3.tpl                        ##
##  Edited by:     ZZJHONS                                                     ##
##  License:       Creative Commons BY-NC-SA 3.0                               ##
##  Copyright:     TravianZ (c) 2025 - All rights reserved                     ##
##  URLs:          http://travian.shadowss.ro                                  ##
##  Source code:   https://github.com/Shadowss/TravianZ                        ##
##                                                                             ##
#################################################################################
?>
<h2><?php echo TZ_N_3_5_BUILDINGS; ?></h2>
            <table class="tutorial_table">
                <tbody>
                    <tr>
                        <td class="visual">
                            <img src="img/en/tut/dorfzentrum1.gif" alt="" />
                            <?php echo TZ_N_1_CHOOSE_BUILDING_SITE; ?>
                        </td>
                        <td class="visual">
                        <img src="img/en/tut/dorfzentrum2.gif" alt="" />
                        <?php echo TZ_N_2_CONSTRUCT_A_BUILDING; ?>
                        </td>
                    </tr>
                    <tr>
                        <td class="beschreibung" colspan="2">
                            <?php echo TZ_AFTER_TAKING_CARE_OF_YOUR_RESOURCE; ?>
                            <br><br>
                            <?php echo TZ_A_WAREHOUSE_AND_A_GRANARY_ENABLE_Y; ?>
                        </td>
                    </tr>
                </tbody>
            </table>
            <table id="tutorial_nav">
                <tbody>
                    <tr>
                        <td class="nav_prev">
                            <a href="tutorial.php?s=2" title="<?php echo BACK; ?>">&laquo; back</a>
                        </td>
                        <td class="nav_next">
                            <a href="tutorial.php?s=4" title="<?php echo TZ_FORWARD; ?>">forward &raquo;</a>
                        </td>
                    </tr>
                </tbody>
            </table>
