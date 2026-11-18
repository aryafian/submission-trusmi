-- Soal 2: jumlah dan persentase tasklist ontime vs late.
-- Jalan tanpa perubahan di MySQL 8+, MariaDB 10.2+, dan PostgreSQL 12+.
-- Tasklist yang belum punya tanggal aktual tidak dihitung ontime maupun late; ditampilkan sebagai "belum_selesai".

-- 2a. Rekap keseluruhan
SELECT COUNT(*)                                             AS total_tasklist,
       COUNT(CASE WHEN aktual <= deadline THEN 1 END)       AS ontime,
       COUNT(CASE WHEN aktual >  deadline THEN 1 END)       AS late,
       COUNT(CASE WHEN aktual IS NULL THEN 1 END)           AS belum_selesai,
       ROUND(COUNT(CASE WHEN aktual <= deadline THEN 1 END) * 100.0
             / NULLIF(COUNT(aktual), 0), 2)                 AS persen_ontime,
       ROUND(COUNT(CASE WHEN aktual >  deadline THEN 1 END) * 100.0
             / NULLIF(COUNT(aktual), 0), 2)                 AS persen_late
FROM table_kpi_marketing;

-- 2b. Rincian per karyawan
SELECT karyawan                                             AS nama,
       COUNT(*)                                             AS total_tasklist,
       COUNT(CASE WHEN aktual <= deadline THEN 1 END)       AS ontime,
       COUNT(CASE WHEN aktual >  deadline THEN 1 END)       AS late,
       COUNT(CASE WHEN aktual IS NULL THEN 1 END)           AS belum_selesai,
       ROUND(COUNT(CASE WHEN aktual <= deadline THEN 1 END) * 100.0
             / NULLIF(COUNT(aktual), 0), 2)                 AS persen_ontime,
       ROUND(COUNT(CASE WHEN aktual >  deadline THEN 1 END) * 100.0
             / NULLIF(COUNT(aktual), 0), 2)                 AS persen_late
FROM table_kpi_marketing
GROUP BY karyawan
ORDER BY MIN(id);
