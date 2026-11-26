# 由各步骤 source, 在编译容器里运行。K = 依赖目录在容器里的路径(ck.sh 传入 CK_K)
set -euo pipefail
K=${CK_K:-/k}
REPO=$K/ck/repo                      # ck.sh 每次把仓库(不含 .local/releases/test)同步到这里
. $REPO/config/versions.conf
VERSION=$(cat $REPO/config/VERSION)         # 如 6.18.65-3
UPV=${VERSION%-*}                    # 上游版本 6.18.65
KREL=$UPV$LOCALVER                   # 内核版本串 6.18.65.c1186-trim
W=$K/ck                              # 工作区
L=$W/linux                           # 内核 git 树(bootstrap 生成)
Z=$W/zfs                             # ZFS git 树
LOGS=$W/logs; mkdir -p $LOGS
# 飞牛的构建路径: 外置模块在这下面编, 让 __FILE__ 字符串和飞牛一致(还原阶段为了逐函数比对)
J=/var/jenkins_home/workspace/kernel-build/modules_integration/build
KS=/var/jenkins_home/workspace/kernel-build/kernel-source/patched_source/linux-$UPV
KJOBS=${KJOBS:-$(nproc)}
# 树归 uid 1000(主机上的构建用户), 容器里是 root: 让 git 不报 dubious ownership
export GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=safe.directory GIT_CONFIG_VALUE_0='*'
# 内核 make 通用参数(和飞牛一致的构建者信息; 时间戳固定为 HEAD 提交时间, 便于重现)
kmake(){ make -C $L -j$KJOBS EXTRAVERSION=$LOCALVER LOCALVERSION= \
  KBUILD_BUILD_USER=devops KBUILD_BUILD_HOST=fnnas.com KBUILD_BUILD_VERSION=1186 \
  KBUILD_BUILD_TIMESTAMP="$(git -C $L log -1 --format=%cd --date=rfc)" KBUILD_MODPOST_WARN=1 "$@"; }
own(){ chown -R 1000:1000 "$@" 2>/dev/null || true; }   # 让主机上的构建用户能直接用 git
die(){ echo "错误: $*" >&2; exit 1; }
