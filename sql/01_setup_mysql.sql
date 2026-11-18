-- Setup database untuk soal 1-4 (MySQL 8+ / MariaDB 10.2+).
-- Struktur dan data sama dengan soal. Tambahan: PRIMARY KEY dan index (lihat soal 5).

CREATE DATABASE IF NOT EXISTS `trusmi_kpi` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE `trusmi_kpi`;

DROP TABLE IF EXISTS `table_kpi_marketing`;
CREATE TABLE `table_kpi_marketing` (
  `id` int(11) NOT NULL,
  `tasklist` varchar(100) DEFAULT NULL,
  `kpi` varchar(100) DEFAULT NULL,
  `karyawan` varchar(100) DEFAULT NULL,
  `deadline` date DEFAULT NULL,
  `aktual` date DEFAULT NULL,
  PRIMARY KEY (`id`),
  -- Covering index: query soal 1 dan 2 cukup membaca index ini tanpa menyentuh baris tabel.
  KEY `idx_karyawan_kpi_tanggal` (`karyawan`, `kpi`, `deadline`, `aktual`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

INSERT INTO `table_kpi_marketing` (`id`, `tasklist`, `kpi`, `karyawan`, `deadline`, `aktual`) VALUES
(1, 'Tasklist 1', 'Sales', 'Budi', '2022-01-10', '2022-01-09'),
(2, 'Tasklist 2', 'Sales', 'Budi', '2022-01-10', '2022-01-08'),
(3, 'Tasklist 3', 'Report', 'Budi', '2022-01-10', '2022-01-07'),
(4, 'Tasklist 4', 'Report', 'Budi', '2022-01-10', '2022-01-12'),
(5, 'Tasklist 5', 'Sales', 'Adi', '2022-01-10', '2022-01-09'),
(6, 'Tasklist 6', 'Sales', 'Adi', '2022-01-10', '2022-01-12'),
(7, 'Tasklist 7', 'Report', 'Adi', '2022-01-10', '2022-01-07'),
(8, 'Tasklist 8', 'Report', 'Adi', '2022-01-10', '2022-01-07'),
(9, 'Tasklist 9', 'Sales', 'Rara', '2022-01-10', '2022-01-12'),
(10, 'Tasklist 10', 'Sales', 'Rara', '2022-01-10', '2022-01-09'),
(11, 'Tasklist 11', 'Report', 'Rara', '2022-01-10', '2022-01-12'),
(12, 'Tasklist 12', 'Report', 'Doni', '2022-01-10', '2022-01-09'),
(13, 'Tasklist 13', 'Sales', 'Doni', '2022-01-10', '2022-01-12');

-- Akun khusus dashboard: hanya boleh SELECT di satu tabel, tidak memakai root.
-- Ganti password ini sebelum dipakai, lalu samakan di dashboard/config.local.php.
CREATE USER IF NOT EXISTS 'trusmi_dash'@'localhost' IDENTIFIED BY 'GantiPasswordIni_2026';
GRANT SELECT ON `trusmi_kpi`.`table_kpi_marketing` TO 'trusmi_dash'@'localhost';
CREATE USER IF NOT EXISTS 'trusmi_dash'@'127.0.0.1' IDENTIFIED BY 'GantiPasswordIni_2026';
GRANT SELECT ON `trusmi_kpi`.`table_kpi_marketing` TO 'trusmi_dash'@'127.0.0.1';
FLUSH PRIVILEGES;
