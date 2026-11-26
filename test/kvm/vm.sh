#!/bin/bash
# vm.sh: 从 stdin 读脚本, 在测试 VM 里以 root 执行
SCRIPT=$(cat)
R=$(cd "$(dirname "$0")/../.." && pwd); [ -f "$R/.env" ] && { set -a; . "$R/.env"; set +a; }   # 读仓库 .env
: "${VM_PASS:?在 .env 里设置 VM_PASS(测试机 admintest 的密码)}"; sshpass -p "$VM_PASS" ssh -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=20 -p 25622 admintest@127.0.0.1 \
  "echo '$VM_PASS' | sudo -S -p '' bash -c $(printf '%q' "$SCRIPT")" 2>&1 | grep -a -v 'Could not chdir'
