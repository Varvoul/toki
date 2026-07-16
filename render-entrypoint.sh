#!/bin/bash
set -eo pipefail

# Render-specific entrypoint for Toki (Jikan v4)
# No Redis, no Typesense, no supercronic needed on Render free tier

echo "[toki] Starting Toki (Jikan v4) on Render..."

# Generate .env from .env.dist if not present
if [ ! -f .env ]; then
    echo "[toki] No .env found, copying from .env.dist"
    cp .env.dist .env
fi

# Generate APP_KEY if not set
if grep -q 'APP_KEY=$' .env || grep -q 'APP_KEY=' .env | grep -qvE '^APP_KEY=.+' ; then
    CURRENT_KEY=$(grep '^APP_KEY=' .env | head -1 | cut -d'=' -f2-)
    if [ -z "$CURRENT_KEY" ]; then
        echo "[toki] Generating APP_KEY..."
        GENERATED_KEY=$(php -r "echo 'base64:'.base64_encode(random_bytes(32));")
        sed -i "s/^APP_KEY=.*/APP_KEY=$GENERATED_KEY/" .env
    fi
fi

# Write all environment variables that start with our config prefixes into .env
# This ensures RoadRunner workers (which reload .env) get Render env vars
for var in $(env | grep -E '^(APP_|DB_|CACHE_|SCOUT_|JIKAN_|QUEUE_|SOURCE_|LOG_|CORS_|MICRO|MAX_RESULTS|DISABLE_|RR_|GITHUB_|REPORTING|SENTRY_|INSIGHTS)' | cut -d= -f1); do
    val=$(printenv "$var")
    # Escape special characters for sed replacement
    escaped_val=$(printf '%s\n' "$val" | sed 's/[&/\]/\\&/g')
    if grep -q "^${var}=" .env; then
        sed -i "s|^${var}=.*|${var}=${escaped_val}|" .env
    else
        echo "${var}=${val}" >> .env
    fi
done

echo "[toki] Environment configured."
echo "[toki] Starting RoadRunner..."

exec rr serve -c .rr.yaml