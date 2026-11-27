# ARM64 `trimafs` 验证

小米 10（Umi）的 fnOS 用户态启动时执行 `mount -t trimafs trimafs /fs`。本仓库的 `fs/trimafs2` 注册文件系统类型 `trimafs`。补丁序列中的 `0111` 将 TRIM ACL 缓存哨兵改为与缓存槽一致的指针类型，让 ARM64 的 `try_cmpxchg()` 通过编译。

从 Linux 6.18.65 的 Umi 内核源码和工作配置开始。按 `patches/kernel/series` 应用本仓库的完整内核补丁，保留 Umi 的设备树和板级支持，使用 `config/arm64-trimafs.config` 启用内建的 `trimafs` 和 Btrfs ACL。以下命令在已应用补丁的 Linux 源码目录执行。`repo`、`out` 和 `umi_config` 分别指向本仓库、新的编译输出目录和 Umi 的工作配置。

```bash
export ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu-
mkdir -p "$out"
scripts/kconfig/merge_config.sh -m -O "$out" "$umi_config" "$repo/config/arm64-trimafs.config"
make O="$out" olddefconfig
for option in BTRFS_FS BTRFS_FS_POSIX_ACL FS_POSIX_ACL EXPORTFS FS_TRIM_ACL TRIMAFS2_FS; do
    grep -Fx "CONFIG_$option=y" "$out/.config" || exit 1
done
make -j"$(nproc)" O="$out" Image modules dtbs
```

在 ARM64 QEMU 中，默认挂载成功，Btrfs 桥接通过了读写、改名和删除测试。用 fnOS ARM64 的 `trimacl` 设置显式拒绝规则后，底层 Btrfs 拒绝了目标用户，但默认挂载的 `/fs` 仍允许该用户读取。初次挂载 `/fs` 时加上 `trimacl`，同一条拒绝规则即可在桥接路径生效。

```bash
mount -t trimafs -o trimacl trimafs /fs
findmnt -M /fs -o SOURCE,FSTYPE,OPTIONS
```

小米 10 的启动镜像、模块和 DTB 由 FnNAS 的 Umi 构建流程组装。接入时让启动流程使用上述挂载选项，并在真机测试卷上验证 Web 建卷、文件共享和普通用户权限。fnOS ARM64 其他私有接口的兼容性需要用对应版本的用户态验收。仓库现有的 `ck.sh` 发布流程仍面向 x86_64。

## 2026-11-27 FnNAS 真机挂载记录

FnNAS 在小米 10（Umi，`csot-90`）上直接刷写 Fastboot 的 `boot` 分区并重启。已安装的 fnOS 从原有 Btrfs 根启动。USB ACM 报告 `kernel=6.18.65-csot90-sm8250-trimafs1`、`rootfs=btrfs`、`fs_mount=trimafs`，并确认 `trim_init.service`、`trim_nginx.service` 和 `usersrv.service` 均为 `active`。fnOS 网页探测返回 HTTP 200。

| 输入或产物 | 完整值 |
| --- | --- |
| Linux Stable 提交 | `4700e3adf3b24b39dd4929e9c6d62811ba3ccea8` |
| FnNAS 内核输入基线 | `0a598a368247a7b70368df8d7722ad433eba1fdb` |
| 本项目补丁基线 | `6e24d88179117e46c78ce3023b793f3f2b93b444` |
| FnNAS 后置补丁 SHA-256 | `8a4588fcb4607181ec1cf44c7a0fc1a981268a8ec4feaf37f9038105623fb542` |
| 本地调试包 SHA-256 | `247d5fe2bddfbacf5966a9ec98839660379ab554dfdecdb8b63f1f2961a515c2` |
| 已刷 boot.img SHA-256 | `f8910069be0ffc0c66a112842b8fcdd7a2338067278c62702a7c469fe6408060` |

真机运行的是 FnNAS 实验构建。其后置补丁包含与 `0111` 等效的指针类型修正，并额外为无选项挂载开启聚合挂载的 `trimacl` 默认值，使 fnOS 原有启动命令可直接使用。单独应用本项目补丁时，仍应通过 `-o trimacl` 显式开启该选项。记录见 FnNAS 开发分支提交 `3eb4c7a0b441a70cdb1a815590ecc5e53e606108` 中的 `make-fnnas/qualcomm/sm8250/docs/umi-trimafs-vm.md`。

无选项挂载的 Btrfs 桥接 ACL 测试，以及 Btrfs、ext4 和 OpenZFS 读写测试，来自同一最终内核的 ARM64 QEMU 回归。Web 建卷、共享、普通用户 ACL、Fastboot 回滚复验和 OTA 仍待真机验收。
