#!/usr/bin/env bash
# Build ImmortalWRT 24.10 firmware for FriendlyARM NanoPi M1 Plus locally.
# Only tested on Ubuntu 22.04 / 24.04 (and the Debian equivalents).
#
# Usage:
#   cd /path/to/immortalwrt-source
#   ./.github/nanopi-m1-plus/build-local.sh
set -euo pipefail

if [ ! -f feeds.conf.default ] || [ ! -f .github/nanopi-m1-plus/config.seed ]; then
	echo "Run this script from the root of the immortalwrt-24.10-nanopi-m1-plus branch." >&2
	exit 1
fi

echo "[*] Installing host dependencies (sudo required)..."
sudo apt-get update
sudo apt-get install -y \
	build-essential clang flex bison g++ gawk gcc-multilib g++-multilib \
	gettext git libncurses5-dev libssl-dev python3-distutils rsync \
	unzip zlib1g-dev file wget libfuse-dev libelf-dev ecj fastjar java-propose-classpath \
	libncursesw5-dev libpython3-dev python3 python3-pip python3-ply python3-pyelftools \
	python3-setuptools swig time xsltproc zstd

echo "[*] Preparing feeds..."
cp feeds.conf.default feeds.conf
./scripts/feeds update -a
./scripts/feeds install -a

echo "[*] Applying seed .config..."
cp .github/nanopi-m1-plus/config.seed .config
make defconfig

echo "[*] Downloading sources..."
for i in 1 2 3; do
	if make download -j"$(nproc)"; then
		break
	fi
	echo "Download attempt $i failed, retrying..."
	sleep 10
done

echo "[*] Compiling (this takes 1-3 hours)..."
if ! make -j"$(nproc)"; then
	echo "Parallel build failed, retrying with -j1 V=s for a readable log..."
	make -j1 V=s
fi

echo
echo "[*] Build finished.  Artifacts:"
ls -lh bin/targets/sunxi/cortexa7/*nanopi-m1-plus* 2>/dev/null || true
