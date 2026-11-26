#!/bin/bash
# nfstest.sh: fnOS NFS 功能/权限回归测试. 用法(宿主机): ./vm.sh < nfstest.sh | tee nfs-<内核>-<tag>.txt
# 在 VM 里以 root 执行, 全部走 127.0.0.1 回环. 输出无时间戳/随机内容, 可直接 diff.
export LC_ALL=C
W=/tmp/nfst-work          # 工作目录(跑完删除; 放 /tmp 因为 uid 1000 持有者要读)
M=/mnt/nfst                # NFS 挂载根(跑完删除)
EXPORT_FNOS=/fs/1000/nfs   # 飞牛网页配的导出
O=$W/o; E=$W/e; RC=0
mkdir -p $W/out $M; chmod 755 $W

# ---------- 辅助函数 ----------
h16() { sha256sum | cut -c1-16; }
# ru UID 'cmd': 以指定 uid(gid 1001, 清附加组)执行, 结果在 $O $E $RC
ru() {
  local u=$1 c="set -o pipefail; $2"
  if [ "$u" = 0 ]; then timeout 120 bash -c "$c" >$O 2>$E
  else timeout 120 setpriv --reuid=$u --regid=1001 --clear-groups bash -c "$c" >$O 2>$E; fi
  RC=$?
}
res() {
  if [ $RC = 0 ]; then echo "成功"
  elif [ $RC = 124 ]; then echo "失败(超时)"
  else
    local m; m=$(grep -a . $E | tail -n1 | sed 's/.*: //')
    echo "失败(${m:-rc=$RC})"
  fi
}
t() { ru "$1" "$3"; echo "$2: $(res)"; }                 # t UID 项目 命令
# ts UID 项目 文件 期望sha16: 读回并比对 sha256 前 16 位
ts() {
  ru "$1" "sha256sum '$3' | cut -c1-16"
  if [ $RC != 0 ]; then echo "$2: $(res)"
  else local g; g=$(cat $O)
    if [ "$g" = "$4" ]; then echo "$2: 成功(sha256=$g)"; else echo "$2: 失败(sha 不一致 期望=$4 实际=$g)"; fi
  fi
}
hdr() { echo; echo "=== $* ==="; }

H_HELLO=$(printf 'hello\n' | h16)
H_HW=$(printf 'hello\nworld\n' | h16)
H_BIG=$(head -c 4194304 /dev/zero | tr '\0' 'a' | h16)

# A/B: 在目录 $1 里以 uid $2 做 新建/写/追加/读回/改名/删除/删目录
fileops() {
  local dir=$1 u=$2 d=$1/nfst-d$2
  t $u "建目录" "mkdir '$d'"
  t $u "新建并写入" "printf 'hello\n' > '$d/f1'"
  ts $u "读回" "$d/f1" $H_HELLO
  ru 0 "stat -c %U '$d/f1'"; echo "新建文件属主(root 视角): $(cat $O)"
  t $u "追加" "printf 'world\n' >> '$d/f1'"
  ts $u "追加后读回" "$d/f1" $H_HW
  t $u "改名" "mv '$d/f1' '$d/f2'"
  ts $u "改名后读回" "$d/f2" $H_HW
  t $u "旧名已不存在" "test ! -e '$d/f1'"
  t $u "写 4MiB" "head -c 4194304 /dev/zero | tr '\0' 'a' > '$d/big'"
  ts $u "4MiB 读回" "$d/big" $H_BIG
  t $u "删文件 f2" "rm '$d/f2'"
  t $u "删文件 big" "rm '$d/big'"
  t $u "删目录" "rmdir '$d'"
  t $u "目录已不存在" "test ! -e '$d'"
}

