FROM docker.io/spiralscout/roadrunner:2.12.3 as roadrunner
FROM docker.io/composer:2.6.6 as composer
FROM docker.io/mlocati/php-extension-installer:2.1.77 as php-ext-installer
FROM php:8.1.27-bullseye
COPY --from=composer /usr/bin/composer /usr/bin/composer
COPY --from=php-ext-installer /usr/bin/install-php-extensions /usr/local/bin/
ENV COMPOSER_HOME="/tmp/composer"
RUN set -x \
    && install-php-extensions intl mbstring mongodb-stable opcache sockets pcntl \
    && apt-get update && apt-get install -y --no-install-recommends \
        openssl \
        git \
        wget \
        curl \
        unzip \
    && rm -rf /var/lib/apt/lists/* \
    && echo -e "\nopcache.enable=1\nopcache.enable_cli=1\nopcache.jit_buffer_size=32M\nopcache.jit=1235\n" >> \
            ${PHP_INI_DIR}/conf.d/docker-php-ext-opcache.ini \
    && php -v \
    && php -m \
    && composer --version \
    && adduser --disabled-password --shell "/sbin/nologin" --home "/nonexistent" --no-create-home --uid "10001" --gecos "" "jikanapi" \
    && mkdir /app /var/run/rr \
    && chown -R jikanapi:jikanapi /app /var/run/rr

USER jikanapi:jikanapi

WORKDIR /app

COPY --chown=jikanapi:jikanapi ./composer.* /app/

RUN composer install -n --no-dev --no-cache --no-ansi --no-autoloader --no-scripts --prefer-dist

COPY --chown=jikanapi:jikanapi . /app/

RUN set -ex \
    && composer dump-autoload -n --optimize --no-ansi --no-dev \
    && chmod -R 777 ${COMPOSER_HOME}/cache \
    && chmod -R a+w storage/ \
    && chown -R jikanapi:jikanapi /app \
    && chmod +x docker-entrypoint.php \
    && chmod +x render-entrypoint.sh

EXPOSE 8080
EXPOSE 2114

HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl --fail http://localhost:2114/health?plugin=http || exit 1

ENTRYPOINT ["/app/render-entrypoint.sh"]