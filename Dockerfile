FROM php:8.1.27-bullseye

COPY --from=composer:2.6.6 /usr/bin/composer /usr/bin/composer
COPY --from=mlocati/php-extension-installer:2.1.77 /usr/bin/install-php-extensions /usr/local/bin/

ENV COMPOSER_HOME="/tmp/composer"
ENV COMPOSER_MEMORY_LIMIT=-1

RUN install-php-extensions intl mbstring mongodb-stable redis opcache sockets pcntl > /tmp/ext.log 2>&1 \
    || (echo "PHP_EXT_FAIL" >> /tmp/step.log; cp /tmp/ext.log /tmp/fail.log)

RUN apt-get update > /tmp/apt.log 2>&1 \
    && apt-get install -y --no-install-recommends openssl git wget unzip curl >> /tmp/apt.log 2>&1 \
    || (echo "APT_FAIL" >> /tmp/step.log; cp /tmp/apt.log /tmp/fail.log)

RUN echo "EXT_INSTALL_OK" > /tmp/step.log && composer --version

WORKDIR /app
COPY --chown=10001:10001 ./composer.* /app/

RUN composer install --no-dev --no-cache --no-ansi --no-autoloader --no-scripts --prefer-dist > /tmp/composer1.log 2>&1 \
    || (echo "COMPOSER1_FAIL" >> /tmp/step.log; cp /tmp/composer1.log /tmp/fail.log)

COPY --chown=10001:10001 . /app/

RUN composer dump-autoload --optimize --no-ansi --no-dev > /tmp/composer2.log 2>&1 \
    || (echo "COMPOSER2_FAIL" >> /tmp/step.log; cp /tmp/composer2.log /tmp/fail.log)

RUN cat /tmp/step.log > /app/build_result.txt \
    && if [ -f /tmp/fail.log ]; then cat /tmp/fail.log >> /app/build_result.txt; fi \
    && echo "BUILD_COMPLETE" >> /app/build_result.txt

COPY --chown=10001:10001 docker-entrypoint.sh /app/
COPY --from=docker.io/spiralscout/roadrunner:2.12.3 /usr/bin/rr /usr/bin/rr

RUN echo '<?php header("Content-Type: text/plain"); readfile("/app/build_result.txt");' > /app/public/index.php \
    && mkdir -p /app/public

EXPOSE 8080
CMD ["php", "-S", "0.0.0.0:8080", "-t", "/app/public"]