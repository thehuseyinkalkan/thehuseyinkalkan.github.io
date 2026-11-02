# huseyinkalkan.net

Hüseyin Kalkan'ın kişisel sitesi — IT altyapı, siber güvenlik, pentest ve bug bounty notları.
Saf HTML/CSS/JS. GitHub Actions her push'ta `tools/build.py` ile dilleri ayırıp GitHub Pages'e yayınlar.

## Yapı

```
index.html                 Ana sayfa
pentest.html               Sızma testi metodolojisi
bug-bounty.html            Doğrulanan zafiyet raporları
blog/index.html            Blog listesi
blog/<slug>/index.html     Blog yazısı (görseller blog/<slug>/img/ altında)
oscp-ultimate-guide/       OSCP Ultimate Guide — menüdeki OSCP sekmesi; TR + EN tek sayfada
oscp.html                  Eski adres; /oscp-ultimate-guide/ adresine yönlendirir
tools/new-post.ps1         Yeni blog yazısı oluşturma betiği
tools/build.py             Dilleri ayıran derleme (çıktı: _site/, git'e girmez)
.github/workflows/pages.yml  Derle + yayınla
404.html                   Özel hata sayfası
.nojekyll                  GitHub Pages Jekyll işlemesini kapatır (silmeyin)
robots.txt, sitemap.xml    Arama motoru dosyaları
CNAME                      Özel alan adı (huseyinkalkan.net)
assets/css/style.css       Tüm stiller
assets/js/main.js          Dil önerisi bandı + mobil menü
assets/favicon.svg         Site ikonu
```

## İki dilli içerik nasıl çalışır?

Kaynak dosyalarda Türkçe ve İngilizce yan yana durur:

```html
<p class="t-tr">Türkçe metin</p>
<p class="t-en" lang="en">English text</p>
```

`tools/build.py` her sayfayı ikiye böler: Türkçe `/<yol>`, İngilizce `/en/<yol>`.
Her sürüm kendi `<title>`/description/canonical/og etiketlerini, karşılıklı `hreflang`
bağlantılarını alır; `sitemap.xml` dil eşleşmeleriyle üretilir. İngilizce başlık ve açıklama
kaynak dosyanın `<head>` kısmındaki şu etiketlerden gelir (çıktıdan silinir):

```html
<meta name="i18n:title:en" content="...">           <!-- zorunlu -->
<meta name="i18n:description:en" content="...">     <!-- zorunlu -->
<meta name="i18n:og-title:en" content="...">        <!-- isteğe bağlı -->
<meta name="i18n:og-description:en" content="..."> <!-- isteğe bağlı -->
```

Dil seçici normal bir bağlantıdır. Dile göre otomatik yönlendirme yoktur (Googlebot'u yanlış
dile atar); tarayıcı dili farklıysa kapatılabilir küçük bir öneri bandı çıkar.

Yerel önizleme: `python tools/build.py` sonra `python -m http.server 8000 -d _site`.

## OSCP Ultimate Guide'ı düzenleme

`oscp-ultimate-guide/index.html` iki dili tek dosyada tutar: Türkçe içerik
`<div class="guide-body t-tr" id="guide-tr">`, İngilizce içerik
`<div class="guide-body t-en" lang="en" id="guide-en">` içindedir; sol menüdeki
içindekiler de iki ayrı `.toc` bloğudur. Bir bölümü değiştirirken **iki dili de**
güncelleyin. İngilizce başlık kimlikleri `en-` önekiyle başlar (ör. `#en-sudo`),
Türkçe kimliklerle çakışmaz.

## Yeni blog yazısı ekleme

Tek komut — üç dosyayı da kendisi hallediyor:

```powershell
.\tools\new-post.ps1 -Slug "nginx-alias-traversal" `
  -TitleTr "Nginx alias yanlış yapılandırması" `
  -TitleEn "Nginx alias misconfiguration" `
  -SummaryTr "Alias direktifindeki eksik eğik çizgi neden path traversal'a yol açıyor." `
  -SummaryEn "Why a missing trailing slash in the alias directive enables path traversal." `
  -Badge "Nginx / Path Traversal"
```

Bu komut:
1. `blog/<slug>/index.html` dosyasını iki dilli şablondan oluşturur,
2. `blog/index.html` listesinin **en üstüne** yazı kartını ekler,
3. `sitemap.xml` dosyasına yeni `<url>` girdisini ekler.

Sonra oluşan dosyadaki `ICERIK BURAYA` / `CONTENT HERE` bölümlerini doldurun ve:

```powershell
git add -A; git commit -m "Yeni yazı: ..."; git push
```

Oluştur + yayınla tek adımda isterseniz komuta `-Push` ekleyin.

Şablonda hazır bloklar var (uyarı kutusu, kod bloğu, tablo) — dosyadaki
HTML yorumunun içinden kopyalayın.

> `tools/new-post.ps1` **BOM'lu UTF-8** olarak kaydedilmiştir. Bu şart:
> Windows PowerShell 5.1, BOM'suz UTF-8 betikleri ANSI sanar ve içindeki
> Türkçe karakterler bozuk çıkar (`Kasım` → `KasÄ±m`).

## Jekyll kapalı

Kökteki `.nojekyll` dosyası GitHub Pages'in Jekyll işlemesini devre dışı bırakır.
**Silmeyin:** `oscp-ultimate-guide` içindeki SSTI bölümü `{{7*7}}` gibi Liquid
söz dizimiyle çakışan yükler içerir; Jekyll açıkken bunlar ya derlemeyi bozar
ya da sessizce silinir.

## Yerelde çalıştırma

Kök dizinden mutlak yollar (`/assets/...`) kullanıldığı için dosyayı çift tıklayarak
açmak yerine basit bir sunucu kullanın:

```bash
python -m http.server 8000
# http://localhost:8000
```
