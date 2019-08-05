ARG PHP_VERSION=7.1.30

# Use this image as the base image for dev and prod.
FROM php:${PHP_VERSION}-apache as common

RUN apt-get update && apt-get install -y zlib1g-dev libicu-dev g++ libpng-dev build-essential libssl-dev libjpeg-dev libfreetype6-dev
RUN docker-php-ext-configure intl
RUN docker-php-ext-install intl
RUN docker-php-ext-install mysqli zip pdo pdo_mysql
RUN docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-install gd

RUN a2enmod rewrite

# Optimizing php
RUN docker-php-ext-install opcache
RUN docker-php-ext-enable opcache
RUN echo "opcache.max_accelerated_files = 20000" >> /usr/local/etc/php/conf.d/docker-php-ext-opcache.ini


# This is the image using in development.
FROM common as dev

RUN apt-get install -y zip unzip git; \
    pecl install xdebug \
    && echo "zend_extension=$(find /usr/local/lib/php/extensions/ -name xdebug.so)" > /usr/local/etc/php/conf.d/xdebug.ini;

# Copy composer binary from official Composer image.
COPY --from=composer /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/html

# We enable the errors only in development.
ENV DISPLAY_ERRORS="On"


# In this image we will download the dependencies, but without the development dependencies.
# The dependencies are installed in the vendor folder that will be copied later into the prod image.
FROM composer as builder-prod

WORKDIR /app

COPY composer.json composer.lock /app/
RUN composer install  \
    --ignore-platform-reqs \
    --no-ansi \
    --no-dev \
    --no-autoloader \
    --no-interaction \
    --no-scripts

# We need to copy our whole application so that we can generate the autoload file inside the vendor folder.
COPY . /app
RUN composer dump-autoload --optimize --no-dev --classmap-authoritative



# This is the image that will be deployed on production.
FROM common as prod

# No display errors to users in production.
ENV DISPLAY_ERRORS="Off"

# Copy our application
COPY . /var/www/html/

# Change files owner to apache
RUN chown -R www-data:www-data /var/www/html

# Copy the downloaded dependencies from the builder-prod stage.
COPY --from=builder-prod /app/vendor /var/www/html/vendor



