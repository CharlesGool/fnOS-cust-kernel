#!/bin/bash
# dfrtest.sh: 热拔 DATA2(dev2) -> 离线时写数据 -> 原盘插回, 看 DFR 能否免重建恢复
R=$(cd "$(dirname "$0")/../.." && pwd); [ -f "$R/.env" ] && { set -a; . "$R/.env"; set +a; }   # 读仓库 .env
T=$(cd "$(dirname "$0")" && pwd); cd "${CK_KVM_DIR:?在 .env 里设置 CK_KVM_DIR}"
H() { python3 -I "$T/qmp.py" qmp.sock hmp "$1"; }
W() { python3 -c "import time; time.sleep($1)"; }
G() { "$T/vm.sh"; }
echo "== 拔盘前"; G <<'X'
uname -r; dd if=/dev/urandom of=/vol1/dfr-a bs=1M count=50 status=none; sync; sha256sum /vol1/dfr-a | cut -c1-16
cat /proc/mdstat | sed -n 2,4p; dmesg -c >/dev/null
X
echo "== device_del dev2"; H 'device_del dev2'; W 4
G <<'X'
dd if=/dev/urandom of=/vol1/dfr-b bs=1M count=50 status=none; sync; sha256sum /vol1/dfr-b | cut -c1-16
echo "-- 拔出 4s 后"; cat /proc/mdstat | sed -n 2,4p; grep . /sys/block/md0/md/dfr/dfr_stat; ls /sys/block | grep vd | tr '\n' ' '; echo
X
echo "== 插回"; H "drive_add 0 file=$CK_KVM_DIR/d2.qcow2,if=none,id=d2"; H 'device_add virtio-blk-pci,drive=d2,serial=DATA2,bus=rp2,id=dev2'
for t in 3 15; do W $t; echo "-- 插回后 +${t}s"; G <<'X'
cat /proc/mdstat | sed -n 2,4p; grep . /sys/block/md0/md/dfr/dfr_stat; for d in /sys/block/vd*; do printf "%s=%s " $(basename $d) $(cat $d/serial); done; echo
X
done
echo "== dmesg"; G <<'X'
dmesg | grep -v trim-mounts-hash | tail -25
X
