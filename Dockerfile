FROM docker.io/spiralscout/roadrunner:2.12.3 as roadrunner
FROM docker.io/composer:2.6.6 as composer
FROM docker.io/mlocati/php-extension-installer:2.1.77 as php-ext-installer
FROM php:8.1-bookworm

COPY --from=composer /usr/bin/composer /usr/bin/composer
COPY --from=php-ext-installer /usr/bin/install-php-extensions /usr/local/bin/

ENV COMPOSER_HOME="/tmp/composer"
ENV COMPOSER_MEMORY_LIMIT=-1

# Install system deps + PHP extensions in one layer (bookworm has OpenSSL 3.0)
RUN apt-get update && apt-get install -y --no-install-recommends libssl-dev ca-certificates openssl git wget unzip \
    && wget -q "https://github.com/aptible/supercronic/releases/download/v0.1.12/supercronic-linux-$(dpkg --print-architecture)" -O /usr/bin/supercronic \
    && chmod +x /usr/bin/supercronic \
    && mkdir /etc/supercronic \
    && echo '*/1 * * * * php /app/artisan schedule:run' > /etc/supercronic/laravel \
    && rm -rf /var/lib/apt/lists/* \
    && echo -e "\nopcache.enable=1\nopcache.enable_cli=1\nopcache.jit_buffer_size=32M\nopcache.jit=1235\n" >> ${PHP_INI_DIR}/conf.d/docker-php-ext-opcache.ini \
    && install-php-extensions intl mbstring mongodb-1.15.0 redis opcache sockets pcntl

COPY --from=roadrunner /usr/bin/rr /usr/bin/rr

LABEL org.opencontainers.image.source=https://github.com/Varvoul/toki

RUN adduser --disabled-password --shell "/sbin/nologin" --home "/nonexistent" --no-create-home --uid "10001" --gecos "" "jikanapi" \
    && mkdir /app /var/run/rr \
    && chown -R jikanapi:jikanapi /app /var/run/rr /etc/supercronic/laravel \
    && chmod -R 777 /var/run/rr

USER jikanapi:jikanapi
WORKDIR /app

COPY --chown=jikanapi:jikanapi ./composer.* /app/

# ext-mongodb 1.15.0 matches composer.lock requirement ^1.13.0
RUN composer install --no-dev --no-cache --no-ansi --no-autoloader --no-scripts --prefer-dist

COPY --chown=jikanapi:jikanapi . /app/

RUN composer dump-autoload --optimize --no-ansi --no-dev \
    && chmod -R 777 ${COMPOSER_HOME}/cache \
    && chmod -R a+w storage/ \
    && chown -R jikanapi:jikanapi /app \
    && chmod +x docker-entrypoint.php \
    && chmod +x docker-entrypoint.sh

EXPOSE 8080
EXPOSE 2114

HEALTHCHECK CMD curl --fail http://localhost:2114/health?plugin=http || exit 1

ENTRYPOINT ["/app/docker-entrypoint.sh"]