#!/usr/bin/env bash
#
# Generates the matrix used for the generate-jobs GitHuab CI step

set -Eeuo pipefail

cd "$(dirname "$(readlink -f "$BASH_SOURCE")")"

# Helper function to remove all whitespaces from a line.
transform_line() {
    line="$1"
    echo "${line//[[:blank:]]/}"
}

# Helper function to add the repository name to each tag that
# generate-stackbrew-library.sh returns.
transform_tags() {
    if [ -z "$1" ]; then
        echo 'call to transform_tags() resulted in error: $1 must not be emtpy, argument 1 is required.' >&1
        exit 1
    fi
    input="$1"
    # we need to add an extra comma to the end otherwise the last value may
    # not be included
    if [ "${input:-1}" != ',' ]; then
        input="$input"','
    fi
    tags="$(
        while read -d ',' -r tag; do
            if [ ! -z "$tag" ]; then
                printf "%s:%s," "aaronmchale/drupal-php" "$tag"
            fi
        done <<< "$input"
    )"
    printf "${tags:0:-1}"
}

# helper function to output test error messages
# `$1`: name of function
# `$2`: input sent to function
# `$3`: expected output from function
# `$4`: actual output from function
exit_with_test_error() {
    echo "Error when testing ""$1"", input did not match expected output:" >&1
    echo >&1
    echo "  input: ""$2" >&1
    echo >&1
    echo "  expected: ""$3" >&1
    echo >&1
    echo "  actual output: ""$4" >&1
    echo >&1
    exit 1
}

# Tests for `transform_line()` function to ensure it's working as expected
test_transform_line() {
    # Test empty line
    input=""
    expected=""
    got="$(transform_line "$input")"
    if [ "$got" != "$expected" ]; then
        exit_with_test_error "transform_line" "$input" "$expected" "$got"
    fi

    # Test line with one value (and forward slashes)
    input="Directory: 8.3-rc/bookworm/cli"
    expected="Directory:8.3-rc/bookworm/cli"
    got="$(transform_line "$input")"
    if [ "$got" != "$expected" ]; then
        exit_with_test_error "transform_line" "$input" "$expected" "$got"
    fi

    # Test line with multiple values
    input="Architectures: amd64, arm32v5, arm32v7, arm64v8, i386, mips64le, ppc64le, s390x"
    expected="Architectures:amd64,arm32v5,arm32v7,arm64v8,i386,mips64le,ppc64le,s390x"
    got="$(transform_line "$input")"
    if [ "$got" != "$expected" ]; then
        exit_with_test_error "transform_line" "$input" "$expected" "$got"
    fi
}
test_transform_line

# Tests for `transform_tags()` function to ensure it's working as expected
test_transform_tags() {
    # Test single value
    input="8"
    expected="aaronmchale/drupal-php:8"
    got="$(transform_tags "$input")"
    if [ "$got" != "$expected" ]; then
        exit_with_test_error "transform_tags" "$input" "$expected" "$got"
    fi

    # Test adding comma to end of string
    input="8,"
    expected="aaronmchale/drupal-php:8"
    got="$(transform_tags "$input")"
    if [ "$got" != "$expected" ]; then
        exit_with_test_error "transform_tags" "$input" "$expected" "$got"
    fi

    # Test version number and "latest"
    input="8,latest"
    expected="aaronmchale/drupal-php:8,aaronmchale/drupal-php:latest"
    got="$(transform_tags "$input")"
    if [ "$got" != "$expected" ]; then
        exit_with_test_error "transform_tags" "$input" "$expected" "$got"
    fi

    # test a real string, probably the longest one, with final tag as "latest"
    input="8.2.12-cli-bookworm,8.2-cli-bookworm,8-cli-bookworm,cli-bookworm,8.2.12-bookworm,8.2-bookworm,8-bookworm,bookworm,8.2.12-cli,8.2-cli,8-cli,cli,8.2.12,8.2,8,latest"
    expected="aaronmchale/drupal-php:8.2.12-cli-bookworm,aaronmchale/drupal-php:8.2-cli-bookworm,aaronmchale/drupal-php:8-cli-bookworm,aaronmchale/drupal-php:cli-bookworm,aaronmchale/drupal-php:8.2.12-bookworm,aaronmchale/drupal-php:8.2-bookworm,aaronmchale/drupal-php:8-bookworm,aaronmchale/drupal-php:bookworm,aaronmchale/drupal-php:8.2.12-cli,aaronmchale/drupal-php:8.2-cli,aaronmchale/drupal-php:8-cli,aaronmchale/drupal-php:cli,aaronmchale/drupal-php:8.2.12,aaronmchale/drupal-php:8.2,aaronmchale/drupal-php:8,aaronmchale/drupal-php:latest"
    got="$(transform_tags "$input")"
    if [ "$got" != "$expected" ]; then
        exit_with_test_error "transform_tags" "$input" "$expected" "$got"
    fi
}
test_transform_tags

