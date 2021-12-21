ARG PHP_VERSION=7.4

FROM php:${PHP_VERSION}-fpm-buster AS rp-php-builder
ENV PHP_SENDMAIL_PATH="/usr/sbin/sendmail -t -i"
COPY --from=mlocati/php-extension-installer /usr/bin/install-php-extensions /usr/local/bin/
RUN chmod +x /usr/local/bin/install-php-extensions && install-php-extensions xdebug ssh2 zip apcu tidy pdo_mysql intl soap gd enchant imap calendar pcntl @composer-1 sqlsrv pdo_sqlsrv
RUN apt update && apt install -y hunspell-nl git gnupg2 graphviz tidy wget curl
COPY php/php.ini /usr/local/etc/php/php.ini

FROM rp-php-builder AS rp-wkhtmltopdf-builder
RUN wget https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6-1/wkhtmltox_0.12.6-1.buster_amd64.deb
RUN apt update && apt install -y fontconfig libfreetype6 libjpeg62-turbo libpng16-16 libx11-6 libxcb1 libxext6 libxrender1 xfonts-75dpi xfonts-base
RUN dpkg --install wkhtmltox_0.12.6-1.buster_amd64.deb

FROM rp-wkhtmltopdf-builder AS rp-php-fpm
COPY php/www.conf /usr/local/etc/php-fpm.d/www.conf
COPY php/docker-healthcheck.sh /usr/local/bin/docker-healthcheck
RUN chmod +x /usr/local/bin/docker-healthcheck
EXPOSE 9000
HEALTHCHECK --interval=10s --timeout=3s --retries=3 CMD ["docker-healthcheck"]

FROM rp-wkhtmltopdf-builder AS rp-php-cli

FROM rp-php-cli AS rp-php-deployer
RUN apt update && apt install -y openssh-client curl
RUN curl -LO https://deployer.org/deployer.phar -o /bin/deployer.phar

FROM devture/exim-relay:4.95-r0 AS rp-exim-relay
USER root
RUN sed -i "s|begin rewrite|begin rewrite \\n*@*   \"\$header_from\"  F|g" /etc/exim/exim.conf
USER exim