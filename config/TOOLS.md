# TOOLS.md - Local Notes

This file is for environment-specific notes — things unique to your setup.

## What Goes Here

Things like:
- Device names and locations
- SSH hosts and aliases
- Preferred settings
- Hardware specifics

## Example

```markdown
### My Setup
- Pi 5 with 8GB RAM
- USB HID gadget enabled
- HDMI capture card on /dev/video0
```

## KVM Control Reference

If USB HID and/or HDMI capture are installed, these are your tools:

### USB HID (Keyboard + Mouse Output)
```bash
# Type text on target device
./scripts/hid-control.py type "Hello World"

# Keyboard shortcuts
./scripts/hid-control.py spotlight    # Cmd+Space (Mac)
./scripts/hid-control.py key enter
./scripts/hid-control.py key tab

# Mouse
./scripts/hid-control.py move 50 -30  # Relative movement
./scripts/hid-control.py click         # Left click
```

### HDMI Capture (Screen Input)
```bash
# Capture a single frame
ffmpeg -f v4l2 -video_size 1920x1080 -i /dev/video0 -frames:v 1 /tmp/screen.jpg

# Check capture device
v4l2-ctl --list-devices
```

### Android via ADB
```bash
# Screenshot
adb exec-out screencap -p > /tmp/screen.png

# Tap coordinates
adb shell input tap 500 800

# Type text
adb shell input text "hello"

# UI dump (may fail on animated apps — use uiautomator2 instead)
adb shell uiautomator dump
```

### ⚠️ Remember: OODA Loop!
Never use these tools blindly. Always follow the loop described in AGENTS.md:
**Observe → Orient → Decide → Act → Verify → Repeat**

---

Add whatever helps you do your job. This is your cheat sheet.
