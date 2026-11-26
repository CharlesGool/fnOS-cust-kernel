cat /sys/block/md0/md/dfr/dfr_enable /sys/block/md0/md/dfr/dfr_timeout /sys/block/md0/md/dfr/dfr_stat 2>&1 | tr '\n' ' '; echo
mdadm /dev/md0 --fail /dev/vdc1 2>&1; sleep 1; mdadm /dev/md0 --remove /dev/vdc1 2>&1
cat /proc/mdstat | grep -A2 md0
head -c 200M /dev/urandom > /vol1/1000/dirA/deg.bin; sync; sha256sum /vol1/1000/dirA/deg.bin | cut -c1-16
t0=$(date +%s); mdadm /dev/md0 --re-add /dev/vdc1 2>&1; sleep 5
for i in $(seq 1 120); do grep -q recovery /proc/mdstat || grep -q resync /proc/mdstat || break; sleep 1; done
echo "resync done in $(( $(date +%s)-t0 ))s"; cat /proc/mdstat | grep -A3 md0
dmesg | grep -iE 'md0|md/raid1|llbitmap|dfr' | tail -8 | cut -c1-150
echo check > /sys/block/md0/md/sync_action; sleep 2
for i in $(seq 1 300); do [ "$(cat /sys/block/md0/md/sync_action)" = idle ] && break; sleep 1; done
echo "mismatch_cnt=$(cat /sys/block/md0/md/mismatch_cnt) array_state=$(cat /sys/block/md0/md/array_state)"
