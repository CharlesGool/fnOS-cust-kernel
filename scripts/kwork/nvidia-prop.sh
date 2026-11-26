#!/bin/bash
# nvidia-prop.sh: 把 NVIDIA-Linux-x86_64-$NVIDIA_PROP.run 里的 kernel/ 目录解到 $K/extsrc/nvidia-prop-work(ck.sh fetch-nvidia 调用)。
# 只用 --extract-only 解包, 不安装驱动。解出的目录用 Git tree 哈希和 NVIDIA_PROP_TREE 核对。
. "$(dirname "$0")/common.sh"
RUN=$K/dl-nvidia-prop/NVIDIA-Linux-x86_64-$NVIDIA_PROP.run; D=$K/extsrc/nvidia-prop-work
[ -f $RUN ] || die "没有 $RUN"
T=$(mktemp -d); trap 'rm -rf $T' EXIT
sh $RUN --extract-only --target $T/x >/dev/null || die "解包失败"
GIT="git --git-dir=$T/g --work-tree=$T/x/kernel"
git init -q --bare $T/g; $GIT add -A; TREE=$($GIT write-tree)
[ "$TREE" = "$NVIDIA_PROP_TREE" ] || die "kernel/ 目录的 tree 哈希是 $TREE, 要 $NVIDIA_PROP_TREE"
rm -rf $D; mkdir -p $K/extsrc; cp -a $T/x/kernel $D
awk -F'\t' '$1=="nvidia-prop-work"{print $4}' $REPO/patches/extmod/MANIFEST.tsv > $D/.ck-rev
own $D; echo "NVIDIA-PROP-OK $D"
