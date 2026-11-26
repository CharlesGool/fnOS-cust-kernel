#!/bin/bash
# extmod.sh [名字...]: 编外置内核模块(非 ZFS), 不给名字就全部编。产物 -> $W/extmod/{updates/trim,modules_trim}/...
# 源码在 $K/extsrc/<目录>(各自是 git, 本地改动 = 作者 kcmp 的提交, 导出在仓库 patches/extmod/);
# 编之前核对 HEAD 和 patches/extmod/MANIFEST.tsv 一致, 不一致就停(改了模块要先 ck.sh export)。
# 编译前 rsync 到 $W/extbuild/<名字>, 并把飞牛的构建路径 $J/<名字> 软链到这里, 让 __FILE__ 和飞牛一致;
# 内核头文件里的 __FILE__ 用 -fmacro-prefix-map 改写成飞牛的 .../patched_source/linux-<版本>。
# 环境变量: KJOBS, NOCLEAN=1(不清旧产物)。加新模块: 在下面 case 里加一段, 并加进 ALL。
. "$(dirname "$0")/common.sh"; set +u
ALL="r8101 r8125 r8126 r8127 r8168 r8169 r8152 it87 nft_fullcone mst_pci mst_pciconf nvidia-gpu-open nvidia-gpu-proprietary rtw88 rtw89 aic8800-sdio aic8800-usb aic_btusb rtl8852bs amdxdna seekwave-swt6621s drm-cx4 rtl8733bu"
if [ $# = 0 ]; then for n in $ALL; do bash "$0" $n || exit 1; done; echo "EXTMOD-ALL-OK"; exit 0; fi
[ $# -gt 1 ] && { for n in "$@"; do bash "$0" $n || exit 1; done; exit 0; }
NAME=$1
K=$L
OUTD=$W/extmod
BASE=$W/extbuild
MAKEARGS=""        # 额外的 make 变量(覆盖厂商 Makefile 里的开关)
MODDIR=.           # 源码里放 Kbuild/Makefile 的子目录
case $NAME in
  # ---- 飞牛 modules_trim 下的 Realtek 厂商网卡驱动 ----
  r8101) SRC=$K/extsrc/r8101/src; OBJ=r8101.ko; OUTREL=modules_trim/r8101 ;;
  r8125) SRC=$K/extsrc/r8125/src; OBJ=r8125.ko; OUTREL=modules_trim/r8125
         MAKEARGS="ENABLE_RSS_SUPPORT=y ENABLE_MULTIPLE_TX_QUEUE=y" ;;
  r8126) SRC=$K/extsrc/r8126/src; OBJ=r8126.ko; OUTREL=modules_trim/r8126
         MAKEARGS="ENABLE_RSS_SUPPORT=y ENABLE_MULTIPLE_TX_QUEUE=y" ;;
  r8127) SRC=$K/extsrc/r8127/src; OBJ=r8127.ko; OUTREL=modules_trim/r8127
         MAKEARGS="ENABLE_RSS_SUPPORT=y ENABLE_MULTIPLE_TX_QUEUE=y" ;;
  r8168) SRC=$K/extsrc/r8168/src; OBJ=r8168.ko; OUTREL=modules_trim/r8168
         MAKEARGS="CONFIG_ASPM=n ENABLE_EEE=n CONFIG_DYNAMIC_ASPM=n" ;;  # 飞牛版 aspm/eee_enable/dynamic_aspm 默认 0
  r8169) SRC=$K/extsrc/r8169/src; OBJ=r8169.ko; OUTREL=modules_trim/r8169 ;;
  r8152) SRC=$K/extsrc/r8152; OBJ=r8152.ko; OUTREL=modules_trim/r8152 ;;
  it87)  SRC=$K/extsrc/it87; OBJ=it87.ko; OUTREL=modules_trim/it87 ;;
  # ---- 飞牛 mod/updates/trim 下的模块 ----
  nft_fullcone) SRC=$K/extsrc/nft-fullcone/src; OBJ=nft_fullcone.ko; OUTREL=updates/trim/fullconenat-nft ;;
  mst_pci)     SRC=$K/extsrc/mft/kernel-mft-dkms; MODDIR=mst_backward_compatibility/mst_pci;     OBJ=mst_pci.ko;     OUTREL=updates/trim/mft ;;
  mst_pciconf) SRC=$K/extsrc/mft/kernel-mft-dkms; MODDIR=mst_backward_compatibility/mst_pciconf; OBJ=mst_pciconf.ko; OUTREL=updates/trim/mft ;;
  # ---- 飞牛 modules_trim 下的 NVIDIA 显卡内核模块(5 个 .ko; NV=1 走下面专用流程) ----
  nvidia-gpu-open)        NV=1; SRC=$K/extsrc/nvidia-open-work; MODDIR=kernel-open; OBJ=nvidia.ko; OUTREL=modules_trim/nvidia-gpu-open ;;
  nvidia-gpu-proprietary) NV=1; SRC=$K/extsrc/nvidia-prop-work; MODDIR=.; OBJ=nvidia.ko; OUTREL=modules_trim/nvidia-gpu-proprietary ;;
  # ---- 第 14 步无线批: 多 .ko 模块(MULTI=1: 把 MODDIR 下所有 .ko 都复制到 OUTREL; KEEPGIT=1: 构建目录保留 .git) ----
  rtw88) MULTI=1; SRC=$K/extsrc/rtw88; OBJ=rtw_core.ko; OUTREL=updates/trim/rtw88 ;;
  rtw89) MULTI=1; KEEPGIT=1; SRC=$K/extsrc/rtw89; OBJ=rtw89_core_git.ko; OUTREL=updates/trim/rtw89 ;;
  # aic8800: 一个 SDK 三个目录; SDIO 版(bsp+fdrv)、USB 版(load_fw + fdrv, 飞牛改名 aic8800DC_fdrv)、USB 蓝牙(aic_btusb)
  aic8800-sdio) MULTI=1; SRC=$K/extsrc/aic8800; MODDIR=src/SDIO/driver_fw/driver/aic8800; OBJ=aic8800_fdrv/aic8800_fdrv.ko; OBJS="aic8800_bsp/aic8800_bsp.ko aic8800_fdrv/aic8800_fdrv.ko"; OUTREL=updates/trim/aic8800
                MAKEARGS="CONFIG_AIC_FW_PATH=/lib/firmware/aic8800/sdio CONFIG_SDIO_BT=y" ;;
  aic8800-usb)  MULTI=1; SRC=$K/extsrc/aic8800; MODDIR=src/USB/driver_fw/drivers/aic8800; OBJ=aic8800_fdrv/aic8800DC_fdrv.ko; OBJS="aic_load_fw/aic_load_fw.ko aic8800_fdrv/aic8800DC_fdrv.ko"; OUTREL=updates/trim/aic8800
                MAKEARGS="CONFIG_AIC_FW_PATH=/lib/firmware/aic8800/usb" ;;
  aic_btusb)    SRC=$K/extsrc/aic8800; MODDIR=src/USB/driver_fw/drivers/aic_btusb; OBJ=aic_btusb.ko; OUTREL=updates/trim/aic8800
                MAKEARGS="CONFIG_AIC_FW_PATH=/lib/firmware/aic8800/usb" ;;
  rtl8852bs) SRC=$K/extsrc/rtl8852bs; OBJ=rtl8852bs.ko; OUTREL=updates/trim/rtl8852bs
         MAKEARGS="MODULE_NAME=rtl8852bs CONFIG_RTL8852BS=m CONFIG_PLATFORM_I386_PC=y CONFIG_CONCURRENT_MODE=y" ;;
  # amdxdna: 先用厂商 tools/configure_kernel.sh 对目标内核做特性检测生成 config_kernel.h, 再追加版本串和 AMDXDNA_DEVEL
  amdxdna) SRC=$K/extsrc/amdxdna; MODDIR=drivers/accel/amdxdna; OBJ=amdxdna.ko; OUTREL=updates/trim/amdxdna
         MAKEARGS="OFT_CONFIG_AMDXDNA_PCI=y"
         PRE='KERNEL_SRC=$K OUT=$PWD/config_kernel.h sh ../tools/configure_kernel.sh && printf "#define AMDXDNA_DEVEL 1\n#define MODULE_VER_STR \"2.25.260102.56.release_20260630,88dda53eee336c998abca38c71d5bc79fb3633b8\"\n" >> config_kernel.h' ;;
  # seekwave: retro98boy/swt6621s(DKMS 版), SDIO+USB 两种底层都编; 在仓库根目录 M=.
  seekwave-swt6621s) MULTI=1; SRC=$K/extsrc/seekwave-swt6621s; OBJ=drivers/swt6621s_wifi/swt6621s_wifi.ko
         OBJS="drivers/seekwaveplatform_lite/skw_sdio_lite.ko drivers/seekwaveplatform_lite/skw_usb_lite.ko drivers/swt6621s_wifi/swt6621s_wifi.ko drivers/swtbt4l/skwbt.ko"; OUTREL=updates/trim/seekwave-swt6621s
         MAKEARGS="CONFIG_SEEKWAVE_BSP_DRIVERS=m CONFIG_SKW_NO_CONFIG=y CONFIG_SKW_SDIOHAL=m CONFIG_SKW_USB=m CONFIG_WLAN_VENDOR_SWT6621S=m CONFIG_SKW_BT=m CONFIG_SWT6621S_LOG_DEBUG=y" ;;
  # drm-cx4: 兆芯 cx4 DRM 驱动(AOSC-Tracking/cx4-kernel-dkms 逐版本导入的 DKMS 源码)
  drm-cx4) SRC=$K/extsrc/drm-cx4; OBJ=cx4.ko; OUTREL=updates/trim/drm-cx4; MAKEARGS="CHECK_GCC_VERSION=0" ;;
  # rtl8733bu: 没找到飞牛的 v5.15.12-264 源码, 用 briansune/rtl8733bu-vendor-5.15.12-123(已带 6.18 适配)近似
  rtl8733bu) SRC=$K/extsrc/rtl8733bu; OBJ=rtl8733bu.ko; OUTREL=updates/trim/rtl8733bu
         MAKEARGS="MODULE_NAME=rtl8733bu CONFIG_RTL8733BU=m CONFIG_PLATFORM_I386_PC=y CONFIG_CONCURRENT_MODE=y" ;;
  *) echo "未知模块: $NAME"; exit 1 ;;
