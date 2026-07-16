#!/usr/bin/env php
<?php

// If vendor/autoload.php is missing, this is a broken build - show error and serve it
if (!file_exists(__DIR__ . '/vendor/autoload.php')) {
    $msg = "FATAL: vendor/autoload.php not found. Composer install likely failed during build. ";
    $msg .= "Dockerfile must ensure composer install succeeds (remove || true).";
    file_put_contents(__DIR__ . '/index.php', '<?php header("Content-Type: text/plain"); readfile(__DIR__ . "/BUILD_ERROR.txt"); ?>');
    file_put_contents(__DIR__ . '/BUILD_ERROR.txt', $msg);
    // Start simple server to show the error
    passthru('php -S 0.0.0.0:8080 -t /app > /dev/null 2>&1 &');
    sleep(2);
    // Exit so RoadRunner doesn't start
    exit(1);
}

error_reporting(E_ALL);
ini_set('display_errors', 'stderr');
ini_set('error_log', '/app/php_err.log');

use Dotenv\Dotenv;