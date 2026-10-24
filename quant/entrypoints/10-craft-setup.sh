#!/bin/bash

# Craft CMS - Database setup and installation
# Runs on every container start; only installs if not already installed.

echo "[$(date +'%Y-%m-%d %H:%M:%S')] Running Craft CMS setup..." >&2

cd /var/www/html || exit 1

# Stop early when the security key is missing or is a known example value.
require_secret CRAFT_SECURITY_KEY

# Ensure .env exists (copy from .env.example if missing)
if [ ! -f .env ]; then
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] Creating .env from .env.example..." >&2
    cp .env.example .env 2>/dev/null || true
fi

# On Quant Cloud the managed database arrives as DB_*, which config/db.php
# reads directly. Craft applies any CRAFT_DB_* it finds (process environment
# or .env) over that file, so remove the local-development values from .env.
# The password is never written to disk: generated passwords contain
# characters like & # $ that break both sed and unquoted dotenv values.
if [ -n "${DB_HOST:-}" ]; then
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] Using the managed database at ${DB_HOST} (DB_* via config/db.php)..." >&2
    sed -i '/^CRAFT_DB_/d' .env
fi

# Ensure storage directories exist with correct permissions
# These subdirectories are required by Craft and may be lost on fresh volume mounts
mkdir -p /var/www/html/storage/runtime /var/www/html/storage/logs \
         /var/www/html/storage/config-deltas /var/www/html/storage/config-backups \
         /var/www/html/web/cpresources /var/www/html/config
chown -R www-data:www-data /var/www/html/storage /var/www/html/web/cpresources /var/www/html/config
chmod -R 775 /var/www/html/storage /var/www/html/web/cpresources /var/www/html/config

# Wait for database to be ready (max 30 seconds)
echo "[$(date +'%Y-%m-%d %H:%M:%S')] Waiting for database..." >&2
for i in $(seq 1 30); do
    # `craft db/check` does not exist; probe with PDO using the same settings Craft will use.
    if php -r 'require "vendor/autoload.php"; $c = require "config/db.php"; new PDO("mysql:host=".$c["server"].";port=".$c["port"].";dbname=".$c["database"], $c["user"], $c["password"], [PDO::ATTR_TIMEOUT => 3]);' 2>/dev/null; then
        echo "[$(date +'%Y-%m-%d %H:%M:%S')] Database is ready" >&2
        break
    fi
    if [ "$i" -eq 30 ]; then
        echo "[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: Database not ready after 30s, continuing anyway..." >&2
    fi
    sleep 1
done

# Check if Craft is already installed
if php craft install/check 2>/dev/null; then
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] Craft CMS is already installed" >&2
else
    require_secret CRAFT_ADMIN_PASSWORD
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] Installing Craft CMS..." >&2
    php craft install \
        --username="${CRAFT_ADMIN_USERNAME:-admin}" \
        --password="${CRAFT_ADMIN_PASSWORD}" \
        --email="${CRAFT_ADMIN_EMAIL:-admin@example.com}" \
        --site-name="${CRAFT_SITE_NAME:-Craft CMS}" \
        --site-url="${PRIMARY_SITE_URL:-http://localhost}" \
        --language="${CRAFT_LANGUAGE:-en-US}" \
        --interactive=0 2>&1 || echo "[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: Craft install failed (may need manual setup)" >&2
fi

# Run any pending migrations
echo "[$(date +'%Y-%m-%d %H:%M:%S')] Running pending migrations..." >&2
php craft migrate/all --interactive=0 2>/dev/null || true

# Apply project config if it exists
if [ -d /var/www/html/config/project ]; then
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] Applying project config..." >&2
    php craft project-config/apply --interactive=0 2>/dev/null || true
fi

# Fix permissions after install/migrations (may have created files as root)
chown -R www-data:www-data /var/www/html/storage /var/www/html/web/cpresources /var/www/html/config 2>/dev/null || true
chmod -R 775 /var/www/html/storage /var/www/html/web/cpresources /var/www/html/config 2>/dev/null || true

echo "[$(date +'%Y-%m-%d %H:%M:%S')] Craft CMS setup complete" >&2
