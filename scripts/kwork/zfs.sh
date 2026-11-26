#!/bin/bash
# zfs.sh: 编 spl.ko / zfs.ko(外置模块)。源 $Z(git) -> rsync -> $W/zfs-build,
# 在飞牛同一路径 $J/zfs-$ZFS(软链)下编, 让 __FILE__ 和飞牛一致。
. "$(dirname "$0")/common.sh"
[ -f $L/include/config/kernel.release ] || die "先编内核"
ZB=$W/zfs-build; mkdir -p $J $ZB; ln -sfn $ZB $J/zfs-$ZFS
rsync -a --checksum --exclude=.git $Z/ $ZB/
cd $J/zfs-$ZFS
if [ "${1:-}" = configure ] || [ ! -f zfs_config.h ]; then
  ./configure --with-config=kernel --with-linux=$L --with-linux-obj=$L > $LOGS/zfs-configure.log 2>&1 || { tail -30 $LOGS/zfs-configure.log; die "zfs configure 失败"; }
fi
make -C module -j$KJOBS > $LOGS/zfs.log 2>&1 || { grep -E "error|Error" -A3 $LOGS/zfs.log | head -40; die "zfs 编译失败"; }
ls -la module/zfs.ko module/spl.ko; own $ZB
echo "ZFS-OK $(git -C $Z rev-parse --short HEAD)"
