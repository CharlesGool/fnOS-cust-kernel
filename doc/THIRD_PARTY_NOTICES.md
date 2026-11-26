---
name: project-third-party-notices
description: 第三方署名与合规声明
metadata:
  version: "1.0.0"
  lang: "zh-CN"
---

# 第三方声明

## 多语言

**简体中文** | [English](en/THIRD_PARTY_NOTICES.md) | [Español](es/THIRD_PARTY_NOTICES.md)

## 文档

- 项目概览: [README](../README.md)

- 设计思路: [DESIGN](DESIGN.md)

- 项目状态: [LOG](LOG.md)
- 历史记录: [HISTORY](HISTORY.md)
- 变更日志: [CHANGELOG](CHANGELOG.md)

- 第三方声明: [THIRD_PARTY_NOTICES](THIRD_PARTY_NOTICES.md)

## 第三方声明

### 组件清单

本仓库包含下列组件的补丁; GitHub Release 的内核包包含由它们编译出的二进制. 外置模块的提交哈希见 [`MANIFEST.tsv`](../patches/extmod/MANIFEST.tsv).

| 组件名称 | 版本或哈希 | 上游地址 | 许可证类型 | 使用方式 | 版权归属 | 发布合规义务 | 核验日期 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Linux | 6.18.65 | https://www.kernel.org/ | GPL-2.0 WITH Linux-syscall-note | 打补丁后编译为 vmlinuz 和树内模块 | Linux 内核贡献者 | 附许可证, 提供完整源码 | 2026-11-26 |
| OpenZFS | 2.4.1 | https://github.com/openzfs/zfs | CDDL-1.0 | 打补丁后编译为 spl.ko, zfs.ko | OpenZFS 贡献者, Oracle 等 | 附许可证, 提供源码 | 2026-11-26 |
| r8101 | 1.039.00 | https://github.com/openwrt/rtl8101 | GPL-2.0 | 打补丁后编译为外置模块, 含 ImmortalWrt 补丁 | Realtek Semiconductor Corp. | 附许可证, 提供完整源码 | 2026-11-26 |
| r8125 | 9.018.00 | https://github.com/openwrt/rtl8125 | GPL-2.0 | 同上, 含 ImmortalWrt 补丁 | Realtek Semiconductor Corp. | 同上 | 2026-11-26 |
| r8126 | 10.016.00 | https://github.com/openwrt/rtl8126 | GPL-2.0 | 同上, 含 ImmortalWrt 补丁 | Realtek Semiconductor Corp. | 同上 | 2026-11-26 |
| r8127 | 11.015.00 | https://github.com/openwrt/rtl8127 | GPL-2.0 | 同上, 含 ImmortalWrt 补丁 | Realtek Semiconductor Corp. | 同上 | 2026-11-26 |
| r8168 | 8.056.02 | https://github.com/openwrt/rtl8168 | GPL-2.0 | 同上, 含 ImmortalWrt 补丁 | Realtek Semiconductor Corp. | 同上 | 2026-11-26 |
| r8169 | 6.022.00 | https://github.com/smooker/realtek | GPL-2.0 | 打补丁后编译为外置模块 | Realtek Semiconductor Corp. | 同上 | 2026-11-26 |
| r8152 | 2.22.1 | https://github.com/wget/realtek-r8152-linux | GPL-2.0 | 打补丁后编译为外置模块 | Realtek Semiconductor Corp. | 同上 | 2026-11-26 |
| it87 | 48b87a397de8 | https://github.com/frankcrawford/it87 | GPL-2.0 | 编译为外置模块 | it87 贡献者 | 同上 | 2026-11-26 |
| nft-fullcone | 07d93b626ce5 | https://github.com/fullcone-nat-nftables/nft-fullcone | GPL-2.0 | 打补丁后编译为外置模块 | nft-fullcone 贡献者 | 同上 | 2026-11-26 |
| NVIDIA MFT kernel-mft-dkms | 4.35.0-159 | https://content.mellanox.com/MFT/mft-4.35.0-159-x86_64-deb.tgz | GPL-2.0 或 BSD(双许可) | 编译为外置模块 mst_pci, mst_pciconf | NVIDIA Corporation | 同上 | 2026-11-26 |
| NVIDIA open-gpu-kernel-modules | 610.57.04 | https://github.com/NVIDIA/open-gpu-kernel-modules | MIT 或 GPL-2.0(双许可) | 编译为外置模块 | NVIDIA Corporation | 附许可证, 提供源码 | 2026-11-26 |
| NVIDIA Linux 驱动内核模块 | 580.142 | https://download.nvidia.com/XFree86/Linux-x86_64/580.142/NVIDIA-Linux-x86_64-580.142.run | NVIDIA 软件许可协议(专有) | 内核接口层编译后与 NVIDIA 提供的二进制目标文件链接为外置模块 | NVIDIA Corporation | 二进制不得修改, 须向每个接收者提供许可协议, 见合规审查 | 2026-11-26 |
| rtw88 | a56bcd26e770 | https://github.com/lwfinger/rtw88 | GPL-2.0 或 BSD-3-Clause(双许可) | 编译为外置模块 | Realtek, rtw88 贡献者 | 附许可证, 提供完整源码 | 2026-11-26 |
| rtw89 | 8b2b78deb357 | https://github.com/morrownr/rtw89 | GPL-2.0 或 BSD-3-Clause(双许可) | 编译为外置模块 | Realtek, rtw89 贡献者 | 同上 | 2026-11-26 |
| aic8800 | d5e11d4b9166 | https://github.com/radxa-pkg/aic8800 | GPL(仓库附 GPL-3.0 文本, 模块声明为 GPL) | 打补丁后编译为外置模块 | AICSemi, RivieraWaves | 同上 | 2026-11-26 |
| rtl8852bs | c895ffa95355 | https://github.com/armbian/wifi-rtl8852bs | GPL-2.0 | 打补丁后编译为外置模块 | Realtek Semiconductor Corp. | 同上 | 2026-11-26 |
| rtl8733bu | 9f19065a24dd | https://github.com/briansune/rtl8733bu-vendor-5.15.12-123 | GPL-2.0 | 编译为外置模块 | Realtek Semiconductor Corp. | 同上 | 2026-11-26 |
| amdxdna | 88dda53eee33 | https://github.com/amd/xdna-driver | GPL-2.0 | 打补丁后编译为外置模块 | Advanced Micro Devices, Inc. | 同上 | 2026-11-26 |
| seekwave swt6621s | d78c90e61ffc | https://github.com/retro98boy/swt6621s-archived | GPL-2.0 | 打补丁后编译为外置模块 | SeekWave Technology, retro98boy | 同上 | 2026-11-26 |
| drm-cx4 | 26.00.45 | https://github.com/AOSC-Tracking/cx4-kernel-dkms | GPL-2.0 | 打补丁后编译为外置模块 | Shanghai Zhaoxin Semiconductor Co., Ltd. | 同上 | 2026-11-26 |

