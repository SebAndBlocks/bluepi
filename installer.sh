#!/bin/bash

# Step 1: Pairing
echo "Step 1: Pair your iPad with the Raspberry Pi"
echo "Make sure Bluetooth is enabled on both devices."
sudo apt-get install wget -y
wget https://raw.githubusercontent.com/sebtnt/bluepi/main/bt.txt
sudo bluetoothctl < bt.txt

# Step 2: Configure Bluetooth PAN/DUN
echo "Step 2: Configuring Bluetooth PAN/DUN on Raspberry Pi"
sudo apt-get update
sudo apt-get install bluez bluez-tools dnsmasq -y

# Rest of the script...

# Step 4: Configure PIN authentication
echo "Step 4: Configure PIN authentication"
PIN="1234"
PIN=$(echo -n && read -rs && echo "$REPLY")
echo

echo "PIN SET TO $PIN"
# Rest of the script...

# Step 6: The Portal
echo "Step 6: The Portal"
echo "When Connected to the Pi over Bluetooth, you can connect to the Pi's website at 192.168.12.1:80 to manage the device"
echo "As a restart is required, your Pi will finalize the setup and then restart as BluePi"
sudo apt-get update
sudo apt-get install python3 python3-pip git -y
pip3 install flask
git clone https://github.com/SebTNT/bluepi.git /usr/bluepi
sudo tee /etc/systemd/system/device_manager.service <<EOF
[Unit]
Description=Device Manager
After=network.target

[Service]
ExecStart=/usr/bin/python3 /usr/bluepi/manager/app.py
WorkingDirectory=/usr/bluepi/manager/
StandardOutput=inherit
StandardError=inherit
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF
sudo systemctl enable device_manager.service

# Step 7: Auto start bluetoothctl in discoverable mode
sudo tee /etc/systemd/system/bluetooth-autostart.service <<EOF
[Unit]
Description=Auto Start Bluetooth in Discoverable Mode
After=bluetooth.service

[Service]
ExecStart=/bin/bash -c 'while true; do bluetoothctl discoverable on; sleep 30; done'
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF
sudo systemctl enable bluetooth-autostart.service

echo "BluePi Setup Finished! Your Pi will now reboot."
sudo reboot