esac
[ -d "$SRC" ] || die "源码目录不存在: $SRC"
SD=${SRC#$K/extsrc/}; SD=${SD%%/*}
WANT=$(awk -F'\t' -v d=$SD '$1==d{print $4}' $REPO/patches/extmod/MANIFEST.tsv)
HAVE=$(git -C $K/extsrc/$SD rev-parse --short=12 HEAD)
[ "$WANT" = "$HAVE" ] || die "$SD 的 HEAD 是 $HAVE, MANIFEST 记的是 ${WANT:-无}; 改了模块先 ck.sh export"
B=$BASE/$NAME
mkdir -p $J $B
ln -sfn $B $J/$NAME
[ -n "$NOCLEAN" ] || find $B -name '*.ko' -o -name '*.o' -o -name '.*.cmd' -o -name 'modules.order' -o -name 'Module.symvers' | xargs -r rm -f
rsync -a --delete --exclude=.git --exclude='*.ko' --exclude='*.o' --exclude='.*.cmd' $SRC/ $B/
[ -z "$KEEPGIT" ] || { rm -rf $B/.git; cp -a $SRC/.git $B/.git; }
if [ -n "$NV" ]; then
  # NVIDIA 用自己的顶层 Makefile(SYSSRC/SYSOUT 指内核树), 不是 make -C 内核 M=。
  # CC 里带 -fmacro-prefix-map, 让 src/ 下闭源部分编出来的内核头文件路径也变成飞牛的。
  cd $B
  make modules SYSSRC=$K SYSOUT=$K EXTRAVERSION=.c1186-trim LOCALVERSION= \
       CC="gcc -fmacro-prefix-map=$K=$KS" KCFLAGS="-fmacro-prefix-map=$K=$KS" $MAKEARGS $EXTRA_MAKEARGS -j${KJOBS:-8} > $B.log 2>&1 \
    || { grep -E "error|Error" -B2 -A3 $B.log | head -40; exit 1; }
  for m in nvidia nvidia-modeset nvidia-drm nvidia-uvm nvidia-peermem; do
    [ -f $B/$MODDIR/$m.ko ] || { echo "没有产出 $m.ko"; tail -20 $B.log; exit 1; }
    mkdir -p $OUTD/$OUTREL; cp -f $B/$MODDIR/$m.ko $OUTD/$OUTREL/$m.ko
    echo "$m.ko vermagic: $(modinfo -F vermagic $B/$MODDIR/$m.ko)"
  done
  own $BASE $OUTD
  echo "(树内参考: $(modinfo -F vermagic $L/fs/nfsd/nfsd.ko))"
  echo EXTBUILD-OK $NAME
  exit 0
fi
cd $J/$NAME/$MODDIR
[ -z "$PRE" ] || eval "$PRE" || { echo "PRE 步骤失败"; exit 1; }
make -C $K M=$J/$NAME/$MODDIR EXTRAVERSION=.c1186-trim LOCALVERSION= \
     KCFLAGS="-fmacro-prefix-map=$K=$KS" $MAKEARGS $EXTRA_MAKEARGS -j${KJOBS:-8} modules > $B.log 2>&1 \
  || { grep -E "error|Error" -B2 -A3 $B.log | head -40; exit 1; }
grep -E "warning:" $B.log | grep -v objtool | head -10 || true
KO=$B/$MODDIR/$OBJ
[ -f $KO ] || { echo "没有产出 $KO"; tail -20 $B.log; exit 1; }
if [ -n "$MULTI" ]; then
  mkdir -p $OUTD/$OUTREL
  if [ -n "$OBJS" ]; then for o in $OBJS; do cp -f $B/$MODDIR/$o $OUTD/$OUTREL/$(basename $o); done; else cp -f $B/$MODDIR/*.ko $OUTD/$OUTREL/; fi
  OUT=$KO; echo "多模块产物 -> $OUTD/$OUTREL/"
else
  mkdir -p $OUTD/$OUTREL
  cp -f $KO $OUTD/$OUTREL/$OBJ
  OUT=$OUTD/$OUTREL/$OBJ
fi
own $BASE $OUTD
echo "产物: $OUT"
echo "vermagic: $(modinfo -F vermagic $OUT)   (树内参考: $(modinfo -F vermagic $L/fs/nfsd/nfsd.ko))"
echo EXTBUILD-OK $NAME
