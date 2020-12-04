ARG PHP_VERSION=8.0
ARG COMPOSER_VERSION=2

FROM composer:${COMPOSER_VERSION} as composer
FROM php:${PHP_VERSION}-fpm-alpine

ARG PICKLE_VERSION=19.11.11

COPY --from=composer /usr/bin/composer /usr/bin/composer
COPY --from=symfonycorp/cli /symfony /usr/bin/symfony

RUN set -eux; \
	apk add --no-cache \
	fcgi \
	acl \
	; \
	apk add --no-cache --virtual .build-deps \
	$PHPIZE_DEPS \
	libzip-dev \
	freetype-dev \
	libjpeg-turbo-dev \
	libpng-dev \
	libxpm-dev \
	libwebp-dev \
	postgresql-dev \
	zstd-dev \
	libffi-dev \
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
	; \
	docker-php-source delete; \
	# 安装 PECL 扩展
	echo "--with-libzstd" > /tmp/zstd.configure.options; \
	pickle install -n --defaults --strip --cleanup \
	apcu \
	zstd \
	redis \
	mongodb \
	; \
	# 默认不启用的扩展
	pickle install -n --defaults --strip --cleanup --no-write \
	xdebug \
	# /tmp/blackfire \
	; \
	pickle install opcache; \
	version=$(php -r "echo PHP_MAJOR_VERSION.PHP_MINOR_VERSION;"); \
	curl -A "Docker" -o /tmp/blackfire-probe.tar.gz -D - -L -s https://blackfire.io/api/v1/releases/probe/php/alpine/amd64/$version; \
    mkdir -p /tmp/blackfire; \
	tar zxpf /tmp/blackfire-probe.tar.gz -C /tmp/blackfire; \
	mv /tmp/blackfire/blackfire-*.so $(php -r "echo ini_get ('extension_dir');")/blackfire.so; \
	runDeps="$( \
	scanelf --needed --nobanner --format '%n#p' --recursive /usr/local/lib/php/extensions \
	| tr ',' '\n' \
	| sort -u \
	| awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }' \
	)"; \
	apk add --no-cache --virtual .phpexts-rundeps $runDeps; \
	\
	apk del .build-deps; \
	rm -rf /tmp/*; \
	# 设置 composer 国内镜像
	composer config -g repo.packagist composer https://mirrors.aliyun.com/composer/