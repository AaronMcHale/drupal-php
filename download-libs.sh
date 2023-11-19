#!/usr/bin/env bash
#
# Downloads the known version of libraries to ./lib

if [ ! -d lib ]; then
    mkdir lib
fi
cd lib

# Clone PHP upstream if it doesn't exist
if [ ! -d php ]; then
    echo "Downloading docker-library/php..."
    git clone https://github.com/docker-library/php.git
fi
cd php && git fetch
if [ -f ../.php-known-hash ]; then
    echo "Checking out known version of docker-library/php..."
    git checkout -d "$(cat ../.php-known-hash)"
else
    echo "Known version for docker-library/php not stored, storing latest commit as known version..."
    echo "$(git rev-parse HEAD)" > ../.php-known-hash
fi
cd ..

# Clone bashbrew if it doesn't exist
if [ ! -d bashbrew ]; then
    echo "Downloading docker-library/bashbrew..."
    git clone https://github.com/docker-library/bashbrew.git
fi
cd bashbrew && git fetch
if [ -f ../.bashbrew-known-hash ]; then
    echo "Checking out known version of docker-library/bashbrew..."
    git checkout -d "$(cat ../.bashbrew-known-hash)"
else
    echo "Known version for docker-library/bashbrew not stored, storing latest commit as known version..."
    echo "$(git rev-parse HEAD)" > ../.bashbrew-known-hash
fi
cd ..
