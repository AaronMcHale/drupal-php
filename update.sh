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
echo "Starting update of libraries..."
cd lib/php
echo "Setting remote for docker-library/php..."
git remote set-url origin https://github.com/docker-library/php.git
echo "Pulling latest commits and checking out master for docker-library/php..."
git pull origin master && git checkout master
echo "Storing latest commit as known version for docker-library/php..."
echo "$(git rev-parse HEAD)" > ../.php-known-hash

cd ../bashbrew
echo "Setting remote for docker-library/bashbrew..."
git remote set-url origin https://github.com/docker-library/bashbrew.git
echo "Pulling latest commits and checking out master for docker-library/bashbrew..."
git pull origin master && git checkout master
echo "Storing latest commit as known version for docker-library/bashbrew..."
echo "$(git rev-parse HEAD)" > ../.bashbrew-known-hash
cd ../..
echo "Library update complete."

./apply-templates.sh "$@"
