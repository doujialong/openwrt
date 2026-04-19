# NanoPi M1 Plus — ImmortalWRT 24.10 build

This branch (`immortalwrt-24.10-nanopi-m1-plus`) customises the
[ImmortalWRT 24.10](https://github.com/immortalwrt/immortalwrt/tree/openwrt-24.10)
tree with:

- A kernel 6.6 device-tree patch that switches the NanoPi M1 Plus EMAC
  to **`rgmii-id`**, which fixes the *"link LED on but zero packets flow"*
  Ethernet bug on the Allwinner H3 + RTL8211E combo.
- A pre-canned `.config` (`.github/nanopi-m1-plus/config.seed`) that
  bakes in LuCI + Chinese translations + OpenClash + SmartDNS + MosDNS +
  AdGuard Home + adblock-fast.
- A GitHub Actions workflow that builds the firmware in the cloud and
  publishes a GitHub Release.

## Why ImmortalWRT 24.10 rather than upstream OpenWrt 23.05?

OpenWrt 23.05 ships Go 1.21, and recent versions of MosDNS need Go
≥ 1.24. The ImmortalWRT 24.10 tree ships Go 1.23 **and** pins
`mosdns` at 5.3.3, `adguardhome` at 0.107.57 (which declares
`go 1.23.6`) — so everything compiles in-tree without toolchain
hacking. `luci-app-openclash` is pure Lua/shell, it doesn't require
Go at all; the `clash` binary is downloaded by OpenClash itself on
first launch.

## How to trigger a cloud build

1. Push any change that touches one of the paths the workflow is
   watching:
   - `.github/workflows/build-nanopi-m1-plus.yml`
   - `.github/nanopi-m1-plus/**`
   - `target/linux/sunxi/patches-6.6/**`
2. …or go to the **Actions** tab on GitHub, pick
   *Build ImmortalWRT 24.10 for NanoPi M1 Plus*, and click
   **Run workflow** on the `immortalwrt-24.10-nanopi-m1-plus` branch.
3. Build time is roughly 2–3 hours on a fresh GitHub runner (first
   run has to build the full toolchain).
4. When it finishes you'll find the firmware both as an Actions
   artifact and as a GitHub Release tagged
   `nanopi-m1-plus-immortal-YYYY.MM.DD-HHMM`.

## How to flash

The firmware file you want is:

```
immortalwrt-*-sunxi-cortexa7-friendlyarm_nanopi-m1-plus-squashfs-sdcard.img.gz
```

1. Decompress it (`gunzip` or 7-Zip).
2. Burn the `.img` onto a ≥ 4 GB SD card with
   [balenaEtcher](https://www.balena.io/etcher) or `dd`.
3. Put the SD card in the NanoPi M1 Plus and power it up.

## First boot

| Item | Default |
|---|---|
| LAN IP | `192.168.1.1` |
| LuCI URL | <http://192.168.1.1> |
| Username | `root` |
| Password | *(blank — set one immediately)* |

Plug the Ethernet port into a free LAN port on your existing
router, let the NanoPi get Internet that way for the first boot, and
then configure OpenClash / AdGuard Home / etc. via LuCI.

## Build locally instead

If you have an Ubuntu 22.04/24.04 box (or WSL) handy:

```bash
git clone -b immortalwrt-24.10-nanopi-m1-plus https://github.com/doujialong/openwrt.git
cd openwrt
./.github/nanopi-m1-plus/build-local.sh
```

The script installs the build dependencies, syncs feeds, applies the
seed `.config`, and kicks off `make -j$(nproc)`. Expect 1–3 hours.
