#!/bin/bash
# boot.sh [iso] : KVM 启动飞牛测试机; web 127.0.0.1:25666, ssh 127.0.0.1:25622; QMP qmp.sock
R=$(cd "$(dirname "$0")/../.." && pwd); [ -f "$R/.env" ] && { set -a; . "$R/.env"; set +a; }   # 读仓库 .env
Q=${CK_KVM_DIR:?在 .env 里设置 CK_KVM_DIR}   # VM 磁盘/固件/qmp.sock 所在目录(不进仓库)
CD=${1:+-drive file=$1,if=none,id=cd,media=cdrom,readonly=on -device ide-cd,drive=cd,bus=ide.0,bootindex=0}
qemu-system-x86_64 -machine q35 -accel kvm -cpu host -smp 4 -m 6144 \
  -drive if=pflash,format=raw,readonly=on,file=/usr/share/OVMF/OVMF_CODE_4M.fd -drive if=pflash,format=raw,file=$Q/vars.fd \
  -drive file=$Q/sys.qcow2,if=none,id=sys -device virtio-blk-pci,drive=sys,serial=SYS0,bootindex=1 \
  -drive file=$Q/d1.qcow2,if=none,id=d1 -device pcie-root-port,id=rp1,chassis=1,slot=1 -device virtio-blk-pci,drive=d1,serial=DATA1,bus=rp1,id=dev1 \
  -drive file=$Q/d2.qcow2,if=none,id=d2 -device pcie-root-port,id=rp2,chassis=2,slot=2 -device virtio-blk-pci,drive=d2,serial=DATA2,bus=rp2,id=dev2 \
  -drive file=$Q/d3.qcow2,if=none,id=d3 -device pcie-root-port,id=rp3,chassis=3,slot=3 -device virtio-blk-pci,drive=d3,serial=DATA3,bus=rp3,id=dev3 \
  -drive file=$Q/d4.qcow2,if=none,id=d4 -device pcie-root-port,id=rp4,chassis=4,slot=4 -device virtio-blk-pci,drive=d4,serial=DATA4,bus=rp4,id=dev4 \
  $CD \
  -netdev user,id=n0,hostfwd=tcp:127.0.0.1:25666-:5666,hostfwd=tcp:127.0.0.1:25622-:22,hostfwd=tcp:127.0.0.1:25445-:445 -device virtio-net-pci,netdev=n0 \
  -serial file:$Q/serial.log \
  -device qemu-xhci -device usb-tablet -display none -vga std -qmp unix:$Q/qmp.sock,server,nowait -daemonize -pidfile $Q/qemu.pid
