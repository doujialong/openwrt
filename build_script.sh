#!/bin/bash
set -e

# Update OpenWrt feeds
./scripts/feeds update -a
./scripts/feeds install -a

# Add packages
echo "Installing packages..."
# Add the specified packages
./scripts/feeds install openclash smartdns adguardhome mosdns adblock

# Compile the OpenWrt image
make -j$(nproc)