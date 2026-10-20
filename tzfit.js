/*
 * Fit the fixed-size village-centre map (540x448, absolutely positioned
 * buildings and image-map click areas) to the available width (redesign).
 * CSS zoom scales the click areas with the picture, so the map is zoomed to
 * fill the centre panel on desktop (up to 1.18x) and shrunk on phones.
 * The level toggle (#lswitch) is moved inside the map so it scales along.
 */
(function () {
    'use strict';

    var MAP_W = 540, MAX_ZOOM = 1.18;

    function fit() {
        var map = document.querySelector('div.village2 div#village_map');
        if (!map) return;
        var box = map.parentNode;
        var cs = window.getComputedStyle(box);
        var avail = box.clientWidth - parseFloat(cs.paddingLeft) - parseFloat(cs.paddingRight);
        var z = Math.min(MAX_ZOOM, avail / MAP_W);
        map.style.zoom = z > 0 ? z.toFixed(3) : '';
    }

    function init() {
        var map = document.querySelector('div.village2 div#village_map');
        if (!map) return;
        var sw = document.getElementById('lswitch');
        if (sw && sw.parentNode !== map) {
            map.appendChild(sw);
            sw.classList.add('tz-in-map');
        }
        fit();
        var t;
        window.addEventListener('resize', function () {
            clearTimeout(t);
            t = setTimeout(fit, 100);
        });
    }

    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', init);
    } else {
        init();
    }
})();
