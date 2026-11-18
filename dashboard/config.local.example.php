<?php

// Salin menjadi config.local.php lalu isi password akun trusmi_dash (lihat sql/01_setup_mysql.sql).
// config.local.php tidak boleh di-commit.
return [
    'db' => [
        'host'     => '127.0.0.1',
        'port'     => 3306,
        'name'     => 'trusmi_kpi',
        'user'     => 'trusmi_dash',
        'password' => '',
    ],
];
