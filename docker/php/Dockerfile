FROM php:7-fpm

#拷贝php.ini文件
ADD  php.ini /usr/local/etc/php/php.ini

RUN set -xe \
# "构建依赖"
    && buildDeps=" \
        build-essential \
        php5-dev \
        libfreetype6-dev \
        libjpeg62-turbo-dev \
        libmcrypt-dev \
        libpng12-dev \
    " \
# "运行依赖，不加这个，gd库不能正确安装"
    && runtimeDeps=" \
        libfreetype6 \
        libjpeg62-turbo \
        libmcrypt4 \
        libpng12-0 \
    " \
# "安装 php 以及编译构建组件所需包"
    && apt-get update \
	&& apt-get install -y ${runtimeDeps} ${buildDeps} --no-install-recommends \
	 curl \
	 git  \
	 wget \
# "编译安装 php 组件"
    && docker-php-ext-install iconv mcrypt mysqli pdo pdo_mysql zip \
    && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-install gd \
	
# "安装缓存类"	
	&& docker-php-ext-install mcrypt pdo_mysql zip mysqli \
    && pecl install msgpack-beta \
    && echo "extension=msgpack.so" > /usr/local/etc/php/conf.d/msgpack.ini \
    && pecl install mongodb \
    && echo "extension=mongodb.so" > /usr/local/etc/php/conf.d/mongodb.ini \
    && pecl install redis \
    && echo "extension=redis.so" > /usr/local/etc/php/conf.d/redis.ini \
	&& pecl clear-cache \
	
#安装ai.oneapm.com中的ai监控
	&& wget https://user.oneapm.com/account/9611aac4ceb6f73261e7c5022e44324c/agent/php/OneAPM_php_Agent_latest.tar.gz \
	&& tar -xzf OneAPM_php_Agent_latest.tar.gz \
	&& cd oneapm-php-install \
	&& ./oneapm-install install --php-path=/usr/local/bin --php-ini-file=/usr/local/etc/php/php.ini --license=BwdRAwIHVgR12c5TGl0WW1sdCE46e7ReDxkGBlQBSe63cAYATgQGHVQA771fA1UYBAVIB1I= \
	
	
# "清理"
    && apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false -o APT::AutoRemove::SuggestsImportant=false $buildDeps \
    && rm -rf /var/cache/apt/* \
    && rm -rf /var/lib/apt/lists/*
