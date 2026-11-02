#!/usr/bin/env python3
"""huseyinkalkan.net build: split the bilingual source pages into one URL per language.

Source pages hold both languages side by side (.t-tr / .t-en). This script writes:
  _site/<path>      Turkish only (same URLs as before, so existing indexing is kept)
  _site/en/<path>   English only
with per-language <title>/description/canonical/og tags, reciprocal hreflang links,
a link-based language switch, and a sitemap carrying the language alternates.

English head metadata comes from these source tags (removed from the output):
  <meta name="i18n:title:en" content="...">          required
  <meta name="i18n:description:en" content="...">    required
  <meta name="i18n:og-title:en" content="...">       optional (falls back to title)
  <meta name="i18n:og-description:en" content="..."> optional (falls back to description)

Standard library only. Run from anywhere:  python tools/build.py
Local preview:  python -m http.server 8000 -d _site
"""

import html
import json
import re
import shutil
import sys
from html.parser import HTMLParser
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "_site"
BASE = "https://huseyinkalkan.net"

SKIP = {".git", ".github", "tools", "_site", "README.md", ".gitignore"}
VOID = {"area", "base", "br", "col", "embed", "hr", "img", "input", "link", "meta",
        "source", "track", "wbr"}
LOCALE = {"tr": "tr_TR", "en": "en_US"}

# Shared header/footer attribute text that sits outside .t-tr/.t-en blocks
ATTR_EN = [
    ('aria-label="Ana menü"', 'aria-label="Main menu"'),
    ('aria-label="Menü"', 'aria-label="Menu"'),
    ('aria-label="Telefon: ', 'aria-label="Phone: '),
    ('aria-label="E-posta: ', 'aria-label="Email: '),
    ('aria-label="Teknolojiler"', 'aria-label="Technologies"'),
    ('aria-label="İçindekiler / Contents"', 'aria-label="Contents"'),
]
ATTR_TR = [
    ('aria-label="İçindekiler / Contents"', 'aria-label="İçindekiler"'),
]


class BuildError(Exception):
    pass


# --------------------------------------------------------------------------- #
# Removing every element carrying a given class
# --------------------------------------------------------------------------- #
class _Spans(HTMLParser):
    """Collects [start, end) offsets of elements whose class list contains `cls`.

    Depth is counted on the dropped element's own tag name only, so unclosed
    <p>/<li> inside a dropped block cannot unbalance it.
    """

    def __init__(self, src, cls):
        super().__init__(convert_charrefs=False)
        self.src = src
        self.cls = cls
        self.spans = []
        self._line_starts = [0]
        for m in re.finditer("\n", src):
            self._line_starts.append(m.end())
        self._tag = None
        self._depth = 0
        self._start = 0

    def _offset(self):
        line, col = self.getpos()
        return self._line_starts[line - 1] + col

    def handle_starttag(self, tag, attrs):
        if self._tag is not None:
            if tag == self._tag:
                self._depth += 1
            return
        classes = (dict(attrs).get("class") or "").split()
        if self.cls not in classes:
            return
        start = self._offset()
        if tag in VOID:
            self.spans.append((start, start + len(self.get_starttag_text())))
            return
        self._tag, self._depth, self._start = tag, 1, start

    def handle_startendtag(self, tag, attrs):
        if self._tag is not None:
            return
        classes = (dict(attrs).get("class") or "").split()
        if self.cls in classes:
            start = self._offset()
            self.spans.append((start, start + len(self.get_starttag_text())))

    def handle_endtag(self, tag):
        if self._tag is None or tag != self._tag:
            return
        self._depth -= 1
        if self._depth == 0:
            pos = self._offset()
            end = self.src.index(">", pos) + 1
            self.spans.append((self._start, end))
            self._tag = None


def drop_class(src, cls):
    p = _Spans(src, cls)
    p.feed(src)
    p.close()
    if p._tag is not None:
        raise BuildError(f"unclosed <{p._tag} class=...{cls}...>")
    out, last = [], 0
    for a, b in p.spans:
        out.append(src[last:a])
        last = b
    out.append(src[last:])
    return "".join(out), len(p.spans)


# --------------------------------------------------------------------------- #
# Helpers
# --------------------------------------------------------------------------- #
def meta_content(src, name):
    m = re.search(r'<meta name="%s" content="([^"]*)">' % re.escape(name), src)
    return m.group(1) if m else None


def sub_one(pattern, repl, src, label, required=True):
    new, n = re.subn(pattern, repl, src, count=1)
    if required and n != 1:
        raise BuildError(f"pattern not found: {label}")
    return new


