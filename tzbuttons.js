/*
 * Real buttons for the old image buttons (redesign).
 *
 * The game draws many buttons as <input type="image"> with the label baked
 * into a sprite (OK, Train, Save, Delete, ...). Those inputs submit click
 * coordinates (s1.x / s1.y), and the PHP behind each form may depend on it,
 * so the input is kept: it is wrapped in a text button (.tz-ibtn) with the
 * label from its alt/value, and stretched invisibly over that button. Every
 * click still lands on the original input, so forms submit exactly as before.
 *
 * Image links (<a><img class="dynamic_img"></a>, e.g. "new forum") get the
 * same text label and the link itself is styled as the button.
 */
(function () {
    'use strict';

    function label(el) {
        var t = (el.getAttribute('alt') || '').trim();
        if (!t) {
            var v = (el.getAttribute('value') || '').trim();
            if (v && v.length > 1) t = v;
        }
        if (!t) t = (el.getAttribute('title') || '').trim();
        if (!t || /^ok$/i.test(t)) t = 'OK';
        return t.charAt(0).toUpperCase() + t.slice(1);
    }

    function wrapInput(input) {
        if (input.parentNode && input.parentNode.classList && input.parentNode.classList.contains('tz-ibtn')) return;
        var src = input.getAttribute('src') || '';
        if (src.indexOf('x.gif') === -1) return; // a real picture, not a sprite button

        var wrap = document.createElement('span');
        wrap.className = 'tz-btn tz-ibtn' + (input.disabled ? ' is-disabled' : '');
        if (input.id) wrap.setAttribute('data-for', input.id);
        wrap.appendChild(document.createTextNode(label(input)));
        input.parentNode.insertBefore(wrap, input);
        wrap.appendChild(input);

        // keep the disabled look in sync if a script toggles it later
        if (window.MutationObserver) {
            new MutationObserver(function () {
                wrap.classList.toggle('is-disabled', input.disabled);
            }).observe(input, { attributes: true, attributeFilter: ['disabled'] });
        }
    }

    function wrapImageLink(img) {
        var a = img.parentNode;
        if (!a || a.tagName !== 'A' || a.classList.contains('tz-btn')) return;
        a.classList.add('tz-btn', 'tz-ilink');
        var span = document.createElement('span');
        span.textContent = label(img);
        a.insertBefore(span, img);
    }

    function init() {
        var inputs = document.querySelectorAll('input[type="image"]');
        for (var i = 0; i < inputs.length; i++) wrapInput(inputs[i]);
        var imgs = document.querySelectorAll('a > img.dynamic_img');
        for (var j = 0; j < imgs.length; j++) wrapImageLink(imgs[j]);
    }

    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', init);
    } else {
        init();
    }
})();
