#!/usr/bin/env bash
#
# This script:
# - Updates to the latest version of upstream libraries
# - Runs apply-templates.sh
#
set -Eeuo pipefail

cd "$(dirname "$(readlink -f "$BASH_SOURCE")")"

# Download upstream php if we don't have it
./download-libs.sh

# Update the known version of PHP to the latest version
cd lib/php
git remote set-url origin git@github.com:docker-library/php.git
git pull origin master && git checkout master
echo "$(git rev-parse HEAD)" > ../.php-known-hash
cd ../bashbrew
git remote set-url origin git@github.com:docker-library/bashbrew.git
git pull origin master && git checkout master
echo "$(git rev-parse HEAD)" > ../.bashbrew-known-hash
cd ../..

./apply-templates.sh "$@"
