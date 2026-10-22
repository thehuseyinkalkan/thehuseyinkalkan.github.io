document.addEventListener('DOMContentLoaded', () => {
  const savedLang = localStorage.getItem('site_lang') || 'tr';
  setLanguage(savedLang);
});

function toggleLanguage() {
  const currentLang = localStorage.getItem('site_lang') || 'tr';
  const newLang = currentLang === 'tr' ? 'en' : 'tr';
  setLanguage(newLang);
}

function setLanguage(lang) {
  localStorage.setItem('site_lang', lang);
  
  const trElements = document.querySelectorAll('[lang="tr"]');
  const enElements = document.querySelectorAll('[lang="en"]');
  const langBtn = document.getElementById('lang-btn');

  if (lang === 'en') {
    trElements.forEach(el => el.style.display = 'none');
    enElements.forEach(el => el.style.display = 'block');
    if (langBtn) langBtn.textContent = 'TR / EN [EN]';
  } else {
    enElements.forEach(el => el.style.display = 'none');
    trElements.forEach(el => el.style.display = 'block');
    if (langBtn) langBtn.textContent = 'TR / EN [TR]';
  }
}
