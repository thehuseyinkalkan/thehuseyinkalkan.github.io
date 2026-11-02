<#
.SYNOPSIS
  huseyinkalkan.net icin yeni blog yazisi olusturur.

.DESCRIPTION
  Tek komutla su uc isi birden yapar:
    1. blog/<slug>/index.html dosyasini iki dilli sablondan olusturur
    2. blog/index.html listesine yeni yazi kartini ekler
    3. sitemap.xml dosyasina yeni URL girdisini ekler

  Sonrasinda sadece olusan index.html icindeki "ICERIK BURAYA" bolumlerini
  doldurup commit atman yeterli.

.EXAMPLE
  .\tools\new-post.ps1 -Slug "nginx-path-traversal" `
    -TitleTr "Nginx alias yanlis yapilandirmasi" `
    -TitleEn "Nginx alias misconfiguration" `
    -SummaryTr "Alias direktifinin sonundaki egik cizgi neden path traversal'a yol aciyor." `
    -SummaryEn "Why a missing trailing slash in the alias directive enables path traversal." `
    -Badge "Nginx / Path Traversal"

.EXAMPLE
  # Olustur, commit'le ve yayinla
  .\tools\new-post.ps1 -Slug "ornek" -TitleTr "Ornek" -TitleEn "Example" `
    -SummaryTr "Ozet." -SummaryEn "Summary." -Push
#>

[CmdletBinding()]
param(
  # URL'de gorunecek kisa ad. Sadece kucuk harf, rakam ve tire kullanin.
  [Parameter(Mandatory)][ValidatePattern('^[a-z0-9]+(-[a-z0-9]+)*$')][string]$Slug,

  [Parameter(Mandatory)][string]$TitleTr,
  [Parameter(Mandatory)][string]$TitleEn,
  [Parameter(Mandatory)][string]$SummaryTr,
  [Parameter(Mandatory)][string]$SummaryEn,

  # Kartta gorunen kucuk etiket, orn. "CVE-2026-1234" veya "Azure / IDOR"
  [string]$Badge = "",

  # Yayin tarihi (varsayilan: bugun)
  [datetime]$Date = (Get-Date),

  # Olusturduktan sonra commit'le ve GitHub'a gonder
  [switch]$Push
)

$ErrorActionPreference = 'Stop'

# Baslik/ozet metinlerini HTML icinde guvenli hale getirir
function ConvertTo-HtmlSafe([string]$s) {
  $s.Replace('&', '&amp;').Replace('<', '&lt;').Replace('>', '&gt;').Replace('"', '&quot;')
}

# --- yollar -----------------------------------------------------------------
$repo = Split-Path -Parent $PSScriptRoot
$postDir = Join-Path $repo "blog\$Slug"
$postFile = Join-Path $postDir 'index.html'
$blogIndex = Join-Path $repo 'blog\index.html'
$sitemap = Join-Path $repo 'sitemap.xml'

foreach ($f in @($blogIndex, $sitemap)) {
  if (-not (Test-Path $f)) { throw "Bulunamadi: $f  (betigi repo icinden calistirin)" }
}
if (Test-Path $postFile) { throw "Bu slug zaten var: $postFile" }

# --- tarih bicimleri --------------------------------------------------------
$iso = $Date.ToString('yyyy-MM-dd')
$trAylar = @('Ocak','Şubat','Mart','Nisan','Mayıs','Haziran','Temmuz','Ağustos','Eylül','Ekim','Kasım','Aralık')
$dateTr = "$($Date.Day) $($trAylar[$Date.Month - 1]) $($Date.Year)"
$dateEn = $Date.ToString('MMMM d, yyyy', [Globalization.CultureInfo]::GetCultureInfo('en-US'))