# dirB 保护/恢复(通过本地 /vol1 路径以 root 操作)
DB=/vol1/1000/dirB
dirb_save() {
  mkdir -p $W/bk
  cat $DB/f.txt > $W/bk/f.txt
  stat -c '%a %u %g' $DB/f.txt > $W/bk/stat
  getfacl -p $DB/f.txt > $W/bk/acl 2>/dev/null
  stat -c '%a %u %g' $DB > $W/bk/dstat
  getfacl -p $DB > $W/bk/dacl 2>/dev/null
  H_ORIG=$(h16 < $W/bk/f.txt)
}
dirb_state() { # root 本地视角
  echo "dirB/f.txt 状态: $(stat -c 'mode=%a owner=%U size=%s' $DB/f.txt) sha256=$(h16 < $DB/f.txt)"
  echo "dirB 目录条目: $(ls -A $DB | tr '\n' ' ')"
}
dirb_restore() {
  rm -f $DB/nfst-* 2>/dev/null
  read -r m u g < $W/bk/stat
  chmod u+rw $DB/f.txt 2>/dev/null
  cat $W/bk/f.txt > $DB/f.txt 2>/dev/null
  chown $u:$g $DB/f.txt; chmod $m $DB/f.txt
  setfacl --restore=$W/bk/acl 2>/dev/null
  read -r dm du dg < $W/bk/dstat; chown $du:$dg $DB; chmod $dm $DB
  local ok=1
  [ "$(h16 < $DB/f.txt)" = "$H_ORIG" ] || ok=0
  [ "$(stat -c '%a %u %g' $DB/f.txt)" = "$(cat $W/bk/stat)" ] || ok=0
  [ "$(getfacl -p $DB/f.txt 2>/dev/null)" = "$(cat $W/bk/acl)" ] || ok=0
  [ "$(getfacl -p $DB 2>/dev/null)" = "$(cat $W/bk/dacl)" ] || ok=0
  [ "$(stat -c '%a %u %g' $DB)" = "$(cat $W/bk/dstat)" ] || ok=0
  [ -z "$(ls -A $DB | grep -v '^f.txt$')" ] || ok=0
  [ $ok = 1 ] && echo "dirB 恢复核对: 与原样一致" || echo "dirB 恢复核对: 不一致!(内容/模式/ACL/条目有差异)"
}

# dirB 操作: $1=dirB 路径(NFS 挂载或本地) $2=uid
dirbops() {
  local d=$1 u=$2
  t $u "列目录" "ls -A '$d' >/dev/null"
  ru $u "ls -A '$d' | tr '\n' ' '"; echo "目录条目(该 uid 视角): $(res | grep -q ^成功 && cat $O || echo -)"
  t $u "读已有文件 f.txt" "cat '$d/f.txt' >/dev/null"
  ts $u "读已有文件 sha" "$d/f.txt" $H_ORIG
  t $u "覆盖写 f.txt" "printf 'ow\n' > '$d/f.txt'"
  t $u "追加 f.txt" "printf 'ap\n' >> '$d/f.txt'"
  t $u "截断 f.txt" "truncate -s 0 '$d/f.txt'"
  t $u "新建文件" "printf 'n\n' > '$d/nfst-new'"
  t $u "删除新建文件" "rm '$d/nfst-new'"
  t $u "chmod f.txt" "chmod 600 '$d/f.txt'"
  t $u "stat f.txt" "stat '$d/f.txt'"
  dirb_state
}

# 把一组测试的输出存文件并显示
grp() { local n=$1; shift; "$@" > $W/out/$n.txt 2>&1; echo "--- $n"; cat $W/out/$n.txt; }
# 对照: cmpg 名 参照名
cmpg() {
  if diff -q $W/out/$1.txt $W/out/$2.txt >/dev/null; then echo "[对照] $1 vs $2: 完全一致"
  else echo "[对照] $1 vs $2: 有差异(< 为 $1, > 为 $2)"; diff $W/out/$1.txt $W/out/$2.txt | grep '^[<>]'; fi
}

mnt() { # mnt 版本 导出路径 挂载点 [额外选项]
  mkdir -p "$3"
  local opt="vers=$1,noac${4:+,$4}"; [ "${1%%.*}" = 3 ] && opt="$opt,nolock"
  local err; err=$(timeout 60 mount -t nfs -o $opt 127.0.0.1:$2 "$3" 2>&1); local rc=$?
  [ $rc = 0 ] && echo "挂载 $2 -> ${3#$M/} (v$1): 成功" || echo "挂载 $2 -> ${3#$M/} (v$1): 失败(${err##*: })"
  return $rc
}

