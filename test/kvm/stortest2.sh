set -u
log(){ echo; echo "### $*"; }
H(){ sha256sum "$1" | cut -c1-16; }
losetup -D 2>/dev/null; wipefs -aq /dev/vdd /dev/vde
log "btrfs raid1 + 快照 + qgroup + scrub + balance"
mkfs.btrfs -q -f -d raid1 -m raid1 /dev/vdd /dev/vde && mkdir -p /mnt/b && mount /dev/vdd /mnt/b
btrfs subvolume create /mnt/b/data >/dev/null; btrfs quota enable /mnt/b; head -c 500M /dev/urandom > /mnt/b/data/a.bin; sync; A=$(H /mnt/b/data/a.bin)
btrfs subvolume snapshot -r /mnt/b/data /mnt/b/snap1 >/dev/null; rm /mnt/b/data/a.bin; head -c 100M /dev/urandom > /mnt/b/data/b.bin; sync
btrfs qgroup show /mnt/b 2>&1 | tail -3
[ "$(H /mnt/b/snap1/a.bin)" = "$A" ] && echo "快照数据 OK" || echo "快照数据失败!"
btrfs qgroup limit 50M /mnt/b/data; head -c 200M /dev/zero > /mnt/b/data/over.bin 2>&1 | tail -1; ls -l /mnt/b/data/over.bin | awk '{print "超限写入大小", $5}'; btrfs qgroup limit none /mnt/b/data; rm -f /mnt/b/data/over.bin
btrfs scrub start -B /mnt/b 2>&1 | grep -iE "error|summary|status" | head -3
btrfs balance start --full-balance /mnt/b 2>&1 | tail -1
btrfs send /mnt/b/snap1 2>/dev/null | btrfs receive /mnt/b/ 2>&1 | tail -1 || true
umount /mnt/b; btrfs check --readonly /dev/vdd 2>&1 | tail -2; mount /dev/vdd /mnt/b; echo 3 > /proc/sys/vm/drop_caches; [ "$(H /mnt/b/snap1/a.bin)" = "$A" ] && echo "重挂后 OK"; umount /mnt/b
log "btrfs 单盘压缩 zstd + defrag"
wipefs -aq /dev/vdd /dev/vde; mkfs.btrfs -q -f /dev/vdd && mount -o compress=zstd:3 /dev/vdd /mnt/b && cp -r /usr/share/doc /mnt/b/ 2>/dev/null; sync; btrfs filesystem defragment -r -czstd /mnt/b >/dev/null 2>&1; echo "defrag rc=$?"; umount /mnt/b
log "ZFS mirror"
wipefs -aq /dev/vdd /dev/vde; zpool create -f -o ashift=12 tp mirror /dev/vdd /dev/vde && zfs set compression=zstd tp
head -c 500M /dev/urandom > /tp/a.bin; zfs snapshot tp@s1; Z=$(H /tp/a.bin)
zfs create tp/rx; zfs send tp@s1 | zfs recv -F tp/rx/copy && [ "$(H /tp/rx/copy/a.bin)" = "$Z" ] && echo "send/recv OK"
zpool scrub -w tp; zpool status tp | grep -E "scan|errors"
zpool offline tp vde; head -c 100M /dev/urandom > /tp/b.bin; zpool online tp vde; sleep 3; zpool wait -t resilver tp; zpool status tp | grep -E "state|scan|errors"
zpool export tp; zpool import tp && echo "export/import OK"; [ "$(H /tp/a.bin)" = "$Z" ] && echo "ZFS 数据 OK"
zfs rewrite -h 2>&1 | head -1
zpool destroy tp; wipefs -aq /dev/vdd /dev/vde
dmesg | tail -400 | grep -iE "btrfs|zfs|spl" | grep -iE "error|bug|warn|fail|oops" | head -5; echo "dmesg 检查完"
