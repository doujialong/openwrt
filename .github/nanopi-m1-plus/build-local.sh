#!/usr/bin/env bash
# Local build helper for NanoPi M1 Plus (OpenWrt 23.05).
#
# Usage (from the top-level openwrt/ directory on a Linux host):
#
#   ./.github/nanopi-m1-plus/build-local.sh
#
# Requires a clean OpenWrt 23.05 checkout and the standard Debian/Ubuntu build
# deps (see the "Install build dependencies" step in
# .github/workflows/build-nanopi-m1-plus.yml).

set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
root="$(cd "$here/../.." && pwd)"
cd "$root"

if [ ! -f feeds.conf.default ] || [ ! -d target/linux/sunxi ]; then
    echo "error: this does not look like an OpenWrt source tree (run from the openwrt/ root)" >&2
    exit 1
fi

echo "[1/6] appending extra feeds"
if ! grep -q '^src-git small8' feeds.conf.default; then
    cat "$here/feeds.extra.conf" >> feeds.conf.default
fi

echo "[2/6] updating and installing feeds"
./scripts/feeds update -a
./scripts/feeds install -a

echo "[3/6] generating .config from seed"
cp "$here/config.seed" .config
make defconfig

echo "[4/6] downloading package sources"
make download -j8 V=s || true
find dl -size -1024c -type f -delete || true
make download -j1 V=s

echo "[5/6] building tools + toolchain"
make tools/install -j"$(nproc)" V=s || make tools/install -j1 V=s
make toolchain/install -j"$(nproc)" V=s || make toolchain/install -j1 V=s

echo "[6/6] building OpenWrt image"
make -j"$(nproc)" V=s || make -j1 V=s

echo
echo "build complete. artifacts:"
ls -lh bin/targets/sunxi/cortexa7/openwrt-sunxi-cortexa7-friendlyarm_nanopi-m1-plus-* || true
