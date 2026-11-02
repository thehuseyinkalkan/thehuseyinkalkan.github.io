/* huseyinkalkan.net — dil degistirme ve mobil menu
 *
 * Onemli: gorunurluk `.t-tr` / `.t-en` siniflariyla, CSS uzerinden yonetilir.
 * Eski surum `querySelectorAll('[lang="tr"]')` kullaniyordu; bu secici
 * <html lang="tr"> etiketini de yakaliyor ve koke display:none vererek
 * butun sayfayi gorunmez birakiyordu. Artik lang niteligi secici degil.
 */

(function () {
  'use strict';

  var STORAGE_KEY = 'site_lang';
  var SUPPORTED = ['tr', 'en'];
  var root = document.documentElement;

  function isSupported(lang) {
    return SUPPORTED.indexOf(lang) !== -1;
  }

  /* localStorage gizli sekmede veya kapali cerezlerde patlayabilir */
  function readLang() {
    try {
      var stored = localStorage.getItem(STORAGE_KEY);
      return isSupported(stored) ? stored : null;
    } catch (e) {
      return null;
    }
  }

  function writeLang(lang) {
    try {
      localStorage.setItem(STORAGE_KEY, lang);
    } catch (e) {
      /* kalici olmasa da oturum icinde calismaya devam etsin */
    }
  }

  function applyLang(lang) {
    if (!isSupported(lang)) {
      lang = 'tr';
    }

    root.setAttribute('data-lang', lang);
    root.setAttribute('lang', lang); /* ekran okuyucular dogru dili okusun */

    var btn = document.getElementById('lang-btn');
    if (btn) {
      btn.textContent = lang === 'en' ? 'EN' : 'TR';
      btn.setAttribute('aria-label', lang === 'en'
        ? 'Switch language to Turkish'
        : 'Dili Ingilizceye cevir');
      btn.setAttribute('title', lang === 'en' ? 'Switch to Turkish' : 'Switch to English');
    }

    document.dispatchEvent(new CustomEvent('langchange', { detail: { lang: lang } }));
  }

  function toggleLang() {
    var current = root.getAttribute('data-lang') === 'en' ? 'en' : 'tr';
    var next = current === 'tr' ? 'en' : 'tr';
    writeLang(next);
    applyLang(next);
  }

  function initLang() {
    /* <head> icindeki satir ici betik data-lang'i zaten yazdi (FOUC olmasin diye).
       Burada yalnizca dugme metnini ve olay dinleyicisini bagliyoruz. */
    applyLang(readLang() || root.getAttribute('data-lang') || 'tr');

    var btn = document.getElementById('lang-btn');
    if (btn) {
      btn.addEventListener('click', toggleLang);
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
    var wide = window.matchMedia('(min-width: 761px)');
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
