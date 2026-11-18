-- Soal 1: skor KPI per karyawan. Jalan tanpa perubahan di MySQL 8+, MariaDB 10.2+, dan PostgreSQL 12+.
-- Angka persen ditulis dalam satuan % (100.00 = 100%).
WITH aturan AS (
  -- Satu-satunya tempat aturan KPI ditulis. Ubah di sini kalau bobot/target berubah.
  SELECT 2 AS sales_target,  50 AS sales_bobot,  -7 AS sales_bobot_late,
         2 AS report_target, 50 AS report_bobot, -5 AS report_bobot_late
),
rekap AS (
  -- Satu kali baca tabel: semua hitungan per KPI dikumpulkan lewat conditional aggregation.
  SELECT karyawan,
         MIN(id) AS urutan,
         COUNT(CASE WHEN kpi = 'Sales'  AND aktual IS NOT NULL THEN 1 END) AS sales_actual,
         COUNT(CASE WHEN kpi = 'Sales'  AND aktual > deadline  THEN 1 END) AS sales_jumlah_late,
         COUNT(CASE WHEN kpi = 'Report' AND aktual IS NOT NULL THEN 1 END) AS report_actual,
         COUNT(CASE WHEN kpi = 'Report' AND aktual > deadline  THEN 1 END) AS report_jumlah_late
  FROM table_kpi_marketing
  WHERE kpi IN ('Sales', 'Report')
  GROUP BY karyawan
),
skor AS (
  SELECT r.karyawan,
         r.urutan,
         a.sales_target,
         r.sales_actual,
         LEAST(r.sales_actual * 100.0 / a.sales_target, 100) AS sales_pencapaian,
         a.sales_bobot,
         r.sales_jumlah_late * a.sales_bobot_late AS sales_late,
         a.report_target,
         r.report_actual,
         LEAST(r.report_actual * 100.0 / a.report_target, 100) AS report_pencapaian,
         a.report_bobot,
         r.report_jumlah_late * a.report_bobot_late AS report_late
  FROM rekap r
  CROSS JOIN aturan a
)
SELECT karyawan                                                   AS nama,
       sales_target,
       sales_actual,
       ROUND(sales_pencapaian, 2)                                 AS sales_pencapaian,
       sales_bobot,
       sales_late,
       ROUND(sales_pencapaian * sales_bobot / 100 + sales_late, 2)     AS sales_total,
       report_target,
       report_actual,
       ROUND(report_pencapaian, 2)                                AS report_pencapaian,
       report_bobot,
       report_late,
       ROUND(report_pencapaian * report_bobot / 100 + report_late, 2) AS report_total,
       ROUND(sales_pencapaian * sales_bobot / 100 + sales_late
           + report_pencapaian * report_bobot / 100 + report_late, 2) AS total_bobot
FROM skor
ORDER BY urutan;
