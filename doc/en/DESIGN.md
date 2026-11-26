---
name: project-design-en
description: Project architecture and design constraints
metadata:
  version: "1.0.0"
  lang: "en"
---

# fnOS-cust-kernel — Design

## Multi-language

[简体中文](../DESIGN.md) | **English** | [Español](../es/DESIGN.md)

## Documentation

- Project overview: [README](README.md)

- Design rationale: [DESIGN](DESIGN.md)

- Project status: [LOG](LOG.md)
- Historical records: [HISTORY](HISTORY.md)
- Version changelog: [CHANGELOG](CHANGELOG.md)

- Third-party notices: [THIRD_PARTY_NOTICES](THIRD_PARTY_NOTICES.md)

## Design Goals

- [x] Replace the stock kernel of fnOS 1.2.1000 with the official 6.18 LTS plus patches, with the behavior of the fnOS storage, permission, recycle bin, and sharing features unchanged.
- [x] Reverse-engineer the fnOS private changes into C source, rebuild them on the official 6.18.18 with the same toolchain, and port them only after a function-by-function binary comparison confirms they match.
- [x] Rebuild an equivalent package from the upstream source tarballs and `patches/`.
- [x] Maintain only one kernel. The reconstructed 6.18.18 tree is only a comparison reference and is not packaged.
- [ ] Reimplement 4 groups of suspected private changes in i915 and xe.
- [ ] Add the external module `houmo-drv-xh2`, which fnOS has and this project lacks (no source available).
- [ ] Verify network cards, bonding, wireless, and NVIDIA on real hardware.
- Non-goal: following new fnOS releases and new fnOS kernels.

## Architecture

Build flow:

```text
linux-<upstream>.tar.xz + patches/kernel ─> kernel tree ─> bzImage, in-tree modules ─┐
zfs-<version>.tar.gz + patches/zfs ─────> ZFS tree ─> spl.ko, zfs.ko ─────────────────┼─> pkg ─> linux-image-<version string>_<version>_amd64.deb
extsrc/<directory> (= HEAD in MANIFEST.tsv) ──────> external modules ────────────────┘
```

- `scripts/ck.sh` runs on the host. It downloads and verifies the upstream tarballs, syncs the repository into the workspace, and then runs the steps in `scripts/kwork/` inside the build container.
- The workspace is under `ck/` in the dependency directory, not in the repository: `linux/`, `zfs/` (Git trees), `zfs-build/`, `extbuild/`, `extmod/`, `pkg/`, `out/`, `logs/`.

Top-level directories:

| Directory | Responsibility |
| --- | --- |
| `config/` | Kernel configuration `config-<version string>`, version number `VERSION`, version string suffix and ZFS version in `versions.conf` |
| `patches/` | The only source of truth for sources: `kernel/` (with `series`), `zfs/`, `extmod/<directory>/`, and `MANIFEST.tsv`, which records the upstream baseline and HEAD of each external module |
| `scripts/` | Host entry point `ck.sh`, package comparison `cmpdeb.sh` and `kocmp.py`, in-container steps in `kwork/` |
| `test/` | KVM regression test scripts in `kvm/` |
| `third_party/` | License texts of the third-party components in the release package, one subdirectory per source |
| `doc/` | Project documentation |
| `releases/` | Build output, ignored by Git: packages, source archives, `SHA256SUMS`, `BUILDINFO` for each version |

The kernel patches (`patches/kernel/`) are grouped by origin:

| Part | Content |
| --- | --- |
| event_report, libata | netlink event reporting for sysdiag; ATA ACPI power and `manage_restart` (ported from 6.19) |
| trimacl | New `inode` field, 12 callbacks in `inode_operations`, 11 trim system calls, recycle bin, ext4/btrfs/fuse/nfsd adaptation |
| trimafs2 | The fnOS bridge file system, written from scratch |
| md | DFR (recovery from degraded state without rebuild), resync hint, llbitmap |
| btrfs | Wholesale port of upstream 7.0.9, plus 7.0.10 fixes and fnOS private changes |
| Other | recvfile system call, bonding mixed-speed support, r8169/motorcomm network cards, small changes to x86, ACPI, PCI, and DRM fbdev |
| Security fixes | 4 NFS fixes added by this project |

## Design Constraints

1. The kernel version string suffix is fixed to `.c1186-trim` (`config/versions.conf`); the fnOS user space uses it to find the module directory.
2. The compiler and pahole versions match the original fnOS build: `gcc (Debian 12.2.0-14+deb12u1) 12.2.0`, pahole v1.31. Changing them would remove the reference for function-level comparison.
3. The package layout matches fnOS:
   - external modules are uncompressed and processed with `strip --strip-debug`;
   - `updates/trim/<name>/*.ko` is placed in `/lib/modules/<version string>/`, and `modules_trim/<name>/*.ko` in `/usr/lib/modules_trim/<version string>/`;
   - `updates/trim/alternatives` is an absolute link to `/usr/lib/modules_trim/<version string>/alternatives`, and `alternatives/nvidia-gpu` points to the proprietary version by default;
   - in-tree modules are xz-compressed and signed.
4. External modules are compiled under the fnOS build path `/var/jenkins_home/workspace/kernel-build/...`, so that the `__FILE__` strings match fnOS.
5. Each fresh build generates a random module signing key (`CONFIG_MODULE_SIG_ALL=y`, `MODULE_SIG_FORCE` not enabled). Module signatures differ between builds; do not mix modules from different builds.
6. btrfs follows upstream 7.0.x and mainline, not 6.18.y.
7. When changing trimacl, nfsd, or trimafs2, the checks of the 4 NFS security fixes must not be weakened: `nfsd_permission` checks write and execute for trimacl, `fh_getattr` reports 0777 only for trimacl, trimafs2 handles must be under the bridge root, and only the internal second-level `nfs` directory counts as an NFS path.
8. Do not unpack or build on an fnOS storage volume: trimacl changes the permissions of the extracted files.
