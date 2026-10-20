/*
 * Live resource cards (redesign): keeps each store's fill bar (--fill) and its
 * "full in ..." text (data-full) up to date every second.
 *
 * unx.js already ticks the numbers in #l1..#l4 by rewriting the cell's text,
 * so this script only touches attributes on those cells and works out the
 * amounts on its own from the values printed at page load:
 *   cell text  "amount/capacity", cell title = production per hour.
 */
(function () {
    'use strict';

    function fmt(seconds) {
        seconds = Math.max(0, Math.round(seconds));
        var h = Math.floor(seconds / 3600);
        var m = Math.floor((seconds % 3600) / 60);
        if (h >= 48) return Math.floor(h / 24) + 'd ' + (h % 24) + 'h';
        if (h > 0) return h + 'h ' + m + 'm';
        return m + 'm';
    }

    function setup() {
        var cells = [];
        ['l4', 'l3', 'l2', 'l1'].forEach(function (id) {
            var td = document.getElementById(id);
            if (!td) return;
            var m = (td.textContent || '').match(/(-?\d+)\s*\/\s*(\d+)/);
            var prod = parseFloat(td.getAttribute('title'));
            if (!m || isNaN(prod)) return;
            cells.push({ td: td, start: parseInt(m[1], 10), cap: parseInt(m[2], 10), prod: prod });
            td.setAttribute('data-prod', (prod >= 0 ? '+' : '−') + Math.abs(Math.round(prod)) + '/h');
        });
        if (!cells.length) return;

        var t0 = Date.now();

        function tick() {
            var hours = (Date.now() - t0) / 3600000;
            cells.forEach(function (c) {
                var now = Math.min(c.cap, Math.max(0, c.start + c.prod * hours));
                var pct = c.cap > 0 ? now / c.cap * 100 : 0;
                c.td.style.setProperty('--fill', pct.toFixed(1) + '%');

                var text, state;
                if (c.prod > 0) {
                    if (now >= c.cap) { text = 'full'; state = 'full'; }
                    else {
                        var left = (c.cap - now) / c.prod * 3600;
                        text = 'full in ' + fmt(left);
                        state = left < 3600 ? 'soon' : '';
                    }
                } else if (c.prod < 0) {
                    var gone = now / -c.prod * 3600;
                    text = now <= 0 ? 'empty' : 'empty in ' + fmt(gone);
                    state = 'empty';
                } else {
                    text = ''; state = '';
                }
                c.td.setAttribute('data-full', text);
                c.td.setAttribute('data-state', state);
            });
        }

        tick();
        setInterval(tick, 1000);
    }

    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', setup);
    } else {
        setup();
    }
})();
