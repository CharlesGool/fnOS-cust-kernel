---
name: project-log-en
description: Project bugs, limitations, decisions, and handoff
metadata:
  version: "1.0.0"
  lang: "en"
---

# Log

## Multi-language

[简体中文](../LOG.md) | **English** | [Español](../es/LOG.md)

## Documentation

- Project overview: [README](README.md)

- Design rationale: [DESIGN](DESIGN.md)

- Project status: [LOG](LOG.md)
- Historical records: [HISTORY](HISTORY.md)
- Version changelog: [CHANGELOG](CHANGELOG.md)

- Third-party notices: [THIRD_PARTY_NOTICES](THIRD_PARTY_NOTICES.md)

## Records

- [History](HISTORY.md)
- [Changelog](CHANGELOG.md)

## Bugs

- [ ] `houmo-drv-xh2` (`xh2a_drv.ko`) is missing: it is in the fnOS package, but no source is available.
- [ ] `rtl8733bu` uses an approximate version, 5.15.12-123; the source of the -264 version used by fnOS could not be found.
- [ ] The `r8169` vendor driver is a placeholder version, 6.022.00.
- [ ] The NVIDIA open modules do not contain the fnOS changes for the CMP 40HX.
- [ ] 4 groups of suspected private changes in i915 and xe are not reimplemented (storage and permissions are not affected).
- [ ] The md reimplementation is less complete: `md_do_sync` has 18 fewer instructions, `mddev_create_serial_pool` lacks one check, and the large raid10 functions were not compared segment by segment.
- [ ] External modules were only tested for loading and unloading, not on the corresponding hardware.

## Limitations

- The actual function of network cards, bonding, wireless, and NVIDIA cannot be tested on the KVM test machine; real hardware is required.
- RAID5, online conversion to llbitmap, btrfs snapshots and qgroup, and ZFS mirrors were only tested from the command line, not created and managed through the fnOS web UI.

## Decisions

| Date | Decision | Status | Reason |
| --- | --- | --- | --- |
| 2026-11-24 | Stay on fnOS 1.2.1000, maintain the kernel ourselves, port it to 6.18 LTS | Accepted | The fnOS vendor does not publish the kernel source, so the stock kernel cannot receive upstream fixes. |
| 2026-11-24 | Do not follow new fnOS releases | Accepted | New releases also come without source, so they cannot be reviewed or patched. |
| 2026-11-26 | Maintain only one kernel; the reconstructed 6.18.18 tree is only a comparison reference | Accepted | Two parallel kernels would double the security-fix and testing work. |
| 2026-11-26 | Project exception: exempt from rule 2 of `版本标识` (version identifiers) in the all-in-one Skill release workflow (official releases use only `vMAJOR.MINOR.PATCH`). Scope: tags and Releases of this project. Restriction: a tag must be `v<upstream version>-<revision>`, matching the package version | Accepted | The package version consists of the upstream kernel version and a revision, and is embedded in the deb and in use. |
| 2026-11-26 | The repository is licensed under GPL-2.0-only | Accepted | The kernel patches are derivative works of Linux. |
| 2026-11-26 | Releases provide both the deb and the complete source (upstream tarballs, external module source archive) | Accepted | Distributing binaries requires meeting the GPL source offer obligation. |
| 2026-11-26 | The tools, comparison records, and fnOS binaries from the reverse-engineering phase are not published | Accepted | The build does not need them, and they contain fnOS binaries and disassembly. |
| 2026-11-26 | This project no longer distributes the source of the NVIDIA proprietary driver; users download it from NVIDIA with `ck.sh fetch-nvidia` when needed | Accepted | The NVIDIA license places conditions on redistribution, so it is clearer for users to accept it themselves. |
| 2026-11-26 | All downloads needed for a build are done and verified by `ck.sh container` and `ck.sh fetch`, and listed in the README in advance | Accepted | Others can build completely from this repository and public downloads alone. |

## Handoff

The current handoff is maintained in the [Simplified Chinese LOG.md](../LOG.md#交接).
