ARG PHP_VERSION=7.4
ARG COMPOSER_VERSION=2

FROM composer:${COMPOSER_VERSION} as composer

FROM php:${PHP_VERSION}-fpm-alpine

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
	curl -fsSL -o /usr/local/bin/pickle https://github.com/khs1994-php/pickle/releases/download/nightly/pickle-debug.phar; \
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
		ffi \
	; \
	docker-php-source delete; \
# 安装 PECL 扩展
	echo "--with-libzstd" > /tmp/zstd.configure.options; \
	pickle install -n --defaults --strip --cleanup \
		apcu \
		zstd \
		mongodb \
		redis \
		wasm \
	; \
# 默认不启用的扩展
	pickle install -n --defaults --strip --cleanup --no-write \
		https://github.com/xdebug/xdebug/archive/master.tar.gz \
		https://github.com/tideways/php-xhprof-extension/archive/master.tar.gz \
		https://blackfire.io/api/v1/releases/probe/php/alpine/amd64/74 \
	; \
	pickle install opcache; \
	runDeps="$( \
		scanelf --needed --nobanner --format '%n#p' --recursive /usr/local/lib/php/extensions \
			| tr ',' '\n' \
			| sort -u \
			| awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }' \
	)"; \
	apk add --no-cache --virtual .phpexts-rundeps $runDeps; \
	\
	apk del .build-deps; \
	rm -rf /tmp/*

COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

RUN set -eux; \
    composer config -g repo.packagist composer https://mirrors.aliyun.com/composer/
