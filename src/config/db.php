<?php
/**
 * Database Configuration
 *
 * All of your system's database configuration settings go in here.
 * You can see a list of the default settings in vendor/craftcms/cms/src/config/DbConfig.php.
 *
 * @see \craft\config\DbConfig
 *
 * Quant Cloud injects DB_HOST, DB_PORT, DB_DATABASE, DB_USERNAME and
 * DB_PASSWORD for the application's managed database. Those win when present;
 * local docker compose keeps using the CRAFT_DB_* variables.
 */

use craft\helpers\App;

return [
    // Shared with Drupal: managed database TLS verifies the server certificate.
    'attributes' => (App::env('CRAFT_DB_DRIVER') ?: 'mysql') === 'mysql' &&
        App::env('DISABLE_DB_TLS') !== 'true' && App::env('DISABLE_DB_TLS') !== true
        ? [
            PDO::MYSQL_ATTR_SSL_CA => '/opt/rds-ca-certs/rds-ca-cert-bundle.pem',
            PDO::MYSQL_ATTR_SSL_VERIFY_SERVER_CERT => true,
        ] : [],
    'driver' => App::env('CRAFT_DB_DRIVER') ?: 'mysql',
    'server' => App::env('DB_HOST') ?: App::env('CRAFT_DB_SERVER') ?: 'localhost',
    'port' => App::env('DB_PORT') ?: App::env('CRAFT_DB_PORT') ?: 3306,
    'database' => App::env('DB_DATABASE') ?: App::env('CRAFT_DB_DATABASE') ?: 'craft',
    'user' => App::env('DB_USERNAME') ?: App::env('CRAFT_DB_USER') ?: 'root',
    'password' => App::env('DB_PASSWORD') ?: App::env('CRAFT_DB_PASSWORD') ?: '',
    'schema' => App::env('CRAFT_DB_SCHEMA') ?: 'public',
    'tablePrefix' => App::env('CRAFT_DB_TABLE_PREFIX') ?: '',
    'charset' => 'utf8mb4',
    'collation' => 'utf8mb4_unicode_ci',
];
