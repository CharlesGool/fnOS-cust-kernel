K=$(uname -r); echo "uname=$K uptime=$(uptime -p)"; cat /proc/sys/kernel/tainted
dmesg -T | grep -ciE 'Oops|BUG:|Call Trace|WARNING:'
cleanup() { for i in 1 2 3 4 5 6; do for m in $(lsmod | awk 'NR>1{print $1}'); do grep -qx "$m" /tmp/base.lst || rmmod $m 2>/dev/null; done; done; }
lsmod | awk 'NR>1{print $1}' > /tmp/base.lst
dmesg -C
for f in $(find /lib/modules/$K/updates/trim /usr/lib/modules_trim/$K -name '*.ko' ! -path '*/zfs/*' | sort); do
  n=$(basename $f .ko); mn=${n//-/_}
  case $f in */alternatives/*) continue;; esac
  : > /tmp/dm.mark; dmesg -C
  deps=$(modinfo -F depends $f | tr ',' ' ')
  for d in $deps; do modprobe $d 2>/dev/null; done
  if grep -q "/$n.ko" /lib/modules/$K/modules.dep && [ "${f#/lib/modules}" != "$f" ]; then via=modprobe; out=$(modprobe $n 2>&1); rc=$?
  else via=insmod; out=$(insmod $f 2>&1); rc=$?; fi
  ld=no; lsmod | awk '{print $1}' | grep -qx $mn && ld=yes
  info=$(modinfo -F version $f | head -1)
  dm=$(dmesg | grep -iE 'Unknown symbol|disagrees|version magic|NVRM|Oops|BUG|WARNING|failed|error' | head -3 | tr '\n' '|' | cut -c1-300)
  echo "R|${f#/lib/modules/$K/}|$via|rc=$rc|loaded=$ld|ver=$info|out=$out|dm=$dm"
  cleanup
  lsmod | awk '{print $1}' | grep -qx $mn && echo "  !! $mn not unloadable"
done
echo "dmesg bad since boot: $(dmesg | grep -ciE 'Oops|BUG:|Call Trace')"; cat /proc/sys/kernel/tainted
