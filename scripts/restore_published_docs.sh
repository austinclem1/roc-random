#!/usr/bin/env bash

# https://vaneyckt.io/posts/safer_bash_scripts_with_set_euxo_pipefail/
set -euo pipefail

# Restore the published documentation site from GitHub release assets.
#
# The docs site is not checked into this repository. Each release ships its
# generated docs as a `roc-random-docs-<version>.tar.gz` asset, and the site is
# reassembled here by unpacking those assets from newest to oldest.
#
# Two asset layouts exist:
#   * current: the archive holds a single `<version>/` directory, so every
#     release contributes only its own docs.
#   * legacy: releases up to 0.9.0 archived the entire site, so the archive
#     holds a `www/` directory with every version that existed at the time.
#     Such an archive already supplies everything older than itself, so
#     unpacking stops there. Stopping also preserves deliberate removals: the
#     0.9.0 archive dropped 0.5.0, and walking further back would resurrect it.
#
# Versions restored from a newer release always win, so a legacy archive can
# never overwrite docs that a later release republished.

OUTPUT_DIR="www"
ALLOW_MISSING="false"
REPO="${GITHUB_REPOSITORY:-}"

usage() {
    echo "Usage: $0 [--output-dir DIR] [--allow-missing] [--repo OWNER/NAME]"
    echo "  --output-dir DIR   Where to place the restored site (default: www)"
    echo "  --allow-missing    Create an empty site instead of failing when no"
    echo "                     release carries a docs asset yet"
    echo "  --repo OWNER/NAME  Repository to read releases from (default:"
    echo "                     \$GITHUB_REPOSITORY, else the current clone's remote)"
}

while [ $# -gt 0 ]; do
    case "$1" in
        --output-dir)
            if [ $# -lt 2 ]; then
                echo "Error: --output-dir requires a value" >&2
                exit 1
            fi
            OUTPUT_DIR="$2"
            shift 2
            ;;
        --allow-missing)
            ALLOW_MISSING="true"
            shift
            ;;
        --repo)
            if [ $# -lt 2 ]; then
                echo "Error: --repo requires a value" >&2
                exit 1
            fi
            REPO="$2"
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Error: unknown argument: $1" >&2
            usage >&2
            exit 1
            ;;
    esac
done

ASSET_PREFIX="roc-random-docs-"
ASSET_SUFFIX=".tar.gz"
ASSET_GLOB="$ASSET_PREFIX*$ASSET_SUFFIX"

# Without this, `gh` resolves the repository from the current clone's remote,
# which is not available to out-of-clone runs.
if [ -n "$REPO" ]; then
    export GH_REPO="$REPO"
fi

# The releases listing already carries each release's assets, so the set of
# docs-carrying releases is one API call away. Assigned before it is inspected
# so a failed lookup aborts here, rather than being mistaken for a repository
# that has no docs asset yet.
#
# Releases come back newest first. Older releases predate the docs asset, and
# drafts/prereleases must never become the published site.
docs_tags="$(
    gh api 'repos/{owner}/{repo}/releases?per_page=100' \
        --jq ".[] | select(.draft or .prerelease | not)
                  | select(any(.assets[]; (.name | startswith(\"$ASSET_PREFIX\"))
                                          and (.name | endswith(\"$ASSET_SUFFIX\"))))
                  | .tag_name"
)"

if [ -z "$docs_tags" ]; then
    if [ "$ALLOW_MISSING" = "true" ]; then
        echo "No release carries a $ASSET_GLOB asset yet; starting from an empty docs site."
        mkdir -p "$OUTPUT_DIR"
        exit 0
    fi
    echo "Error: no release carries a $ASSET_GLOB asset." >&2
    exit 1
fi

# The newest docs-carrying release is what the site root should redirect to.
latest_version="${docs_tags%%$'\n'*}"

# Staged next to the output so the final move stays on one filesystem.
mkdir -p "$(dirname "${OUTPUT_DIR%/}")"
tmp_dir="$(mktemp -d "${OUTPUT_DIR%/}.restore.XXXXXX")"
trap 'rm -rf "$tmp_dir"' EXIT

staging="$tmp_dir/staging"
mkdir -p "$staging"

# Copy version directories into the staging site, keeping any already there
# because they came from a newer release.
take_version_dirs() {
    local source_dir="$1"
    local entry name
    for entry in "$source_dir"/*; do
        [ -d "$entry" ] || continue
        name="$(basename "$entry")"
        [[ "$name" =~ ^[0-9]+\.[0-9]+\.[0-9]+ ]] || continue
        [ -e "$staging/$name" ] || cp -R "$entry" "$staging/$name"
    done
}

while read -r tag; do
    [ -n "$tag" ] || continue

    download_dir="$tmp_dir/download/$tag"
    extract_dir="$tmp_dir/extract/$tag"
    mkdir -p "$download_dir" "$extract_dir"

    gh release download "$tag" --pattern "$ASSET_GLOB" --dir "$download_dir"

    archive="$(find "$download_dir" -maxdepth 1 -name "$ASSET_GLOB" | sort | tail -n 1)"
    if [ -z "$archive" ]; then
        echo "Error: release $tag did not yield a $ASSET_GLOB asset." >&2
        exit 1
    fi

    tar -xzf "$archive" -C "$extract_dir"

    if [ -d "$extract_dir/www" ]; then
        echo "Unpacking $tag (legacy whole-site archive; older releases not needed)"
        take_version_dirs "$extract_dir/www"
        break
    fi

    echo "Unpacking $tag"
    take_version_dirs "$extract_dir"
done <<< "$docs_tags"

restored="$(find "$staging" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | sort -V | tr '\n' ' ')"
if [ -z "$restored" ]; then
    echo "Error: no version directories were found in the docs assets." >&2
    exit 1
fi

if [ ! -d "$staging/$latest_version" ]; then
    echo "Error: docs for the newest release ($latest_version) are missing from its asset." >&2
    exit 1
fi

# Redirect the site root at the newest release, matching what the release
# workflow's docs-index step writes.
repo_name="${REPO##*/}"
if [ -z "$repo_name" ]; then
    repo_name="$(gh repo view --json name --jq .name)"
fi
target="/$repo_name/$latest_version/"
cat > "$staging/index.html" <<EOF
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta http-equiv="refresh" content="0; url=$target">
  <link rel="canonical" href="$target">
  <title>Redirecting to $latest_version</title>
</head>
<body>
  <p><a href="$target">Redirecting to $latest_version</a></p>
</body>
</html>
EOF

rm -rf "$OUTPUT_DIR"
mv "$staging" "$OUTPUT_DIR"

echo "Restored docs versions: $restored"
echo "Site root redirects to $target"
