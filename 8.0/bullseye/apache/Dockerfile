#
# NOTE: THIS DOCKERFILE IS GENERATED VIA "apply-templates.sh"
#
# PLEASE DO NOT EDIT IT DIRECTLY.
#

FROM php:8.0-apache-bullseye

# Install PHP extensions which are recommended for Drupal,
# `mlocati/php-extension-installer` provides an easy way to install extensions.
# https://github.com/mlocati/docker-php-extension-installer/blob/master/README.md
COPY --from=mlocati/php-extension-installer /usr/bin/install-php-extensions /usr/local/bin/
RUN install-php-extensions \
    apcu \
    gd \
    opcache \
    uploadprogress
