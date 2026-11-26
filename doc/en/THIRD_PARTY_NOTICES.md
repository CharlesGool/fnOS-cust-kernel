---
name: project-third-party-notices-en
description: Third-party attribution and compliance notices
metadata:
  version: "1.0.0"
  lang: "en"
---

# Third-Party Notices

## Multi-language

[简体中文](../THIRD_PARTY_NOTICES.md) | **English** | [Español](../es/THIRD_PARTY_NOTICES.md)

## Documentation

- Project overview: [README](README.md)

- Design rationale: [DESIGN](DESIGN.md)

- Project status: [LOG](LOG.md)
- Historical records: [HISTORY](HISTORY.md)
- Version changelog: [CHANGELOG](CHANGELOG.md)

- Third-party notices: [THIRD_PARTY_NOTICES](THIRD_PARTY_NOTICES.md)

## Third-Party Notices

### Components

This repository contains patches for the components below; the kernel package in the GitHub Release contains binaries built from them. The commit hashes of the external modules are in [`MANIFEST.tsv`](../../patches/extmod/MANIFEST.tsv).

| Component | Version or hash | Upstream URL | License | Usage | Copyright holder | Release obligations | Verified on |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Linux | 6.18.65 | https://www.kernel.org/ | GPL-2.0 WITH Linux-syscall-note | Patched and built into vmlinuz and in-tree modules | Linux kernel contributors | Include the license, provide the complete source | 2026-11-26 |
| OpenZFS | 2.4.1 | https://github.com/openzfs/zfs | CDDL-1.0 | Patched and built into spl.ko, zfs.ko | OpenZFS contributors, Oracle, et al. | Include the license, provide the source | 2026-11-26 |
| r8101 | 1.039.00 | https://github.com/openwrt/rtl8101 | GPL-2.0 | Patched and built as an external module, includes ImmortalWrt patches | Realtek Semiconductor Corp. | Include the license, provide the complete source | 2026-11-26 |
| r8125 | 9.018.00 | https://github.com/openwrt/rtl8125 | GPL-2.0 | Same as above, includes ImmortalWrt patches | Realtek Semiconductor Corp. | Same as above | 2026-11-26 |
| r8126 | 10.016.00 | https://github.com/openwrt/rtl8126 | GPL-2.0 | Same as above, includes ImmortalWrt patches | Realtek Semiconductor Corp. | Same as above | 2026-11-26 |
| r8127 | 11.015.00 | https://github.com/openwrt/rtl8127 | GPL-2.0 | Same as above, includes ImmortalWrt patches | Realtek Semiconductor Corp. | Same as above | 2026-11-26 |
| r8168 | 8.056.02 | https://github.com/openwrt/rtl8168 | GPL-2.0 | Same as above, includes ImmortalWrt patches | Realtek Semiconductor Corp. | Same as above | 2026-11-26 |
| r8169 | 6.022.00 | https://github.com/smooker/realtek | GPL-2.0 | Patched and built as an external module | Realtek Semiconductor Corp. | Same as above | 2026-11-26 |
| r8152 | 2.22.1 | https://github.com/wget/realtek-r8152-linux | GPL-2.0 | Patched and built as an external module | Realtek Semiconductor Corp. | Same as above | 2026-11-26 |
| it87 | 48b87a397de8 | https://github.com/frankcrawford/it87 | GPL-2.0 | Built as an external module | it87 contributors | Same as above | 2026-11-26 |
| nft-fullcone | 07d93b626ce5 | https://github.com/fullcone-nat-nftables/nft-fullcone | GPL-2.0 | Patched and built as an external module | nft-fullcone contributors | Same as above | 2026-11-26 |
| NVIDIA MFT kernel-mft-dkms | 4.35.0-159 | https://content.mellanox.com/MFT/mft-4.35.0-159-x86_64-deb.tgz | GPL-2.0 or BSD (dual license) | Built as external modules mst_pci, mst_pciconf | NVIDIA Corporation | Same as above | 2026-11-26 |
| NVIDIA open-gpu-kernel-modules | 610.57.04 | https://github.com/NVIDIA/open-gpu-kernel-modules | MIT or GPL-2.0 (dual license) | Built as external modules | NVIDIA Corporation | Include the license, provide the source | 2026-11-26 |
| NVIDIA Linux driver kernel modules | 580.142 | https://download.nvidia.com/XFree86/Linux-x86_64/580.142/NVIDIA-Linux-x86_64-580.142.run | NVIDIA Software License Agreement (proprietary) | The kernel interface layer is built and linked with the binary object files provided by NVIDIA into external modules | NVIDIA Corporation | The binaries must not be modified, and the license agreement must be provided to every recipient; see Compliance Review | 2026-11-26 |
| rtw88 | a56bcd26e770 | https://github.com/lwfinger/rtw88 | GPL-2.0 or BSD-3-Clause (dual license) | Built as an external module | Realtek, rtw88 contributors | Include the license, provide the complete source | 2026-11-26 |
| rtw89 | 8b2b78deb357 | https://github.com/morrownr/rtw89 | GPL-2.0 or BSD-3-Clause (dual license) | Built as an external module | Realtek, rtw89 contributors | Same as above | 2026-11-26 |
| aic8800 | d5e11d4b9166 | https://github.com/radxa-pkg/aic8800 | GPL (the repository includes a GPL-3.0 text; the module declares GPL) | Patched and built as an external module | AICSemi, RivieraWaves | Same as above | 2026-11-26 |
| rtl8852bs | c895ffa95355 | https://github.com/armbian/wifi-rtl8852bs | GPL-2.0 | Patched and built as an external module | Realtek Semiconductor Corp. | Same as above | 2026-11-26 |
| rtl8733bu | 9f19065a24dd | https://github.com/briansune/rtl8733bu-vendor-5.15.12-123 | GPL-2.0 | Built as an external module | Realtek Semiconductor Corp. | Same as above | 2026-11-26 |
| amdxdna | 88dda53eee33 | https://github.com/amd/xdna-driver | GPL-2.0 | Patched and built as an external module | Advanced Micro Devices, Inc. | Same as above | 2026-11-26 |
| seekwave swt6621s | d78c90e61ffc | https://github.com/retro98boy/swt6621s-archived | GPL-2.0 | Patched and built as an external module | SeekWave Technology, retro98boy | Same as above | 2026-11-26 |
| drm-cx4 | 26.00.45 | https://github.com/AOSC-Tracking/cx4-kernel-dkms | GPL-2.0 | Patched and built as an external module | Shanghai Zhaoxin Semiconductor Co., Ltd. | Same as above | 2026-11-26 |

