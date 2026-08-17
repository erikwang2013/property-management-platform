# ============================================================
# 物业管理系统-业务端 — 生产 Dockerfile
# Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
# ============================================================

FROM php:8.3-cli-alpine

RUN addgroup -S app && adduser -S app -G app

RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"

RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories \
    && apk update --no-cache \
    && apk add --no-cache \
        libpng-dev \
        libjpeg-turbo-dev \
        freetype-dev \
        oniguruma-dev \
        libxml2-dev \
        curl \
        git \
        unzip \
    && docker-php-source extract

RUN docker-php-ext-install -j$(nproc) \
        pdo pdo_mysql \
        pcntl \
        mbstring \
        gd \
        xml \
        dom \
        xmlwriter \
    && docker-php-ext-enable opcache pcntl \
    && apk add --no-cache $PHPIZE_DEPS \
    && pecl install redis \
    && docker-php-ext-enable redis \
    && apk del $PHPIZE_DEPS

RUN echo "opcache.enable=1" >> "$PHP_INI_DIR/php.ini" \
    && echo "opcache.enable_cli=1" >> "$PHP_INI_DIR/php.ini" \
    && echo "opcache.memory_consumption=128" >> "$PHP_INI_DIR/php.ini" \
    && echo "opcache.max_accelerated_files=10000" >> "$PHP_INI_DIR/php.ini"

COPY --from=composer:2 /usr/bin/composer /usr/local/bin/composer

RUN docker-php-source delete && rm -rf /var/cache/apk/*

RUN mkdir -p /app
WORKDIR /app

COPY composer.json composer.lock ./
RUN composer install --no-dev --no-interaction --optimize-autoloader

COPY . .

USER app

EXPOSE 8788
CMD ["php", "start.php", "start"]
