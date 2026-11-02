/* huseyinkalkan.net — dil onerisi ve mobil menu
 *
 * Her dilin kendi adresi var: Turkce /..., Ingilizce /en/... (tools/build.py uretir).
 * Dil secici artik normal bir baglanti; burada dil DEGISTIRILMEZ, yalnizca:
 *   - secilen dil hatirlanir,
 *   - tarayici dili sayfanin dilinden farkliysa ve kisi henuz secim yapmadiysa,
 *     kapatilabilir kucuk bir "bu sayfa X dilinde de var" bandi gosterilir.
 * Otomatik yonlendirme bilerek YOK: Googlebot'un tarayici dili en-US oldugu icin
 * Turkce sayfalari Ingilizceye atar ve indekslenmelerini bozar (Google da onermiyor).
 */

(function () {
  'use strict';

  var STORAGE_KEY = 'site_lang';
  var root = document.documentElement;

  /* localStorage gizli sekmede veya kapali cerezlerde patlayabilir */
  function readLang() {
    try {
      var v = localStorage.getItem(STORAGE_KEY);
      return v === 'tr' || v === 'en' ? v : null;
    } catch (e) {
      return null;
    }
  }

  function writeLang(lang) {
    try {
      localStorage.setItem(STORAGE_KEY, lang);
    } catch (e) { /* yoksay */ }
  }

  function browserLang() {
    var l = (navigator.languages && navigator.languages[0]) || navigator.language || '';
    return /^tr(-|$)/i.test(l) ? 'tr' : 'en';
  }

  var HINT = {
    en: { text: 'This page is also available in English.', go: 'View in English', close: 'Dismiss' },
    tr: { text: 'Bu sayfanın Türkçesi de var.', go: 'Türkçe görüntüle', close: 'Kapat' }
  };

  function showHint(target, href) {
    var t = HINT[target];
    var bar = document.createElement('div');
    bar.className = 'lang-hint';
    bar.setAttribute('role', 'region');
    bar.setAttribute('aria-label', t.text);
    bar.setAttribute('lang', target);

    var msg = document.createElement('span');
    msg.textContent = t.text;
    var go = document.createElement('a');
    go.href = href;
    go.textContent = t.go;
    go.addEventListener('click', function () { writeLang(target); });
    var x = document.createElement('button');
    x.type = 'button';
    x.className = 'lang-hint-close';
    x.setAttribute('aria-label', t.close);
    x.textContent = '×';
    x.addEventListener('click', function () {
      writeLang(root.getAttribute('data-lang'));
      bar.parentNode.removeChild(bar);
    });

    bar.appendChild(msg);
    bar.appendChild(go);
    bar.appendChild(x);
    var header = document.querySelector('.site-header');
    if (header && header.parentNode) {
      header.parentNode.insertBefore(bar, header.nextSibling);
    }
  }

  function initLang() {
    var opts = document.querySelectorAll('.lang-opt[data-set-lang]');
    var hrefs = {};
    for (var i = 0; i < opts.length; i++) {
      var code = opts[i].getAttribute('data-set-lang');
      hrefs[code] = opts[i].getAttribute('href');
      opts[i].addEventListener('click', function () {
        writeLang(this.getAttribute('data-set-lang'));
      });
    }

    var page = root.getAttribute('data-lang');
    var want = readLang() || browserLang();
    if (!readLang() && want !== page && hrefs[want] && document.querySelector('.lang-opt[aria-current]')) {
      showHint(want, hrefs[want]);
    }
  }

  function initNav() {
    var toggle = document.querySelector('.nav-toggle');
    var links = document.getElementById('nav-links');
    if (!toggle || !links) {
      return;
    }

    function setOpen(open) {
      links.classList.toggle('is-open', open);
      toggle.setAttribute('aria-expanded', String(open));
    }

    toggle.addEventListener('click', function () {
      setOpen(toggle.getAttribute('aria-expanded') !== 'true');
    });

    /* Bir baglantiya basilinca panel kapansin */
    links.addEventListener('click', function (event) {
      if (event.target.closest('a')) {
        setOpen(false);
      }
    });

    document.addEventListener('keydown', function (event) {
      if (event.key === 'Escape' && toggle.getAttribute('aria-expanded') === 'true') {
        setOpen(false);
        toggle.focus();
      }
    });

    /* Masaustu genisligine gecince acik panel kalmasin */
    var wide = window.matchMedia('(min-width: 901px)');
    var onChange = function (event) {
      if (event.matches) {
        setOpen(false);
      }
    };
    if (wide.addEventListener) {
      wide.addEventListener('change', onChange);
    } else if (wide.addListener) {
      wide.addListener(onChange); /* eski Safari */
    }
  }

  function ready(fn) {
    if (document.readyState === 'loading') {
      document.addEventListener('DOMContentLoaded', fn);
    } else {
      fn();
    }
  }

  ready(function () {
    initLang();
    initNav();
  });
})();
