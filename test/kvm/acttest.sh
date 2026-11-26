S=/sys/block/md0/md/sync_action
for a in idle frozen idle check reshape idle; do printf "%-8s -> " $a; timeout 10 bash -c "echo $a > $S" 2>/tmp/e && echo ok || { r=$?; [ $r = 124 ] && echo "卡住(超时)" || sed 's/.*error: //' /tmp/e; }; done
printf "写入测试 -> "; timeout 10 dd if=/dev/urandom of=/vol1/act.bin bs=1M count=20 conv=fsync status=none && echo ok || echo "卡住/失败"
cat /sys/block/md0/md/sync_action /sys/block/md0/md/array_state
printf "repair   -> "; echo repair > $S 2>/tmp/e && echo ok || cat /tmp/e
python3 -c 'import time; time.sleep(15)'; dmesg | grep -E 'md: md0: (repair|check)|md: (repair|check) of' | tail -2; echo "mismatch_cnt=$(cat /sys/block/md0/md/mismatch_cnt)"
