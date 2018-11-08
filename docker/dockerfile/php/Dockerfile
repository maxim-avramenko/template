FROM php:7.1-fpm

ARG USER
ARG USER_ID

RUN set -ex \
    && yes | adduser --disabled-password --uid ${USER_ID} ${USER} \
    && usermod -aG sudo ${USER}

## add our user and group first to make sure their IDs get assigned consistently, regardless of whatever dependencies get added
#RUN groupadd -r redis && useradd -r -g redis redis
#
## grab gosu for easy step-down from root
## https://github.com/tianon/gosu/releases
#ENV GOSU_VERSION 1.10
#RUN set -ex; \
#	\
#	fetchDeps=" \
#		ca-certificates \
#		dirmngr \
#		gnupg \
#		wget \
#	"; \
#	apt-get update; \
#	apt-get install -y --no-install-recommends $fetchDeps; \
#	rm -rf /var/lib/apt/lists/*; \
#	\
#	dpkgArch="$(dpkg --print-architecture | awk -F- '{ print $NF }')"; \
#	wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch"; \
#	wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch.asc"; \
#	export GNUPGHOME="$(mktemp -d)"; \
#	gpg --keyserver ha.pool.sks-keyservers.net --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4; \
#	gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu; \
#	gpgconf --kill all; \
#	rm -r "$GNUPGHOME" /usr/local/bin/gosu.asc; \
#	chmod +x /usr/local/bin/gosu; \
#	gosu nobody true; \
#	\
#	apt-get purge -y --auto-remove $fetchDeps

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
