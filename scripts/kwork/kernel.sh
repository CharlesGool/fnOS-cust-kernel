#!/bin/bash
# kernel.sh: 编内核(bzImage + 模块)。配置取仓库 config/config-$KREL; olddefconfig 后若有变化就停下,
# 确认无误后用 ck.sh saveconfig 存回仓库再编(跟进新上游时会遇到)。
. "$(dirname "$0")/common.sh"
[ -d $L/.git ] || die "没有内核树, 先 ck.sh bootstrap"
C=$REPO/config/config-$KREL
[ -f $C ] || { C=$(ls $REPO/config/config-* | sort -V | tail -1); echo "没有 config-$KREL, 用 $(basename $C) 起步"; }
cp $C $L/.config; kmake olddefconfig >/dev/null
cf(){ grep -E '^(CONFIG_|# CONFIG_)' "$1" | grep -v CC_VERSION_TEXT; }   # 只比选项, 不比注释头
if ! diff <(cf $C) <(cf $L/.config) > $LOGS/config-diff.txt; then
  cat $LOGS/config-diff.txt
  [ "${ALLOW_CONFIG_CHANGE:-}" = 1 ] || die "olddefconfig 改了配置(见上), 核对后 ck.sh saveconfig 再编"
fi
kmake bzImage modules > $LOGS/kernel.log 2>&1 || { grep -E 'error|Error' -A3 $LOGS/kernel.log | head -40; die "内核编译失败, 日志 $LOGS/kernel.log"; }
[ "$(cat $L/include/config/kernel.release)" = $KREL ] || die "kernel.release 是 $(cat $L/include/config/kernel.release), 应为 $KREL"
grep -E 'warning:' $LOGS/kernel.log | head -20 || true
own $L; echo "KERNEL-OK $KREL $(git -C $L rev-parse --short HEAD)"
