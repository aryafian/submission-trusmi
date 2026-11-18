# Test Programmer Trusmi Group: KPI Divisi Marketing

Implementasi query SQL (Soal 1, 2, dan 5) serta dashboard web (Soal 3 dan 4) untuk memantau pencapaian KPI (`Sales` dan `Report`) dan ketepatan deadline karyawan divisi Marketing.

## Struktur Folder

- `sql/`: skrip setup database, query Soal 1 & 2 (kompatibel MySQL 8+/MariaDB 10.2+ dan PostgreSQL 12+), serta DDL normalisasi Soal 5 (`MySQL` dan `PostgreSQL`).
- `dashboard/`: aplikasi dashboard PHP native + PDO + Chart.js (di-vendor lokal).
  - `dashboard/public/`: document root web (`index.php`, `api.php`, `assets/`).
  - `dashboard/src/`: koneksi database, repository query, dan konfigurasi keamanan HTTP.
- `jawaban/`: file `.txt` siap kirim untuk Soal 1, 2, 5, dan lampiran prompt.
- `screenshots/`: hasil tangkapan layar dashboard dan grafik Soal 3 & 4.

## Prasyarat

- PHP 8.2+ dengan ekstensi `pdo_mysql` aktif (sudah tersedia di XAMPP).
- MySQL 8.0+ atau MariaDB 10.2+.
- Opsional: PostgreSQL 12+ jika ingin menguji skrip SQL versi PostgreSQL.

## Setup dan Menjalankan Dashboard (Soal 3 & 4)

### 1. Jalankan MySQL / MariaDB
Buka XAMPP Control Panel lalu klik **Start** pada MySQL, atau jalankan lewat PowerShell:

```powershell
C:\xampp\mysql\bin\mysqld.exe --defaults-file=C:\xampp\mysql\bin\my.ini --standalone
```

### 2. Import Database dan Akun Read-Only
Jalankan skrip setup berikut untuk membuat database `trusmi_kpi`, tabel `table_kpi_marketing` beserta data awal, covering index, dan akun khusus `trusmi_dash` (hanya punya hak `SELECT`):

```powershell
Get-Content e:\Trusmi\sql\01_setup_mysql.sql -Raw | C:\xampp\mysql\bin\mysql.exe -uroot
```

> Catatan keamanan: sebelum dipakai di server non-lokal, ubah password `trusmi_dash` di `sql/01_setup_mysql.sql`.

### 3. Konfigurasi Kredensial Dashboard
Salin `dashboard/config.local.example.php` menjadi `dashboard/config.local.php` (jika belum ada) lalu samakan password `trusmi_dash`:

```php
<?php

return [
    'db' => [
        'host'     => '127.0.0.1',
        'port'     => 3306,
        'name'     => 'trusmi_kpi',
        'user'     => 'trusmi_dash',
        'password' => 'GantiPasswordIni_2026',
    ],
];
```

Alternatif untuk server produksi: isi environment variable `DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USER`, dan `DB_PASSWORD` tanpa membuat `config.local.php`.

### 4. Jalankan Web Server
Arahkan document root **ke folder `dashboard/public`** (jangan ke root `dashboard/` agar `config.local.php` dan `src/` tetap berada di luar jangkauan web):

```powershell
php -S 127.0.0.1:8080 -t e:\Trusmi\dashboard\public
```

Jika memakai Apache XAMPP, buat VirtualHost dengan `DocumentRoot "e:/Trusmi/dashboard/public"`.

### 5. Buka di Browser
- Dashboard: `http://127.0.0.1:8080/`
- Endpoint JSON: `http://127.0.0.1:8080/api.php`

## Menjalankan Query SQL (Soal 1, 2, & 5)

### MySQL / MariaDB
```powershell
Get-Content e:\Trusmi\sql\soal_1.sql -Raw | C:\xampp\mysql\bin\mysql.exe -uroot -t trusmi_kpi
Get-Content e:\Trusmi\sql\soal_2.sql -Raw | C:\xampp\mysql\bin\mysql.exe -uroot -t trusmi_kpi
Get-Content e:\Trusmi\sql\soal_5_normalisasi_mysql.sql -Raw | C:\xampp\mysql\bin\mysql.exe -uroot -t trusmi_kpi
```

### PostgreSQL
Jalankan berurutan menggunakan `psql` atau pgAdmin:
1. `sql/01_setup_postgresql.sql`
2. `sql/soal_1.sql`
3. `sql/soal_2.sql`
4. `sql/soal_5_normalisasi_postgresql.sql`

## Catatan Optimasi & Keamanan

- **Query & Index**: Soal 1 dan 2 memakai single-pass conditional aggregation (`COUNT(CASE WHEN ...)`), `NULLIF` untuk mencegah pembagian nol, dan covering index `idx_karyawan_kpi_tanggal (karyawan, kpi, deadline, aktual)`.
- **HTTP & Caching**: `api.php` hanya menerima `GET`/`HEAD` (metode lain ditolak `405`) dan mengirim header `ETag` (`xxh128`) untuk mendukung `304 Not Modified`.
- **Keamanan Aplikasi**: PDO memakai `ATTR_EMULATE_PREPARES => false`, `display_errors = 0`, header keamanan (`Content-Security-Policy` ketat, `X-Frame-Options: DENY`, `X-Content-Type-Options: nosniff`), serta rendering DOM menggunakan `textContent` tanpa `innerHTML`.
