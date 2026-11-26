set -u
log(){ echo; echo "### $*"; }
H(){ sha256sum "$1" | cut -c1-16; }
waitsync(){ for i in $(seq 1 900); do grep -qE 'recovery|resync|check|reshape' /proc/mdstat || break; sleep 1; done; }
uname -r; mdadm --version 2>&1
wipefs -aq /dev/vdd /dev/vde
truncate -s 20G /root/loop3.img; L3=$(losetup -f --show /root/loop3.img)
log "RAID5 3 盘 + 内部 bitmap"
mdadm --create /dev/md9 --run --level=5 --raid-devices=3 --bitmap=internal /dev/vdd /dev/vde $L3 2>&1 | tail -1
echo 200000 > /proc/sys/dev/raid/speed_limit_min; waitsync; grep -A3 md9 /proc/mdstat
mkfs.ext4 -q -F /dev/md9 && mkdir -p /mnt/r5 && mount /dev/md9 /mnt/r5
head -c 1G /dev/urandom > /mnt/r5/a.bin; sync; A=$(H /mnt/r5/a.bin); echo "a=$A"
log "降级: 拔 vde, 降级写入, 读回"
mdadm /dev/md9 --fail /dev/vde --remove /dev/vde 2>&1
head -c 300M /dev/urandom > /mnt/r5/b.bin; sync; B=$(H /mnt/r5/b.bin); echo 3 > /proc/sys/vm/drop_caches
[ "$(H /mnt/r5/a.bin)" = "$A" ] && echo "降级读 a OK" || echo "降级读 a 不一致!"
log "re-add (bitmap 增量重建)"
t0=$(date +%s); mdadm /dev/md9 --re-add /dev/vde 2>&1; sleep 2; waitsync; echo "重建 $(( $(date +%s)-t0 ))s"; grep -A2 md9 /proc/mdstat
log "check"
echo check > /sys/block/md9/md/sync_action; sleep 2; waitsync; echo "mismatch_cnt=$(cat /sys/block/md9/md/mismatch_cnt)"
log "整盘换新: fail vdd, 清掉再 add (全量重建)"
mdadm /dev/md9 --fail /dev/vdd --remove /dev/vdd 2>&1; wipefs -aq /dev/vdd; mdadm --zero-superblock /dev/vdd 2>/dev/null
t0=$(date +%s); mdadm /dev/md9 --add /dev/vdd 2>&1; sleep 2; waitsync; echo "全量重建 $(( $(date +%s)-t0 ))s"
echo check > /sys/block/md9/md/sync_action; sleep 2; waitsync; echo "mismatch_cnt=$(cat /sys/block/md9/md/mismatch_cnt)"
umount /mnt/r5; e2fsck -fn /dev/md9 2>&1 | tail -1; mount /dev/md9 /mnt/r5
echo 3 > /proc/sys/vm/drop_caches; [ "$(H /mnt/r5/a.bin)" = "$A" ] && [ "$(H /mnt/r5/b.bin)" = "$B" ] && echo "数据校验 OK" || echo "数据校验失败!"
log "llbitmap 在线转换"
cat /sys/block/md9/md/bitmap_type 2>&1
umount /mnt/r5
echo none > /sys/block/md9/md/bitmap_type 2>&1; mdadm --grow /dev/md9 --bitmap=none 2>&1 | tail -1; cat /sys/block/md9/md/bitmap_type 2>&1
mdadm --grow /dev/md9 --bitmap=lockless 2>&1 | tail -2 || true
echo llbitmap > /sys/block/md9/md/bitmap_type 2>&1; cat /sys/block/md9/md/bitmap_type 2>&1
mdadm --detail /dev/md9 | grep -iE "bitmap|state :"
mount /dev/md9 /mnt/r5 && head -c 200M /dev/urandom > /mnt/r5/c.bin; sync; C=$(H /mnt/r5/c.bin)
mdadm /dev/md9 --fail /dev/vde --remove /dev/vde 2>&1 | tail -1; head -c 100M /dev/urandom > /mnt/r5/d.bin; sync
t0=$(date +%s); mdadm /dev/md9 --re-add /dev/vde 2>&1 | tail -1; sleep 2; waitsync; echo "llbitmap 下 re-add 重建 $(( $(date +%s)-t0 ))s"
echo check > /sys/block/md9/md/sync_action; sleep 2; waitsync; echo "mismatch_cnt=$(cat /sys/block/md9/md/mismatch_cnt)"
umount /mnt/r5; mdadm --stop /dev/md9 2>&1; mdadm --assemble /dev/md9 /dev/vdd /dev/vde $L3 2>&1; mount /dev/md9 /mnt/r5
echo 3 > /proc/sys/vm/drop_caches; [ "$(H /mnt/r5/a.bin)$(H /mnt/r5/c.bin)" = "$A$C" ] && echo "停止重组后数据 OK" || echo "停止重组后数据失败!"
umount /mnt/r5; mdadm --stop /dev/md9 2>&1; mdadm --zero-superblock /dev/vdd /dev/vde $L3
dmesg | grep -iE "md9|raid5|llbitmap|bitmap" | grep -iE "error|bug|warn|fail" | head -5
