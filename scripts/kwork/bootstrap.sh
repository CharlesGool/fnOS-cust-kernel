#!/bin/bash
# bootstrap.sh: 用官方源码包 + 仓库里的补丁建出内核树和 ZFS 树(已存在就拒绝, 要重建先删)
# 内核: $K/linux-$UPV.tar.xz(ck.sh fetch 下载并校验过) -> $L, tag v$UPV, 分支 r$UPV = 打完 patches/kernel
# ZFS : $K/dl-zfs-$ZFS/zfs-$ZFS.tar.gz -> $Z, tag zfs-$ZFS, 分支 fnos = 打完 patches/zfs
. "$(dirname "$0")/common.sh"
G="git -c user.name=kcmp -c user.email=kcmp@localhost"
if [ ! -e $L ]; then
  T=$K/linux-$UPV.tar.xz; [ -f $T ] || die "没有 $T, 先 ck.sh fetch"
  mkdir -p $L.tmp; tar --no-same-owner -C $L.tmp -xf $T; mv $L.tmp/linux-$UPV $L; rmdir $L.tmp
  cd $L; git init -q -b r$UPV; $G add -A >/dev/null; $G commit -qm "官方 linux-$UPV(GPG 校验过)"; git tag v$UPV
  $G am -q --committer-date-is-author-date $(sed "s|^|$REPO/patches/kernel/|" $REPO/patches/kernel/series)
  echo "内核树: $(git log --oneline v$UPV..HEAD | wc -l) 个补丁, HEAD $(git rev-parse --short HEAD)"
else echo "$L 已存在, 跳过"; fi
if [ ! -e $Z ]; then
  T=$K/dl-zfs-$ZFS/zfs-$ZFS.tar.gz; [ -f $T ] || die "没有 $T"
  mkdir -p $Z.tmp; tar --no-same-owner -C $Z.tmp -xf $T; mv $Z.tmp/zfs-$ZFS $Z; rmdir $Z.tmp
  cd $Z; git init -q -b fnos; $G add -Af >/dev/null; $G commit -qm "OpenZFS zfs-$ZFS 官方 release 源码包"; git tag zfs-$ZFS
  $G am -q --committer-date-is-author-date $REPO/patches/zfs/*.patch
  echo "ZFS 树: $(git log --oneline zfs-$ZFS..HEAD | wc -l) 个补丁, HEAD $(git rev-parse --short HEAD)"
else echo "$Z 已存在, 跳过"; fi
own $L $Z
