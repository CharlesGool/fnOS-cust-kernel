S="smbclient -m SMB3 //127.0.0.1"
# 需要在 VM 里有环境变量 VM_PASS(admintest)、U1_PASS(u1); 用法: { echo "VM_PASS=...; U1_PASS=..."; cat smbtest.sh; } | ./vm.sh
cd /tmp && head -c 100M /dev/urandom > big.bin && sha256sum big.bin | cut -c1-16
echo "== admin put/get dirA"; $S/dirA -U admintest%"$VM_PASS" -c 'put big.bin; get big.bin big2.bin' 2>&1 | grep -iE 'putting|getting|NT_STATUS' | sed 's/(.*average/(avg/'
sha256sum big2.bin /vol1/1000/dirA/big.bin | cut -c1-16
echo "== u1 dirB read/write"; echo x > small.txt
$S/dirB -U u1%"$U1_PASS" -c 'ls; get f.txt f_u1.txt; put small.txt' 2>&1 | grep -E 'f.txt|NT_STATUS|putting|getting' | head
echo "== u1 dirA (everyone full via chmod)"; $S/dirA -U u1%"$U1_PASS" -c 'put small.txt u1small.txt' 2>&1 | grep -E 'NT_STATUS|putting'
echo "== admin delete via SMB"; $S/dirA -U admintest%"$VM_PASS" -c 'del big.bin' 2>&1 | grep NT_STATUS; ls /vol1/1000/dirA
echo "== trash"; find /vol1 -path '*trash*' -maxdepth 6 2>/dev/null | head; find /vol1 -name big.bin 2>/dev/null
journalctl -b --no-pager -n 400 2>/dev/null | grep -iE 'trash|recycle' | tail -5
rm -f big.bin big2.bin small.txt f_u1.txt