$badgeHtml = if ($Badge) { "`n            <span class=`"badge`">$Badge</span>" } else { "" }

$utf8 = New-Object System.Text.UTF8Encoding($false)

# --- 1) yazi sayfasi --------------------------------------------------------
$template = @'
<!DOCTYPE html>
<html lang="tr" data-lang="tr" class="no-js">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <script>
    (function () {
      var r = document.documentElement;
      r.className = r.className.replace(/\bno-js\b/, '');
      try {
        var l = localStorage.getItem('site_lang');
        if (l === 'en' || l === 'tr') { r.setAttribute('data-lang', l); r.setAttribute('lang', l); }
      } catch (e) {}
    })();
  </script>

  <title>__TITLE_TR__ — Hüseyin Kalkan</title>
  <meta name="description" content="__SUMMARY_TR__">
  <meta name="author" content="Hüseyin Kalkan">
  <meta name="theme-color" content="#080a0f">
  <link rel="canonical" href="https://huseyinkalkan.net/blog/__SLUG__/">

  <meta property="og:type" content="article">
  <meta property="og:site_name" content="huseyinkalkan.net">
  <meta property="og:title" content="__TITLE_TR__">
  <meta property="og:description" content="__SUMMARY_TR__">
  <meta property="og:url" content="https://huseyinkalkan.net/blog/__SLUG__/">
  <meta property="og:locale" content="tr_TR">
  <meta property="og:locale:alternate" content="en_US">
  <meta property="article:published_time" content="__ISO__">
  <meta name="twitter:card" content="summary">

  <link rel="icon" href="/assets/favicon.svg" type="image/svg+xml">
<link rel="icon" href="/favicon.ico" sizes="48x48">
<link rel="apple-touch-icon" href="/assets/apple-touch-icon.png">
<link rel="manifest" href="/site.webmanifest">
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&family=JetBrains+Mono:wght@500;600;700&display=swap">
  <link rel="stylesheet" href="/assets/css/style.css">

  <script type="application/ld+json">
  {
    "@context": "https://schema.org",
    "@type": "BlogPosting",
    "headline": "__TITLE_TR__",
    "datePublished": "__ISO__",
    "dateModified": "__ISO__",
    "inLanguage": "tr",
    "author": { "@type": "Person", "name": "Hüseyin Kalkan", "url": "https://huseyinkalkan.net/" },
    "mainEntityOfPage": "https://huseyinkalkan.net/blog/__SLUG__/"
  }
  </script>
</head>
<body>

  <a class="skip-link" href="#main"><span class="t-tr">İçeriğe atla</span><span class="t-en" lang="en">Skip to content</span></a>

  <header class="site-header">
    <div class="container">
      <nav class="nav" aria-label="Ana menü">
        <a href="/" class="logo">
          <svg class="logo-mark" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linejoin="round" aria-hidden="true">
            <path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/>
          </svg>
          <span>huseyinkalkan.net</span><span class="caret" aria-hidden="true">_</span>
        </a>

        <button class="nav-toggle" type="button" id="nav-toggle" aria-expanded="false" aria-controls="nav-links" aria-label="Menü">
          <svg class="icon-open" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" aria-hidden="true"><path d="M3 6h18M3 12h18M3 18h18"/></svg>
          <svg class="icon-close" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" aria-hidden="true"><path d="M18 6 6 18M6 6l12 12"/></svg>
        </button>

        <div class="nav-links" id="nav-links">
          <a href="/"><span class="t-tr">Hakkımda</span><span class="t-en" lang="en">About</span></a>
          <a href="/pentest.html">Pentest</a>
          <a href="/oscp-ultimate-guide/">OSCP Ultimate Guide</a>
          <a href="/bug-bounty.html">Bug Bounty</a>
          <a href="/blog/" aria-current="page">Blog</a>
          <div class="lang-switch" role="group" aria-label="Language / Dil"><button type="button" class="lang-opt" data-set-lang="en" lang="en" aria-pressed="false">English</button><button type="button" class="lang-opt" data-set-lang="tr" lang="tr" aria-pressed="true">T&uuml;rk&ccedil;e</button></div>
        </div>
      </nav>
    </div>
  </header>

  <main id="main">
    <div class="container">

      <!-- ===================== Türkçe ===================== -->
      <article class="article t-tr">
        <a class="back-link" href="/blog/">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="m15 18-6-6 6-6"/></svg>
          Tüm yazılar
        </a>

        <div class="post-meta">
          <time datetime="__ISO__">__DATE_TR__</time>__BADGE__
        </div>

        <h1>__TITLE_TR__</h1>

        <p>__SUMMARY_TR__</p>

        <h2>ICERIK BURAYA — ilk bölüm başlığı</h2>
        <p>Metni buraya yazın.</p>

        <!-- Kullanabileceğiniz hazır bloklar:

        <div class="callout">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M12 9v4M12 17h.01"/><path d="M10.3 3.9 1.8 18a2 2 0 0 0 1.7 3h17a2 2 0 0 0 1.7-3L13.7 3.9a2 2 0 0 0-3.4 0z"/></svg>
          <p>Vurgulamak istediğiniz uyarı.</p>
        </div>

        <pre><code>komut --ornek</code></pre>

        <div class="table-wrap">
          <table>
            <thead><tr><th>Sütun</th><th>Sütun</th></tr></thead>
            <tbody><tr><td>değer</td><td>değer</td></tr></tbody>
          </table>
        </div>
        -->

        <aside class="support-box" aria-label="Bu içerik işine yaradıysa">
          <svg viewBox="0 0 16 16" fill="currentColor" aria-hidden="true"><path d="M4.25 2.5c-1.336 0-2.75 1.164-2.75 3 0 2.15 1.58 4.144 3.365 5.682A20.6 20.6 0 0 0 8 13.393a20.6 20.6 0 0 0 3.135-2.211C12.92 9.644 14.5 7.65 14.5 5.5c0-1.836-1.414-3-2.75-3-1.373 0-2.609.986-3.029 2.456a.75.75 0 0 1-1.442 0C6.859 3.486 5.623 2.5 4.25 2.5z"/></svg>
          <div class="support-text">
            <p class="support-title">Bu içerik işine yaradıysa</p>
            <p>Yazılar ve OSCP rehberi ücretsiz. Yenilerini yazmama destek olmak istersen GitHub Sponsors üzerinden bir kahve ısmarlayabilirsin.</p>
          </div>
          <a class="btn btn-ghost" href="https://github.com/sponsors/thehuseyinkalkan" target="_blank" rel="noopener">Destek ol</a>
        </aside>

      </article>

      <!-- ===================== English ===================== -->
      <article class="article t-en" lang="en">
        <a class="back-link" href="/blog/">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="m15 18-6-6 6-6"/></svg>
          All posts
        </a>

        <div class="post-meta">
          <time datetime="__ISO__">__DATE_EN__</time>__BADGE__
        </div>

        <h1>__TITLE_EN__</h1>

        <p>__SUMMARY_EN__</p>

        <h2>CONTENT HERE — first section heading</h2>
        <p>Write the text here.</p>

        <aside class="support-box" aria-label="Found this useful?">
          <svg viewBox="0 0 16 16" fill="currentColor" aria-hidden="true"><path d="M4.25 2.5c-1.336 0-2.75 1.164-2.75 3 0 2.15 1.58 4.144 3.365 5.682A20.6 20.6 0 0 0 8 13.393a20.6 20.6 0 0 0 3.135-2.211C12.92 9.644 14.5 7.65 14.5 5.5c0-1.836-1.414-3-2.75-3-1.373 0-2.609.986-3.029 2.456a.75.75 0 0 1-1.442 0C6.859 3.486 5.623 2.5 4.25 2.5z"/></svg>
          <div class="support-text">
            <p class="support-title">Found this useful?</p>
            <p>The posts and the OSCP guide are free. If you would like to support new ones, you can buy me a coffee through GitHub Sponsors.</p>
          </div>
          <a class="btn btn-ghost" href="https://github.com/sponsors/thehuseyinkalkan" target="_blank" rel="noopener">Sponsor</a>
        </aside>

      </article>

    </div>
  </main>

  <footer class="site-footer">
    <div class="container footer-inner">
      <div class="footer-meta">
        <p>&copy; 2026 Hüseyin Kalkan. <span class="t-tr">Tüm hakları saklıdır.</span><span class="t-en" lang="en">All rights reserved.</span></p>
        <p class="contact-line">
          <a href="mailto:info@huseyinkalkan.net">info@huseyinkalkan.net</a>
          <span aria-hidden="true">·</span>
          <a href="tel:+905365071963">+90 536 507 19 63</a>
        </p>
      </div>
      <div class="social">
        <a href="https://www.linkedin.com/in/huseyinkalkann/" rel="me noopener" target="_blank" aria-label="LinkedIn">
          <svg viewBox="0 0 24 24" fill="currentColor" aria-hidden="true"><path d="M20.45 20.45h-3.56v-5.57c0-1.33-.03-3.04-1.85-3.04-1.86 0-2.14 1.45-2.14 2.94v5.67H9.35V9h3.41v1.56h.05c.48-.9 1.63-1.85 3.36-1.85 3.6 0 4.27 2.37 4.27 5.45v6.29zM5.34 7.43a2.06 2.06 0 1 1 0-4.13 2.06 2.06 0 0 1 0 4.13zM7.12 20.45H3.55V9h3.57v11.45zM22.22 0H1.77C.79 0 0 .77 0 1.72v20.56C0 23.23.79 24 1.77 24h20.45c.98 0 1.78-.77 1.78-1.72V1.72C24 .77 23.2 0 22.22 0z"/></svg>
        </a>
        <a href="https://github.com/thehuseyinkalkan" rel="me noopener" target="_blank" aria-label="GitHub">
          <svg viewBox="0 0 24 24" fill="currentColor" aria-hidden="true"><path d="M12 .5A11.5 11.5 0 0 0 .5 12a11.5 11.5 0 0 0 7.86 10.92c.58.1.79-.25.79-.56v-2c-3.2.7-3.88-1.37-3.88-1.37-.53-1.34-1.29-1.7-1.29-1.7-1.05-.72.08-.7.08-.7 1.16.08 1.77 1.2 1.77 1.2 1.03 1.77 2.7 1.26 3.36.96.1-.75.4-1.26.73-1.55-2.56-.3-5.25-1.28-5.25-5.7 0-1.26.45-2.29 1.19-3.1-.12-.3-.52-1.47.11-3.07 0 0 .97-.31 3.18 1.18a11 11 0 0 1 5.8 0c2.2-1.49 3.17-1.18 3.17-1.18.63 1.6.23 2.77.12 3.06.74.82 1.18 1.85 1.18 3.11 0 4.43-2.69 5.4-5.26 5.69.41.36.78 1.06.78 2.14v3.17c0 .31.2.67.8.56A11.5 11.5 0 0 0 23.5 12 11.5 11.5 0 0 0 12 .5z"/></svg>
        </a>
        <a href="mailto:info@huseyinkalkan.net" aria-label="E-posta: info@huseyinkalkan.net">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><rect x="2" y="4" width="20" height="16" rx="2"/><path d="m22 7-10 6L2 7"/></svg>
        </a>
        <a href="tel:+905365071963" aria-label="Telefon: +90 536 507 19 63">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M22 16.92v3a2 2 0 0 1-2.18 2 19.79 19.79 0 0 1-8.63-3.07 19.5 19.5 0 0 1-6-6A19.79 19.79 0 0 1 2.12 4.22 2 2 0 0 1 4.11 2h3a2 2 0 0 1 2 1.72c.13.96.36 1.9.7 2.81a2 2 0 0 1-.45 2.11L8.09 9.91a16 16 0 0 0 6 6l1.27-1.27a2 2 0 0 1 2.11-.45c.91.34 1.85.57 2.81.7A2 2 0 0 1 22 16.92z"/></svg>
        </a>
      </div>
    </div>
  </footer>

  <script src="/assets/js/main.js" defer></script>
  <!-- Cloudflare Web Analytics (cerezsiz) -->
  <script defer src="https://static.cloudflareinsights.com/beacon.min.js" data-cf-beacon='{"token": "1f2740f3b3f248f0ba07407bda304372"}'></script>
</body>
</html>
'@

$post = $template.
  Replace('__TITLE_TR__',   (ConvertTo-HtmlSafe $TitleTr)).
  Replace('__TITLE_EN__',   (ConvertTo-HtmlSafe $TitleEn)).
  Replace('__SUMMARY_TR__', (ConvertTo-HtmlSafe $SummaryTr)).
  Replace('__SUMMARY_EN__', (ConvertTo-HtmlSafe $SummaryEn)).
  Replace('__SLUG__',       $Slug).
  Replace('__ISO__',        $iso).
  Replace('__DATE_TR__',    $dateTr).
  Replace('__DATE_EN__',    $dateEn).
  Replace('__BADGE__',      $badgeHtml)

New-Item -ItemType Directory -Force -Path $postDir | Out-Null
[System.IO.File]::WriteAllText($postFile, $post, $utf8)
Write-Host "[1/3] olusturuldu: blog\$Slug\index.html" -ForegroundColor Green

# --- 2) blog listesine kart ekle --------------------------------------------
$cardBadge = if ($Badge) { "`n            <span class=`"badge`">$Badge</span>" } else { "" }
$TitleTr   = ConvertTo-HtmlSafe $TitleTr
$TitleEn   = ConvertTo-HtmlSafe $TitleEn
$SummaryTr = ConvertTo-HtmlSafe $SummaryTr
$SummaryEn = ConvertTo-HtmlSafe $SummaryEn
$card = @"
<article class="post-card">
          <div class="post-meta">
            <time datetime="$iso"><span class="t-tr">$dateTr</span><span class="t-en" lang="en">$dateEn</span></time>$cardBadge
          </div>
          <h3 class="post-title">
            <a href="/blog/$Slug/">
              <span class="t-tr">$TitleTr</span>
              <span class="t-en" lang="en">$TitleEn</span>
            </a>
          </h3>
          <p class="t-tr">$SummaryTr</p>
          <p class="t-en" lang="en">$SummaryEn</p>
        </article>

        <article class="post-card">
