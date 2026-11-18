-- Setup tabel untuk PostgreSQL 12+. Query soal 1 dan 2 berjalan apa adanya di sini.

DROP TABLE IF EXISTS table_kpi_marketing;
CREATE TABLE table_kpi_marketing (
  id integer PRIMARY KEY,
  tasklist varchar(100),
  kpi varchar(100),
  karyawan varchar(100),
  deadline date,
  aktual date
);

CREATE INDEX idx_karyawan_kpi_tanggal ON table_kpi_marketing (karyawan, kpi, deadline, aktual);

INSERT INTO table_kpi_marketing (id, tasklist, kpi, karyawan, deadline, aktual) VALUES
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
