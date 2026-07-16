FROM php:8.1.27-bullseye

RUN apt-get update && apt-get install -y --no-install-recommends curl git unzip wget

# Step 1: Copy tools
COPY --from=composer:2.6.6 /usr/bin/composer /usr/bin/composer
COPY --from=mlocati/php-extension-installer:2.1.77 /usr/bin/install-php-extensions /usr/local/bin/
COPY --from=spiralscout/roadrunner:2.12.3 /usr/bin/rr /usr/bin/rr
RUN echo "STEP1_COPY_TOOLS: PASS" > /tmp/build.log

ENV COMPOSER_HOME="/tmp/composer"
ENV COMPOSER_MEMORY_LIMIT=-1

# Step 2: PHP extensions
RUN (install-php-extensions intl mbstring mongodb-stable redis opcache sockets pcntl 2>&1 | tail -5 && echo "STEP2_PHP_EXTS: PASS" >> /tmp/build.log) || echo "STEP2_PHP_EXTS: FAIL" >> /tmp/build.log

# Step 3: System packages + supercronic
RUN (apt-get update && apt-get install -y --no-install-recommends openssl git wget unzip curl \
    && wget -q "https://github.com/aptible/supercronic/releases/download/v0.1.12/supercronic-linux-$(dpkg --print-architecture)" -O /usr/bin/supercronic \
    && chmod +x /usr/bin/supercronic \
    && mkdir -p /etc/supercronic \
    && echo '*/1 * * * * php /app/artisan schedule:run' > /etc/supercronic/laravel \
    && rm -rf /var/lib/apt/lists/* \
    && echo -e "\nopcache.enable=1\nopcache.enable_cli=1\nopcache.jit_buffer_size=32M\nopcache.jit=1235\n" >> ${PHP_INI_DIR}/conf.d/docker-php-ext-opcache.ini \
    && echo "STEP3_SYSTEM: PASS" >> /tmp/build.log) || echo "STEP3_SYSTEM: FAIL" >> /tmp/build.log

# Step 4: User creation
RUN (adduser --disabled-password --shell "/sbin/nologin" --home "/nonexistent" --no-create-home --uid "10001" --gecos "" "jikanapi" \
    && mkdir -p /app /var/run/rr \
    && chown -R jikanapi:jikanapi /app /var/run/rr /etc/supercronic/laravel \
    && chmod -R 777 /var/run/rr \
    && echo "STEP4_USER: PASS" >> /tmp/build.log) || echo "STEP4_USER: FAIL" >> /tmp/build.log

# Step 5: Composer install
COPY --chown=jikanapi:jikanapi ./composer.json ./composer.lock /app/
WORKDIR /app
RUN (composer install --no-dev --no-cache --no-ansi --no-autoloader --no-scripts --prefer-dist 2>&1 | tail -10 && echo "STEP5_COMPOSER: PASS" >> /tmp/build.log) || echo "STEP5_COMPOSER: FAIL" >> /tmp/build.log

# Serve results
RUN echo '<?php header("Content-Type: text/plain"); readfile("/tmp/build.log"); ?>' > /tmp/index.php
EXPOSE 8080
CMD ["php", "-S", "0.0.0.0:8080", "/tmp/index.php"]