<?php

// Support full MongoDB Atlas DSN string via DB_DSN env var
// If DB_DSN is set, use it directly (supports replica sets, multiple hosts, etc.)
// Otherwise, build the DSN from individual env vars for simple/local MongoDB
$dsn = env('DB_DSN');

if (empty($dsn)) {
    $db_username = env('DB_USERNAME', env("APP_ENV") === "testing" ? "" : "admin");
    $dsn = "mongodb://";
    if (empty($db_username)) {
        $dsn .= env('DB_HOST', 'localhost').":".env('DB_PORT', 27017)."/".env('DB_ADMIN', 'admin');
    }
    else {
        $dsn .= env('DB_USERNAME', 'admin').":".env('DB_PASSWORD', '')."@".env('DB_HOST', 'localhost').":".env('DB_PORT', 27017)."/".env('DB_ADMIN', 'admin');
    }
}

return [
    'default' => env('DB_CONNECTION', 'mongodb'),

    'connections' => [
        'mongodb' => [
            'driver' => 'mongodb',
            'dsn'=> $dsn,
            'database' => env('DB_DATABASE', 'jikan'),
            'options' => [
                // Required for MongoDB Atlas replica sets
                'connectTimeoutMS' => 30000,
                'socketTimeoutMS' => 60000,
                'serverSelectionTimeoutMS' => 30000,
                'retryWrites' => true,
                'w' => 'majority',
                // TLS configuration for Atlas
                'tls' => true,
                'tlsCAFile' => '/etc/ssl/certs/ca-certificates.crt',
                'tlsAllowInvalidHostnames' => false,
            ]
        ]
    ],

    'redis' => [
        'client' => 'predis',
        'default' => [
            'host' => env('REDIS_HOST', '127.0.0.1'),
            'password' => env('REDIS_PASSWORD', null),
            'port' => env('REDIS_PORT', 6379),
            'database' => 0
        ]
    ],

    'migrations' => 'migrations'
];
