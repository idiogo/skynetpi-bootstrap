#!/usr/bin/env python3
"""
SkynetPi HID Control - Send keyboard/mouse commands via USB gadget

Usage:
    hid-control.py type "Hello World"   # Type text
    hid-control.py key 0x28             # Press key (Enter=0x28)
    hid-control.py enter                # Press Enter
    hid-control.py tab                  # Press Tab
    hid-control.py esc                  # Press Escape
    hid-control.py spotlight            # Cmd+Space (Mac)
    hid-control.py click                # Mouse left click
    hid-control.py move 50 -30          # Move mouse relative
"""
import struct
import time
import sys

# HID device paths
KEYBOARD = '/dev/hidg0'
MOUSE = '/dev/hidg1'

# Modifier keys
MOD_LCTRL = 0x01
MOD_LSHIFT = 0x02
MOD_LALT = 0x04
MOD_LGUI = 0x08  # Cmd on Mac, Win on Windows
MOD_RCTRL = 0x10
MOD_RSHIFT = 0x20
MOD_RALT = 0x40
MOD_RGUI = 0x80

# Common keys
KEY_ENTER = 0x28
KEY_ESC = 0x29
KEY_BACKSPACE = 0x2A
KEY_TAB = 0x2B
KEY_SPACE = 0x2C

def send_key(keycode, modifier=0, hold=0.05):
    """Send a single key press"""
    with open(KEYBOARD, 'wb') as f:
        # Press
        report = struct.pack('BBBBBBBB', modifier, 0, keycode, 0, 0, 0, 0, 0)
        f.write(report)
        f.flush()
        time.sleep(hold)
        # Release
        report = struct.pack('BBBBBBBB', 0, 0, 0, 0, 0, 0, 0, 0)
        f.write(report)
        f.flush()
    time.sleep(0.05)

def type_text(text):
    """Type ASCII text"""
    char_map = {
        'a':0x04,'b':0x05,'c':0x06,'d':0x07,'e':0x08,'f':0x09,'g':0x0A,
        'h':0x0B,'i':0x0C,'j':0x0D,'k':0x0E,'l':0x0F,'m':0x10,'n':0x11,
        'o':0x12,'p':0x13,'q':0x14,'r':0x15,'s':0x16,'t':0x17,'u':0x18,
        'v':0x19,'w':0x1A,'x':0x1B,'y':0x1C,'z':0x1D,
        '1':0x1E,'2':0x1F,'3':0x20,'4':0x21,'5':0x22,'6':0x23,'7':0x24,
        '8':0x25,'9':0x26,'0':0x27,
        ' ':0x2C,'-':0x2D,'=':0x2E,'[':0x2F,']':0x30,'\\':0x31,
        ';':0x33,"'":0x34,'`':0x35,',':0x36,'.':0x37,'/':0x38,
        '\n':0x28,'\t':0x2B,
    }
    shift_chars = {
        'A':0x04,'B':0x05,'C':0x06,'D':0x07,'E':0x08,'F':0x09,'G':0x0A,
        'H':0x0B,'I':0x0C,'J':0x0D,'K':0x0E,'L':0x0F,'M':0x10,'N':0x11,
        'O':0x12,'P':0x13,'Q':0x14,'R':0x15,'S':0x16,'T':0x17,'U':0x18,
        'V':0x19,'W':0x1A,'X':0x1B,'Y':0x1C,'Z':0x1D,
        '!':0x1E,'@':0x1F,'#':0x20,'$':0x21,'%':0x22,'^':0x23,'&':0x24,
        '*':0x25,'(':0x26,')':0x27,
        '_':0x2D,'+':0x2E,'{':0x2F,'}':0x30,'|':0x31,
        ':':0x33,'"':0x34,'~':0x35,'<':0x36,'>':0x37,'?':0x38,
    }
    
    for char in text:
        if char in char_map:
            send_key(char_map[char])
        elif char in shift_chars:
            send_key(shift_chars[char], MOD_LSHIFT)
        else:
            pass  # Skip unknown chars

def mouse_click(button=1):
    """Mouse click (1=left, 2=right, 4=middle)"""
    with open(MOUSE, 'wb') as f:
        f.write(struct.pack('Bbbb', button, 0, 0, 0))
        f.flush()
        time.sleep(0.05)
        f.write(struct.pack('Bbbb', 0, 0, 0, 0))
        f.flush()
    time.sleep(0.05)

def mouse_move(dx, dy):
    """Move mouse relative"""
    dx = max(-127, min(127, dx))
    dy = max(-127, min(127, dy))
    with open(MOUSE, 'wb') as f:
        f.write(struct.pack('Bbbb', 0, dx, dy, 0))
        f.flush()

if __name__ == '__main__':
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(1)
    
    cmd = sys.argv[1]
    
    if cmd == 'type' and len(sys.argv) > 2:
        type_text(' '.join(sys.argv[2:]))
    elif cmd == 'key' and len(sys.argv) > 2:
        keycode = int(sys.argv[2], 0)
        modifier = int(sys.argv[3], 0) if len(sys.argv) > 3 else 0
        send_key(keycode, modifier)
    elif cmd == 'enter':
        send_key(KEY_ENTER)
    elif cmd == 'tab':
        send_key(KEY_TAB)
    elif cmd == 'esc':
        send_key(KEY_ESC)
    elif cmd == 'space':
        send_key(KEY_SPACE)
    elif cmd == 'backspace':
        send_key(KEY_BACKSPACE)
    elif cmd == 'spotlight':
        send_key(KEY_SPACE, MOD_LGUI)  # Cmd+Space
    elif cmd == 'click':
        mouse_click()
    elif cmd == 'rightclick':
        mouse_click(2)
    elif cmd == 'move' and len(sys.argv) > 3:
        mouse_move(int(sys.argv[2]), int(sys.argv[3]))
    else:
        print(f"Unknown command: {cmd}")
        sys.exit(1)
    
    print(f"Done: {cmd}")
