#!/usr/bin/env bash
# Print the fetchFromGitHub and fetchNpmDeps hashes for a tagged GitHub release,
# for use in overrideAttrs version bumps (e.g. uptime-kuma in hosts/tachi).
#
# Usage: scripts/prefetch-github-npm.sh <owner/repo> <tag> [lockfile-path]
#   e.g. scripts/prefetch-github-npm.sh louislam/uptime-kuma 2.5.12
#
# lockfile-path is relative to the repo root and defaults to package-lock.json.
# If the lockfile doesn't exist, only the src hash is printed.
set -euo pipefail

if [[ $# -lt 2 ]]; then
  echo "Usage: $0 <owner/repo> <tag> [lockfile-path]" >&2
  exit 1
fi

repo="$1"
tag="$2"
lockfile="${3:-package-lock.json}"

echo "Prefetching github:${repo}/${tag}..." >&2
prefetch_json="$(nix flake prefetch --json "github:${repo}/${tag}")"
src_hash="$(nix run nixpkgs#jq -- -r .hash <<<"$prefetch_json")"
store_path="$(nix run nixpkgs#jq -- -r .storePath <<<"$prefetch_json")"

cat <<EOF
version      = "${tag}"
src hash     = "${src_hash}"
EOF

if [[ ! -f "${store_path}/${lockfile}" ]]; then
  exit 0
fi

npm_hash="$(nix run nixpkgs#prefetch-npm-deps -- "${store_path}/${lockfile}" 2>/dev/null | tail -1)"
echo "npmDeps hash = \"${npm_hash}\""