### 许可证文本

| 许可证 | 原文 |
| --- | --- |
| GPL-2.0 | [LICENSE](../LICENSE) |
| Linux 内核许可说明, GPL-2.0, Linux-syscall-note | [third_party/linux/](../third_party/linux/COPYING) |
| CDDL-1.0 | [third_party/openzfs/LICENSE](../third_party/openzfs/LICENSE), [NOTICE](../third_party/openzfs/NOTICE) |
| aic8800 附带的 GPL-3.0 | [third_party/aic8800/LICENSE](../third_party/aic8800/LICENSE) |
| NVIDIA open-gpu-kernel-modules(MIT) | [third_party/nvidia-open-gpu-kernel-modules/COPYING](../third_party/nvidia-open-gpu-kernel-modules/COPYING) |
| NVIDIA 软件许可协议 | [third_party/nvidia-linux-driver/LICENSE](../third_party/nvidia-linux-driver/LICENSE), 也作为 Release 资产 `NVIDIA-LICENSE.txt` 提供 |

BSD 双许可组件按 GPL-2.0 使用. 各组件源码中的其他许可证文件随源码包提供.

### 源代码提供

每个 GitHub Release 附带内核包对应的完整源码:

- 内核: `linux-<上游版本>.tar.xz` 和签名 `.tar.sign`, 加本仓库同一标签下的 `patches/kernel/` 和 `config/`.
- ZFS: `zfs-<版本>.tar.gz` 和签名 `.asc`, 加 `patches/zfs/`.
- 外置模块: `fnos-cust-kernel-<版本>-extmod-src.tar.xz`, 是 `MANIFEST.tsv` 所列各提交的完整源码树(已包含 `patches/extmod/` 的改动). v6.18.65-3 的源码包还含 NVIDIA 闭源驱动的 `kernel/` 目录; 之后的版本不含, 由使用者从上表的 NVIDIA 地址下载, `scripts/ck.sh fetch-nvidia` 校验并解出.
- 构建脚本: 本仓库 `scripts/`.

### 合规审查

- GPL 组件: 内核, GPL 外置模块的二进制随包分发, 对应源码按上节提供.
- OpenZFS(CDDL-1.0)以独立模块 spl.ko, zfs.ko 分发, 与 GPL 内核在同一个包中. CDDL 与 GPL 能否这样组合分发存在争议, 本项目未取得法律意见.
- NVIDIA 闭源模块: 许可协议第 1.1 条 d 项允许随开源内核分发, 条件是二进制文件未经修改且向每个接收者提供许可协议. 包内的 `nvidia.ko` 等由内核接口层与 NVIDIA 的二进制目标文件链接而成, 并经过 `strip --strip-debug`, 是否仍属于"未经修改", 本项目无法确定. 许可协议通过 Release 资产 `NVIDIA-LICENSE.txt` 和本仓库提供, 但不在 deb 包内. 使用者如有疑虑应寻求专业意见.
- 决定记录见 [LOG 的决策](LOG.md#决策).
