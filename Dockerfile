ARG PHP_VERSION=7.4
ARG COMPOSER_VERSION=2

FROM composer:${COMPOSER_VERSION} as composer
FROM php:${PHP_VERSION}-fpm-buster

ARG PICKLE_VERSION=19.11.11

COPY --from=composer /usr/bin/composer /usr/bin/composer
COPY --from=symfonycorp/cli /symfony /usr/bin/symfony
COPY --from=ucloudant/sdktools /sdktools /usr/bin/sdktools
COPY --from=ucloudant/sdktools /libWeWorkFinanceSdk_C.so /usr/bin/libWeWorkFinanceSdk_C.so

ENV BUILD_DEPS \
	libfreetype6-dev \
	libjpeg62-turbo-dev \
	libpng-dev \
    libwebp-dev \
    libxpm-dev \
    libzip-dev \
    libicu-dev \
    libzstd-dev \
    libffi-dev

RUN set -eux; \
	apt-get update; \
	apt-get install -y \
    acl \
	libfcgi-bin \
	$BUILD_DEPS \
    ; \
	curl -fsSL -o /usr/local/bin/pickle https://github.com/khs1994-php/pickle/releases/download/v${PICKLE_VERSION}/pickle.phar; \
	chmod +x /usr/local/bin/pickle; \
	# 安装内置扩展
	docker-php-source extract; \
	docker-php-ext-install zip; \
	strip --strip-all $(php -r "echo ini_get('extension_dir');")/zip.so; \
	echo " \
	--with-freetype \
	--with-jpeg \
	--with-webp \
	--with-xpm" > /tmp/gd.configure.options; \
	pickle install -n --defaults --strip --cleanup \
	gd \
	pdo_mysql \
	pdo_pgsql \
	intl \
	; \
	docker-php-source delete; \
	# 安装 PECL 扩展
	echo "--with-libzstd" > /tmp/zstd.configure.options; \
	pickle install -n --defaults --strip --cleanup \
	apcu \
	zstd \
	mongodb \
	redis \
	; \
	# 默认不启用的扩展
	pickle install -n --defaults --strip --cleanup --no-write \
	xdebug \
	; \
	pickle install opcache; \
	# 安装 Blackfire 扩展, 默认不开启
	version=$(php -r "echo PHP_MAJOR_VERSION.PHP_MINOR_VERSION;"); \
	curl -A "Docker" -o /tmp/blackfire-probe.tar.gz -D - -L -s https://blackfire.io/api/v1/releases/probe/php/linux/amd64/$version; \
    mkdir -p /tmp/blackfire; \
	tar zxpf /tmp/blackfire-probe.tar.gz -C /tmp/blackfire; \
	mv /tmp/blackfire/blackfire-*.so $(php -r "echo ini_get ('extension_dir');")/blackfire.so; \
 	apt-get remove -y \
    $PHPIZE_DEPS \
    $BUILD_DEPS \
    ; \
    apt-get clean; \
	rm -rf /tmp/*;
