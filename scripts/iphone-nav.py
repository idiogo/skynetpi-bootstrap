#!/usr/bin/env python3
"""iPhone navigation via HID with corner reset"""
import struct
import time
import sys

HIDG1 = '/dev/hidg1'

def move(dx, dy):
    """Move mouse relative"""
    with open(HIDG1, 'wb') as f:
        # Clamp to -127 to 127
        dx = max(-127, min(127, dx))
        dy = max(-127, min(127, dy))
        f.write(struct.pack('Bbb', 0, dx, dy) + b'\x00')
        f.flush()
    time.sleep(0.015)

def click():
    """Click left button"""
    with open(HIDG1, 'wb') as f:
        f.write(struct.pack('Bbb', 1, 0, 0) + b'\x00')  # Button down
        f.flush()
        time.sleep(0.05)
        f.write(struct.pack('Bbb', 0, 0, 0) + b'\x00')  # Button up
        f.flush()
    time.sleep(0.1)

def reset_to_corner():
    """Reset cursor to top-left corner"""
    print("Resetando pro canto superior esquerdo...")
    for _ in range(60):
        move(-127, -127)
    time.sleep(0.2)
    print("Cursor em (0,0)")

def move_to(x, y):
    """Move from corner (0,0) to absolute position"""
    # Move in steps of 100 max
    while x > 0 or y > 0:
        dx = min(100, x)
        dy = min(100, y)
        move(dx, dy)
        x -= dx
        y -= dy
    time.sleep(0.1)

# iPhone screen mapping (approximate, based on HDMI capture)
# Screen area in capture: roughly 560-890 X, 50-780 Y
# iPhone logical resolution ~335 x 730 in the capture
# 
# Key positions (relative to top-left of app):
POSITIONS = {
    'buscar': (170, 70),      # Search bar
    'shop': (235, 700),       # Shop tab
    'home': (45, 700),        # Home tab
    'voltar': (25, 55),       # Back arrow
}

if __name__ == '__main__':
    if len(sys.argv) < 2:
        print("Uso: iphone-nav.py <comando>")
        print("Comandos: reset, buscar, shop, home, voltar, click, pos X Y")
        sys.exit(1)
    
    cmd = sys.argv[1]
    
    if cmd == 'reset':
        reset_to_corner()
    elif cmd == 'click':
        click()
    elif cmd == 'pos' and len(sys.argv) >= 4:
        reset_to_corner()
        x, y = int(sys.argv[2]), int(sys.argv[3])
        print(f"Movendo para ({x}, {y})...")
        move_to(x, y)
    elif cmd in POSITIONS:
        reset_to_corner()
        x, y = POSITIONS[cmd]
        print(f"Indo para {cmd} ({x}, {y})...")
        move_to(x, y)
        time.sleep(0.2)
        click()
    else:
        print(f"Comando desconhecido: {cmd}")
