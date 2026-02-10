#!/usr/bin/env python3
"""Fast iPhone navigation via HID"""
import struct
import time
import sys

HIDG1 = '/dev/hidg1'

def move(dx, dy):
    with open(HIDG1, 'wb') as f:
        f.write(struct.pack('Bbb', 0, max(-127,min(127,dx)), max(-127,min(127,dy))) + b'\x00')
        f.flush()
    time.sleep(0.008)

def click():
    with open(HIDG1, 'wb') as f:
        f.write(struct.pack('Bbb', 1, 0, 0) + b'\x00')
        f.flush()
        time.sleep(0.03)
        f.write(struct.pack('Bbb', 0, 0, 0) + b'\x00')
        f.flush()
    time.sleep(0.1)

def reset():
    """Fast reset to top-left corner"""
    for _ in range(40):
        move(-127, -127)
    time.sleep(0.15)

def goto(x, y):
    """Move to position (calibrated for slow tracking speed)"""
    # ~2.2 units per pixel
    units_x = int(x * 2.2)
    units_y = int(y * 2.2)
    
    while units_x > 0 or units_y > 0:
        dx = min(127, units_x)
        dy = min(127, units_y)
        move(dx, dy)
        units_x -= dx
        units_y -= dy
    time.sleep(0.1)

# Positions (pixels from top-left)
POS = {
    'buscar': (165, 70),
    'shop': (230, 700),
    'home': (45, 700),
    'voltar': (25, 55),
    'cartao': (100, 700),
    'menu': (295, 700),
}

if __name__ == '__main__':
    if len(sys.argv) < 2:
        print("Uso: iphone-fast.py <cmd> [args]")
        print("Cmds: reset, click, goto X Y, tap NOME")
        print("Nomes:", list(POS.keys()))
        sys.exit(1)
    
    cmd = sys.argv[1]
    
    if cmd == 'reset':
        reset()
        print("Reset OK")
    elif cmd == 'click':
        click()
        print("Click OK")
    elif cmd == 'goto' and len(sys.argv) >= 4:
        reset()
        goto(int(sys.argv[2]), int(sys.argv[3]))
        print(f"Goto {sys.argv[2]},{sys.argv[3]} OK")
    elif cmd == 'tap' and len(sys.argv) >= 3:
        name = sys.argv[2]
        if name in POS:
            reset()
            goto(*POS[name])
            click()
            print(f"Tap {name} OK")
        else:
            print(f"Posição desconhecida: {name}")
    else:
        print(f"Comando inválido: {cmd}")
