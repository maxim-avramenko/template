FROM php:7.1-fpm

ARG USER
ARG USER_ID

RUN set -ex \
    && yes | adduser --disabled-password --uid ${USER_ID} ${USER} \
    && usermod -aG sudo ${USER}

COPY ./config/php.ini /usr/local/etc/php/php.ini

RUN apt-get update \
    && mkdir -p /usr/share/man/man1 \
    && mkdir -p /usr/share/man/man7 \
    && mkdir -p /usr/share/man/man8 \
    && apt-get install -y --no-install-recommends \
        libmemcached-dev \
        zlib1g-dev \
        g++ \
        git \
        curl \
        apt-utils \
        wget \
        libcurl4-openssl-dev \
        libfreetype6-dev \
        libjpeg62-turbo-dev \
        libmcrypt-dev \
        libpng-dev \
        libxml2-dev \
        libicu-dev \
        libpq-dev \
        postgresql-client \
        nano \
    && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-install -j$(nproc) \
        gd \
        iconv \
        mcrypt \
        fileinfo \
        json \
        mbstring \
        bcmath \
        opcache \
        pdo \
        pdo_pgsql \
        pgsql \
        zip \
        soap \
        intl \
        dom \
        xml \
    && apt-get clean; rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /usr/share/doc/*

RUN pecl install memcached-3.0.4 && docker-php-ext-enable memcached

RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

WORKDIR /app

USER ${USER}

CMD ["php-fpm"]
