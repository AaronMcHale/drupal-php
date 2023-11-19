#!/usr/bin/env bash
#
# Downloads the known version of the upstream php to ./lib/php

# Clone PHP upstream if it doesn't exist
if [ ! -e lib/php ]; then
    git clone git@github.com:docker-library/php.git lib/php
fi

# Get the known commit hash and change to it
hash="$(cat .upstream-php-hash)"
cd lib/php
git checkout -d "$hash"
