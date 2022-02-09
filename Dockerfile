ARG PHP_VERSION=7.4
ARG WITH_SQL_SRV
ARG WITH_XDEBUG

FROM php:${PHP_VERSION}-fpm-buster AS rp-php-builder
ENV PHP_SENDMAIL_PATH="/usr/sbin/sendmail -t -i"
COPY --from=mlocati/php-extension-installer /usr/bin/install-php-extensions /usr/local/bin/
RUN chmod +x /usr/local/bin/install-php-extensions && install-php-extensions xdebug ssh2 zip apcu tidy pdo_mysql intl soap gd enchant imap calendar pcntl @composer-1
RUN if [ -n "$WITH_SQL_SRV" ]; then install-php-extensions sqlsrv pdo_sqlsrv; fi;
RUN if [ -n "$WITH_XDEBUG" ] ; then install-php-extensions xdebug; fi;
RUN apt update && apt install -y hunspell-nl git gnupg2 graphviz tidy wget curl
COPY php/php.ini /usr/local/etc/php/php.ini

FROM rp-php-builder AS rp-wkhtmltopdf-builder
RUN platform=$(uname -m | sed s/aarch64/arm64/ | sed s/x86_64/amd64/) && \
    wget https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6-1/wkhtmltox_0.12.6-1.buster_${platform}.deb && \
    apt update && apt install -y fontconfig libfreetype6 libjpeg62-turbo libpng16-16 libx11-6 libxcb1 libxext6 libxrender1 xfonts-75dpi xfonts-base && \
    dpkg --install wkhtmltox_0.12.6-1.buster_${platform}.deb

FROM rp-wkhtmltopdf-builder AS rp-php-fpm
COPY php/www.conf /usr/local/etc/php-fpm.d/www.conf
COPY php/docker-healthcheck.sh /usr/local/bin/docker-healthcheck
RUN chmod +x /usr/local/bin/docker-healthcheck
EXPOSE 9000
HEALTHCHECK --interval=10s --timeout=3s --retries=3 CMD ["docker-healthcheck"]

FROM rp-wkhtmltopdf-builder AS rp-php-cli