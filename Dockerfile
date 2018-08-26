FROM php:7.2-alpine3.8

RUN apk update && apk add --no-cache bash libcurl libzip-dev zip libpng-dev composer \
&& docker-php-ext-configure zip --with-libzip \
&& docker-php-ext-install mysqli pdo_mysql gd zip \
&& addgroup -g 1000 october \
&& adduser -u 1000 -D -h /october -s /bin/bash -G october october

# Download october
RUN cd /october \
&& curl -s https://octobercms.com/api/installer | php 

# Copy the configuration files
# Inspect app.php, cms.php, database.php for default settings
COPY composer.json /october
COPY server.php /october
COPY config/ /october/config/

RUN chown -R october:october /october && chmod -R 755 /october

WORKDIR /october
USER october

#Run the initial setup
RUN composer install --no-dev \
&& touch /october/storage/database.sqlite \
&& php artisan october:up \
&& php artisan key:generate \
&& php artisan october:util set build

EXPOSE 8000

HEALTHCHECK CMD curl --fail http://localhost:8000 || exit 1  

CMD ["php", "artisan", "serve", "--host", "0.0.0.0"]
