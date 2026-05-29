# DeepCool AK Series Digital Monitor for Linux

Personal fork of `raghulkrishna/deepcool-ak620-digital-linux` for running the DeepCool AK620 Digital display on Linux.

This version is focused on a systemd-based installation with an isolated Python virtual environment in `/opt/deepcool-ak-series-digital`.

## Tested Setup

- Cooler: DeepCool AK620 Digital
- HID vendor id: `0x3633`
- HID product id: `0x0002`
- Temperature sensor used on my system: `coretemp`
- Service manager: systemd

## Supported Models

- `ak620`
- `ak500s`

## Requirements

- Python 3
- Python venv support
- systemd
- sudo/root access for installing the service

On Debian/Ubuntu-based systems, venv support is usually provided by:

```bash
sudo apt install python3-venv
```

The Python packages are installed automatically into the project venv from `requirements.txt`:

- `hid`
- `psutil`

## Find The Temperature Sensor

Before installing, check which temperature sensors `psutil` can see:

```bash
python3 - <<'PY'
import psutil
print(psutil.sensors_temperatures().keys())
PY
```

On my system the useful sensor is `coretemp`.

## Install

For my AK620 setup:

```bash
./setup.sh ak620 coretemp
```

The installer will:

- copy the application to `/opt/deepcool-ak-series-digital`
- create `/opt/deepcool-ak-series-digital/venv`
- install Python dependencies into that venv
- install systemd units into `/etc/systemd/system`
- enable the main service
- enable the resume restart service
- restart the main service

## Install Options

Usage:

```bash
./setup.sh <model> <sensor> [-dt | --disable-temp] [-du | --disable-utils]
```

Examples:

```bash
./setup.sh ak620 coretemp
./setup.sh ak620 coretemp --disable-utils
./setup.sh ak620 coretemp --disable-temp
./setup.sh ak620 coretemp --disable-temp --disable-utils
```

## Check Service Status

```bash
systemctl status deepcool-ak-series-digital.service
```

Follow logs:

```bash
journalctl -u deepcool-ak-series-digital.service -f
```

Restart manually:

```bash
sudo systemctl restart deepcool-ak-series-digital.service
```

## Uninstall

```bash
sudo systemctl disable --now deepcool-ak-series-digital.service
sudo systemctl disable deepcool-ak-series-digital-restart.service
sudo rm -f /etc/systemd/system/deepcool-ak-series-digital.service
sudo rm -f /etc/systemd/system/deepcool-ak-series-digital-restart.service
sudo rm -rf /opt/deepcool-ak-series-digital
sudo systemctl daemon-reload
```

## Changes In This Fork

- Uses `/usr/bin/python3`/venv instead of relying on `/usr/bin/python`.
- Installs into `/opt/deepcool-ak-series-digital` instead of copying the script to `/usr/bin`.
- Installs local systemd units into `/etc/systemd/system`.
- Adds `requirements.txt` for reproducible dependency installation.
- Handles missing temperature sensor readings without sending invalid data to the HID device.
- Validates supported model names in `setup.sh`.
- Supports using both `--disable-temp` and `--disable-utils` in one install command.

## Credits

- Original project: https://github.com/raghulkrishna/deepcool-ak620-digital-linux
- Related reference: https://github.com/Algorithm0/deepcool-digital-info
