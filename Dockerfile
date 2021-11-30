ARG PHP_VERSION=7.4
FROM php:${PHP_VERSION}-fpm-alpine AS rp-php-fpm
COPY --from=mlocati/php-extension-installer /usr/bin/install-php-extensions /usr/local/bin/
COPY --from=ghcr.io/tiemez/rp-pub/rp-php-cli /usr/local/bin/php /usr/local/bin/php
RUN chmod +x /usr/local/bin/install-php-extensions && install-php-extensions xdebug ssh2 zip apcu tidy pdo_mysql intl soap gd enchant imap calendar pcntl @composer-1 sqlsrv pdo_sqlsrv
RUN apk add --no-cache hunspell git graphviz tidyhtml
COPY php/php.ini /usr/local/etc/php.ini
COPY php/xdebug.ini /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini
COPY php/www.conf /usr/local/etc/php-fpm.d/www.conf
COPY php/docker-healthcheck.sh /usr/local/bin/docker-healthcheck
RUN chmod +x /usr/local/bin/docker-healthcheck
HEALTHCHECK --interval=10s --timeout=3s --retries=3 CMD ["docker-healthcheck"]
RUN id -u www-data &>/dev/null || useradd www-data -S www-data -u 1000
USER www-data

FROM php:${PHP_VERSION}-cli-alpine AS rp-php-cli
COPY --from=mlocati/php-extension-installer /usr/bin/install-php-extensions /usr/local/bin/
RUN chmod +x /usr/local/bin/install-php-extensions && install-php-extensions xdebug ssh2 zip apcu tidy pdo_mysql intl soap gd enchant imap calendar pcntl @composer-1 sqlsrv pdo_sqlsrv
RUN apk add --no-cache hunspell git graphviz tidyhtml
COPY php/php.ini /usr/local/etc/php.ini
COPY php/xdebug.ini /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini
RUN id -u www-data &>/dev/null || useradd www-data -S www-data -u 1000
USER www-data

FROM rp-php-cli AS rp-php-deployer
RUN apk add --no-cache openssh-client curl
RUN curl -LO https://deployer.org/deployer.phar -o /bin/deployer.phar