# 最初に以下を実行する。
#   pip install pybluez pyserial

# 使うときは以下を実行する。
#   python tools/bt.py

import bluetooth
import serial.tools.list_ports

devices = []
found = []

print("Bluetooth devices")
for address, name in bluetooth.discover_devices(lookup_names=True):
    print(" ", address, name)
    devices.append((address, name))

print("COM ports")
for port, desc, hwid in serial.tools.list_ports.comports():
    print(" ", port, desc, hwid)
    for address, name in devices:
        if address.replace(":", "") in hwid:
            found.append((port, name))

if found:
    print("found pairs")
    for port, name in found:
        print(" ", port, "<->", name)
else:
    print("no pairs found")
