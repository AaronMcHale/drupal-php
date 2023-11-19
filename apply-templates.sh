#!/usr/bin/env bash
#
# Based on apply-templates.sh in lib/php
set -Eeuo pipefail

if [ ! -f lib/php/versions.json ] || [ ! -f lib/bashbrew/scripts/jq-template.awk ]; then
	echo "Cannot find library files to copy from, run ./download-libs.sh"
	exit 1
fi

# Get the latest files from lib
cp -f lib/php/versions.json .
cp -f lib/bashbrew/scripts/jq-template.awk .jq-template.awk
jqt='.jq-template.awk'

if [ "$#" -eq 0 ]; then
	versions="$(jq -r 'keys | map(@sh) | join(" ")' versions.json)"
	eval "set -- $versions"
fi

generated_warning() {
	cat <<-EOH
		#
		# NOTE: THIS DOCKERFILE IS GENERATED VIA "apply-templates.sh"
		#
		# PLEASE DO NOT EDIT IT DIRECTLY.
		#

	EOH
}

for version; do
	export version

	rm -rf "$version"

	if jq -e '.[env.version] | not' versions.json > /dev/null; then
		echo "deleting $version ..."
		continue
	fi

	variants="$(jq -r '.[env.version].variants | map(@sh) | join(" ")' versions.json)"
	eval "variants=( $variants )"

	for dir in "${variants[@]}"; do
		suite="$(dirname "$dir")" # "buster", etc
		variant="$(basename "$dir")" # "cli", etc
		export suite variant

		# our apply-templates.sh is simplier than the one in lib/php
		# Our "from" line is always the php image, and we use the exact
		# same version, variant and suite, so we don't need logic to
		# figure out the version number, etc.
        from="php:$version-$variant-$suite"
		export from
		# apply-templates.sh in lib/php also varies the cmd depnding on
		# the variant, but we just use the cmd from the php image, so we
		# don't need to set it here.

		echo "processing $version/$dir ..."
		mkdir -p "$version/$dir"

		{
			generated_warning
			gawk -f "$jqt" 'Dockerfile-linux.template'
		} > "$version/$dir/Dockerfile"
	done
done

# Generate JSON for CI jobs using upstream generate.sh script. We use the
# upstream php library to generate the JSON. We need to ensure that the
# GITHUB_REPOSITORY environment variable is set appropriately, then re-set
# it once we're done.
echo "Generate JSON structure for CI jobs..."
cd lib/php
if env | grep -q "GITHUB_REPOSITORY="; then
	temp_GITHUB_REPOSITORY="$GITHUB_REPOSITORY"
	export GITHUB_REPOSITORY="docker-library/php"
	strategy="$("../bashbrew/scripts/github-actions/generate.sh")"
	export GITHUB_REPOSITORY="$temp_GITHUB_REPOSITORY"
else
	export GITHUB_REPOSITORY="docker-library/php"
	strategy="$("../bashbrew/scripts/github-actions/generate.sh")"
	unset GITHUB_REPOSITORY
fi
cd ../..

# Replace "php" with "drupal-php" in generated JSON
strategy="$(echo "$strategy" | sed -e "s/php/drupal-php/g")"

# The CI job picks up the output from this script and uses it to generate jobs
echo "$strategy" > "versions-ci-json.lock"
echo "JSON for CI jobs saved to versions-ci-json.lock"
