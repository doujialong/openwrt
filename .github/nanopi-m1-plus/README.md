# NanoPi M1 Plus build (OpenWrt 23.05)

本目录包含在 GitHub Actions 上为 **FriendlyARM NanoPi M1 Plus**（Allwinner H3）
构建 OpenWrt 23.05 基础固件所需的全部文件。

这份配置走的是 **"基础系统 + 插件所需的内核模块"** 路线：固件本身只带 LuCI
和常用诊断工具；OpenClash / AdGuardHome / MosDNS / SmartDNS 这些 Go 写的代理
/ DNS 插件在 23.05 的 Go 工具链（1.21）下会因为 `go.mod` 要求 Go ≥ 1.24 而
编不出来，所以不走 in-tree 编译，改成固件起来后用 `opkg install` 安装。
固件已经预埋了 `kmod-tun` / `kmod-*-tproxy` / `dnsmasq-full` 等插件会依赖
的内核模块。

## 文件说明

| 路径                                                                                                       | 作用                                                                     |
| ---------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------ |
| `target/linux/sunxi/patches-5.15/700-arm-dts-sun8i-h3-nanopi-m1-plus-fix-rgmii-phy-mode.patch`             | 内核 patch：把 `phy-mode` 从 `rgmii` 改成 `rgmii-id`，修复以太网不通信 |
| `.github/nanopi-m1-plus/config.seed`                                                                       | 精简版 `.config`，基础系统 + 插件会用到的内核模块                        |
| `.github/nanopi-m1-plus/feeds.extra.conf`                                                                  | 追加的第三方 feed（当前为空）                                            |
| `.github/nanopi-m1-plus/build-local.sh`                                                                    | Linux 主机本地构建脚本                                                   |
| `.github/workflows/build-nanopi-m1-plus.yml`                                                               | GitHub Actions 工作流                                                    |

## 触发云端编译

1. 确认上述文件都已推到 `nanopi-m1-plus-23.05` 分支。
2. 打开仓库的 **Actions** 页，左侧选择 **Build NanoPi M1 Plus (OpenWrt 23.05 + OpenClash)**。
3. 点右上角 **Run workflow** → 分支选 `nanopi-m1-plus-23.05` → 再点绿色 **Run workflow**。
4. 首次编译预计 2–3 小时（工具链冷编译）。编译成功后：
   - 到 **Actions** 的这次 run 页面底部下载 `openwrt-nanopi-m1-plus` artifact，或
   - 到仓库 **Releases** 页面下载同名 tag 的 Release 附件。

## 烧录 SD 卡

下载 `openwrt-sunxi-cortexa7-friendlyarm_nanopi-m1-plus-squashfs-sdcard.img.gz`：

```bash
gunzip openwrt-sunxi-cortexa7-friendlyarm_nanopi-m1-plus-squashfs-sdcard.img.gz
# macOS: diskutil list, 找到你的 SD 卡设备 /dev/diskN
diskutil unmountDisk /dev/diskN
sudo dd if=openwrt-sunxi-cortexa7-friendlyarm_nanopi-m1-plus-squashfs-sdcard.img \
        of=/dev/rdiskN bs=4m status=progress
sync
```

或者用 Balena Etcher / Raspberry Pi Imager 图形界面烧录。

## 首次启动

- 把 SD 卡插到 NanoPi M1 Plus，网线接到路由器（或电脑）
- 默认 LAN IP：`192.168.1.1`
- 浏览器打开 `http://192.168.1.1`，用户名 `root`，首次登录**没有密码**
- 记得马上在 **System → Administration** 里设置 root 密码
- OpenClash 配置入口：**Services → OpenClash**

## 以太网修复说明

官方 OpenWrt 23.05 的 `sun8i-h3-nanopi-m1-plus.dts` 里写的是
`phy-mode = "rgmii"`，而板载 RTL8211E PHY 用的是 RGMII 接口。plain RGMII
模式下 MAC 和 PHY 都不注入时钟延迟，链路可以协商上（灯亮）但收发数据全部
CRC/帧错误——表现就是 "识别但无法通信"。

patch 把它改为 `phy-mode = "rgmii-id"`（Internal Delay），由 PHY 芯片在其
内部给 RX/TX 时钟各自加 ~2 ns 延迟，这也是 OrangePi Plus 2E、NanoPi K1 Plus
等同样用 RTL8211E + H3 的板子的做法。
