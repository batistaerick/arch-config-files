# Rise Mode AIO LCD Temperature Display on Arch Linux

This guide restores the Linux setup that sends CPU temperature to the mini display on the Rise Mode Aura Ice Black AIO.

## Hardware detected

The AIO LCD appears as this USB HID device:

```txt
ID aa88:8666 东莞铭研电子科技 温度显示HID设备
```

Equivalent decimal values used by `wcoolmon`:

```txt
0xaa88 = 43656
0x8666 = 34406
```

The working command was:

```bash
sudo ./target/release/wcoolmon -v 43656 -p 34406 -r
```

## 1. Install dependencies

```bash
sudo pacman -S git rust cargo
```

## 2. Build wcoolmon

```bash
cd ~/Development
git clone https://github.com/jgardona/wcoolmon.git
cd wcoolmon
cargo build --release
```

## 3. Test manually

```bash
sudo ./target/release/wcoolmon -v 43656 -p 34406 -r
```

If the AIO display updates with the CPU temperature, it works.

## 4. Install wcoolmon globally

From inside the `wcoolmon` folder:

```bash
sudo cp ./target/release/wcoolmon /usr/local/bin/wcoolmon
```

## 5. Create the systemd service

Create the service file:

```bash
sudo nano /etc/systemd/system/wcoolmon.service
```

Paste:

```ini
[Unit]
Description=Water Cooler CPU Temperature Display
After=multi-user.target

[Service]
Type=simple
ExecStart=/usr/local/bin/wcoolmon -v 43656 -p 34406 -r
Restart=always
RestartSec=2

[Install]
WantedBy=multi-user.target
```

Enable it:

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now wcoolmon.service
```

Check status:

```bash
systemctl status wcoolmon.service
```

View logs:

```bash
journalctl -u wcoolmon.service -f
```

## Backup after it is working

Create a small backup folder:

```bash
mkdir -p ~/Backups/wcoolmon
```

Copy the binary and service:

```bash
cp /usr/local/bin/wcoolmon ~/Backups/wcoolmon/
cp /etc/systemd/system/wcoolmon.service ~/Backups/wcoolmon/
```

Copy this guide there too:

```bash
cp ~/Backups/wcoolmon/wcoolmon-arch-setup.md ~/Backups/wcoolmon/
```

Then back up this folder to cloud storage, external drive, or your dotfiles repo.

## Restore from backup after formatting

If you saved the binary and service file, restore them like this:

```bash
sudo cp ~/Backups/wcoolmon/wcoolmon /usr/local/bin/wcoolmon
sudo chmod +x /usr/local/bin/wcoolmon
sudo cp ~/Backups/wcoolmon/wcoolmon.service /etc/systemd/system/wcoolmon.service
sudo systemctl daemon-reload
sudo systemctl enable --now wcoolmon.service
```

Check:

```bash
systemctl status wcoolmon.service
```

## Useful detection commands

Check USB device:

```bash
lsusb | grep -i aa88
```

Find hidraw device:

```bash
for h in /sys/class/hidraw/hidraw*/device/uevent; do
  echo "==== $h ===="
  cat "$h" | grep -E "HID_ID|HID_NAME|HID_UNIQ"
done
```

Expected entry:

```txt
HID_ID=0003:0000AA88:00008666
HID_NAME=东莞铭研电子科技 温度显示HID设备
```
