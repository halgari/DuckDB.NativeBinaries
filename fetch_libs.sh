#!/usr/bin/env bash

# This script downloads the prebuilt DuckDB shared libraries for the specified
# release and extracts them into the appropriate runtime folders.  Set
# DUCKDB_VERSION (e.g. v1.3.2) in the environment to override the default.
set -euo pipefail

DUCKDB_VERSION=${DUCKDB_VERSION:-v1.3.2}

BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
DOWNLOADS="$BASE_DIR/downloads"
RUNTIMES="$BASE_DIR/runtimes"

mkdir -p "$DOWNLOADS"
mkdir -p "$RUNTIMES/win-x64/native" "$RUNTIMES/win-arm64/native" \
         "$RUNTIMES/linux-x64/native" "$RUNTIMES/linux-arm64/native" \
         "$RUNTIMES/osx-x64/native" "$RUNTIMES/osx-arm64/native"

download_asset() {
  local asset_name=$1
  local dest="$DOWNLOADS/$asset_name"
  local url="https://github.com/duckdb/duckdb/releases/download/${DUCKDB_VERSION}/${asset_name}"
  echo "Downloading $url"
  curl -L -o "$dest" "$url"
}

# Download release assets
download_asset "libduckdb-linux-amd64.zip"
download_asset "libduckdb-linux-arm64.zip"
download_asset "libduckdb-osx-universal.zip"
download_asset "libduckdb-windows-amd64.zip"
download_asset "libduckdb-windows-arm64.zip"

extract_and_copy() {
  local zipfile=$1
  local pattern=$2
  local dest=$3
  local tmpdir
  tmpdir=$(mktemp -d)
  unzip -oq "$zipfile" -d "$tmpdir"
  local libfile
  libfile=$(find "$tmpdir" -name "$pattern" | head -n1)
  if [[ -z "$libfile" ]]; then
    echo "Failed to find $pattern in $zipfile" >&2
    exit 1
  fi
  cp "$libfile" "$dest/"
  rm -rf "$tmpdir"
}

# Extract and copy Linux libs
extract_and_copy "$DOWNLOADS/libduckdb-linux-amd64.zip" "libduckdb.so" "$RUNTIMES/linux-x64/native"
extract_and_copy "$DOWNLOADS/libduckdb-linux-arm64.zip" "libduckdb.so" "$RUNTIMES/linux-arm64/native"

# Extract Mac universal library once and copy to both RIDs
tmpdir=$(mktemp -d)
unzip -oq "$DOWNLOADS/libduckdb-osx-universal.zip" -d "$tmpdir"
maclib=$(find "$tmpdir" -name 'libduckdb.dylib' | head -n1)
cp "$maclib" "$RUNTIMES/osx-x64/native/"
cp "$maclib" "$RUNTIMES/osx-arm64/native/"
rm -rf "$tmpdir"

# Extract Windows libs
extract_and_copy "$DOWNLOADS/libduckdb-windows-amd64.zip" "duckdb.dll" "$RUNTIMES/win-x64/native"
extract_and_copy "$DOWNLOADS/libduckdb-windows-arm64.zip" "duckdb.dll" "$RUNTIMES/win-arm64/native"

echo "DuckDB native libraries have been downloaded and placed in the runtimes directory."