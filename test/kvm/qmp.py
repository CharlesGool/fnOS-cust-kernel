#!/usr/bin/python3 -I
"""qmp.py <qmp.sock> shot <out.png> | key <combo>... | click <x> <y> | type <text> | hmp <cmd>
x/y 为截图像素坐标(按当前分辨率换算成 usb-tablet 绝对坐标)。"""
import json, socket, struct, sys, time, zlib, os

sock, cmd, args = sys.argv[1], sys.argv[2], sys.argv[3:]
s = socket.socket(socket.AF_UNIX); s.connect(sock); f = s.makefile('rw')
def rd():
    while True:
        m = json.loads(f.readline())
        if 'event' not in m: return m
def q(ex, **a):
    f.write(json.dumps({'execute': ex, 'arguments': a} if a else {'execute': ex}) + '\n'); f.flush(); return rd()
rd(); q('qmp_capabilities')

def ppm2png(src, dst):
    d = open(src, 'rb').read(); parts = d.split(b'\n', 3); w, h = map(int, parts[1].split()); px = parts[3]
    raw = b''.join(b'\0' + px[y*w*3:(y+1)*w*3] for y in range(h))
    ch = lambda t, b: struct.pack('>I', len(b)) + t + b + struct.pack('>I', zlib.crc32(t + b))
    open(dst, 'wb').write(b'\x89PNG\r\n\x1a\n' + ch(b'IHDR', struct.pack('>IIBBBBB', w, h, 8, 2, 0, 0, 0)) + ch(b'IDAT', zlib.compress(raw)) + ch(b'IEND', b''))
    return w, h

def size():
    tmp = os.path.abspath(sock) + '.ppm'; q('screendump', filename=tmp); time.sleep(0.5)
    d = open(tmp, 'rb').read(64).split(b'\n'); return tuple(map(int, d[1].split()))

if cmd == 'shot':
    args[0] = os.path.abspath(args[0]); tmp = args[0] + '.ppm'; q('screendump', filename=tmp); time.sleep(0.8)
    print(ppm2png(tmp, args[0])); os.unlink(tmp)
elif cmd == 'key':
    for k in args:
        print(q('human-monitor-command', **{'command-line': 'sendkey ' + k})); time.sleep(0.3)
elif cmd == 'type':
    m = {' ': 'spc', '-': 'minus', '.': 'dot', '/': 'slash', '_': 'shift-minus', '@': 'shift-2', '!': 'shift-1', ':': 'shift-semicolon'}
    for c in args[0]:
        k = m.get(c, ('shift-' + c.lower()) if c.isupper() else c)
        q('human-monitor-command', **{'command-line': 'sendkey ' + k}); time.sleep(0.08)
elif cmd == 'click':
    w, h = size(); x, y = int(args[0]), int(args[1])
    ax, ay = x * 32767 // (w - 1), y * 32767 // (h - 1)
    ev = lambda *e: q('input-send-event', events=list(e))
    ev({'type': 'abs', 'data': {'axis': 'x', 'value': ax}}, {'type': 'abs', 'data': {'axis': 'y', 'value': ay}}); time.sleep(0.2)
    ev({'type': 'btn', 'data': {'button': 'left', 'down': True}}); time.sleep(0.1)
    print(ev({'type': 'btn', 'data': {'button': 'left', 'down': False}}))
elif cmd == 'hmp':
    print(q('human-monitor-command', **{'command-line': ' '.join(args)}).get('return', ''))
else:
    sys.exit(__doc__)
