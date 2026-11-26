# fnOS-cust-kernel

[简体中文](../../README.md) | **English** | [Español](../es/README.md)

A kernel that keeps receiving upstream security fixes for systems left on fnOS 1.2.1000: the official Linux 6.18 LTS plus the reverse-engineered, reimplemented private patches of fnOS.

[![License](https://img.shields.io/badge/License-GPL--2.0--only-orange)](../../LICENSE)
[![Release](https://img.shields.io/github/v/release/CharlesGool/fnOS-cust-kernel?logo=github)](https://github.com/CharlesGool/fnOS-cust-kernel/releases/latest)

## Documentation

- Project overview: [README](README.md)

- Design rationale: [DESIGN](DESIGN.md)

- Project status: [LOG](LOG.md)
- Historical records: [HISTORY](HISTORY.md)
- Version changelog: [CHANGELOG](CHANGELOG.md)

- Third-party notices: [THIRD_PARTY_NOTICES](THIRD_PARTY_NOTICES.md)

## Introduction

fnOS 1.2.1000 ships the kernel `6.18.18.c1186-trim`, which contains many private changes whose source code is not published. This project reverse-engineers those changes into C source patches, ports them to the official 6.18 LTS (maintained until 2028-12), and builds and security-patches the kernel itself. This project is not affiliated with the fnOS vendor.

- Kernel package `linux-image-6.18.65.c1186-trim`, a replacement for the stock kernel of fnOS 1.2.1000. The version string keeps the `.c1186-trim` suffix.
- Reimplemented fnOS features: trimacl permissions (VFS, ext4, btrfs, fuse, nfsd, ZFS), 11 trim system calls, recycle bin, trimafs2 file system, sysdiag event reporting, md DFR and llbitmap changes, recvfile system call, bonding mixed-speed support, and network card and libata changes. btrfs is a wholesale port of upstream 7.0.9, as in fnOS.
- 4 NFS security fixes (not present in the original fnOS kernel); see [CHANGELOG](CHANGELOG.md).
- The package includes OpenZFS 2.4.1 and the same external drivers as fnOS (Realtek vendor network drivers, NVIDIA open and proprietary drivers, wireless adapters, etc.), with the same directory layout as fnOS.
- Known issues are listed in [Bugs in LOG](LOG.md#bugs); unfinished goals are listed in [Design Goals in DESIGN](DESIGN.md#design-goals).

## Requirements

Runtime:

- fnOS 1.2.1000, x86_64.

Build:

- An x86_64 Linux host with Docker and `curl` that can reach the addresses in the table below. The dependency directory (`CK_DEPS_DIR`) needs about 30 GB of free space and must not be on an fnOS storage volume.
- The build container is created by `ck.sh container`: `debian:12` plus the build dependencies. The compiler is `gcc (Debian 12.2.0-14+deb12u1) 12.2.0` (identical to the original fnOS build), and `pahole` is v1.31 built from source.

The build downloads the following, all into the dependency directory or the build container, and verifies them against the sha256 values in `config/versions.conf` or the kernel.org signature:

| Content | Source | Size | Command |
| --- | --- | --- | --- |
| Docker image `debian:12` and about 110 Debian packages | Docker Hub, `deb.debian.org` | about 180 MB | `ck.sh container` |
| pahole v1.31 source with the libbpf submodule | `git.kernel.org`, GitHub | about 10 MB | `ck.sh container` |
| `linux-6.18.65.tar.xz` and signature | `cdn.kernel.org` | 155 MB | `ck.sh fetch` |
| `zfs-2.4.1.tar.gz` and signature | OpenZFS GitHub Release | 35 MB | `ck.sh fetch` |
| External module source archive `fnos-cust-kernel-6.18.65-3-extmod-src.tar.xz` | GitHub Release of this project | 180 MB | `ck.sh fetch` |
| Optional: NVIDIA proprietary driver `NVIDIA-Linux-x86_64-580.142.run` | `download.nvidia.com` | 380 MB | `ck.sh fetch-nvidia` |

The NVIDIA proprietary driver is distributed under the NVIDIA Software License. This project no longer distributes its source; users download it themselves after reading the [license](../../third_party/nvidia-linux-driver/LICENSE). Without it, the build skips `nvidia-gpu-proprietary`, the package contains only the NVIDIA open driver, and `alternatives/nvidia-gpu` points to the open driver; everything else matches the release.

- Testing: a host with KVM support, `qemu-system-x86_64`, OVMF, and `sshpass`.

## Install

### Quick Install

Run as root on fnOS 1.2.1000:

```bash
V=6.18.65-3
curl -fLO https://github.com/CharlesGool/fnOS-cust-kernel/releases/download/v$V/linux-image-6.18.65.c1186-trim_${V}_amd64.deb
curl -fLO https://github.com/CharlesGool/fnOS-cust-kernel/releases/download/v$V/SHA256SUMS
sha256sum -c --ignore-missing SHA256SUMS
dpkg -i linux-image-6.18.65.c1186-trim_${V}_amd64.deb
reboot
```

After boot, `uname -r` should print `6.18.65.c1186-trim`. The stock 6.18.18 kernel remains in the advanced options of the boot menu.

### Normal Install

Build from source, then install with `dpkg -i` as in Quick Install. A build takes about 1 hour (20 threads):

```bash
git clone https://github.com/CharlesGool/fnOS-cust-kernel.git
cd fnOS-cust-kernel
cp .env.example .env        # set at least CK_DEPS_DIR, see Usage
scripts/ck.sh container     # create the build container: debian:12, build dependencies, pahole v1.31
scripts/ck.sh fetch         # download and verify the kernel, ZFS, and external module sources
scripts/ck.sh bootstrap     # source tarballs + patches/ -> ck/linux and ck/zfs in the dependency directory
scripts/ck.sh build         # kernel, ZFS, external modules, packaging; output in ck/out/ in the dependency directory
```

To include the NVIDIA proprietary driver, read the [NVIDIA license](../../third_party/nvidia-linux-driver/LICENSE) before `bootstrap` and, if you accept it, run:

```bash
scripts/ck.sh fetch-nvidia --accept-nvidia-license
```

It only extracts the `kernel/` directory of the driver with `--extract-only`, does not install the driver on the host, and checks that the extracted content matches the one used by the release.

Compare with the release (module signing keys differ between builds, so signatures are removed before comparing):

```bash
scripts/cmpdeb.sh linux-image-6.18.65.c1186-trim_6.18.65-3_amd64.deb <dependency directory>/ck/out/linux-image-6.18.65.c1186-trim_6.18.65-3_amd64.deb
```

## Usage

### Configuration

`.env` (copy from `.env.example`):

| Parameter | Meaning |
| --- | --- |
| `CK_DEPS_DIR` | Dependency directory: upstream source tarballs, external module sources, and the workspace `ck/`. Required |
| `CK_CONTAINER_DIR` | Path of the dependency directory inside the build container, default `/k` |
| `CK_BUILD_CONTAINER` | Build container name, default `kwork` |
| `CK_DOCKER` | Command used to call docker, default `docker`; a wrapper script can be used when `sudo` is needed or the container is in another environment |
| `KJOBS` | Number of parallel build jobs, default is the CPU count of the container |
| `CK_GNUPGHOME` | GnuPG directory used to verify kernel.org signatures, default `$CK_DEPS_DIR/gnupg` |
| `CK_KVM_DIR` | Test VM directory (disk, OVMF variables, `qmp.sock`); required for testing |
| `VM_PASS` | Password of the account `admintest` on the test VM; required for testing |
| `U1_PASS` | Password of the account `u1` on the test VM; required by `smbtest.sh` |

The version number is in `config/VERSION`, in the format `<upstream version>-<revision>`; `config/versions.conf` holds the version string suffix, the versions of ZFS, the NVIDIA proprietary driver, and pahole, the sha256 values of the downloads, and the version of the external module source archive.

### Build Commands

| Command | Purpose |
| --- | --- |
| `ck.sh container` | Create the build container; stops if a container with the same name exists |
| `ck.sh fetch [version]` | Download and verify the kernel source tarball; without a version, also download the ZFS source tarball and extract the external module sources missing from the dependency directory into `extsrc/` |
| `ck.sh fetch-nvidia --accept-nvidia-license` | Download the NVIDIA proprietary driver and extract `extsrc/nvidia-prop-work` |
| `ck.sh kernel` / `zfs` / `pkg` | Build a single step. `kernel` copies the configuration from `config/` into the tree and runs `olddefconfig`, and stops if options changed |
| `ck.sh extmod [name...]` | Build external modules, all by default; before building, checks that the source commit matches `MANIFEST.tsv` (directories extracted from the source archive record it in `.ck-rev`) |
| `ck.sh saveconfig` | Save the `.config` in the tree back to `config/` |
| `ck.sh export` | Export local commits of the kernel tree, ZFS tree, and external module sources to `patches/` |
| `ck.sh newbase <version>` | Create a new upstream baseline on the kernel tree and rebase the patches onto it |
| `ck.sh release` | Copy the artifacts to `releases/<version>/` and write `SHA256SUMS` and `BUILDINFO` |
| `ck.sh srcpkg` | Put the complete release sources in `releases/<version>/`: external module source archive (without the NVIDIA proprietary driver), upstream kernel and ZFS tarballs with signatures, NVIDIA license |
| `cmpdeb.sh <old> <new>` | Compare two kernel packages: file list, and contents after removing signatures and build-ids |

Logs are in `ck/logs/` in the dependency directory; external module logs are in `ck/extbuild/<name>.log`.

### Modifying Patches

Commit in `ck/linux` (branch `r<upstream version>`), `ck/zfs`, or `extsrc/<directory>` in the dependency directory, then run `ck.sh export` and commit the changes to `patches/` in this repository. External module directories extracted from the source archive are not Git repositories; before modifying one, run `git init` in it, delete `.ck-rev`, and commit the content as is.

### Testing

The test machine is a KVM virtual machine with stock fnOS 1.2.1000 installed, 4 data disks, a Btrfs RAID1 storage space, and the accounts `admintest` and `u1`. `boot.sh` forwards Web, SSH, and SMB to the local loopback ports 25666, 25622, and 25445.

```bash
test/kvm/boot.sh
sshpass -p "$VM_PASS" scp -P 25622 <deb> admintest@127.0.0.1:/tmp/k.deb
echo 'dpkg -i /tmp/k.deb && reboot' | test/kvm/vm.sh
test/kvm/vm.sh < test/kvm/probe.sh
```

| Script | What it tests |
| --- | --- |
| `probe.sh` | Kernel version, failed services, dmesg errors, mdstat |
| `ptest.sh`, `ptest2.sh` | trimacl permissions: administrator, regular user, read-only share |
| `smbtest.sh` | SMB read/write and permissions; prefix the script with the assignments `VM_PASS=...; U1_PASS=...` before passing it to `vm.sh` |
| `nfstest.sh` | NFS functionality and permissions, including the 4 security fixes |
| `mdtest.sh`, `acttest.sh` | md degradation, DFR, `sync_action` |
| `dfrtest.sh` | Runs on the host: hot-unplugs a data disk and verifies DFR recovery without a rebuild |
| `stortest.sh`, `stortest2.sh` | RAID5, btrfs snapshots, qgroup, scrub, balance, ext4 |
| `modtest.sh` | Loads and unloads each external module and checks for Oops |

The output of `vm.sh` has no timestamps, so it can be diffed directly against the output of the previous version. The actual function of network cards, bonding, wireless, and NVIDIA can only be tested on real hardware.

### Releasing a New Version

Version number: when patches, configuration, or modules change on the same upstream version, the revision is incremented by 1; when the upstream version changes, the revision starts at 1. A published version is never overwritten.

Adding patches only (for example, a security fix):

1. Commit the fix in `ck/linux` and run `ck.sh export`.
2. Edit `config/VERSION` and run `ck.sh build`.
3. Run the tests on the test machine and compare with the output of the previous version.
4. Run `ck.sh release` and `ck.sh srcpkg`; if the external modules changed, update `EXTSRC_VER` and `EXTSRC_SHA256` in `config/versions.conf` as `srcpkg` prompts. Update [CHANGELOG](CHANGELOG.md), tag `v<version>`, and publish, uploading all files in `releases/<version>/`.

Following upstream 6.18.y:

```bash
scripts/ck.sh fetch 6.18.66
scripts/ck.sh newbase 6.18.66      # on conflicts, resolve them in ck/linux and run git rebase --continue
echo 6.18.66-1 > config/VERSION
scripts/ck.sh export
scripts/ck.sh build                # if the configuration changed, run saveconfig as prompted
scripts/cmpdeb.sh <previous deb> <new deb>
```

Then perform steps 3 and 4 above. btrfs is a wholesale port of 7.0.9, so btrfs fixes in 6.18.y do not take effect automatically and must be ported manually from 7.0.x and mainline. ZFS follows OpenZFS 2.4.x; when changing the version, edit `config/versions.conf` and reapply `patches/zfs` on the new source tarball. CVE announcements for 6.18.y are at [linux-cve-announce](https://lore.kernel.org/linux-cve-announce/).

## Upgrade

- A new revision of the same upstream version (for example `6.18.65-3` to `6.18.65-4`): run `dpkg -i` with the new package and reboot; the package is upgraded in place.
- A new upstream version (for example `6.18.65-3` to `6.18.66-1`): the package name differs, so after `dpkg -i` the new kernel is installed alongside the old one and boots by default. After rebooting, confirm `uname -r`, then remove the old kernel with `dpkg -r linux-image-6.18.65.c1186-trim`.
- Only the kernel and modules are replaced; storage spaces, settings, and data are not affected. Check with `probe.sh` after upgrading.

## Uninstall

Quick uninstall (restores the stock kernel, keeps data and settings): boot the stock `6.18.18.c1186-trim` from the advanced options of the boot menu, then run:

```bash
dpkg -r linux-image-6.18.65.c1186-trim
```

Full uninstall (also removes leftover module directories and configuration records):

```bash
dpkg --purge linux-image-6.18.65.c1186-trim
update-grub
```

## Acknowledgements

- Upstream of [Linux](https://www.kernel.org/), [OpenZFS](https://github.com/openzfs/zfs), and the external drivers; the full list is in [THIRD_PARTY_NOTICES](THIRD_PARTY_NOTICES.md).
- Some fnOS changes were ported from upstream mainline and [ImmortalWrt](https://github.com/immortalwrt/immortalwrt); the patch descriptions state the source.

## License

This repository is licensed under the GNU General Public License v2.0 only, SPDX identifier `GPL-2.0-only`; the full text is in [LICENSE](../../LICENSE). `patches/zfs/` is under OpenZFS's CDDL-1.0, the driver patches under `patches/extmod/` are under the license of each driver's upstream, and the third-party components in the release package are listed in [THIRD_PARTY_NOTICES](THIRD_PARTY_NOTICES.md).