def url_of(rel):
    """Source file path -> site URL path ('/', '/pentest.html', '/blog/x/')."""
    p = "/" + rel.as_posix()
    if p.endswith("/index.html"):
        p = p[: -len("index.html")]
    return p


def en_url(path):
    return "/en" + path


def switch_html(tr_href, en_href, lang):
    def a(code, href, label):
        cur = ' aria-current="true"' if code == lang else ""
        return (f'<a class="lang-opt" href="{href}" hreflang="{code}" lang="{code}"'
                f' data-set-lang="{code}"{cur}>{label}</a>')
    return ('<div class="lang-switch" role="group" aria-label="Language / Dil">'
            + a("en", en_href, "English") + a("tr", tr_href, "T&uuml;rk&ccedil;e") + "</div>")


SWITCH_RE = re.compile(r'<div class="lang-switch"[^>]*>.*?</div>', re.S)
FOUC_TRY_RE = re.compile(r"\n\s*try \{\s*var l = localStorage\.getItem\('site_lang'\);.*?\} catch \(e\) \{\}", re.S)
I18N_META_RE = re.compile(r'\n\s*<meta name="i18n:[^"]+" content="[^"]*">')


# --------------------------------------------------------------------------- #
# One language version of one page
# --------------------------------------------------------------------------- #
def render(src, path, lang, pages):
    other = "en" if lang == "tr" else "tr"
    tr_abs, en_abs = BASE + path, BASE + en_url(path)
    self_abs = tr_abs if lang == "tr" else en_abs

    out, _ = drop_class(src, "t-" + other)

    out = sub_one(r'<html lang="tr" data-lang="tr"', f'<html lang="{lang}" data-lang="{lang}"', out, "<html>")
    # The language is fixed by the URL now: no localStorage override before first paint.
    out = FOUC_TRY_RE.sub("", out, count=1)

    if lang == "en":
        t = meta_content(src, "i18n:title:en")
        d = meta_content(src, "i18n:description:en")
        if not t or not d:
            raise BuildError("missing i18n:title:en / i18n:description:en")
        ot = meta_content(src, "i18n:og-title:en") or t
        od = meta_content(src, "i18n:og-description:en") or d
        out = sub_one(r"<title>[^<]*</title>", lambda m: f"<title>{t}</title>", out, "<title>")
        out = sub_one(r'<meta name="description" content="[^"]*">',
                      lambda m: f'<meta name="description" content="{d}">', out, "description")
        out = sub_one(r'<meta property="og:title" content="[^"]*">',
                      lambda m: f'<meta property="og:title" content="{ot}">', out, "og:title", required=False)
        out = sub_one(r'<meta property="og:description" content="[^"]*">',
                      lambda m: f'<meta property="og:description" content="{od}">', out, "og:description", required=False)
        headline = json.dumps(html.unescape(ot), ensure_ascii=False)
        out = sub_one(r'"headline": "(?:[^"\\]|\\.)*"', lambda m: f'"headline": {headline}', out, "headline", required=False)
        out = out.replace('"inLanguage": "tr"', '"inLanguage": "en"')
        out = out.replace(f'"mainEntityOfPage": "{tr_abs}"', f'"mainEntityOfPage": "{en_abs}"')
        for a, b in ATTR_EN:
            out = out.replace(a, b)
        # Internal page links stay inside the English site
        def relink(m):
            href = m.group(1)
            base, sep, frag = href.partition("#")
            if base in pages:
                return f'href="{en_url(base)}{sep}{frag}"'
            return m.group(0)
        out = re.sub(r'href="(/[^"]*)"', relink, out)
    else:
        for a, b in ATTR_TR:
            out = out.replace(a, b)

    out = I18N_META_RE.sub("", out)

    # canonical + og:url + locales + hreflang
    alt = (f'<link rel="canonical" href="{self_abs}">\n'
           f'  <link rel="alternate" hreflang="tr" href="{tr_abs}">\n'
           f'  <link rel="alternate" hreflang="en" href="{en_abs}">\n'
           f'  <link rel="alternate" hreflang="x-default" href="{tr_abs}">')
    out = sub_one(r'<link rel="canonical" href="[^"]*">', lambda m: alt, out, "canonical")
    out = sub_one(r'<meta property="og:url" content="[^"]*">',
                  lambda m: f'<meta property="og:url" content="{self_abs}">', out, "og:url", required=False)
    out = sub_one(r'<meta property="og:locale" content="[^"]*">',
                  lambda m: f'<meta property="og:locale" content="{LOCALE[lang]}">', out, "og:locale", required=False)
    out = sub_one(r'<meta property="og:locale:alternate" content="[^"]*">',
                  lambda m: f'<meta property="og:locale:alternate" content="{LOCALE[other]}">', out, "og:locale:alternate", required=False)

    out = sub_one(SWITCH_RE, lambda m: switch_html(path, en_url(path), lang), out, "lang-switch")

    if re.search(r'class="[^"]*\bt-%s\b' % other, out):
        raise BuildError(f"t-{other} content left behind")
    return out


