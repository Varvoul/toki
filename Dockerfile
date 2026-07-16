FROM php:8.1.27-bullseye

RUN apt-get update && apt-get install -y --no-install-recommends curl git unzip wget 2>&1 | tail -5

# Test 1: Can we download from GitHub?
RUN wget -q "https://github.com/aptible/supercronic/releases/download/v0.1.12/supercronic-linux-$(dpkg --print-architecture)" -O /usr/bin/supercronic \
    && chmod +x /usr/bin/supercronic \
    && echo "TEST1_PASS: GitHub download works" > /tmp/test_results.txt || echo "TEST1_FAIL" > /tmp/test_results.txt

# Test 2: install-php-extensions tool
COPY --from=mlocati/php-extension-installer:2.1.77 /usr/bin/install-php-extensions /usr/local/bin/
RUN install-php-extensions intl mbstring 2>&1 | tail -3 && echo "TEST2_PASS: Basic PHP extensions work" >> /tmp/test_results.txt

# Test 3: MongoDB extension
RUN install-php-extensions mongodb-stable 2>&1 | tail -5 && echo "TEST3_PASS: MongoDB extension works" >> /tmp/test_results.txt

# Test 4: Redis extension  
RUN install-php-extensions redis 2>&1 | tail -3 && echo "TEST4_PASS: Redis extension works" >> /tmp/test_results.txt

# Test 5: Composer
COPY --from=composer:2.6.6 /usr/bin/composer /usr/bin/composer
ENV COMPOSER_HOME="/tmp/composer"
ENV COMPOSER_MEMORY_LIMIT=-1

COPY ./composer.json ./composer.lock /app/
WORKDIR /app
RUN composer install --no-dev --no-cache --no-ansi --no-autoloader --no-scripts --prefer-dist 2>&1 | tail -20 \
    && echo "TEST5_PASS: Composer install works" >> /tmp/test_results.txt \
    || echo "TEST5_FAIL: Composer install failed" >> /tmp/test_results.txt

# Serve the test results
RUN echo '<?php echo file_get_contents("/tmp/test_results.txt"); ?>' > /app/index.php \
    && echo '<?php header("Content-Type: text/plain"); readfile("/tmp/test_results.txt"); ?>' > /app/public/index.php 2>/dev/null; true

EXPOSE 8080
CMD php -S 0.0.0.0:8080 /app/index.php