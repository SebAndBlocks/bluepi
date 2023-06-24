#!/bin/bash

# Step 1: Pairing
echo "Step 1: Pair your iPad with the Raspberry Pi"
echo "Make sure Bluetooth is enabled on both devices."
read -p "Press Enter to continue..."
sudo bluetoothctl <<EOF
discoverable on
EOF

echo "Please go to your iPad and pair it with the Raspberry Pi."
read -p "Press Enter to continue..."

# Step 2: Configure Bluetooth PAN/DUN
echo "Step 2: Configuring Bluetooth PAN/DUN on Raspberry Pi"
sudo apt-get update
sudo apt-get install bluez bluez-tools dnsmasq -y

sudo tee /etc/systemd/network/pan0.netdev <<EOF
[NetDev]
Name=pan0
Kind=bridge
EOF

sudo tee /etc/systemd/network/pan0.network <<EOF
[Match]
Name=pan0

[Network]
Address=192.168.12.1/24
DHCPServer=yes
EOF

sudo systemctl restart systemd-networkd
sudo systemctl enable systemd-networkd

sudo sed -i 's/#interface=lo,eth0/interface=pan0/g' /etc/dnsmasq.conf
sudo sed -i 's/^#dhcp-range=192.168.0.0,192.168.0.255,255.255.255.0,1h/dhcp-range=192.168.12.2,192.168.12.254,255.255.255.0,24h/g' /etc/dnsmasq.conf
sudo hciconfig hci0 name "MyBluePi"
sudo systemctl restart bluetooth

# Step 3: Enable IP forwarding and configure NAT
echo "Step 3: Enabling IP forwarding and configuring NAT"
sudo sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/g' /etc/sysctl.conf
sudo sysctl -p

sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
sudo iptables -A FORWARD -i eth0 -o pan0 -m state --state RELATED,ESTABLISHED -j ACCEPT
sudo iptables -A FORWARD -i pan0 -o eth0 -j ACCEPT

sudo sh -c "iptables-save > /etc/iptables.ipv4.nat"

sudo sed -i '/exit 0/d' /etc/rc.local
sudo tee -a /etc/rc.local <<EOF
iptables-restore < /etc/iptables.ipv4.nat
exit 0
EOF

# Step 4: Configure PIN authentication
echo "Step 4: Configure PIN authentication"
read -p "Enter a 4-6 digit PIN for pairing: " PIN

sudo tee /etc/bluetooth/pin.conf <<EOF
$PIN
EOF

sudo sed -i 's/#auth/passkey-agent = /usr/bin/passkey-agent/g' /etc/bluetooth/main.conf
sudo systemctl restart bluetooth

# Step 5: Instructions
echo "Step 5: Instructions"
echo "Please go to your iPad and connect to the Raspberry Pi's Bluetooth PAN/DUN network."
echo "When prompted, enter the PIN you set on the Raspberry Pi."
echo "The Raspberry Pi's IP address is 192.168.12.1, and other devices will be assigned IP addresses in the range 192.168.12.2 to 192.168.12.254."
echo "The devices connected over PAN should now have access to the internet through the Raspberry Pi's internet connection."

# Step 6: The Portal
echo "Step 6: The Portal"
echo "When Connected to the Pi over bluetooth, You can connect to the Pi's website at 192.168.12.1:80 to manage the device"
echo "As a restart is required, you Pi will finalise setup and then restart as BluePi"
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
WorkingDirectory=/path/to/
StandardOutput=inherit
StandardError=inherit
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF
sudo systemctl enable device_manager.service
echo "BluePi Setup Finished! Your Pi will now reboot."
sudo reboot