"@

$bi = Get-Content $blogIndex -Raw -Encoding UTF8
$anchor = '<article class="post-card">'
if ($bi -notmatch [regex]::Escape($anchor)) { throw "blog/index.html icinde yazi karti bulunamadi" }
# en yeni yazi en uste gelsin: ilk kartin onune ekle
$idx = $bi.IndexOf($anchor)
$bi = $bi.Substring(0, $idx) + $card + $bi.Substring($idx + $anchor.Length)
[System.IO.File]::WriteAllText($blogIndex, $bi, $utf8)
Write-Host "[2/3] blog/index.html listesine eklendi" -ForegroundColor Green

# --- 3) sitemap girdisi -----------------------------------------------------
$sm = Get-Content $sitemap -Raw -Encoding UTF8
$entry = @"
  <!-- Blog yazisi: $Slug -->
  <url>
    <loc>https://huseyinkalkan.net/blog/$Slug/</loc>
    <lastmod>$iso</lastmod>
    <changefreq>monthly</changefreq>
    <priority>0.9</priority>
  </url>

</urlset>
"@
$sm = $sm.Replace("</urlset>", $entry)
[System.IO.File]::WriteAllText($sitemap, $sm, $utf8)
Write-Host "[3/3] sitemap.xml guncellendi" -ForegroundColor Green

Write-Host ""
Write-Host "Simdi icerigi yazin:" -ForegroundColor Cyan
Write-Host "  $postFile"
Write-Host "  (iki makaledeki 'ICERIK BURAYA' / 'CONTENT HERE' bolumlerini doldurun)"

if ($Push) {
  Push-Location $repo
  try {
    git add -A
    git commit -m "Yeni blog yazisi: $TitleTr"
    git push origin main
    Write-Host "`nYayinlandi: https://huseyinkalkan.net/blog/$Slug/" -ForegroundColor Green
  } finally { Pop-Location }
} else {
  Write-Host ""
  Write-Host "Yayinlamak icin:" -ForegroundColor Cyan
  Write-Host "  git add -A; git commit -m `"Yeni yazi: $TitleTr`"; git push"
}
