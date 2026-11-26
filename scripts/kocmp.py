#!/usr/bin/python3 -I
# kocmp.py <旧解包目录> <新解包目录> <文件清单>: 去掉模块签名、清零 build-id 后逐文件比较(cmpdeb.sh 解包后用)
import sys, os, lzma, struct, collections
A, B, L = sys.argv[1], sys.argv[2], sys.argv[3]
MAGIC = b"~Module signature appended~\n"
def body(p):
    d = open(p, 'rb').read()
    if p.endswith('.xz'): d = lzma.decompress(d)
    if d.endswith(MAGIC):
        sig_len = struct.unpack('>I', d[-len(MAGIC)-4:-len(MAGIC)])[0]
        d = d[:-len(MAGIC)-12-sig_len]
    return zero_bid(d)
def zero_bid(d):
    # ELF64: 把 .note.gnu.build-id 段内容清零(build-id 随构建目录变化, 不代表代码不同)
    shoff, = struct.unpack_from('<Q', d, 0x28); shentsize, shnum, shstrndx = struct.unpack_from('<HHH', d, 0x3a)
    def sh(i): return struct.unpack_from('<IIQQQQIIQQ', d, shoff + i*shentsize)
    stroff = sh(shstrndx)[4]; b = bytearray(d)
    for i in range(shnum):
        h = sh(i); n = d[stroff+h[0]:d.index(b'\0', stroff+h[0])]
        if n == b'.note.gnu.build-id': b[h[4]:h[4]+h[5]] = bytes(h[5])
    return bytes(b)
res = collections.Counter(); bad = []
for f in open(L).read().split():
    a, b = os.path.join(A, f), os.path.join(B, f)
    if os.path.islink(a): continue
    if '.ko' in f:
        same = body(a) == body(b); res['ko-same' if same else 'ko-diff'] += 1
    else:
        same = open(a,'rb').read() == open(b,'rb').read(); res['other-same' if same else 'other-diff'] += 1
    if not same: bad.append(f)
print(dict(res)); print('\n'.join(bad[:40]))