def render_404(src):
    """GitHub Pages serves one /404.html for every missing URL: keep both languages
    and pick one from the requested path (/en/...) or the browser language."""
    out = FOUC_TRY_RE.sub(
        "\n      var en = location.pathname.indexOf('/en/') === 0 ||"
        " !/^tr\\b/i.test((navigator.languages && navigator.languages[0]) || navigator.language || '');"
        "\n      if (en) { r.setAttribute('data-lang', 'en'); r.setAttribute('lang', 'en'); }",
        src, count=1)
    out = I18N_META_RE.sub("", out)
    out = sub_one(SWITCH_RE, lambda m: switch_html("/", "/en/", None), out, "lang-switch")
    return out


# --------------------------------------------------------------------------- #
# Sitemap with xhtml:link alternates
# --------------------------------------------------------------------------- #
def build_sitemap(src_xml):
    entries = re.findall(r"<url>(.*?)</url>", src_xml, re.S)
    blocks = []
    for e in entries:
        loc = re.search(r"<loc>([^<]+)</loc>", e).group(1).strip()
        path = loc[len(BASE):] if loc.startswith(BASE) else loc
        rest = re.sub(r"\s*<loc>[^<]+</loc>", "", e).strip()
        rest = "\n    ".join(l.strip() for l in rest.splitlines() if l.strip())
        links = (f'    <xhtml:link rel="alternate" hreflang="tr" href="{BASE}{path}"/>\n'
                 f'    <xhtml:link rel="alternate" hreflang="en" href="{BASE}/en{path}"/>\n'
                 f'    <xhtml:link rel="alternate" hreflang="x-default" href="{BASE}{path}"/>')
        for u in (BASE + path, BASE + "/en" + path):
            blocks.append(f"  <url>\n    <loc>{u}</loc>\n    {rest}\n{links}\n  </url>")
    return ('<?xml version="1.0" encoding="UTF-8"?>\n'
            '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9"\n'
            '        xmlns:xhtml="http://www.w3.org/1999/xhtml">\n'
            + "\n".join(blocks) + "\n</urlset>\n")


# --------------------------------------------------------------------------- #
def main():
    if OUT.exists():
        shutil.rmtree(OUT)
    OUT.mkdir()

    files = [p for p in ROOT.rglob("*")
             if p.is_file() and p.relative_to(ROOT).parts[0] not in SKIP]

    bilingual = {}
    for p in files:
        rel = p.relative_to(ROOT)
        if p.suffix == ".html" and rel.as_posix() != "404.html":
            text = p.read_text(encoding="utf-8")
            if 'class="lang-switch"' in text:
                bilingual[rel] = text
    pages = {url_of(rel) for rel in bilingual}

    for p in files:
        rel = p.relative_to(ROOT)
        dst = OUT / rel
        dst.parent.mkdir(parents=True, exist_ok=True)
        if rel in bilingual:
            continue
        if rel.as_posix() == "404.html":
            dst.write_text(render_404(p.read_text(encoding="utf-8")), encoding="utf-8", newline="")
        elif rel.as_posix() == "sitemap.xml":
            dst.write_text(build_sitemap(p.read_text(encoding="utf-8")), encoding="utf-8", newline="")
        else:
            shutil.copy2(p, dst)

    for rel, text in sorted(bilingual.items()):
        path = url_of(rel)
        for lang in ("tr", "en"):
            try:
                out = render(text, path, lang, pages)
            except BuildError as e:
                raise SystemExit(f"[build] {rel} ({lang}): {e}")
            dst = OUT / rel if lang == "tr" else OUT / "en" / rel
            dst.parent.mkdir(parents=True, exist_ok=True)
            dst.write_text(out, encoding="utf-8", newline="")
        print(f"[build] {path}  ->  {path}  +  {en_url(path)}")

    print(f"[build] {len(bilingual)} pages x 2 languages, output in {OUT}")


if __name__ == "__main__":
    sys.exit(main())
