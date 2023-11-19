#!/usr/bin/env bash
#
# Update to the latest version of upstream php and generate from templates.
#
set -Eeuo pipefail

cd "$(dirname "$(readlink -f "$BASH_SOURCE")")"

# Download upstream php if we don't have it
./get-upstream-php.sh

# Update the known version of PHP to the latest version
cd lib/php
git remote set-url origin git@github.com:docker-library/php.git
git pull origin master
git checkout master
echo "$(git rev-parse HEAD)" > ../../.upstream-php-hash
cd ../..

./apply-templates.sh "$@"
