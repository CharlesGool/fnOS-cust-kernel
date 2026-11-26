---
name: project-design
description: 项目架构与设计约束
metadata:
  version: "1.0.0"
  lang: "zh-CN"
---

# fnOS-cust-kernel — 设计

## 多语言

**简体中文** | [English](en/DESIGN.md) | [Español](es/DESIGN.md)

## 文档

- 项目概览: [README](../README.md)

- 设计思路: [DESIGN](DESIGN.md)

- 项目状态: [LOG](LOG.md)
- 历史记录: [HISTORY](HISTORY.md)
- 变更日志: [CHANGELOG](CHANGELOG.md)

- 第三方声明: [THIRD_PARTY_NOTICES](THIRD_PARTY_NOTICES.md)

## 设计目标

- [x] 用官方 6.18 LTS 加补丁替换 fnOS 1.2.1000 的原装内核, 飞牛的存储, 权限, 回收站, 共享功能行为不变.
- [x] 飞牛私有改动反推成 C 源码, 在官方 6.18.18 上用同一工具链重编, 逐函数比对二进制确认一致后再移植.
- [x] 从上游源码包和 `patches/` 重建出等价的包.
- [x] 只维护一个内核. 6.18.18 的还原树只作比对参照, 不出包.
- [ ] 还原 i915, xe 中 4 组疑似私有改动.
- [ ] 补齐飞牛有而本项目缺少的外置模块 `houmo-drv-xh2`(没有源码).
- [ ] 网卡, bonding, 无线, NVIDIA 在真机上验证.
- 非目标: 跟进飞牛官方的新版本和新内核.

## 架构

构建流程:

```text
linux-<上游>.tar.xz + patches/kernel ─> 内核树 ─> bzImage, 树内模块 ─┐
zfs-<版本>.tar.gz + patches/zfs ─────> ZFS 树 ─> spl.ko, zfs.ko ─────┼─> pkg ─> linux-image-<版本串>_<版本>_amd64.deb
extsrc/<目录> (= MANIFEST.tsv 的提交) ─────> 外置模块 ─────────────┘
```

- `scripts/ck.sh` 在主机上运行: 建编译容器, 下载和校验源码, 把仓库同步到工作区, 再在编译容器里运行 `scripts/kwork/` 的各步骤.
- 源码来源, 都在依赖目录里:

  | 源码 | 来源 | 校验 |
  | --- | --- | --- |
  | 内核 | kernel.org 源码包 | kernel.org 签名的 `sha256sums.asc` |
  | ZFS | OpenZFS 的 GitHub Release | `config/versions.conf` 的 sha256 |
  | 外置模块 | 维护者: 各目录的 Git 仓库; 其他人: 本项目 Release 的外置模块源码包, 解出后提交号记在 `.ck-rev` | 源码包 sha256; 构建前核对提交号与 `MANIFEST.tsv` 一致 |
  | NVIDIA 闭源驱动 | 使用者从 NVIDIA 下载 `.run`, 只解出 `kernel/` | `.run` 的 sha256 和解出目录的 Git tree 哈希 |
  | pahole | `git.kernel.org` 的 v1.31 标签 | 提交哈希 |

- 工作区在依赖目录的 `ck/` 下, 不在仓库里: `linux/`, `zfs/`(Git 树), `zfs-build/`, `extbuild/`, `extmod/`, `pkg/`, `out/`, `logs/`.

顶层目录:

| 目录 | 职责 |
| --- | --- |
| `config/` | 内核配置 `config-<版本串>`, 版本号 `VERSION`, `versions.conf`: 版本串后缀, 各依赖的版本和 sha256 |
| `patches/` | 源码的唯一来源: `kernel/`(含 `series`), `zfs/`, `extmod/<目录>/` 和记录各外置模块上游基线与 HEAD 的 `MANIFEST.tsv` |
| `scripts/` | 主机端入口 `ck.sh`, 包比较 `cmpdeb.sh` 和 `kocmp.py`, 容器内步骤 `kwork/`(含建容器 `container.sh`, 解 NVIDIA 驱动 `nvidia-prop.sh`) |
| `test/` | KVM 回归测试脚本 `kvm/` |
| `third_party/` | 发布包中第三方组件的许可证原文, 每个来源一个子目录 |
| `doc/` | 项目文档 |
| `releases/` | 构建输出, 被 Git 忽略: 各版本的包, 源码包, `SHA256SUMS`, `BUILDINFO` |

内核补丁(`patches/kernel/`)按来源分为:

| 部分 | 内容 |
| --- | --- |
| event_report, libata | sysdiag 用的 netlink 事件上报; ATA ACPI 电源和 `manage_restart`(移植自 6.19) |
| trimacl | `inode` 新字段, `inode_operations` 12 个回调, 11 个 trim 系统调用, 回收站, ext4/btrfs/fuse/nfsd 适配 |
| trimafs2 | 飞牛的桥接文件系统, 从零写出 |
| md | DFR(降级免重建恢复), resync hint, llbitmap |
| btrfs | 上游 7.0.9 整体移植, 加 7.0.10 修复和飞牛私有改动 |
| 其他 | recvfile 系统调用, bonding 混合速率, r8169/motorcomm 网卡, x86, ACPI, PCI, DRM fbdev 小改动 |
| 安全修复 | 本项目新增的 4 个 NFS 修复 |

## 设计约束

1. 内核版本串后缀固定为 `.c1186-trim`(`config/versions.conf`), 飞牛用户态按它找模块目录.
2. 编译器和 pahole 版本与飞牛原版一致: `gcc (Debian 12.2.0-14+deb12u1) 12.2.0`, pahole v1.31. 换版本会使函数级比对失去参照.
3. 包内布局与飞牛一致:
   - 外置模块不压缩, `strip --strip-debug`;
   - `updates/trim/<名>/*.ko` 放在 `/lib/modules/<版本串>/`, `modules_trim/<名>/*.ko` 放在 `/usr/lib/modules_trim/<版本串>/`;
   - `updates/trim/alternatives` 是指向 `/usr/lib/modules_trim/<版本串>/alternatives` 的绝对链接, `alternatives/nvidia-gpu` 默认指向闭源版;
   - 树内模块 xz 压缩并签名.
4. 外置模块在飞牛的构建路径 `/var/jenkins_home/workspace/kernel-build/...` 下编译, 使 `__FILE__` 字符串与飞牛一致.
5. 每次全新编译自动生成随机的模块签名密钥(`CONFIG_MODULE_SIG_ALL=y`, 未开 `MODULE_SIG_FORCE`). 不同构建的模块签名不同, 不要混装.
6. btrfs 跟上游 7.0.x 和主线, 不跟 6.18.y.
7. 改动 trimacl, nfsd, trimafs2 时, 不能削弱 4 个 NFS 安全修复的检查: `nfsd_permission` 对 trimacl 查写和执行, `fh_getattr` 只对 trimacl 报 0777, trimafs2 句柄必须在桥根下, 只有内部的第二级 `nfs` 目录算 NFS 路径.
8. 不要在飞牛存储卷上解包或构建: trimacl 会把解出文件的权限改掉.
9. 本项目不分发 NVIDIA 闭源驱动的源码: 外置模块源码包不含 `nvidia-prop-work`, 由使用者用 `ck.sh fetch-nvidia` 下载. 没有它时构建必须仍能完成, 只少 `nvidia-gpu-proprietary`.
