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

jqt='.jq-template.awk'
if [ -n "${BASHBREW_SCRIPTS:-}" ]; then
	jqt="$BASHBREW_SCRIPTS/jq-template.awk"
elif [ "$BASH_SOURCE" -nt "$jqt" ]; then
	# https://github.com/docker-library/bashbrew/blob/master/scripts/jq-template.awk
	wget -qO "$jqt" 'https://github.com/docker-library/bashbrew/raw/9f6a35772ac863a0241f147c820354e4008edf38/scripts/jq-template.awk'
fi

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