if [ ! -f lib/php/generate-stackbrew-library.sh ]; then
	echo "Cannot find library files to copy from, run ./download-libs.sh"
	exit 1
fi

# Use the output of `generate-stackbrew-library.sh` from php upstream
cd lib/php

# Initialise empty variables
declare tags= arches= dir= name=

# generate-stackbrew-library.sh generates an output in the follwing format
# ```
# Tags: 8.3.0RC6-cli-bookworm, 8.3-rc-cli-bookworm, 8.3.0RC6-bookworm, 8.3-rc-bookworm, 8.3.0RC6-cli, 8.3-rc-cli, 8.3.0RC6, 8.3-rc
# Architectures: amd64, arm32v5, arm32v7, arm64v8, i386, mips64le, ppc64le, s390x
# GitCommit: bde3d5c08a72f61ed5af7592b1910faed1e4a3f2
# Directory: 8.3-rc/bookworm/cli
#
# Tags: 8.3.0RC6-apache-bookworm, 8.3-rc-apache-bookworm, 8.3.0RC6-apache, 8.3-rc-apache
# Architectures: amd64, arm32v5, arm32v7, arm64v8, i386, mips64le, ppc64le, s390x
# GitCommit: bde3d5c08a72f61ed5af7592b1910faed1e4a3f2
# Directory: 8.3-rc/bookworm/apache
#
# ```
# And so on...
# It includes every version/variation, along with all of the tags and platforms that
# we need.
strategy="$(
set -Eeuo pipefail
./generate-stackbrew-library.sh | while IFS=$'\n' read -r line; do
    # Remove all whitespace characters (spaces, tabs, etc) from the line
    # so that, for instance, the "Tags" line looks like:
    # `Tags:8.3.0RC6-apache-bookworm,8.3-rc-apache-bookworm,8.3.0RC6-apache, 8.3-rc-apache`
    line="$(transform_line "$line")"

    # Split the line into the key and value, where for instnace Tags is the key and
    # everything after `:` is the avlue
    IFS=$':' read -r key value <<< "$line"

    case "$key" in
        "Tags")
            tags="$(transform_tags "$value")" ;;
        "Architectures")
            arches="${value/arm32v5,/}" ;;
        "Directory")
            dir="$value"
            # For the name of this job, we use the value of `$dir` but
            # replace the `/` directory separateor with `-`.
            name="${dir//\//-}"
            ;;
    esac

    if [ -z "$line" ] && [ -n "$tags" ] && [ -n "$arches" ] && [ -n "$dir" ]; then
        # If we get here, we've reached a empty line, and we have values for
        # `$tags`, `$arches` and `$dir`, so we're ready to construct the JSON
        # object for this job.
        echo "{
            \"name\": \"$name\",
            \"dir\": \"$dir\",
            \"tags\": \"$tags\",
            \"arches\": \"$arches\"
        }"
        # Reset variables to empty strings, the next line should be the start
        # of a new version/variant.
        declare tags= arches= dir= name=
    fi
done | jq -cs '
		{
			"fail-fast": false,
			matrix: { include: . },
		}
	'
)"

if [ -t 1 ]; then
	jq <<<"$strategy"
else
	cat <<<"$strategy"
fi
