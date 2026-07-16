FROM php:8.1.27-bullseye

# Copy tools from official images
COPY --from=composer:2.6.6 /usr/bin/composer /usr/bin/composer
COPY --from=mlocati/php-extension-installer:2.1.77 /usr/bin/install-php-extensions /usr/local/bin/
COPY --from=spiralscout/roadrunner:2.12.3 /usr/bin/rr /usr/bin/rr

ENV COMPOSER_HOME="/tmp/composer"
ENV COMPOSER_MEMORY_LIMIT=-1

# Install PHP extensions
RUN install-php-extensions intl mbstring mongodb-stable redis opcache sockets pcntl

# Install system packages
RUN apt-get update && apt-get install -y --no-install-recommends \
        openssl git wget unzip curl \
    && wget -q "https://github.com/aptible/supercronic/releases/download/v0.1.12/supercronic-linux-$(dpkg --print-architecture)" \
       -O /usr/bin/supercronic \
    && chmod +x /usr/bin/supercronic \
    && mkdir -p /etc/supercronic \
    && echo '*/1 * * * * php /app/artisan schedule:run' > /etc/supercronic/laravel \
    && rm -rf /var/lib/apt/lists/* \
    && echo -e "\nopcache.enable=1\nopcache.enable_cli=1\nopcache.jit_buffer_size=32M\nopcache.jit=1235\n" >> \
        ${PHP_INI_DIR}/conf.d/docker-php-ext-opcache.ini

# Create user and directories
RUN adduser --disabled-password --shell "/sbin/nologin" --home "/nonexistent" --no-create-home --uid "10001" --gecos "" "jikanapi" \
    && mkdir -p /app /var/run/rr \
    && chown -R jikanapi:jikanapi /app /var/run/rr /etc/supercronic/laravel \
    && chmod -R 777 /var/run/rr

USER jikanapi:jikanapi
WORKDIR /app

# Install composer dependencies (autoloader generated later)
COPY --chown=jikanapi:jikanapi ./composer.* /app/
RUN composer install --no-dev --no-cache --no-ansi --no-autoloader --no-scripts --prefer-dist

# Copy application sources
COPY --chown=jikanapi:jikanapi . /app/

RUN composer dump-autoload --optimize --no-ansi --no-dev \
    && cp .env.dist .env \
    && chmod -R 777 ${COMPOSER_HOME}/cache \
    && chmod -R a+w storage/ \
    && chown -R jikanapi:jikanapi /app \
    && chmod +x docker-entrypoint.php docker-entrypoint.sh

LABEL org.opencontainers.image.source=https://github.com/Varvoul/toki

EXPOSE 8080
EXPOSE 2114

HEALTHCHECK CMD curl --fail http://localhost:2114/health?plugin=http || exit 1

ENTRYPOINT ["/app/docker-entrypoint.sh"]