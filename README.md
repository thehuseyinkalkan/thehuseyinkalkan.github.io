# huseyinkalkan.net

Hüseyin Kalkan'ın kişisel sitesi — IT altyapı, siber güvenlik, pentest ve bug bounty notları.
GitHub Pages üzerinde, derleme adımı olmadan (saf HTML/CSS/JS) yayınlanır.

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
404.html                   Özel hata sayfası
.nojekyll                  GitHub Pages Jekyll işlemesini kapatır (silmeyin)
robots.txt, sitemap.xml    Arama motoru dosyaları
CNAME                      Özel alan adı (huseyinkalkan.net)
assets/css/style.css       Tüm stiller
assets/js/main.js          Dil değiştirme + mobil menü
assets/favicon.svg         Site ikonu
```

## İki dilli içerik nasıl çalışır?

Türkçe ve İngilizce metinler aynı sayfada durur, görünürlük CSS ile yönetilir:

```html
<p class="t-tr">Türkçe metin</p>
<p class="t-en" lang="en">English text</p>
```

```css
html[data-lang="tr"] .t-en { display: none !important; }
html[data-lang="en"] .t-tr { display: none !important; }
```

Seçilen dil `<html data-lang="...">` üzerinde tutulur ve `localStorage` içine yazılır.
Her sayfanın `<head>` bölümündeki küçük satır içi betik, dili **ilk boyamadan önce**
uygular; böylece içerik yanlış dilde yanıp sönmez.

> **Dikkat:** Görünürlük için asla `[lang="tr"]` / `[lang="en"]` seçicisi kullanmayın.
> Bu seçici `<html lang="tr">` etiketini de yakalar ve köke `display:none` vererek
> tüm sayfayı görünmez bırakır.

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
