echo "== uname"; uname -r
echo "== failed units"; systemctl --failed --no-legend | awk '{print $1}'
echo "== dmesg err count"; dmesg -l err,crit,alert,emerg | wc -l
echo "== dmesg err"; dmesg -l err,crit,alert,emerg | sed 's/^\[[^]]*\] //' | sort | uniq -c | sort -rn | head -15
echo "== mdstat"; cat /proc/mdstat
echo "== mounts"; grep -E '^/dev/(md|mapper|vd|sd)|zfs|trimafs' /proc/mounts
echo "== md sysfs"; for m in /sys/block/md*/md; do echo $m: $(cat $m/level $m/array_state $m/bitmap_type 2>/dev/null); ls $m/dfr 2>/dev/null | tr '\n' ' '; echo; done
echo "== trim modules"; lsmod | grep -E 'trim|zfs|spl|btrfs|raid' | awk '{print $1}' | tr '\n' ' '; echo
echo "== vol acl"; for v in /vol*; do ls -la $v | head -5; getfattr -d -m - $v 2>/dev/null | head -8; done
echo "== services"; systemctl is-active trim_main trim_sac smbd nginx 2>/dev/null | tr '\n' ' '; echo
