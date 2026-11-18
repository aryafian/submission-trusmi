<?php

declare(strict_types=1);

namespace Trusmi\Kpi;

ini_set('display_errors', '0');
ini_set('log_errors', '1');
error_reporting(E_ALL);

require __DIR__ . '/Database.php';
require __DIR__ . '/KpiRepository.php';

function kirim_header_keamanan(): void
{
    header_remove('X-Powered-By');
    header("Content-Security-Policy: default-src 'none'; script-src 'self'; style-src 'self'; img-src 'self'; "
        . "connect-src 'self'; base-uri 'none'; form-action 'none'; frame-ancestors 'none'");
    header('X-Content-Type-Options: nosniff');
    header('X-Frame-Options: DENY');
    header('Referrer-Policy: no-referrer');
    header('Cross-Origin-Opener-Policy: same-origin');
    header('Cross-Origin-Resource-Policy: same-origin');
    header('Permissions-Policy: camera=(), microphone=(), geolocation=(), payment=()');
}

/** @return array{db: array{host: string, port: int, name: string, user: string, password: string}} */
function muat_config(): array
{
    return require dirname(__DIR__) . '/config.php';
}
