# fnOS-cust-kernel

**简体中文** | [English](doc/en/README.md) | [Español](doc/es/README.md)

为停留在飞牛 fnOS 1.2.1000 的系统提供一个持续获得上游安全修复的内核: 官方 Linux 6.18 LTS 加上反推还原的飞牛私有补丁.

[![License](https://img.shields.io/badge/License-GPL--2.0--only-orange)](LICENSE)
[![Release](https://img.shields.io/github/v/release/CharlesGool/fnOS-cust-kernel?logo=github)](https://github.com/CharlesGool/fnOS-cust-kernel/releases/latest)

## 文档

- 项目概览: [README](README.md)

- 设计思路: [DESIGN](doc/DESIGN.md)

- 项目状态: [LOG](doc/LOG.md)
- 历史记录: [HISTORY](doc/HISTORY.md)
- 变更日志: [CHANGELOG](doc/CHANGELOG.md)

- 第三方声明: [THIRD_PARTY_NOTICES](doc/THIRD_PARTY_NOTICES.md)

## 简介

飞牛 fnOS 1.2.1000 自带内核 `6.18.18.c1186-trim`, 含大量私有改动, 飞牛不公开其源码. 本项目把这些改动反推成 C 源码补丁, 移植到官方 6.18 LTS(维护到 2028-12), 自己构建和打安全补丁. 本项目与飞牛官方无关.

- 内核包 `linux-image-6.18.65.c1186-trim`, 可替换 fnOS 1.2.1000 的原装内核, 版本串保留飞牛的 `.c1186-trim` 后缀.
- 还原的飞牛功能: trimacl 权限(VFS, ext4, btrfs, fuse, nfsd, ZFS), 11 个 trim 系统调用, 回收站, trimafs2 文件系统, sysdiag 事件上报, md 的 DFR 和 llbitmap 改动, recvfile 系统调用, bonding 混合速率, 网卡和 libata 改动. btrfs 是飞牛整体移植的上游 7.0.9.
- 4 个 NFS 安全修复(飞牛原版没有), 见 [CHANGELOG](doc/CHANGELOG.md).
- 包内含 OpenZFS 2.4.1 和飞牛同款外置驱动(Realtek 厂商网卡驱动, NVIDIA 开源和闭源驱动, 无线网卡等), 目录布局与飞牛一致.
- 已知问题见 [LOG 的缺陷](doc/LOG.md#缺陷), 未实现的目标见 [DESIGN 的设计目标](doc/DESIGN.md#设计目标).

## 要求

运行:

- fnOS 1.2.1000, x86_64.

构建:

- Linux 主机, 有 Docker, 约 25 GB 可用空间.
- 编译容器: `debian:12`, 装 `bc binutils bison bpftool build-essential cmake cpio flex git kmod libdw-dev libelf-dev libssl-dev python3 rsync xz-utils zlib1g-dev zstd`, 编译器为 `gcc (Debian 12.2.0-14+deb12u1) 12.2.0`(与飞牛原版相同, 不要升级), `pahole` 为从源码编译的 v1.31. 依赖目录挂载进容器.
- 依赖目录(`CK_DEPS_DIR`)中: OpenZFS 2.4.1 源码包 `dl-zfs-2.4.1/zfs-2.4.1.tar.gz`, 外置模块源码 `extsrc/<目录>/`(各为 Git 仓库, 版本见 [`patches/extmod/MANIFEST.tsv`](patches/extmod/MANIFEST.tsv), 也可从 Release 的源码包解出). 内核源码包由 `ck.sh fetch` 下载.
- 测试: 主机支持 KVM, 有 `qemu-system-x86_64`, OVMF, `sshpass`.

## 安装

### 快速安装

在 fnOS 1.2.1000 上以 root 执行:

```bash
V=6.18.65-3
curl -fLO https://github.com/CharlesGool/fnOS-cust-kernel/releases/download/v$V/linux-image-6.18.65.c1186-trim_${V}_amd64.deb
curl -fLO https://github.com/CharlesGool/fnOS-cust-kernel/releases/download/v$V/SHA256SUMS
sha256sum -c --ignore-missing SHA256SUMS
dpkg -i linux-image-6.18.65.c1186-trim_${V}_amd64.deb
reboot
```

开机后 `uname -r` 应为 `6.18.65.c1186-trim`. 原装 6.18.18 内核保留在启动菜单的高级选项里.

### 常规安装

从源码构建, 然后按快速安装的 `dpkg -i` 安装:

```bash
git clone https://github.com/CharlesGool/fnOS-cust-kernel.git
cd fnOS-cust-kernel
cp .env.example .env        # 按 指南 填写
scripts/ck.sh fetch         # 下载内核源码包并校验 kernel.org 签名
scripts/ck.sh bootstrap     # 源码包 + patches/ -> 依赖目录下 ck/linux 和 ck/zfs
scripts/ck.sh build         # 内核, ZFS, 外置模块, 打包; 产物在依赖目录下 ck/out/
```

## 指南

### 配置

`.env`(从 `.env.example` 复制):

| 参数 | 含义 |
| --- | --- |
| `CK_DEPS_DIR` | 依赖目录: 上游源码包, 外置模块源码, 工作区 `ck/`. 必填 |
| `CK_CONTAINER_DIR` | 依赖目录在编译容器里的路径, 默认 `/k` |
| `CK_BUILD_CONTAINER` | 编译容器名, 默认 `kwork` |
| `CK_DOCKER` | 调用 docker 的命令, 默认 `docker`; 容器在另一个环境里时可填一个包装脚本 |
| `KJOBS` | 并行编译数, 默认为容器的 CPU 数 |
| `CK_GNUPGHOME` | 校验 kernel.org 签名用的 GnuPG 目录, 默认 `$CK_DEPS_DIR/gnupg` |
| `CK_KVM_DIR` | 测试机目录(磁盘, OVMF 变量, `qmp.sock`), 测试必填 |
| `VM_PASS` | 测试机账户 `admintest` 的密码, 测试必填 |
| `U1_PASS` | 测试机账户 `u1` 的密码, `smbtest.sh` 必填 |

版本号在 `config/VERSION`, 格式为 `<上游版本>-<修订号>`; `config/versions.conf` 写版本串后缀和 ZFS 版本.

### 构建命令

| 命令 | 作用 |
| --- | --- |
| `ck.sh kernel` / `zfs` / `pkg` | 单步构建. `kernel` 把 `config/` 的配置复制进树并 `olddefconfig`, 选项有变化时停下 |
| `ck.sh extmod [名字...]` | 编外置模块, 默认全部; 编之前核对源码 HEAD 与 `MANIFEST.tsv` 一致 |
| `ck.sh saveconfig` | 把树里的 `.config` 存回 `config/` |
| `ck.sh export` | 把内核树, ZFS 树, 外置模块源码的本地提交导出到 `patches/` |
| `ck.sh newbase <版本>` | 在内核树上建新上游基线并把补丁 rebase 上去 |
| `ck.sh release` | 把产物复制到 `releases/<版本>/`, 写 `SHA256SUMS` 和 `BUILDINFO` |
| `ck.sh srcpkg` | 在 `releases/<版本>/` 放齐发布用的源码: 外置模块源码包, 内核和 ZFS 上游源码包及签名, NVIDIA 许可证 |
| `cmpdeb.sh <旧> <新>` | 比较两个内核包: 文件清单, 去掉签名和 build-id 后的内容 |

日志在依赖目录的 `ck/logs/`, 外置模块的在 `ck/extbuild/<名字>.log`.

### 修改补丁

在依赖目录的 `ck/linux`(分支 `r<上游版本>`), `ck/zfs`, `extsrc/<目录>` 里提交, 然后 `ck.sh export` 并在本仓库提交 `patches/` 的变化.

### 测试

测试机是装了原版 fnOS 1.2.1000 的 KVM 虚拟机, 4 块数据盘, 有 Btrfs RAID1 存储空间和账户 `admintest`, `u1`. `boot.sh` 把 Web, SSH, SMB 转发到本机回环地址 25666, 25622, 25445.

```bash
test/kvm/boot.sh
sshpass -p "$VM_PASS" scp -P 25622 <deb> admintest@127.0.0.1:/tmp/k.deb
echo 'dpkg -i /tmp/k.deb && reboot' | test/kvm/vm.sh
test/kvm/vm.sh < test/kvm/probe.sh
```

| 脚本 | 测试内容 |
| --- | --- |
| `probe.sh` | 内核版本, 失败的服务, dmesg 错误, mdstat |
| `ptest.sh`, `ptest2.sh` | trimacl 权限: 管理员, 普通用户, 只读共享 |
| `smbtest.sh` | SMB 读写和权限; 在脚本前加 `VM_PASS=...; U1_PASS=...` 赋值后传给 `vm.sh` |
| `nfstest.sh` | NFS 功能和权限, 含 4 个安全修复 |
| `mdtest.sh`, `acttest.sh` | md 降级, DFR, `sync_action` |
| `dfrtest.sh` | 在主机运行: 热拔数据盘, 验证 DFR 免重建恢复 |
| `stortest.sh`, `stortest2.sh` | RAID5, btrfs 快照, qgroup, scrub, balance, ext4 |
| `modtest.sh` | 逐个加载和卸载外置模块, 检查 Oops |

`vm.sh` 的输出没有时间戳, 可以和上一版本的输出直接 diff. 网卡, bonding, 无线和 NVIDIA 的实际功能只能在真机上测.

### 出新版本

版本号: 同一上游版本上改补丁, 配置或模块时修订号加 1; 换上游版本时修订号从 1 开始. 已发布的版本不覆盖.

只加补丁(例如安全修复):

1. 在 `ck/linux` 提交修复, `ck.sh export`.
2. 修改 `config/VERSION`, `ck.sh build`.
3. 在测试机上运行测试, 与上一版本的输出比较.
4. `ck.sh release`, `ck.sh srcpkg`, 更新 [CHANGELOG](doc/CHANGELOG.md), 打标签 `v<版本>` 并发布.

跟进上游 6.18.y:

```bash
scripts/ck.sh fetch 6.18.66
scripts/ck.sh newbase 6.18.66      # 有冲突时在 ck/linux 里解决后 git rebase --continue
echo 6.18.66-1 > config/VERSION
scripts/ck.sh export
scripts/ck.sh build                # 配置有变化时按提示 saveconfig
scripts/cmpdeb.sh <上一版 deb> <新 deb>
```

然后执行上面第 3, 4 步. btrfs 是 7.0.9 的整体移植, 6.18.y 的 btrfs 修复不会自动生效, 需要从 7.0.x 和主线手工移植. ZFS 跟 OpenZFS 2.4.x, 换版本时修改 `config/versions.conf` 并在新源码包上重打 `patches/zfs`. 6.18.y 的 CVE 公告见 [linux-cve-announce](https://lore.kernel.org/linux-cve-announce/).

## 升级

- 同一上游版本的新修订(如 `6.18.65-3` 到 `6.18.65-4`): `dpkg -i` 新包后重启, 包原地升级.
- 新上游版本(如 `6.18.65-3` 到 `6.18.66-1`): 包名不同, `dpkg -i` 新包后与旧内核并存, 新内核默认启动. 重启后确认 `uname -r`, 再 `dpkg -r linux-image-6.18.65.c1186-trim` 删除旧内核.
- 只替换内核和模块, 存储空间, 设置和数据不受影响. 升级后用 `probe.sh` 检查.

## 卸载

快速卸载(恢复原装内核, 保留数据和设置): 在启动菜单的高级选项里选原装 `6.18.18.c1186-trim` 启动, 然后:

```bash
dpkg -r linux-image-6.18.65.c1186-trim
```

完全卸载(另删除残留的模块目录和配置记录):

```bash
dpkg --purge linux-image-6.18.65.c1186-trim
update-grub
```

## 致谢

- [Linux](https://www.kernel.org/), [OpenZFS](https://github.com/openzfs/zfs) 和各外置驱动的上游, 完整清单见 [THIRD_PARTY_NOTICES](doc/THIRD_PARTY_NOTICES.md).
- 部分飞牛改动移植自上游主线和 [ImmortalWrt](https://github.com/immortalwrt/immortalwrt), 补丁说明中写明了来源.

## 许可证

本仓库按 GNU General Public License v2.0 only 授权, SPDX 标识符 `GPL-2.0-only`, 全文见 [LICENSE](LICENSE). `patches/zfs/` 按 OpenZFS 的 CDDL-1.0, `patches/extmod/` 下各驱动补丁按该驱动上游的许可证, 发布包中的第三方组件见 [THIRD_PARTY_NOTICES](doc/THIRD_PARTY_NOTICES.md).
