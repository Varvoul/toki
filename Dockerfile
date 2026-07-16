FROM docker.io/spiralscout/roadrunner:2.12.3 as roadrunner
FROM docker.io/composer:2.6.6 as composer
FROM docker.io/mlocati/php-extension-installer:2.1.77 as php-ext-installer
FROM php:8.1.27-bullseye
COPY --from=composer /usr/bin/composer /usr/bin/composer
COPY --from=php-ext-installer /usr/bin/install-php-extensions /usr/local/bin/
ENV COMPOSER_HOME="/tmp/composer"
RUN set -x \
    && install-php-extensions intl mbstring mongodb-stable redis opcache sockets pcntl \
    && IPE_DONT_ENABLE=1 install-php-extensions xdebug-3.2.0

COPY --from=roadrunner /usr/bin/rr /usr/bin/rr
RUN set -ex \
    && apt-get update && apt-get install -y --no-install-recommends openssl git wget unzip \
    && wget -q "https://github.com/aptible/supercronic/releases/download/v0.1.12/supercronic-linux-$(dpkg --print-architecture)" -O /usr/bin/supercronic \
    && chmod +x /usr/bin/supercronic && mkdir /etc/supercronic \
    && echo '*/1 * * * * php /app/artisan schedule:run' > /etc/supercronic/laravel \
    && rm -rf /var/lib/apt/lists/* \
    && echo -e "\nopcache.enable=1\nopcache.enable_cli=1\nopcache.jit_buffer_size=32M\nopcache.jit=1235\n" >> ${PHP_INI_DIR}/conf.d/docker-php-ext-opcache.ini \
    && adduser --disabled-password --shell "/sbin/nologin" --home "/nonexistent" --no-create-home --uid "10001" --gecos "" "jikanapi" \
    && mkdir /app /var/run/rr && chown -R jikanapi:jikanapi /app /var/run/rr /etc/supercronic/laravel && chmod -R 777 /var/run/rr

USER jikanapi:jikanapi
WORKDIR /app
COPY --chown=jikanapi:jikanapi ./composer.* /app/
RUN composer install -n --no-dev --no-cache --no-ansi --no-autoloader --no-scripts --prefer-dist && echo "COMPOSER INSTALL OK"
