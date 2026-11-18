// Dipasang sebelum CSS dirender supaya tidak ada kedipan tema terang saat pengguna memilih gelap.
(function () {
  var tersimpan = null;
  try {
    tersimpan = localStorage.getItem('tema');
  } catch (e) {
    // localStorage bisa diblokir (mode privat tertentu); jatuh ke preferensi sistem.
  }
  var tema = tersimpan === 'gelap' || tersimpan === 'terang'
    ? tersimpan
    : (window.matchMedia('(prefers-color-scheme: dark)').matches ? 'gelap' : 'terang');
  document.documentElement.dataset.tema = tema;
})();
