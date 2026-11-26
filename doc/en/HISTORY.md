---
name: project-history-en
description: Historical Records
metadata:
  version: "1.0.0"
  lang: "en"
---

# Historical Records

## Multi-language

[简体中文](../HISTORY.md) | **English** | [Español](../es/HISTORY.md)

## Documentation

- Project overview: [README](README.md)

- Design rationale: [DESIGN](DESIGN.md)

- Project status: [LOG](LOG.md)
- Historical records: [HISTORY](HISTORY.md)
- Version changelog: [CHANGELOG](CHANGELOG.md)

- Third-party notices: [THIRD_PARTY_NOTICES](THIRD_PARTY_NOTICES.md)

## Historical Records

### 2026-11-24: Reverse-engineering the fnOS private patches

The private changes of the fnOS `6.18.18.c1186-trim` were reimplemented on the official 6.18.18 in 12 steps, rebuilt with the same toolchain, and compared function by function at the binary level:

| Step | Part | Result |
| --- | --- | --- |
| 1 | event_report | 13 identical, 2 differ only in register allocation, 2 differ by 1 instruction each |
| 2 | libata event reporting, `ATA_FORCE_MANAGE_RESTART` | Identical; 1 function differs only in register allocation |
| 3 | Small vmlinux changes (about 60 functions) | Identical except the ACPI whitelist (same behavior, different layout) |
| 4 | Network cards | r8169: 201 identical, 3 differ only in registers, 4 differ only in branch layout; PHY and mdio identical |
| 5 | md | Of 461 functions, 384 identical, 19 differ only in registers, 56 differ; low completeness |
| 6 | trimacl core | Identical or differing only in compiler layout |
| 7 | trimacl file system adaptation | ext4, fuse, and nfsd private changes identical; btrfs is a wholesale port of upstream 7.0.9 |
| 8 | recvfile system call | System call table identical |
| 9 | trimafs2 | Written from scratch; of 115 functions, 51 identical, 13 differ only in registers, the rest differ in code generation |
| 10 | bonding, GPU | bonding reimplemented; amdgpu changes are all upstream backports; i915 and xe not reimplemented |
| 11 | ZFS | OpenZFS 2.4.1 + 7 private patches + 1 upstream fix; of 6750 items in zfs.ko, only 2 code generation differences remain |
| 12 | Port to 6.18.65 and boot on the KVM test machine | Booted; storage space mount, permissions and read-only shares, SMB, recycle bin, md degraded recovery, DFR hot-plug, `sync_action`, and two reboots all matched the stock kernel; testing revealed an omission in the md `action_store` reimplementation, which was fixed |

During the reimplementation it was found that the NFS handles of trimafs2 could escape the bridge directory.

### 2026-11-24: 6.18.65-1 (internal version)

110 patches, including 4 NFS security fixes. On the KVM test machine, NFS was compared before and after the fixes with the same script; after the 4 issues were fixed, normal functionality was unchanged.

### 2026-11-25: 6.18.65-2 (internal version)

External modules were included in the kernel package, with the same layout as fnOS. Loading and unloading each module on the KVM test machine revealed that the aic8800 USB module had a wrong dependency and that seekwave caused an oops when unloaded without hardware.

### 2026-11-25: 6.18.65-3

Fixed the two external module problems above. RAID5, online conversion to llbitmap, btrfs snapshots, qgroup, scrub, balance, and ZFS mirrors were tested from the command line, and data verification passed.

### 2026-11-26: Split into a separate project, rebuild verification

Kernel maintenance was split out of the system build into this project. 6.18.65-3 was rebuilt from the official tarballs plus `patches/`:

- The Git tree hashes of the kernel tree and the ZFS tree are identical to the original working trees.
- The package file lists are identical (3881 files). Of 3863 modules, 3855 are byte-for-byte identical after removing signatures and zeroing build-ids; the other 8 are: i915 and hamachi differ only in `.BTF` order; rtl8733bu, rtl8852bs, and 2 NVIDIA open modules differ only in `__DATE__`/`__TIME__`; spl and zfs differ only in the build path in `__FILE__`.
- vmlinuz differs only in the compile time string and the built-in signing certificate.

The first public repository of the same day contained local paths; it was deleted and republished with the current structure.
