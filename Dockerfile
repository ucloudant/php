FROM ubuntu:latest
MAINTAINER  jacky.shenyu@gmail.com
ARG DEBIAN_FRONTEND=noninteractive
RUN sed -i -e "s/archive.ubuntu.com/mirrors.aliyun.com/g" /etc/apt/sources.list \
    && sed -i -e "s/security.ubuntu.com/mirrors.aliyun.com/g" /etc/apt/sources.list \
    && apt-get update \
    && apt-get install -y \
        software-properties-common \
        curl \
    && add-apt-repository ppa:stesie/libv8 \
    && add-apt-repository ppa:ondrej/php \
    && apt-get update \
    && apt-get install -y \
        php7.3-fpm \
        php7.3-curl \
        php7.3-gd \
        php7.3-mbstring \
        php7.3-zip \
        php7.3-xml \
        php7.3-mysql \
        php7.3-intl \
        php7.3-xdebug \
        php7.3-mongodb \
        php7.3-redis \
        php7.3-apcu \
        libv8-7.5 \
        php7.3-dev \
        libv8-7.5-dev \
    && echo '/opt/libv8-7.5' | pecl install v8js \
    && apt-get autoremove -y \
        php7.3-dev \
        libv8-7.5-dev \
    && sed -i "s/;date.timezone =.*/date.timezone = Asia\/Shanghai/" /etc/php/7.3/cli/php.ini \
    && sed -i "s/;date.timezone =.*/date.timezone = Asia\/Shanghai/" /etc/php/7.3/fpm/php.ini \
    && sed -i "s/display_errors = Off/display_errors = On/" /etc/php/7.3/fpm/php.ini \
    && sed -i "s/upload_max_filesize = .*/upload_max_filesize = 10M/" /etc/php/7.3/fpm/php.ini \
    && sed -i "s/post_max_size = .*/post_max_size = 12M/" /etc/php/7.3/fpm/php.ini \
    && sed -i "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/" /etc/php/7.3/fpm/php.ini \
    && sed -i -e "s/pid =.*/pid = \/var\/run\/php7.3-fpm.pid/" /etc/php/7.3/fpm/php-fpm.conf \
    && sed -i -e "s/error_log =.*/error_log = \/proc\/self\/fd\/2/" /etc/php/7.3/fpm/php-fpm.conf \
    && sed -i -e "s/;daemonize\s*=\s*yes/daemonize = no/g" /etc/php/7.3/fpm/php-fpm.conf \
    && sed -i "s/listen = .*/listen = 9000/" /etc/php/7.3/fpm/pool.d/www.conf \
    && sed -i "s/;catch_workers_output = .*/catch_workers_output = yes/" /etc/php/7.3/fpm/pool.d/www.conf \
    && curl https://getcomposer.org/installer > composer-setup.php \
    && php composer-setup.php \
    && mv composer.phar /usr/local/bin/composer \
    && rm composer-setup.php \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
EXPOSE 9000
CMD ["php-fpm7.3"]
