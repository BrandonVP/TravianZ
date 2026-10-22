<?php

#################################################################################
##                -= YOU MAY NOT REMOVE OR CHANGE THIS NOTICE =-               ##
## --------------------------------------------------------------------------- ##
##  Filename       : chat.tpl                                                  ##
##  Type           : Alliance Internal Chat                                    ##
## --------------------------------------------------------------------------- ##
##  Developed by   : Shadow                                                    ##
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

// -------------------------------------------------
// SAFE ALLIANCE ID
// -------------------------------------------------
if (!isset($aid)) {
    $aid = (int)$session->alliance;
}

// -------------------------------------------------
// LOAD ALLIANCE DATA
// -------------------------------------------------
$allianceinfo = $database->getAlliance($aid);

// header (XSS safe)
echo "<h1>" 
    . htmlspecialchars($allianceinfo['tag'], ENT_QUOTES, 'UTF-8') 
    . " - " 
    . htmlspecialchars($allianceinfo['name'], ENT_QUOTES, 'UTF-8') 
    . "</h1>";

// menu
include("alli_menu.tpl");
?>

<script type="text/javascript">
<?php sajax_show_javascript(); ?>

// -------------------------------------------------
// local redesign: themed chat box. Polls every 2s, only redraws when
// something changed, keeps the view at the newest message unless the
// reader scrolled up (or switched "Follow new messages" off).
// -------------------------------------------------
var tzChatLast = null;

function tzChatAtBottom(box) {
    return box.scrollHeight - box.scrollTop - box.clientHeight < 30;
}

function show_data_cb(text) {
    if (text === tzChatLast) return;
    tzChatLast = text;
    var box = document.getElementById("masnun");
    var follow = document.getElementById("scrollCheckbox").checked;
    var stick = follow && (tzChatAtBottom(box) || box.getAttribute("data-init") !== "1");
    box.innerHTML = text;
    box.setAttribute("data-init", "1");
    if (stick) box.scrollTop = box.scrollHeight;
}

function start_it() {
    x_get_data(show_data_cb);
    setTimeout(start_it, 2000);
}

function add_cb() {
    // show the new message right away
    x_get_data(function (text) {
        var box = document.getElementById("masnun");
        tzChatLast = null;
        show_data_cb(text);
        box.scrollTop = box.scrollHeight;
    });
}

function send_data() {
    var msgField = document.form1.msg;
    var msg = msgField.value.trim();
    if (msg.length === 0) {
        return false;
    }
    if (msg.length > 250) {
        msg = msg.substring(0, 250);
    }
    // the sajax GET call puts arguments into the URL as they are, so
    // characters like & # + would cut the message short - encode them
    x_add_data(encodeURIComponent(msg), add_cb);
    msgField.value = "";
    msgField.focus();
    return false;
}
</script>

<div class="tz-chat">
    <div class="tz-chat-head">
        <span class="tz-chat-title"><?php echo TZ_ALLY_CHAT; ?></span>
        <label class="tz-chat-follow"><input id="scrollCheckbox" type="checkbox" checked="checked" /> Follow new messages</label>
    </div>
    <div id="masnun" class="tz-chat-log"><div class="tz-chat-empty">Loading&hellip;</div></div>
    <form name="form1" class="tz-chat-form" onsubmit="return send_data();">
        <input name="s" value="6" type="hidden" />
        <input class="tz-chat-input" type="text" name="msg" maxlength="250" autocomplete="off" placeholder="Write a message to your alliance&hellip;" />
        <button type="submit" class="tz-btn"><?php echo defined('SEND') ? SEND : 'Send'; ?></button>
    </form>
</div>

<script>
start_it();
</script>
