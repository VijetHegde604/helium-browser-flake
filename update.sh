#!/usr/bin/env bash
set -euo pipefail

repo="imputnet/helium-linux"
package_file="${PACKAGE_NIX:-package.nix}"
api_url="https://api.github.com/repos/${repo}/releases/latest"

if [[ ! -f "$package_file" ]]; then
  echo "error: cannot find $package_file; run from the flake root or set PACKAGE_NIX" >&2
  exit 1
fi

if ! command -v python3 >/dev/null 2>&1; then
  echo "error: python3 is required to update package.nix" >&2
  exit 1
fi

if command -v curl >/dev/null 2>&1; then
  release_json="$(curl -fsSL -H 'Accept: application/vnd.github+json' "$api_url")"
elif command -v python3 >/dev/null 2>&1; then
  release_json="$(python3 - "$api_url" <<'PY'
import sys, urllib.request
req = urllib.request.Request(sys.argv[1], headers={"Accept": "application/vnd.github+json"})
with urllib.request.urlopen(req) as response:
    print(response.read().decode())
PY
)"
else
  echo "error: curl or python3 is required to query GitHub releases" >&2
  exit 1
fi

version="$(RELEASE_JSON="$release_json" python3 - <<'PY'
import json, os
print(json.loads(os.environ["RELEASE_JSON"])["tag_name"].lstrip("v"))
PY
)"

asset="helium-${version}-x86_64_linux.tar.xz"
url="https://github.com/${repo}/releases/download/${version}/${asset}"

if command -v nix >/dev/null 2>&1 && nix store prefetch-file --help >/dev/null 2>&1; then
  prefetch_json="$(nix store prefetch-file --json --hash-type sha256 "$url")"
  hash="$(PREFETCH_JSON="$prefetch_json" python3 - <<'PY'
import json, os
print(json.loads(os.environ["PREFETCH_JSON"])["hash"])
PY
)"
elif command -v nix-prefetch-url >/dev/null 2>&1 && command -v nix >/dev/null 2>&1; then
  raw_hash="$(nix-prefetch-url --type sha256 "$url")"
  hash="$(nix hash convert --hash-algo sha256 --to sri "$raw_hash")"
else
  echo "error: nix store prefetch-file or nix-prefetch-url plus nix is required" >&2
  exit 1
fi

python3 - "$package_file" "$version" "$hash" <<'PY'
from pathlib import Path
import re, sys
path = Path(sys.argv[1])
version = sys.argv[2]
hash_ = sys.argv[3]
text = path.read_text()
text = re.sub(r'version = "[^"]+";', f'version = "{version}";', text, count=1)
text = re.sub(r'hash = "sha256-[^"]+";', f'hash = "{hash_}";', text, count=1)
path.write_text(text)
PY

echo "Updated ${package_file} to Helium ${version} (${hash})"
