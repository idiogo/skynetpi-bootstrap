# Hardware Setup

Optional hardware for advanced features.

## USB HID Gadget (Control other computers)

Your Pi can act as a USB keyboard + mouse to control other computers.

### 1. Configure boot settings

Edit `/boot/firmware/config.txt`, add under `[all]`:
```ini
dtoverlay=dwc2,dr_mode=peripheral
```

Edit `/boot/firmware/cmdline.txt`, add at the end:
```
modules-load=dwc2,libcomposite
```

### 2. Reboot

```bash
sudo reboot
```

### 3. Run setup script

```bash
sudo ./setup-hid-gadget.sh
```

### 4. Connect to target

Use a **USB-C data cable** (not charge-only!) to connect:
- Pi 5 USB-C port (PWR) → Target computer USB port

### Testing

```bash
# Test keyboard
echo -ne '\x00\x00\x04\x00\x00\x00\x00\x00' | sudo tee /dev/hidg0 > /dev/null
# Should type 'a' on the target

# Test mouse
echo -ne '\x00\x10\x10' | sudo tee /dev/hidg1 > /dev/null
# Should move mouse on the target
```

## HDMI Capture Card

For RAM KVM AI (see and control screens).

### 1. Connect

- HDMI cable from target computer → Capture card
- Capture card USB → Pi USB 3.0 port

### 2. Test

```bash
# Check device
v4l2-ctl --list-devices

# Capture frame
ffmpeg -f v4l2 -video_size 1920x1080 -i /dev/video0 -vframes 1 test.jpg
```

## Full RAM KVM AI Setup

For the complete autonomous agent, install ram-kvm-ai:

```bash
git clone https://github.com/idiogo/ram-kvm-ai.git
cd ram-kvm-ai
pip install -r requirements.txt
```

See: https://github.com/idiogo/ram-kvm-ai
