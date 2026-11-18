<?php

declare(strict_types=1);

namespace Trusmi\Kpi;

use Throwable;

require dirname(__DIR__) . '/src/bootstrap.php';

kirim_header_keamanan();
header('Content-Type: application/json; charset=utf-8');

function selesai(int $status, array $data): never
{
    http_response_code($status);
    echo json_encode($data, JSON_UNESCAPED_UNICODE | JSON_THROW_ON_ERROR);
    exit;
}

$metode = $_SERVER['REQUEST_METHOD'] ?? 'GET';
if ($metode !== 'GET' && $metode !== 'HEAD') {
    header('Allow: GET, HEAD');
    selesai(405, ['error' => 'Endpoint ini hanya menerima GET.']);
}

try {
    $repo = new KpiRepository(Database::connect(muat_config()['db']));
    $body = json_encode([
        'kpi'      => $repo->skorKpi(),
        'deadline' => $repo->ketepatanDeadline(),
    ], JSON_UNESCAPED_UNICODE | JSON_THROW_ON_ERROR);
} catch (Throwable $e) {
    // Detail error (host, user, pesan SQL) hanya ke log server, tidak pernah ke browser.
    error_log('[dashboard-kpi] ' . $e::class . ': ' . $e->getMessage());
    header('Cache-Control: no-store');
    selesai(503, ['error' => 'Database tidak bisa dihubungi.']);
}

// ETag dari isi data: kalau data belum berubah, browser cukup menerima 304 tanpa body.
$etag = '"' . hash('xxh128', $body) . '"';
header('ETag: ' . $etag);
header('Cache-Control: private, no-cache');

if (trim($_SERVER['HTTP_IF_NONE_MATCH'] ?? '') === $etag) {
    http_response_code(304);
    exit;
}

if ($metode !== 'HEAD') {
    echo $body;
}
