<?php

declare(strict_types=1);

namespace Trusmi\Kpi;

use PDO;

/**
 * Query di sini sama persis dengan jawaban soal 1 dan soal 2b (folder sql/).
 * Tidak ada input pengguna yang masuk ke SQL, jadi query statis aman dijalankan langsung.
 */
final class KpiRepository
{
    private const SQL_SKOR_KPI = <<<'SQL'
        WITH aturan AS (
          SELECT 2 AS sales_target,  50 AS sales_bobot,  -7 AS sales_bobot_late,
                 2 AS report_target, 50 AS report_bobot, -5 AS report_bobot_late
        ),
        rekap AS (
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
        ORDER BY urutan
        SQL;

    private const SQL_DEADLINE_PER_KARYAWAN = <<<'SQL'
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
        ORDER BY MIN(id)
        SQL;

    public function __construct(private readonly PDO $pdo)
    {
    }

    /** @return list<array<string, mixed>> */
    public function skorKpi(): array
    {
        $rows = [];
        foreach ($this->pdo->query(self::SQL_SKOR_KPI) as $r) {
            $rows[] = [
                'nama'   => (string) $r['nama'],
                'sales'  => self::blokKpi($r, 'sales'),
                'report' => self::blokKpi($r, 'report'),
                'totalBobot' => (float) $r['total_bobot'],
            ];
        }
        return $rows;
    }

    /** @return array{ringkasan: array<string, int|float|null>, perKaryawan: list<array<string, mixed>>} */
    public function ketepatanDeadline(): array
    {
        $perKaryawan = [];
        $total = ['total' => 0, 'ontime' => 0, 'late' => 0, 'belumSelesai' => 0];

        foreach ($this->pdo->query(self::SQL_DEADLINE_PER_KARYAWAN) as $r) {
            $baris = [
                'nama'         => (string) $r['nama'],
                'total'        => (int) $r['total_tasklist'],
                'ontime'       => (int) $r['ontime'],
                'late'         => (int) $r['late'],
                'belumSelesai' => (int) $r['belum_selesai'],
                'persenOntime' => $r['persen_ontime'] === null ? null : (float) $r['persen_ontime'],
                'persenLate'   => $r['persen_late'] === null ? null : (float) $r['persen_late'],
            ];
            $perKaryawan[] = $baris;
            foreach ($total as $k => $_) {
                $total[$k] += $baris[$k];
            }
        }

        // Ringkasan dihitung dari hasil per karyawan, jadi cukup satu query ke database (setara query 2a).
        $selesai = $total['ontime'] + $total['late'];
        $total['persenOntime'] = $selesai > 0 ? round($total['ontime'] * 100 / $selesai, 2) : null;
        $total['persenLate']   = $selesai > 0 ? round($total['late'] * 100 / $selesai, 2) : null;

        return ['ringkasan' => $total, 'perKaryawan' => $perKaryawan];
    }

    /** @param array<string, mixed> $r */
    private static function blokKpi(array $r, string $kpi): array
    {
        return [
            'target'     => (int) $r["{$kpi}_target"],
            'actual'     => (int) $r["{$kpi}_actual"],
            'pencapaian' => (float) $r["{$kpi}_pencapaian"],
            'bobot'      => (float) $r["{$kpi}_bobot"],
            'late'       => (float) $r["{$kpi}_late"],
            'total'      => (float) $r["{$kpi}_total"],
        ];
    }
}
