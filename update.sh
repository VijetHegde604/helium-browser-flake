#!/usr/bin/env bash
set -euo pipefail

repo="imputnet/helium-linux"
package_file="package.nix"

if [[ ! -f "$package_file" ]]; then
  echo "error: run this script from the repository root" >&2
  exit 1
fi

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "error: required command not found: $1" >&2
    exit 1
  fi
}

require_cmd curl
require_cmd python3
require_cmd nix

latest_json="$(curl --fail --location --silent --show-error \
  --header "Accept: application/vnd.github+json" \
  "https://api.github.com/repos/${repo}/releases/latest")"

tag="$(LATEST_JSON="$latest_json" python3 - <<'PY'
import json
import os

release = json.loads(os.environ["LATEST_JSON"])
tag = release.get("tag_name")
if not tag:
    raise SystemExit("latest release response did not contain tag_name")
print(tag)
PY
)"

version="${tag#v}"
asset_name="helium-${version}-x86_64_linux.tar.xz"
asset_url="https://github.com/${repo}/releases/download/${tag}/${asset_name}"

prefetch_json="$(nix store prefetch-file --json --hash-type sha256 "$asset_url")"
hash="$(PREFETCH_JSON="$prefetch_json" python3 - <<'PY'
import json
import os

prefetch = json.loads(os.environ["PREFETCH_JSON"])
hash_value = prefetch.get("hash")
if not hash_value:
    raise SystemExit("prefetch response did not contain hash")
print(hash_value)
PY
)"

VERSION="$version" HASH="$hash" python3 - <<'PY'
from pathlib import Path
import os
import re

path = Path("package.nix")
text = path.read_text()
text, version_count = re.subn(
    r'(version = ")[^"]+(";)',
    rf'\g<1>{os.environ["VERSION"]}\2',
    text,
    count=1,
)
text, hash_count = re.subn(
    r'(hash = ")[^"]+(";)',
    rf'\g<1>{os.environ["HASH"]}\2',
    text,
    count=1,
)
if version_count != 1 or hash_count != 1:
    raise SystemExit("failed to update exactly one version and one hash field")
path.write_text(text)
PY

printf 'Updated %s to version %s with hash %s\n' "$package_file" "$version" "$hash"
