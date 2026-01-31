<?php
/**
 * General Configuration
 *
 * All of your system's general configuration settings go in here.
 * You can see a list of the default settings in vendor/craftcms/cms/src/config/GeneralConfig.php.
 *
 * @see \craft\config\GeneralConfig
 */

use craft\config\GeneralConfig;
use craft\helpers\App;

return GeneralConfig::create()
    // Set the default week start day for date pickers (0 = Sunday, 1 = Monday, etc.)
    ->defaultWeekStartDay(1)
    // Prevent generated URLs from including "index.php"
    ->omitScriptNameInUrls()
    // Enable Dev Mode (see https://craftcms.com/guides/what-dev-mode-does)
    ->devMode(App::env('CRAFT_DEV_MODE') ?? false)
    // Allow administrative changes
    ->allowAdminChanges(App::env('CRAFT_ALLOW_ADMIN_CHANGES') ?? false)
    // Disallow robots
    ->disallowRobots(App::env('CRAFT_DISALLOW_ROBOTS') ?? false)
    // Set the @webroot alias so the clear-caches command knows where to find CP resources
    ->aliases([
        '@webroot' => dirname(__DIR__) . '/web',
    ])
    // Run queue jobs automatically
    ->runQueueAutomatically(true)
    // Set the max upload file size
    ->maxUploadFileSize('100M')
    // Set the default image quality
    ->defaultImageQuality(82)
    // Use PHP 8+ query string parsing
    ->useIframeResizer(false)
    // Security key (should be set via environment variable)
    ->securityKey(App::env('CRAFT_SECURITY_KEY'))
;
