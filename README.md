# huseyinkalkan.net

Hüseyin Kalkan'ın kişisel sitesi — IT altyapı, siber güvenlik, pentest ve bug bounty notları.
GitHub Pages üzerinde, derleme adımı olmadan (saf HTML/CSS/JS) yayınlanır.

## Yapı

```
index.html                 Ana sayfa
pentest.html               Sızma testi metodolojisi
oscp.html                  OSCP hazırlık notları
bug-bounty.html            Doğrulanan zafiyet raporları
blog/index.html            Blog listesi
blog/<slug>/index.html     Blog yazısı
404.html                   Özel hata sayfası
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

## Yeni blog yazısı ekleme

1. `blog/<slug>/index.html` oluşturun (mevcut bir yazıyı kopyalayarak başlayın).
2. `blog/index.html` içine yeni bir `<article class="post-card">` bloğu ekleyin.
3. `sitemap.xml` dosyasına yeni `<url>` girdisi ekleyin.

## Yerelde çalıştırma

Kök dizinden mutlak yollar (`/assets/...`) kullanıldığı için dosyayı çift tıklayarak
açmak yerine basit bir sunucu kullanın:

```bash
python -m http.server 8000
# http://localhost:8000
```
