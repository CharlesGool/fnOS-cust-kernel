#!/bin/bash
# container.sh: 在全新的 debian:12 容器里装编译依赖, 并从源码装 pahole(ck.sh container 调用)。
# 检查结果: gcc 必须是 Debian 12.2.0-14+deb12u1, pahole 必须是 $PAHOLE(见 doc/DESIGN.md 设计约束 2)。
. "$(dirname "$0")/common.sh"
export DEBIAN_FRONTEND=noninteractive
apt-get update -q
apt-get install -y -q --no-install-recommends bc binutils bison bpftool build-essential ca-certificates cmake cpio \
  curl flex git kmod libdw-dev libelf-dev libssl-dev python3 rsync xz-utils zlib1g-dev zstd
if [ "$(pahole --version 2>/dev/null)" != "$PAHOLE" ]; then
  P=$K/dl-pahole-$PAHOLE
  [ -d $P/.git ] || git clone -q --depth 1 --branch $PAHOLE --recurse-submodules --shallow-submodules \
      https://git.kernel.org/pub/scm/devel/pahole/pahole.git $P
  [ "$(git -C $P rev-parse HEAD)" = "$PAHOLE_COMMIT" ] || die "pahole $PAHOLE 的提交不是 $PAHOLE_COMMIT"
  cmake -S $P -B $P/build -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr >/dev/null
  make -s -C $P/build -j$KJOBS install >/dev/null
fi
G=$(gcc --version | head -1)
[ "$G" = "gcc (Debian 12.2.0-14+deb12u1) 12.2.0" ] || echo "警告: gcc 是 $G, 与发布版不同, 编出的包不能和发布版逐字节比对" >&2
[ "$(pahole --version)" = "$PAHOLE" ] || die "pahole 是 $(pahole --version), 要 $PAHOLE"
echo "$G; pahole $(pahole --version)"; echo CONTAINER-OK
