/*
 * Live resource cards (redesign): every second, update each card's amount,
 * fill bar (--fill) and "Full in ..." line.
 *
 * Templates/res.tpl prints, per card, a hidden span (#l1..#l4) holding
 * "amount/capacity" with the production per hour in its title; unx.js ticks
 * those spans. This script works the amounts out on its own from the values
 * printed at page load and only writes to the visible parts of the card.
 */
(function () {
    'use strict';

    function fmtTime(seconds) {
        seconds = Math.max(0, Math.round(seconds));
        var h = Math.floor(seconds / 3600);
        var m = Math.floor((seconds % 3600) / 60);
        if (h >= 48) return Math.floor(h / 24) + 'd ' + (h % 24) + 'h';
        if (h > 0) return h + 'h ' + m + 'm';
        return m + 'm';
    }

    function fmtNum(n) {
        return Math.floor(n).toString().replace(/\B(?=(\d{3})+(?!\d))/g, ',');
    }

    function setup() {
        var cards = [];
        var raws = document.querySelectorAll('.tz-rcard .tz-rraw');
        for (var i = 0; i < raws.length; i++) {
            var raw = raws[i];
            var card = raw.parentNode;
            var m = (raw.textContent || '').match(/(-?\d+)\s*\/\s*(\d+)/);
            var prod = parseFloat(raw.getAttribute('title'));
            if (!m || isNaN(prod)) continue;
            cards.push({
                card: card,
                now: card.querySelector('.tz-rnow'),
                full: card.querySelector('.tz-rfull'),
                start: parseInt(m[1], 10),
                cap: parseInt(m[2], 10),
                prod: prod
            });
        }
        if (!cards.length) return;

        var t0 = Date.now();

        function tick() {
            var hours = (Date.now() - t0) / 3600000;
            cards.forEach(function (c) {
                var now = Math.min(c.cap, Math.max(0, c.start + c.prod * hours));
                c.card.style.setProperty('--fill', (c.cap > 0 ? now / c.cap * 100 : 0).toFixed(1) + '%');
                if (c.now) c.now.textContent = fmtNum(now);

                var text = '', state = '';
                if (c.prod > 0) {
                    if (now >= c.cap) { text = 'Full'; state = 'full'; }
                    else {
                        var left = (c.cap - now) / c.prod * 3600;
                        text = 'Full in ' + fmtTime(left);
                        state = left < 3600 ? 'soon' : '';
                    }
                } else if (c.prod < 0) {
                    text = now <= 0 ? 'Empty' : 'Empty in ' + fmtTime(now / -c.prod * 3600);
                    state = 'empty';
                }
                if (c.full) c.full.textContent = text || ' ';
                c.card.setAttribute('data-state', state);
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
