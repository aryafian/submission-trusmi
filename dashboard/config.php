<?php

declare(strict_types=1);

// Nilai diambil dari environment variable dulu (dipakai di server), lalu config.local.php (development lokal).
$local = is_file(__DIR__ . '/config.local.php') ? require __DIR__ . '/config.local.php' : [];

$env = static function (string $key, string $fallback): string {
    $value = getenv($key);
    return $value === false || $value === '' ? $fallback : $value;
};

return [
    'db' => [
        'host'     => $env('DB_HOST', $local['db']['host'] ?? '127.0.0.1'),
        'port'     => (int) $env('DB_PORT', (string) ($local['db']['port'] ?? 3306)),
        'name'     => $env('DB_NAME', $local['db']['name'] ?? 'trusmi_kpi'),
        'user'     => $env('DB_USER', $local['db']['user'] ?? 'trusmi_dash'),
        'password' => $env('DB_PASSWORD', $local['db']['password'] ?? ''),
    ],
];