cleanup() {
  cd /
  for m in $M/*; do mountpoint -q "$m" 2>/dev/null && umount -f "$m" 2>/dev/null; done
  umount /mnt/e4 2>/dev/null
  exportfs -u 127.0.0.1:/vol1/1000 2>/dev/null
  exportfs -u 127.0.0.1:/mnt/e4 2>/dev/null
  rm -f /root/nfst-e4.img
  rm -rf /vol1/1000/dirA/nfst-* /vol1/1000/dirB/nfst-* 2>/dev/null
  rmdir $M/* $M /mnt/e4 2>/dev/null
  rm -rf $W
}
trap cleanup EXIT
rm -rf /vol1/1000/dirA/nfst-* /vol1/1000/dirB/nfst-* 2>/dev/null
dirb_save

hdr "0 环境"
echo "内核: $(uname -r)"
echo "nfs-server: $(systemctl is-active nfs-server)"
echo "nfsd 版本: $(cat /proc/fs/nfsd/versions)"
echo "/etc/exports 有效行:"; grep -v '^#' /etc/exports | grep .
echo "exportfs -v:"; exportfs -v
echo "dirA/dirB 本地: $(stat -c '%n %A %U' /vol1/1000/dirA /vol1/1000/dirB | tr '\n' ';')"
echo "原 dirB/f.txt: $(dirb_state | head -1)"

# ================= A =================
hdr "A 飞牛共享(127.0.0.1:$EXPORT_FNOS)"
mnt 3   $EXPORT_FNOS $M/a3  || true
mnt 4.2 $EXPORT_FNOS $M/a42 || true
for v in a3 a42; do
  for u in 1000 1001; do
    hdr "A $v dirA uid=$u"; grp A-$v-dirA-$u fileops $M/$v/dirA $u
  done
  for u in 1001; do
    hdr "A $v dirB uid=$u"; grp A-$v-dirB-$u dirbops $M/$v/dirB $u; dirb_restore
  done
done
hdr "A 本地对照(不经 NFS, 直接 /vol1)"
for u in 1000 1001; do echo "## 本地 dirA uid=$u"; grp L-dirA-$u fileops /vol1/1000/dirA $u; done
for u in 1001 1000; do echo "## 本地 dirB uid=$u"; grp L-dirB-$u dirbops $DB $u; dirb_restore; done
hdr "A 对照结果"
for v in a3 a42; do
  cmpg A-$v-dirB-1001 L-dirB-1001
  cmpg A-$v-dirB-1001 L-dirB-1000
  cmpg A-$v-dirA-1001 L-dirA-1001
  cmpg A-$v-dirA-1000 L-dirA-1000
  cmpg A-$v-dirA-1001 A-$v-dirA-1000
done
cmpg A-a3-dirB-1001 A-a42-dirB-1001

# ================= B =================
hdr "B 直接导出 trimacl 卷(/vol1/1000, fsid=101, no_root_squash)"
t 0 "exportfs 临时导出" "exportfs -o rw,no_subtree_check,no_root_squash,fsid=101 127.0.0.1:/vol1/1000"
mnt 3 /vol1/1000 $M/b3 || true
for u in 1000 1001; do hdr "B b3 dirA uid=$u"; grp B-b3-dirA-$u fileops $M/b3/dirA $u; done
hdr "B b3 dirB uid=1001"; grp B-b3-dirB-1001 dirbops $M/b3/dirB 1001; dirb_restore
hdr "B b3 dirB uid=1000"; grp B-b3-dirB-1000 dirbops $M/b3/dirB 1000; dirb_restore
hdr "B 对照结果"
cmpg B-b3-dirB-1001 L-dirB-1001
cmpg B-b3-dirB-1000 L-dirB-1000
cmpg B-b3-dirA-1001 L-dirA-1001
cmpg B-b3-dirA-1000 L-dirA-1000
cmpg B-b3-dirB-1001 A-a3-dirB-1001

# ================= C =================
hdr "C 客户端看到的权限位"
ls_stat() { # 目录 -> 相对路径列表的 stat
  (cd "$1" && find . -maxdepth 2 | sort | while read -r p; do stat -c '%A %U %n' "$p"; done)
}
for v in a3 a42; do echo "## C $v ($M/$v, 飞牛导出)"; ls_stat $M/$v; done
echo "## C b3 ($M/b3, 直接导出 /vol1/1000)"; ls_stat $M/b3 | grep -v '\.@#local'
echo "## C 本地 /vol1/1000 对照"; ls_stat /vol1/1000 | grep -v '\.@#local'
echo "## C ext4 loop"
t 0 "建 64M 镜像" "dd if=/dev/zero of=/root/nfst-e4.img bs=1M count=64 status=none && mkfs.ext4 -q -F /root/nfst-e4.img"
mkdir -p /mnt/e4
t 0 "挂载 ext4 loop" "mount -o loop /root/nfst-e4.img /mnt/e4"
ru 0 "cd /mnt/e4 && rm -rf lost+found && printf 'secret\n' > sfile && chown root:root sfile && chmod 0640 sfile && mkdir sdir && chown root:root sdir && chmod 0700 sdir && printf 'x\n' > sdir/inner"
echo "本地 ext4: $(cd /mnt/e4 && stat -c '%A %U %n' sfile sdir | tr '\n' ';')"
t 0 "临时导出 ext4" "exportfs -o rw,no_subtree_check,no_root_squash,fsid=102 127.0.0.1:/mnt/e4"
mnt 3 /mnt/e4 $M/e3 || true
mnt 4.2 /mnt/e4 $M/e42 || true
for v in e3 e42; do
  echo "## C $v"
  (cd $M/$v && stat -c '%A %U %n' sfile sdir)
  for u in 0 1001; do
    echo "# uid=$u 访问"
    t $u "读 sfile" "cat '$M/$v/sfile' >/dev/null"
    t $u "ls sdir" "ls '$M/$v/sdir' >/dev/null"
    t $u "读 sdir/inner" "cat '$M/$v/sdir/inner' >/dev/null"
    t $u "写 sfile" "printf z >> '$M/$v/sfile'"
    t $u "在 sdir 建文件" "touch '$M/$v/sdir/nfst-x'"
  done
done
rm -f /mnt/e4/sdir/nfst-x
# 清理 C 的 ext4
for m in e3 e42; do umount -f $M/$m 2>/dev/null; done
exportfs -u 127.0.0.1:/mnt/e4; exportfs -f
for i in 1 2 3 4 5 6 7 8 9 10; do umount /mnt/e4 2>/dev/null && break; sleep 1; done
rm -f /root/nfst-e4.img
echo "ext4 清理: 导出=$(exportfs -v | grep -c /mnt/e4) 挂载=$(mount | grep -c ' /mnt/e4 ') 镜像=$(ls /root/nfst-e4.img 2>/dev/null | wc -l)"
# 清理 B
umount -f $M/b3; exportfs -u 127.0.0.1:/vol1/1000
echo "B 清理: 导出=$(exportfs -v | grep -c '/vol1/1000') 挂载=$(mount | grep -c ' /mnt/nfst/b3 ')"

# ================= D =================
hdr "D 缓存清空/重启 nfs-server 后照常工作"
dstep() { # dstep 标签: 让持有者执行一轮
  echo "$1" > $W/ctl; cat $W/done >/dev/null
}
for ver in 3 4.2; do
  v=d$ver; base=$M/$v/dirA/nfst-dd; sub=$base/sub
  mkdir -p $M/$v
  opt="vers=$ver"; [ "$ver" = 3 ] && opt="$opt,nolock"
  mount -t nfs -o $opt 127.0.0.1:$EXPORT_FNOS $M/$v || { echo "D v$ver 挂载失败"; continue; }
  echo "## D NFSv$ver (默认缓存选项)"
  ru 1000 "mkdir -p '$sub' && printf 'line1\nline2\nline3\nline4\n' > '$base/f'"
  echo "准备: $(res)"
  rm -f $W/ctl $W/done; mkfifo $W/ctl $W/done; chmod 666 $W/ctl $W/done
  cat > $W/holder.sh <<HOLD
cd '$sub' || exit 1
exec 3<'$base/f'
step() {
  local tag=\$1 l
  IFS= read -r l <&3 && echo "\$tag 已打开文件继续读: 成功(\$l)" || echo "\$tag 已打开文件继续读: 失败(rc=\$?)"
  l=\$(ls -A . 2>&1) && echo "\$tag cwd 内 ls: 成功(\$(echo \$l | tr '\n' ' '))" || echo "\$tag cwd 内 ls: 失败(\${l##*: })"
  l=\$(touch "new-\$tag" 2>&1) && echo "\$tag cwd 内新建: 成功" || echo "\$tag cwd 内新建: 失败(\${l##*: })"
  l=\$(pwd 2>&1) && echo "\$tag pwd: \$(echo \$l | sed 's#.*/mnt/nfst/##')"
}
IFS= read -r l <&3 && echo "基线 读首行: 成功(\$l)"
step base
echo ready
while read -r c <$W/ctl; do
  [ "\$c" = quit ] && { echo end >$W/done; break; }
  step "\$c"
  echo end >$W/done
