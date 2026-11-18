<?php

declare(strict_types=1);

require dirname(__DIR__) . '/src/bootstrap.php';

\Trusmi\Kpi\kirim_header_keamanan();
header('Content-Type: text/html; charset=utf-8');
?>
<!doctype html>
<html lang="id">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <meta name="color-scheme" content="light dark">
  <title>KPI Divisi Marketing · Trusmi Group</title>
  <script src="assets/theme-init.js"></script>
  <link rel="stylesheet" href="assets/app.css">
</head>
<body>
  <a class="skip-link" href="#konten">Lompat ke isi dashboard</a>

  <header class="topbar">
    <div class="topbar__judul">
      <p class="topbar__org">Trusmi Group</p>
      <h1>KPI Divisi Marketing</h1>
    </div>
    <div class="topbar__aksi">
      <nav aria-label="Bagian dashboard">
        <a href="#skor-kpi">Skor KPI</a>
        <a href="#deadline">Ketepatan deadline</a>
      </nav>
      <button type="button" class="tombol tombol--garis" id="tombol-tema" aria-pressed="false">Mode gelap</button>
    </div>
  </header>

  <main id="konten" tabindex="-1">
    <p class="aturan">
      Sumber data: <code>table_kpi_marketing</code>. Sales dan Report masing-masing berbobot 50% dengan target 2 tasklist.
      Setiap tasklist yang selesai lewat deadline memotong <span class="angka-late">7%</span> (Sales)
      atau <span class="angka-late">5%</span> (Report).
    </p>

    <div id="status" class="status" role="status" aria-live="polite">
      <p class="status__pesan" id="status-pesan">Memuat data dari table_kpi_marketing...</p>
      <button type="button" class="tombol" id="tombol-coba-lagi" hidden>Coba muat lagi</button>
    </div>

    <section id="skor-kpi" class="bagian" aria-labelledby="judul-skor" hidden>
      <div class="bagian__kepala">
        <h2 id="judul-skor">Siapa yang skor KPI-nya paling tinggi, dan berapa yang hilang karena late?</h2>
        <p class="keterangan">
          Panjang batang adalah skor sebelum potongan. Bagian <span class="swatch-late" aria-hidden="true"></span>bergaris
          adalah bobot yang hilang karena late. Angka di ujung batang adalah total bobot akhir.
        </p>
      </div>
      <p class="sorotan" id="sorotan-kpi"></p>
      <div class="grafik" id="wadah-grafik-kpi">
        <canvas id="grafik-kpi" role="img" aria-label="Grafik skor KPI per karyawan"></canvas>
      </div>

      <h3 id="caption-kpi" class="tabel-judul">Rincian perhitungan KPI (hasil query soal 1)</h3>
      <div class="tabel-wrap" role="region" aria-labelledby="caption-kpi" tabindex="0">
        <table class="tabel tabel--kpi" aria-labelledby="caption-kpi">
          <thead>
            <tr>
              <th scope="col" rowspan="2" class="kolom-nama">Nama</th>
              <th scope="colgroup" colspan="6" class="grup grup--sales">Sales</th>
              <th scope="colgroup" colspan="6" class="grup grup--report">Report</th>
              <th scope="col" rowspan="2" class="kolom-total">Total bobot</th>
            </tr>
            <tr>
              <th scope="col">Target</th><th scope="col">Actual</th><th scope="col">Pencapaian</th>
              <th scope="col">Bobot</th><th scope="col">Late</th><th scope="col">Total</th>
              <th scope="col">Target</th><th scope="col">Actual</th><th scope="col">Pencapaian</th>
              <th scope="col">Bobot</th><th scope="col">Late</th><th scope="col">Total</th>
            </tr>
          </thead>
          <tbody id="isi-tabel-kpi"></tbody>
        </table>
      </div>
    </section>

    <section id="deadline" class="bagian" aria-labelledby="judul-deadline" hidden>
      <div class="bagian__kepala">
        <h2 id="judul-deadline">Berapa tasklist yang selesai sebelum deadline?</h2>
        <p class="keterangan">Ontime jika tanggal aktual sama dengan atau sebelum deadline, late jika sesudahnya.</p>
      </div>

      <div class="deadline-grid">
        <figure class="ringkasan">
          <p class="ringkasan__angka" id="angka-ontime"></p>
          <figcaption class="ringkasan__teks" id="teks-ontime"></figcaption>
          <div class="grafik grafik--donat">
            <canvas id="grafik-donat" role="img" aria-label="Perbandingan tasklist ontime dan late"></canvas>
          </div>
        </figure>
        <div class="per-karyawan">
          <h3>Ontime dan late per karyawan</h3>
          <div class="grafik" id="wadah-grafik-deadline">
            <canvas id="grafik-deadline" role="img" aria-label="Jumlah tasklist ontime dan late per karyawan"></canvas>
          </div>
        </div>
      </div>

      <h3 id="caption-deadline" class="tabel-judul">Jumlah dan persentase tasklist ontime dan late (hasil query soal 2)</h3>
      <div class="tabel-wrap" role="region" aria-labelledby="caption-deadline" tabindex="0">
        <table class="tabel tabel--deadline" aria-labelledby="caption-deadline">
          <thead>
            <tr>
              <th scope="col" class="kolom-nama">Nama</th>
              <th scope="col">Total tasklist</th>
              <th scope="col">Ontime</th>
              <th scope="col">Late</th>
              <th scope="col">Belum selesai</th>
              <th scope="col">% Ontime</th>
              <th scope="col">% Late</th>
            </tr>
          </thead>
          <tbody id="isi-tabel-deadline"></tbody>
          <tfoot id="kaki-tabel-deadline"></tfoot>
        </table>
      </div>
    </section>
  </main>

  <footer class="kaki">
    <p id="waktu-muat"></p>
    <button type="button" class="tombol tombol--garis" id="tombol-muat-ulang" hidden>Muat ulang data</button>
  </footer>

  <script src="assets/vendor/chart-4.5.1.umd.min.js" defer></script>
  <script src="assets/app.js" defer></script>
</body>
</html>
