(function () {
  'use strict';

  var akar = document.documentElement;
  var el = function (id) { return document.getElementById(id); };

  var angka = new Intl.NumberFormat('id-ID', { maximumFractionDigits: 2 });
  var MINUS = '\u2212';

  function persen(v) {
    if (v === null || v === undefined) return '\u2013';
    return (v < 0 ? MINUS + angka.format(-v) : angka.format(v)) + '%';
  }

  var dataTerakhir = null;
  var grafik = [];

  function warna(nama) {
    return getComputedStyle(akar).getPropertyValue('--' + nama).trim();
  }

  // Pola garis miring untuk late: pembeda kedua selain warna, supaya tetap terbaca oleh pengguna buta warna.
  function polaLate() {
    var c = document.createElement('canvas');
    c.width = c.height = 8;
    var x = c.getContext('2d');
    x.fillStyle = warna('late');
    x.fillRect(0, 0, 8, 8);
    x.strokeStyle = warna('surface');
    x.lineWidth = 2;
    x.beginPath();
    x.moveTo(0, 8); x.lineTo(8, 0);
    x.moveTo(-2, 2); x.lineTo(2, -2);
    x.moveTo(6, 10); x.lineTo(10, 6);
    x.stroke();
    return x.createPattern(c, 'repeat');
  }

  // Semua teks dari database masuk lewat textContent, tidak pernah innerHTML, jadi nama berisi HTML tidak dieksekusi.
  function sel(tag, teks, kelas) {
    var n = document.createElement(tag);
    if (teks !== undefined && teks !== null) n.textContent = String(teks);
    if (kelas) n.className = kelas;
    return n;
  }

  function tampilkanStatus(pesan, jenis) {
    var box = el('status');
    box.hidden = false;
    box.classList.toggle('status--error', jenis === 'error');
    el('status-pesan').textContent = pesan;
    el('tombol-coba-lagi').hidden = jenis !== 'error';
  }

  function hapusGrafik() {
    grafik.forEach(function (g) { g.destroy(); });
    grafik = [];
  }

  function opsiDasar() {
    var ink = warna('ink');
    var garis = warna('line');
    Chart.defaults.font.family = getComputedStyle(document.body).fontFamily;
    Chart.defaults.font.size = 13;
    Chart.defaults.color = ink;
    Chart.defaults.borderColor = garis;
    return {
      responsive: true,
      maintainAspectRatio: false,
      // MOTION 1: grafik muncul langsung, tanpa animasi.
      animation: false,
      plugins: {
        legend: {
          position: 'bottom',
          labels: { boxWidth: 18, boxHeight: 12, padding: 16, color: ink }
        }
      }
    };
  }

  var labelTotal = {
    id: 'labelTotal',
    afterDatasetsDraw: function (chart) {
      var meta = chart.getDatasetMeta(chart.data.datasets.length - 1);
      var ctx = chart.ctx;
      var totals = chart.options.plugins.labelTotal.totals;
      ctx.save();
      ctx.font = '700 13px ' + Chart.defaults.font.family;
      ctx.fillStyle = warna('ink');
      ctx.textBaseline = 'middle';
      meta.data.forEach(function (bar, i) {
        ctx.fillText(persen(totals[i]), bar.x + 6, bar.y);
      });
      ctx.restore();
    }
  };

  function aturTinggi(wadahId, jumlahBaris) {
    el(wadahId).style.height = Math.max(16, jumlahBaris * 3.5 + 6) + 'rem';
  }

  function grafikKpi(rows) {
    var surface = warna('surface');
    var opsi = opsiDasar();
    aturTinggi('wadah-grafik-kpi', rows.length);

    var potongan = rows.map(function (r) { return -(r.sales.late + r.report.late); });
    var segmen = { borderColor: surface, borderWidth: 2, borderSkipped: false, barPercentage: 0.7 };

    opsi.indexAxis = 'y';
    opsi.layout = { padding: { right: 48 } };
    opsi.scales = {
      x: {
        stacked: true, min: 0, max: 100,
        ticks: { callback: function (v) { return v + '%'; }, stepSize: 25 },
        title: { display: true, text: 'Bobot KPI (%)' }
      },
      y: { stacked: true, grid: { display: false } }
    };
    opsi.plugins.labelTotal = { totals: rows.map(function (r) { return r.totalBobot; }) };
    opsi.plugins.tooltip = {
      callbacks: {
        label: function (c) {
          var r = rows[c.dataIndex];
          if (c.datasetIndex === 0) return 'Sales: ' + persen(r.sales.total) + ' (pencapaian ' + persen(r.sales.pencapaian) + ', late ' + persen(r.sales.late) + ')';
          if (c.datasetIndex === 1) return 'Report: ' + persen(r.report.total) + ' (pencapaian ' + persen(r.report.pencapaian) + ', late ' + persen(r.report.late) + ')';
          return 'Hilang karena late: ' + persen(-potongan[c.dataIndex]);
        },
        footer: function (items) { return 'Total bobot: ' + persen(rows[items[0].dataIndex].totalBobot); }
      }
    };

    grafik.push(new Chart(el('grafik-kpi'), {
      type: 'bar',
      data: {
        labels: rows.map(function (r) { return r.nama; }),
        datasets: [
          Object.assign({ label: 'Sales', data: rows.map(function (r) { return Math.max(0, r.sales.total); }), backgroundColor: warna('sales') }, segmen),
          Object.assign({ label: 'Report', data: rows.map(function (r) { return Math.max(0, r.report.total); }), backgroundColor: warna('report') }, segmen),
          Object.assign({ label: 'Hilang karena late', data: potongan, backgroundColor: polaLate() }, segmen)
        ]
      },
      options: opsi,
      plugins: [labelTotal]
    }));

    el('grafik-kpi').setAttribute('aria-label', 'Total bobot KPI: ' + rows.map(function (r) {
      return r.nama + ' ' + persen(r.totalBobot) + (r.sales.late + r.report.late < 0 ? ' (potongan late ' + persen(r.sales.late + r.report.late) + ')' : '');
    }).join(', ') + '. Rincian lengkap ada di tabel di bawah grafik.');
  }

  function grafikDeadline(d) {
    var surface = warna('surface');
    var segmen = { borderColor: surface, borderWidth: 2, borderSkipped: false };
    var r = d.ringkasan;

    var opsiDonat = opsiDasar();
    opsiDonat.cutout = '62%';
    opsiDonat.plugins.legend.position = 'bottom';
    grafik.push(new Chart(el('grafik-donat'), {
      type: 'doughnut',
      data: {
        labels: ['Ontime', 'Late'],
        datasets: [Object.assign({ data: [r.ontime, r.late], backgroundColor: [warna('ontime'), polaLate()] }, segmen)]
      },
      options: opsiDonat
    }));
    el('grafik-donat').setAttribute('aria-label', r.ontime + ' tasklist ontime dan ' + r.late + ' tasklist late.');

    var rows = d.perKaryawan;
    var opsi = opsiDasar();
    aturTinggi('wadah-grafik-deadline', rows.length);
    opsi.indexAxis = 'y';
    opsi.scales = {
      x: { stacked: true, beginAtZero: true, ticks: { precision: 0, stepSize: 1 }, title: { display: true, text: 'Jumlah tasklist' } },
      y: { stacked: true, grid: { display: false } }
    };
    opsi.plugins.tooltip = {
      callbacks: {
        label: function (c) {
          var b = rows[c.dataIndex];
          return c.datasetIndex === 0
            ? 'Ontime: ' + b.ontime + ' (' + persen(b.persenOntime) + ')'
            : 'Late: ' + b.late + ' (' + persen(b.persenLate) + ')';
        }
      }
    };
    grafik.push(new Chart(el('grafik-deadline'), {
      type: 'bar',
      data: {
        labels: rows.map(function (b) { return b.nama; }),
        datasets: [
          Object.assign({ label: 'Ontime', data: rows.map(function (b) { return b.ontime; }), backgroundColor: warna('ontime'), barPercentage: 0.7 }, segmen),
          Object.assign({ label: 'Late', data: rows.map(function (b) { return b.late; }), backgroundColor: polaLate(), barPercentage: 0.7 }, segmen)
        ]
      },
      options: opsi
    }));
    el('grafik-deadline').setAttribute('aria-label', rows.map(function (b) {
      return b.nama + ': ' + b.ontime + ' ontime, ' + b.late + ' late';
    }).join('; ') + '.');
  }

  function tabelKpi(rows) {
    var tbody = el('isi-tabel-kpi');
    var frag = document.createDocumentFragment();
    rows.forEach(function (r) {
      var tr = document.createElement('tr');
      var th = sel('th', r.nama);
      th.scope = 'row';
      tr.appendChild(th);
      [r.sales, r.report].forEach(function (k) {
        tr.appendChild(sel('td', k.target));
        tr.appendChild(sel('td', k.actual));
        tr.appendChild(sel('td', persen(k.pencapaian)));
        tr.appendChild(sel('td', persen(k.bobot)));
        tr.appendChild(sel('td', persen(k.late), k.late < 0 ? 'late-ada' : ''));
        tr.appendChild(sel('td', persen(k.total)));
      });
      tr.appendChild(sel('td', persen(r.totalBobot), 'total-bobot'));
      frag.appendChild(tr);
    });
    tbody.replaceChildren(frag);
  }

  function barisDeadline(tag, nama, b) {
    var tr = document.createElement('tr');
    var th = sel('th', nama);
    th.scope = 'row';
    tr.appendChild(th);
    tr.appendChild(sel(tag, b.total));
    tr.appendChild(sel(tag, b.ontime));
    tr.appendChild(sel(tag, b.late, b.late > 0 ? 'late-ada' : ''));
    tr.appendChild(sel(tag, b.belumSelesai));
    tr.appendChild(sel(tag, persen(b.persenOntime)));
    tr.appendChild(sel(tag, persen(b.persenLate), b.late > 0 ? 'late-ada' : ''));
    return tr;
  }

  function tabelDeadline(d) {
    var frag = document.createDocumentFragment();
    d.perKaryawan.forEach(function (b) { frag.appendChild(barisDeadline('td', b.nama, b)); });
    el('isi-tabel-deadline').replaceChildren(frag);
    el('kaki-tabel-deadline').replaceChildren(barisDeadline('td', 'Semua karyawan', d.ringkasan));
  }

  function sorotanKpi(rows) {
    var tertinggi = rows.reduce(function (a, b) { return b.totalBobot > a.totalBobot ? b : a; });
    var potonganTerbesar = rows.reduce(function (a, b) {
      return (b.sales.late + b.report.late) < (a.sales.late + a.report.late) ? b : a;
    });
    var teks = tertinggi.nama + ' tertinggi dengan total bobot ' + persen(tertinggi.totalBobot) + '.';
    var pot = potonganTerbesar.sales.late + potonganTerbesar.report.late;
    if (pot < 0) teks += ' Potongan late terbesar dialami ' + potonganTerbesar.nama + ' (' + persen(pot) + ').';
    el('sorotan-kpi').textContent = teks;
  }

  function ringkasanDeadline(r) {
    el('angka-ontime').textContent = persen(r.persenOntime);
    var teks = 'tasklist selesai ontime (' + r.ontime + ' dari ' + (r.ontime + r.late) + ' yang sudah selesai). ' +
      r.late + ' tasklist late (' + persen(r.persenLate) + ').';
    if (r.belumSelesai > 0) teks += ' ' + r.belumSelesai + ' tasklist belum punya tanggal aktual dan tidak dihitung.';
    el('teks-ontime').textContent = teks;
  }

  function render(data) {
    hapusGrafik();
    var adaKpi = data.kpi.length > 0;
    var adaDeadline = data.deadline.perKaryawan.length > 0;

    if (!adaKpi && !adaDeadline) {
      el('skor-kpi').hidden = true;
      el('deadline').hidden = true;
      tampilkanStatus('Belum ada tasklist di table_kpi_marketing. Tambahkan data tasklist Sales atau Report, lalu tekan Muat ulang data.', 'kosong');
      return;
    }

    el('status').hidden = true;

    el('skor-kpi').hidden = !adaKpi;
    if (adaKpi) {
      sorotanKpi(data.kpi);
      tabelKpi(data.kpi);
      grafikKpi(data.kpi);
    }

    el('deadline').hidden = !adaDeadline;
    if (adaDeadline) {
      ringkasanDeadline(data.deadline.ringkasan);
      tabelDeadline(data.deadline);
      grafikDeadline(data.deadline);
    }
  }

  function muat() {
    var kontrol = new AbortController();
    var batas = setTimeout(function () { kontrol.abort(); }, 10000);
    el('tombol-muat-ulang').disabled = true;
    if (!dataTerakhir) tampilkanStatus('Memuat data dari table_kpi_marketing...', 'muat');

    // cache: 'no-cache' membuat browser bertanya ke server dengan ETag; kalau data sama, server balas 304 tanpa body.
    fetch('api.php', { headers: { Accept: 'application/json' }, cache: 'no-cache', signal: kontrol.signal })
      .then(function (res) {
        return res.json().catch(function () { return {}; }).then(function (body) {
          if (!res.ok) throw new Error(body.error || 'Server membalas kode ' + res.status + '.');
          return body;
        });
      })
      .then(function (data) {
        if (!data || !Array.isArray(data.kpi) || !data.deadline || !Array.isArray(data.deadline.perKaryawan)) {
          throw new Error('Format data dari server tidak dikenali.');
        }
        dataTerakhir = data;
        render(data);
        el('waktu-muat').textContent = 'Data dimuat pukul ' + new Date().toLocaleTimeString('id-ID', { hour: '2-digit', minute: '2-digit' }) + '.';
        el('tombol-muat-ulang').hidden = false;
      })
      .catch(function (err) {
        var pesan = err.name === 'AbortError'
          ? 'Server tidak menjawab dalam 10 detik.'
          : (err instanceof TypeError ? 'Tidak bisa terhubung ke server dashboard.' : err.message);
        el('skor-kpi').hidden = true;
        el('deadline').hidden = true;
        hapusGrafik();
        dataTerakhir = null;
        tampilkanStatus('Data KPI gagal dimuat: ' + pesan + ' Pastikan MariaDB berjalan dan akun trusmi_dash sudah dibuat, lalu coba lagi.', 'error');
      })
      .finally(function () {
        clearTimeout(batas);
        el('tombol-muat-ulang').disabled = false;
      });
  }

  function sinkronTombolTema() {
    var gelap = akar.dataset.tema === 'gelap';
    var tombol = el('tombol-tema');
    tombol.setAttribute('aria-pressed', String(gelap));
    tombol.textContent = gelap ? 'Mode terang' : 'Mode gelap';
  }

  el('tombol-tema').addEventListener('click', function () {
    akar.dataset.tema = akar.dataset.tema === 'gelap' ? 'terang' : 'gelap';
    try { localStorage.setItem('tema', akar.dataset.tema); } catch (e) { /* tema tetap berlaku untuk sesi ini */ }
    sinkronTombolTema();
    if (dataTerakhir) render(dataTerakhir);
  });

  el('tombol-coba-lagi').addEventListener('click', muat);
  el('tombol-muat-ulang').addEventListener('click', muat);

  sinkronTombolTema();

  if (typeof Chart === 'undefined') {
    tampilkanStatus('Library grafik (assets/vendor/chart-4.5.1.umd.min.js) gagal dimuat. Periksa file tersebut, lalu muat ulang halaman.', 'error');
    el('tombol-coba-lagi').hidden = true;
    return;
  }

  muat();
})();
