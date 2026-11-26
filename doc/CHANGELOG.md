---
name: project-changelog
description: 变更日志
metadata:
  version: "1.0.0"
  lang: "zh-CN"
---

# 变更日志

## 多语言

**简体中文** | [English](en/CHANGELOG.md) | [Español](es/CHANGELOG.md)

## 文档

- 项目概览: [README](../README.md)

- 设计思路: [DESIGN](DESIGN.md)

- 项目状态: [LOG](LOG.md)
- 历史记录: [HISTORY](HISTORY.md)
- 变更日志: [CHANGELOG](CHANGELOG.md)

- 第三方声明: [THIRD_PARTY_NOTICES](THIRD_PARTY_NOTICES.md)

## 变更日志

### v6.18.65-3 (2026-11-26)

首个公开版本. 内核包 `linux-image-6.18.65.c1186-trim_6.18.65-3_amd64.deb`, sha256 `8137206846024a173b28bd40c99bbfed345c3ae402915918bc99b1b4f94c3af9`.

#### 新增

- 官方 Linux 6.18.65 加 110 个补丁, 还原飞牛 fnOS 1.2.1000 内核的私有功能: trimacl 权限, trim 系统调用, 回收站, trimafs2, 事件上报, md DFR 和 llbitmap, recvfile, bonding 混合速率, 网卡和 libata 改动; btrfs 为上游 7.0.9 移植.
- OpenZFS 2.4.1 加 8 个补丁(trimacl, recvfile).
- 外置模块, 布局与飞牛一致: Realtek 厂商网卡驱动 r8101, r8125, r8126, r8127, r8152, r8168, r8169, it87, nft_fullcone, mft, NVIDIA 开源 610.57.04 和闭源 580.142, rtw88, rtw89, aic8800, rtl8852bs, rtl8733bu, amdxdna, seekwave, drm-cx4.
- 从上游源码包和补丁构建, 打包, 比较和测试的脚本.

#### 修复

- NFS: trimacl 卷上 `nfsd_permission` 也检查写和执行权限; 飞牛原版只检查读.
- NFS: `fh_getattr` 只对 trimacl 文件报 0777, 普通文件系统报真实权限.
- trimafs2: 伪造的非目录下层句柄不能打开桥目录之外的文件.
- trimafs2: 只有上层内部的第二级 `nfs` 目录算 NFS 共享路径, 用户自建的同名目录不算.
- aic8800 USB 版导出符号与 SDIO 版重名导致 `aic8800DC_fdrv` 加载失败.
- seekwave 在没有硬件时卸载 `skw_usb_lite` 导致 oops.

验证: KVM 测试机(原版 fnOS 1.2.1000)上开机, 存储空间, 权限, SMB, NFS, 回收站, md 降级和 DFR 与原装内核对比一致, 90 个外置模块加载和卸载无 Oops. 网卡, bonding, 无线, NVIDIA 未在真机上测试.