### License Texts

| License | Text |
| --- | --- |
| GPL-2.0 | [LICENSE](../../LICENSE) |
| Linux kernel licensing notes, GPL-2.0, Linux-syscall-note | [third_party/linux/](../../third_party/linux/COPYING) |
| CDDL-1.0 | [third_party/openzfs/LICENSE](../../third_party/openzfs/LICENSE), [NOTICE](../../third_party/openzfs/NOTICE) |
| GPL-3.0 shipped with aic8800 | [third_party/aic8800/LICENSE](../../third_party/aic8800/LICENSE) |
| NVIDIA open-gpu-kernel-modules (MIT) | [third_party/nvidia-open-gpu-kernel-modules/COPYING](../../third_party/nvidia-open-gpu-kernel-modules/COPYING) |
| NVIDIA Software License Agreement | [third_party/nvidia-linux-driver/LICENSE](../../third_party/nvidia-linux-driver/LICENSE), also provided as the Release asset `NVIDIA-LICENSE.txt` |

Dual-licensed BSD components are used under GPL-2.0. Other license files in the source of each component are provided with the source archives.

### Source Code Offer

Each GitHub Release includes the complete source corresponding to the kernel package:

- Kernel: `linux-<upstream version>.tar.xz` and its signature `.tar.sign`, plus `patches/kernel/` and `config/` of this repository at the same tag.
- ZFS: `zfs-<version>.tar.gz` and its signature `.asc`, plus `patches/zfs/`.
- External modules: `fnos-cust-kernel-<version>-extmod-src.tar.xz`, the complete source trees of the commits listed in `MANIFEST.tsv` (already including the changes in `patches/extmod/`). The v6.18.65-3 archive also contains the `kernel/` directory of the NVIDIA proprietary driver; later versions do not, and users download it from the NVIDIA address in the table above, verified and extracted by `scripts/ck.sh fetch-nvidia`.
- Build scripts: `scripts/` of this repository.

### Compliance Review

- GPL components: the binaries of the kernel and the GPL external modules are distributed in the package, and the corresponding source is provided as described in the previous section.
- OpenZFS (CDDL-1.0) is distributed as the separate modules spl.ko and zfs.ko, in the same package as the GPL kernel. Whether CDDL and GPL may be combined and distributed this way is disputed, and this project has not obtained legal advice.
- NVIDIA proprietary modules: section 1.1(d) of the license agreement permits distribution with an open-source kernel, provided the binary files are unmodified and the license agreement is provided to every recipient. `nvidia.ko` and the other modules in the package are linked from the kernel interface layer and NVIDIA's binary object files and processed with `strip --strip-debug`; this project could not determine whether they still count as "unmodified". The license agreement is provided through the Release asset `NVIDIA-LICENSE.txt` and this repository, but not inside the deb package. Users with concerns should seek professional advice.
- Decision records: see [Decisions in LOG](LOG.md#decisions).