done
HOLD
  ( setpriv --reuid=1000 --regid=1001 --clear-groups bash $W/holder.sh > $W/hold.out 2>&1 ) &
  HP=$!
  for i in $(seq 1 30); do grep -q '^ready' $W/hold.out 2>/dev/null && break; sleep 1; done
  sync; echo 2 > /proc/sys/vm/drop_caches
  dstep drop
  systemctl restart nfs-server; echo "restart nfs-server: rc=$?"
  echo "restart 后 exportfs 条目数: $(exportfs -v | grep -c .)"
  s=$(date +%s)
  dstep restart
  echo "(restart 后首轮耗时是否超过 30s: $([ $(( $(date +%s) - s )) -gt 30 ] && echo 是 || echo 否))"
  # restart 后再做一次全新操作(新进程): 读/ls/新建
  t 1000 "restart 后新进程读 f" "cat '$base/f' >/dev/null"
  t 1000 "restart 后新进程 ls" "ls '$sub' >/dev/null"
  t 1000 "restart 后新进程新建" "touch '$sub/new-fresh'"
  echo quit > $W/ctl; cat $W/done >/dev/null; wait $HP
  sed -e '/^ready$/d' $W/hold.out
  rm -rf $base
  umount -f $M/$v
done

# ================= E =================
hdr "E /fs 下看到的权限($EXPORT_FNOS)"
echo "## stat -c '%A %n'"
find $EXPORT_FNOS -maxdepth 2 | sort | while read -r p; do stat -c '%A %n' "$p"; done
if command -v getfacl >/dev/null; then
  echo "## getfacl -p"
  find $EXPORT_FNOS -maxdepth 2 | sort | while read -r p; do getfacl -p "$p" 2>&1; done
else echo "(无 getfacl, 跳过)"; fi
echo "## 对应 /vol1/1000 本地 stat -c '%A %n'"
find /vol1/1000/dirA /vol1/1000/dirB | sort | while read -r p; do stat -c '%A %n' "$p"; done

hdr "结束状态"
echo "exportfs -v:"; exportfs -v
echo "nfs-server: $(systemctl is-active nfs-server)"
cleanup
echo "清理后残留: 挂载=$(mount | grep -cE '/mnt/nfst|/mnt/e4') 导出行=$(exportfs -v | grep -c .) loop=$(losetup -a | wc -l) 镜像=$(ls /root/nfst-e4.img 2>/dev/null | wc -l) 工作目录=$(ls -d /tmp/nfst-work /mnt/nfst /mnt/e4 2>/dev/null | wc -l)"
