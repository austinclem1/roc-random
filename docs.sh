#!/usr/bin/env bash

# https://vaneyckt.io/posts/safer_bash_scripts_with_set_euxo_pipefail/
set -euxo pipefail

# Generate the docs for one version into www/ for local preview.
#
# www/ is not checked in. The release workflow generates these docs itself,
# ships them as a release asset, and deploys GitHub Pages from that asset, so
# nothing here needs to be committed. To preview the published site instead,
# run ./scripts/restore_published_docs.sh

# Function to validate version number format (x.y.z)
validate_version() {
    if [[ ! $1 =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo "Error: Version number must be in format x.y.z (e.g., 0.12.0)"
        exit 1
    fi
}

# Check if version argument is provided
if [ $# -ne 1 ]; then
    echo "Usage: $0 <version>"
    echo "Example: $0 0.12.0"
    exit 1
fi

VERSION=$1

# Validate version number
validate_version "$VERSION"

# Generate docs for this version into www/
rm -rf "www/$VERSION"
roc docs package/main.roc --output="www/$VERSION"
