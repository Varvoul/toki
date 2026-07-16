FROM docker.io/mlocati/php-extension-installer:2.1.77 as php-ext-installer
FROM php:8.1.27-bullseye
COPY --from=php-ext-installer /usr/bin/install-php-extensions /usr/local/bin/
RUN set -x \
    && install-php-extensions intl mbstring mongodb-stable redis opcache sockets pcntl \
    && IPE_DONT_ENABLE=1 install-php-extensions xdebug-3.2.0 \
    && php -m | grep -E 'mongo|redis|intl|pcntl' \
    && echo "ALL EXTENSIONS OK"
