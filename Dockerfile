FROM php:7.4-apache

RUN a2enmod rewrite

# Get packages that we need in container
RUN apt-get update -q -y \
  && apt-get install -q -y --no-install-recommends \
  ca-certificates \
  curl \
  acl \
  sudo \
  ghostscript \
  # Needed for the php extensions we enable below
  libfreetype6 \
  libjpeg62-turbo \
  libxpm4 \
  libpng16-16 \
  libicu63 \
  libxslt1.1 \
  libmemcachedutil2 \
  libzip-dev \
  imagemagick \
  libonig5 \
  libpq5 \ 
  # git & unzip needed for composer, unless we document to use dev image for composer install
  # unzip needed due to https://github.com/composer/composer/issues/4471
  unzip \
  git \
  # packages useful for dev
  less \
  mariadb-client \
  vim \
  wget \
  tree \
  gdb-minimal \
  net-tools \
  && rm -rf /var/lib/apt/lists/*

# Install and configure php plugins
RUN set -xe \
  && buildDeps=" \
  $PHP_EXTRA_BUILD_DEPS \
  libfreetype6-dev \
  libjpeg62-turbo-dev \
  libxpm-dev \
  libpng-dev \
  libicu-dev \
  libxslt1-dev \
  libmemcached-dev \
  libzip-dev \
  libxml2-dev \
  libonig-dev \
  libmagickwand-dev \
  libpq-dev \
  apt-utils \
  " \
  && apt-get update -q -y && apt-get install -q -y --no-install-recommends $buildDeps && rm -rf /var/lib/apt/lists/* \
  # Extract php source and install missing extensions
  && docker-php-source extract \
  && docker-php-ext-configure mysqli --with-mysqli=mysqlnd \
  && docker-php-ext-configure pdo_mysql --with-pdo-mysql=mysqlnd \
  && docker-php-ext-configure pgsql -with-pgsql=/usr/local/pgsql \
  && docker-php-ext-configure gd --with-freetype=/usr/include/ --with-jpeg=/usr/include/ --with-xpm=/usr/include/ --enable-gd-jis-conv \
  && docker-php-ext-install exif gd mbstring intl xsl zip mysqli pdo_mysql pdo_pgsql pgsql soap bcmath \
  && docker-php-ext-enable opcache \
  && cp /usr/src/php/php.ini-production ${PHP_INI_DIR}/php.ini 

# Install imagemagick
RUN pecl install -o imagick && docker-php-ext-enable imagick 

# Install xdebug
RUN pecl install -f xdebug \
&& echo "zend_extension=$(find /usr/local/lib/php/extensions/ -name xdebug.so) \
\nxdebug.remote_enable=1 \
\nxdebug.remote_autostart=1 \
\nxdebug.start_with_request=yes \
\nxdebug.client_host=172.17.0.1 \
\nxdebug.mode=develop,debug,coverage,trace,profile,gcstats \
" > /usr/local/etc/php/conf.d/xdebug.ini;

# Delete source & builds deps so it does not hang around in layers taking up space
RUN pecl clear-cache \
  && rm -Rf "$(pecl config-get temp_dir)/*" \
  && docker-php-source delete \
  && apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false $buildDeps

COPY php.ini /php.ini
RUN cat /php.ini>>${PHP_INI_DIR}/php.ini

RUN php -r "readfile('http://getcomposer.org/installer');" | php -- --install-dir=/usr/bin/ --filename=composer
RUN chmod +x /usr/bin/composer

RUN curl -fsSL https://deb.nodesource.com/setup_16.x | bash -
RUN apt-get install -y nodejs nano 
RUN npm install -g yarn

COPY apache.conf /etc/apache2/sites-enabled/000-default.conf
COPY . /app
RUN echo 'alias ls="ls --color"'>>/etc/bash.bashrc

WORKDIR /app
RUN echo 'alias sc="php /app/bin/console"' >> ~/.bashrc

CMD ["apache2-foreground"]
