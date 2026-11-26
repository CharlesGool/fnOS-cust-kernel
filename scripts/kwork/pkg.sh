#!/bin/bash
# pkg.sh: 把编好的内核 + 模块 + ZFS + 外置模块打成 linux-image-$KREL_$VERSION_amd64.deb, 输出到 $W/out/
# 布局同飞牛(见 doc/DESIGN.md 的设计约束): 外置模块不压缩、strip --strip-debug;
# updates/trim/<名>/*.ko 进 /lib/modules; modules_trim/<名>/*.ko 放 /usr/lib/modules_trim/<内核版本>/;
# updates/trim/alternatives -> /usr/lib/modules_trim/<内核版本>/alternatives(绝对路径), alternatives/nvidia-gpu 默认指闭源版, 没编闭源版就指开源版
. "$(dirname "$0")/common.sh"
EXT=$W/extmod; P=$W/pkg; R=$P/root; OUT=$W/out
[ "$(cat $L/include/config/kernel.release)" = $KREL ] || die "kernel.release 不是 $KREL"
for f in $W/zfs-build/module/zfs.ko $W/zfs-build/module/spl.ko; do [ -f $f ] || die "缺 $f, 先 ck.sh zfs"; done
[ -d $EXT/updates/trim ] && [ -d $EXT/modules_trim ] || die "缺外置模块, 先 ck.sh extmod"
rm -rf $P; mkdir -p $P
kmake INSTALL_MOD_PATH=$R INSTALL_MOD_STRIP=1 modules_install > $LOGS/modules_install.log 2>&1 || { tail -20 $LOGS/modules_install.log; die "modules_install 失败"; }
rm -f $R/lib/modules/$KREL/build $R/lib/modules/$KREL/source
mkdir -p $R/boot $R/lib/modules/$KREL/updates/trim/zfs $R/DEBIAN
cp $L/arch/x86/boot/bzImage $R/boot/vmlinuz-$KREL; cp $L/System.map $R/boot/System.map-$KREL; cp $L/.config $R/boot/config-$KREL
for m in spl zfs; do strip --strip-debug -o $R/lib/modules/$KREL/updates/trim/zfs/$m.ko $W/zfs-build/module/$m.ko; done
MT=$R/usr/lib/modules_trim/$KREL
mkdir -p $MT/alternatives
for d in $EXT/updates/trim/*/; do n=$(basename $d); mkdir -p $R/lib/modules/$KREL/updates/trim/$n; for f in $d*.ko; do strip --strip-debug -o $R/lib/modules/$KREL/updates/trim/$n/$(basename $f) $f; done; done
for d in $EXT/modules_trim/*/; do n=$(basename $d); mkdir -p $MT/$n; for f in $d*.ko; do strip --strip-debug -o $MT/$n/$(basename $f) $f; done; done
NVD=nvidia-gpu-proprietary; [ -d $MT/$NVD ] || NVD=nvidia-gpu-open
ln -s ../$NVD $MT/alternatives/nvidia-gpu
ln -s /usr/lib/modules_trim/$KREL/alternatives $R/lib/modules/$KREL/updates/trim/alternatives
depmod -b $R $KREL 2>&1 | grep -v 'alternatives' || true   # alternatives 是绝对链接, 打包根里解析不到, 无害
REV=$(git -C $L rev-parse --short HEAD)
cat > $R/DEBIAN/control <<CTL
Package: linux-image-$KREL
Version: $VERSION
Architecture: amd64
Maintainer: kcmp <kcmp@localhost>
Section: kernel
Priority: optional
Description: fnOS-cust-kernel $KREL ($VERSION, git $REV)
 官方 $UPV + 还原的飞牛 trimacl/md/btrfs/ZFS 等补丁, 含 spl/zfs $ZFS 模块 + 外置模块(updates/trim 与 /usr/lib/modules_trim)。
CTL
printf '#!/bin/sh\nset -e\ndepmod -a %s\ncommand -v update-initramfs >/dev/null && update-initramfs -c -k %s\ncommand -v update-grub >/dev/null && update-grub\nexit 0\n' $KREL $KREL > $R/DEBIAN/postinst
printf '#!/bin/sh\ncommand -v update-initramfs >/dev/null && update-initramfs -d -k %s || true\nexit 0\n' $KREL > $R/DEBIAN/prerm
printf '#!/bin/sh\ncommand -v update-grub >/dev/null && update-grub || true\nexit 0\n' > $R/DEBIAN/postrm
chmod -R u=rwX,go=rX $R; chmod 755 $R/DEBIAN/postinst $R/DEBIAN/prerm $R/DEBIAN/postrm
mkdir -p $OUT; D=$OUT/linux-image-${KREL}_${VERSION}_amd64.deb; rm -f $D
dpkg-deb --root-owner-group -Zxz -b $R $D >/dev/null
# 构建信息: 各源码树的提交, 供发布时写进 releases/<版本>/BUILDINFO
{ echo "version=$VERSION"; echo "kernel=$(git -C $L rev-parse HEAD) ($(git -C $L describe --tags))"
  echo "zfs=$(git -C $Z rev-parse HEAD) ($(git -C $Z describe --tags))"
  echo "gcc=$(gcc --version | head -1)"; echo "pahole=$(pahole --version)"; echo "built=$(date -u +%FT%TZ)"
  echo "extmod:"; grep -v '^#' $REPO/patches/extmod/MANIFEST.tsv | awk -F'\t' '{print "  "$1" "$4}'; echo "nvidia-gpu=$NVD"
  echo "sha256=$(sha256sum $D | cut -d' ' -f1)"; } > $OUT/BUILDINFO-$VERSION
own $P $OUT; cat $OUT/BUILDINFO-$VERSION; echo "PKG-OK $D"
