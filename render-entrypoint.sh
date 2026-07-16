#!/bin/bash
set -e

echo "[toki] Starting Toki (Jikan v4) on Render..."

# Generate .env from .env.dist if not present
if [ ! -f .env ]; then
    echo "[toki] Copying .env from .env.dist"
    cp .env.dist .env
fi

# Generate APP_KEY if empty
CURRENT_KEY=$(grep '^APP_KEY=' .env 2>/dev/null | head -1 | cut -d'=' -f2-)
if [ -z "$CURRENT_KEY" ]; then
    echo "[toki] Generating APP_KEY..."
    GENERATED_KEY=$(php -r "echo 'base64:'.base64_encode(random_bytes(32));")
    sed -i "s|^APP_KEY=.*|APP_KEY=${GENERATED_KEY}|" .env
fi

# Write DB_DSN safely (contains special chars that break sed)
if [ -n "$DB_DSN" ]; then
    # Remove existing DB_DSN line and append new one
    sed -i '/^DB_DSN=/d' .env
    echo "DB_DSN=${DB_DSN}" >> .env
fi

# Override other .env values with Render environment variables
for envfile_var in APP_ENV APP_DEBUG APP_URL APP_VERSION \
    DB_CACHING DB_CONNECTION DB_DATABASE \
    CACHE_DRIVER CACHE_DEFAULT_EXPIRE CACHE_USER_EXPIRE \
    CACHE_USERLIST_EXPIRE CACHE_404_EXPIRE CACHE_SEARCH_EXPIRE \
    CACHE_PRODUCERS_EXPIRE CACHE_MAGAZINES_EXPIRE CACHE_META_EXPIRE \
    CACHE_MICROCACHE_EXPIRE SCOUT_DRIVER SCOUT_QUEUE \
    QUEUE_CONNECTION MAX_RESULTS_PER_PAGE SOURCE_TIMEOUT \
    CORS_MIDDLEWARE INSIGHTS REPORTING GITHUB_REPORTING \
    DISABLE_USER_LISTS LOG_LEVEL RR_MAX_WORKER_MEMORY \
    CACHING MICROCACHING MICROCACHING_EXPIRE; do
    VAL="${!envfile_var}"
    if [ -n "$VAL" ]; then
        if grep -q "^${envfile_var}=" .env 2>/dev/null; then
            sed -i "s|^${envfile_var}=.*|${envfile_var}=${VAL}|" .env
        else
            echo "${envfile_var}=${VAL}" >> .env
        fi
    fi
done

echo "[toki] Environment configured. Starting RoadRunner..."
exec rr serve -c .rr.yaml