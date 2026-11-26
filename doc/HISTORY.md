---
name: project-history
description: 历史记录
metadata:
  version: "1.0.0"
  lang: "zh-CN"
---

# 历史记录

## 多语言

**简体中文** | [English](en/HISTORY.md) | [Español](es/HISTORY.md)

## 文档

- 项目概览: [README](../README.md)

- 设计思路: [DESIGN](DESIGN.md)

- 项目状态: [LOG](LOG.md)
- 历史记录: [HISTORY](HISTORY.md)
- 变更日志: [CHANGELOG](CHANGELOG.md)

- 第三方声明: [THIRD_PARTY_NOTICES](THIRD_PARTY_NOTICES.md)

## 历史记录

### 2026-11-24: 反推还原飞牛私有补丁

在官方 6.18.18 上按 12 步还原飞牛 `6.18.18.c1186-trim` 的私有改动, 用同一工具链重编并逐函数比对二进制:

| 步骤 | 部分 | 结果 |
| --- | --- | --- |
| 1 | event_report | 13 个一致, 2 个只差寄存器分配, 2 个各差 1 条指令 |
| 2 | libata 事件上报, `ATA_FORCE_MANAGE_RESTART` | 一致, 1 个函数只差寄存器分配 |
| 3 | vmlinux 小改动(约 60 个函数) | 除 ACPI 白名单(行为一致, 排布不同)外一致 |
| 4 | 网卡 | r8169 一致 201, 只差寄存器 3, 只差分支排布 4; PHY 和 mdio 一致 |
| 5 | md | 461 个函数一致 384, 只差寄存器 19, 不一致 56; 完成度较低 |
| 6 | trimacl 核心 | 一致或只差编译排布 |
| 7 | trimacl 文件系统适配 | ext4, fuse, nfsd 私有改动一致; btrfs 是上游 7.0.9 整体移植 |
| 8 | recvfile 系统调用 | 系统调用表一致 |
| 9 | trimafs2 | 从零写出, 115 个函数一致 51, 只差寄存器 13, 其余为代码生成差异 |
| 10 | bonding, GPU | bonding 已还原; amdgpu 全是上游回移; i915, xe 未还原 |
| 11 | ZFS | OpenZFS 2.4.1 + 7 个私有补丁 + 1 个上游修复, zfs.ko 6750 项只剩 2 个代码生成差异 |
| 12 | 移植到 6.18.65 并在 KVM 测试机上开机 | 开机, 存储空间挂载, 权限和只读共享, SMB, 回收站, md 降级恢复, DFR 热拔插, `sync_action`, 两次重启都与原装内核一致; 实测发现 md `action_store` 还原遗漏, 已补上 |

还原过程中发现 trimafs2 的 NFS 句柄可以越出桥目录.

### 2026-11-24: 6.18.65-1(内部版本)

110 个补丁, 含 4 个 NFS 安全修复. KVM 测试机上 NFS 修复前后用同一脚本对比, 4 个问题修复后正常功能不变.

### 2026-11-25: 6.18.65-2(内部版本)

外置模块装进内核包, 布局与飞牛一致. KVM 测试机上逐个加载和卸载, 发现 aic8800 USB 版模块挂错依赖和 seekwave 无硬件卸载时 oops.

### 2026-11-25: 6.18.65-3

修复上述两个外置模块问题. 命令行测试 RAID5, 在线转 llbitmap, btrfs 快照, qgroup, scrub, balance, ZFS 镜像, 数据校验通过.

### 2026-11-26: 独立成项目, 重建验证

内核维护从系统构建中独立成本项目. 用官方源码包加 `patches/` 重建 6.18.65-3:

- 内核树和 ZFS 树的 Git tree 哈希与原工作树相同.
- 包的文件清单相同(3881 个). 3863 个模块去掉签名并清零 build-id 后 3855 个逐字节相同; 其余 8 个: i915, hamachi 只差 `.BTF` 顺序, rtl8733bu, rtl8852bs, 2 个 NVIDIA 开源模块只差 `__DATE__`/`__TIME__`, spl, zfs 只差 `__FILE__` 中的构建路径.
- vmlinuz 只差编译时间串和内置的签名证书.

同日首次公开的仓库含本机路径, 删除后按现行结构重新发布.

### 2026-11-26: 按 README 从头编译验证

在空目录克隆仓库, 用新建的编译容器按 README 执行 `container`, `fetch`, `fetch-nvidia`, `bootstrap`, `build`, 构建所需的源码全部来自公开下载. 过程中发现并修复 `extmod.sh` 中外置模块源码路径错误(v6.18.65-3 的脚本编不了外置模块). 结果:

- 内核树的 `System.map` 和 `.config` 与维护者工作区的重建相同; 与维护者重建的包相比, 除 4 个模块的 `__DATE__`/`__TIME__` 和 vmlinuz 的编译时间串, 签名证书外相同.
- 与发布的 deb 相比, 模块结果与上一节相同; 另有 `config` 文件头的版本串不同, vmlinuz 中 83 个数据符号地址偏移, 原因是发布包在原工作树中构建.
