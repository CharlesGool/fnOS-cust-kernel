---
name: project-changelog-en
description: Changelog
metadata:
  version: "1.0.0"
  lang: "en"
---

# Changelog

## Multi-language

[简体中文](../CHANGELOG.md) | **English** | [Español](../es/CHANGELOG.md)

## Documentation

- Project overview: [README](README.md)

- Design rationale: [DESIGN](DESIGN.md)

- Project status: [LOG](LOG.md)
- Historical records: [HISTORY](HISTORY.md)
- Version changelog: [CHANGELOG](CHANGELOG.md)

- Third-party notices: [THIRD_PARTY_NOTICES](THIRD_PARTY_NOTICES.md)

## Changelog

### v6.18.65-3 (2026-11-26)

First public release. Kernel package `linux-image-6.18.65.c1186-trim_6.18.65-3_amd64.deb`, sha256 `8137206846024a173b28bd40c99bbfed345c3ae402915918bc99b1b4f94c3af9`.

#### Added

- Official Linux 6.18.65 plus 110 patches, reimplementing the private features of the fnOS 1.2.1000 kernel: trimacl permissions, trim system calls, recycle bin, trimafs2, event reporting, md DFR and llbitmap, recvfile, bonding mixed-speed support, and network card and libata changes; btrfs is a port of upstream 7.0.9.
- OpenZFS 2.4.1 plus 8 patches (trimacl, recvfile).
- External modules, with the same layout as fnOS: Realtek vendor network drivers r8101, r8125, r8126, r8127, r8152, r8168, r8169, it87, nft_fullcone, mft, NVIDIA open 610.57.04 and proprietary 580.142, rtw88, rtw89, aic8800, rtl8852bs, rtl8733bu, amdxdna, seekwave, drm-cx4.
- Scripts to build from upstream tarballs and patches, package, compare, and test.

#### Fixed

- NFS: `nfsd_permission` on trimacl volumes also checks write and execute permissions; the original fnOS kernel only checked read.
- NFS: `fh_getattr` reports 0777 only for trimacl files, and reports the real permissions for ordinary file systems.
- trimafs2: a forged handle of a non-directory lower layer can no longer open files outside the bridge directory.
- trimafs2: only the internal second-level `nfs` directory of the upper layer counts as an NFS share path; a user-created directory with the same name does not.
- The exported symbols of the aic8800 USB version had the same names as those of the SDIO version, which caused `aic8800DC_fdrv` to fail to load.
- Unloading `skw_usb_lite` of seekwave without hardware caused an oops.

Verification: on the KVM test machine (stock fnOS 1.2.1000), boot, storage space, permissions, SMB, NFS, recycle bin, md degradation, and DFR matched the stock kernel, and loading and unloading 90 external modules produced no Oops. Network cards, bonding, wireless, and NVIDIA were not tested on real hardware.
