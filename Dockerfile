ARG PHP_VERSION=7.4
FROM php:${PHP_VERSION}-fpm-alpine AS rp-php-fpm
COPY --from=mlocati/php-extension-installer /usr/bin/install-php-extensions /usr/local/bin/
COPY --from=ghcr.io/tiemez/rp-pub/rp-php-cli /usr/local/bin/php /usr/local/bin/php
RUN chmod +x /usr/local/bin/install-php-extensions && install-php-extensions xdebug ssh2 zip apcu tidy pdo_mysql intl soap gd enchant imap calendar pcntl @composer-1 sqlsrv pdo_sqlsrv
RUN apk add --no-cache hunspell git graphviz tidyhtml
COPY php/php-fpm.ini /usr/local/etc/php/php.ini
COPY php/www.conf /usr/local/etc/php-fpm.d/www.conf
COPY php/docker-healthcheck.sh /usr/local/bin/docker-healthcheck
RUN chmod +x /usr/local/bin/docker-healthcheck
EXPOSE 9000
HEALTHCHECK --interval=10s --timeout=3s --retries=3 CMD ["docker-healthcheck"]

FROM php:${PHP_VERSION}-cli-alpine AS rp-php-cli
COPY --from=mlocati/php-extension-installer /usr/bin/install-php-extensions /usr/local/bin/
RUN chmod +x /usr/local/bin/install-php-extensions && install-php-extensions xdebug ssh2 zip apcu tidy pdo_mysql intl soap gd enchant imap calendar pcntl @composer-1 sqlsrv pdo_sqlsrv
COPY php/php-cli.ini /usr/local/etc/php/php.ini
RUN apk add --no-cache hunspell git graphviz tidyhtml

FROM rp-php-cli AS rp-php-deployer
RUN apk add --no-cache openssh-client curl
RUN curl -LO https://deployer.org/deployer.phar -o /bin/deployer.phar

FROM devture/exim-relay:4.95-r0 AS rp-exim-relay
USER root
RUN sed -i "s|begin rewrite|begin rewrite \\n*@*   \"\$header_from\"  F|g" /etc/exim/exim.conf
USER exim