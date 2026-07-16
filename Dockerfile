FROM docker.io/mlocati/php-extension-installer:2.1.77 as php-ext-installer
FROM php:8.1.27-bullseye
COPY --from=php-ext-installer /usr/bin/install-php-extensions /usr/local/bin/
RUN set -x && install-php-extensions mongodb-stable && php -m | grep -i mongo
