-- Soal 5: normalisasi table_kpi_marketing (MySQL 8.0.16+ / MariaDB 10.2+).
-- Hasil: divisi, karyawan, kpi (aturan KPI ikut disimpan), tasklist.
USE `trusmi_kpi`;

DROP VIEW  IF EXISTS `v_skor_kpi`;
DROP TABLE IF EXISTS `tasklist`, `kpi`, `karyawan`, `divisi`;

CREATE TABLE `divisi` (
  `id`   smallint unsigned NOT NULL AUTO_INCREMENT,
  `nama` varchar(50) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_divisi_nama` (`nama`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `karyawan` (
  `id`        int unsigned NOT NULL AUTO_INCREMENT,
  `nama`      varchar(100) NOT NULL,
  `divisi_id` smallint unsigned NOT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_karyawan_divisi` (`divisi_id`),
  CONSTRAINT `fk_karyawan_divisi` FOREIGN KEY (`divisi_id`) REFERENCES `divisi` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Target, bobot, dan bobot late sekarang data, bukan angka yang di-hardcode di query.
CREATE TABLE `kpi` (
  `id`         smallint unsigned NOT NULL AUTO_INCREMENT,
  `divisi_id`  smallint unsigned NOT NULL,
  `nama`       varchar(50) NOT NULL,
  `target`     smallint unsigned NOT NULL,
  `bobot`      decimal(5,2) NOT NULL,
  `bobot_late` decimal(5,2) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_kpi_divisi_nama` (`divisi_id`, `nama`),
  CONSTRAINT `fk_kpi_divisi` FOREIGN KEY (`divisi_id`) REFERENCES `divisi` (`id`),
  CONSTRAINT `ck_kpi_target`     CHECK (`target` > 0),
  CONSTRAINT `ck_kpi_bobot`      CHECK (`bobot` BETWEEN 0 AND 100),
  CONSTRAINT `ck_kpi_bobot_late` CHECK (`bobot_late` BETWEEN -100 AND 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Status ontime/late tidak disimpan: selalu diturunkan dari deadline vs aktual supaya tidak bisa basi.
CREATE TABLE `tasklist` (
  `id`          int unsigned NOT NULL AUTO_INCREMENT,
  `nama`        varchar(100) NOT NULL,
  `kpi_id`      smallint unsigned NOT NULL,
  `karyawan_id` int unsigned NOT NULL,
  `deadline`    date NOT NULL,
  `aktual`      date NULL,
  PRIMARY KEY (`id`),
  -- Urutan kolom mengikuti pola akses: rekap per karyawan per KPI, lalu bandingkan tanggal.
  KEY `idx_tasklist_karyawan_kpi` (`karyawan_id`, `kpi_id`, `deadline`, `aktual`),
  KEY `idx_tasklist_kpi` (`kpi_id`),
  KEY `idx_tasklist_deadline` (`deadline`),
  CONSTRAINT `fk_tasklist_kpi`      FOREIGN KEY (`kpi_id`)      REFERENCES `kpi` (`id`),
  CONSTRAINT `fk_tasklist_karyawan` FOREIGN KEY (`karyawan_id`) REFERENCES `karyawan` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Migrasi data lama.
START TRANSACTION;

INSERT INTO `divisi` (`nama`) VALUES ('Marketing');

INSERT INTO `kpi` (`divisi_id`, `nama`, `target`, `bobot`, `bobot_late`)
SELECT d.id, a.nama, a.target, a.bobot, a.bobot_late
FROM divisi d
CROSS JOIN (
  SELECT 'Sales' AS nama, 2 AS target, 50 AS bobot, -7 AS bobot_late
  UNION ALL
  SELECT 'Report', 2, 50, -5
) a
WHERE d.nama = 'Marketing';

INSERT INTO `karyawan` (`nama`, `divisi_id`)
SELECT s.karyawan, d.id
FROM (
  SELECT TRIM(karyawan) AS karyawan, MIN(id) AS urutan
  FROM table_kpi_marketing
  WHERE karyawan IS NOT NULL
  GROUP BY TRIM(karyawan)
) s
CROSS JOIN divisi d
WHERE d.nama = 'Marketing'
ORDER BY s.urutan;

INSERT INTO `tasklist` (`id`, `nama`, `kpi_id`, `karyawan_id`, `deadline`, `aktual`)
SELECT t.id, t.tasklist, k.id, w.id, t.deadline, t.aktual
FROM table_kpi_marketing t
JOIN divisi d   ON d.nama = 'Marketing'
JOIN kpi k      ON k.divisi_id = d.id AND k.nama = TRIM(t.kpi)
JOIN karyawan w ON w.divisi_id = d.id AND w.nama = TRIM(t.karyawan);

COMMIT;

-- Skor per karyawan per KPI, berlaku untuk KPI berapa pun yang terdaftar di tabel kpi.
CREATE VIEW `v_skor_kpi` AS
SELECT w.id                                                          AS karyawan_id,
       w.nama                                                        AS karyawan,
       k.nama                                                        AS kpi,
       k.target,
       COUNT(t.aktual)                                               AS actual,
       LEAST(COUNT(t.aktual) * 100.0 / k.target, 100)                AS pencapaian,
       k.bobot,
       COUNT(CASE WHEN t.aktual > t.deadline THEN 1 END) * k.bobot_late AS late
FROM karyawan w
JOIN kpi k           ON k.divisi_id = w.divisi_id
LEFT JOIN tasklist t ON t.karyawan_id = w.id AND t.kpi_id = k.id
GROUP BY w.id, w.nama, k.id, k.nama, k.target, k.bobot, k.bobot_late;

-- Output soal 1 dari skema baru (hasilnya identik dengan query di soal 1).
SELECT karyawan                                                                AS nama,
       MAX(CASE WHEN kpi = 'Sales'  THEN target END)                           AS sales_target,
       MAX(CASE WHEN kpi = 'Sales'  THEN actual END)                           AS sales_actual,
       ROUND(MAX(CASE WHEN kpi = 'Sales'  THEN pencapaian END), 2)             AS sales_pencapaian,
       MAX(CASE WHEN kpi = 'Sales'  THEN bobot END)                            AS sales_bobot,
       MAX(CASE WHEN kpi = 'Sales'  THEN late END)                             AS sales_late,
       ROUND(MAX(CASE WHEN kpi = 'Sales'  THEN pencapaian * bobot / 100 + late END), 2) AS sales_total,
       MAX(CASE WHEN kpi = 'Report' THEN target END)                           AS report_target,
       MAX(CASE WHEN kpi = 'Report' THEN actual END)                           AS report_actual,
       ROUND(MAX(CASE WHEN kpi = 'Report' THEN pencapaian END), 2)             AS report_pencapaian,
       MAX(CASE WHEN kpi = 'Report' THEN bobot END)                            AS report_bobot,
       MAX(CASE WHEN kpi = 'Report' THEN late END)                             AS report_late,
       ROUND(MAX(CASE WHEN kpi = 'Report' THEN pencapaian * bobot / 100 + late END), 2) AS report_total,
       ROUND(SUM(pencapaian * bobot / 100 + late), 2)                          AS total_bobot
FROM v_skor_kpi
GROUP BY karyawan_id, karyawan
ORDER BY karyawan_id;
