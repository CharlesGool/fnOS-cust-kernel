#!/bin/bash
# cmpdeb.sh <旧.deb> <新.deb>: 比较两个内核包。解包到 $CK_DEPS_DIR/ck/cmp(不要在飞牛存储卷上解包),
# 输出: 控制信息差异、文件清单差异(增/删)、内容不同的文件数(按目录分组)。
# 用途: 重建验证(应只差 vmlinuz/版本串之类)、出新版前看改动面(新上游版本时大部分 .ko 都会变, 看清单增删就够)。
set -euo pipefail
R=$(cd "$(dirname "$0")/.." && pwd); [ -f "$R/.env" ] && { set -a; . "$R/.env"; set +a; }
A=$(realpath "$1"); B=$(realpath "$2"); C=${CK_DEPS_DIR:?在 .env 里设置 CK_DEPS_DIR}/ck/cmp
rm -rf $C; mkdir -p $C/a $C/b
dpkg-deb -R "$A" $C/a; dpkg-deb -R "$B" $C/b
echo "== control 差异"; diff $C/a/DEBIAN/control $C/b/DEBIAN/control || true
for x in postinst prerm postrm; do cmp -s $C/a/DEBIAN/$x $C/b/DEBIAN/$x || echo "DEBIAN/$x 不同"; done
(cd $C/a && find . -path ./DEBIAN -prune -o \( -type f -o -type l \) -print | sort) > $C/la
(cd $C/b && find . -path ./DEBIAN -prune -o \( -type f -o -type l \) -print | sort) > $C/lb
echo "== 文件清单: 旧 $(wc -l < $C/la) 个, 新 $(wc -l < $C/lb) 个"; diff $C/la $C/lb | grep '^[<>]' || echo "(清单相同)"
echo "== 内容不同的文件"
comm -12 $C/la $C/lb | while read -r f; do
  if [ -L "$C/a/$f" ]; then [ "$(readlink "$C/a/$f")" = "$(readlink "$C/b/$f")" ] || echo "$f"; else cmp -s "$C/a/$f" "$C/b/$f" || echo "$f"; fi
done > $C/diff.txt
wc -l < $C/diff.txt; sed 's|/[^/]*$||' $C/diff.txt | sort | uniq -c | sort -rn | awk "NR<=15"
echo "(完整列表 $C/diff.txt)"
echo "== 去掉模块签名、清零 build-id 后再比(签名密钥每次编译随机生成;build-id 随构建目录变)"
python3 -I "$(dirname "$0")/kocmp.py" $C/a $C/b $C/diff.txt
