#!/bin/bash
sudo echo "dtoverlay=dwc2" | sudo tee -a /boot/config.txt
sudo echo "dwc2" | sudo tee -a /etc/modules
sudo echo "libcomposite" | sudo tee -a /etc/modules

sudo touch /usr/bin/gadget_usb
sudo chmod +x /usr/bin/gadget_usb
#sudo nano /usr/bin/gadget_usb

sudo cat > /usr/bin/gadget_usb << EOF
#!/bin/bash
cd /sys/kernel/config/usb_gadget/
mkdir -p gdagetusb
cd gadgetusb
echo 0x1d6b > idVendor # Linux Foundation
echo 0x0104 > idProduct # Multifunction Composite Gadget
echo 0x0100 > bcdDevice # v1.0.0
echo 0x0200 > bcdUSB # USB2
mkdir -p strings/0x409
echo "fedcba9876543210" > strings/0x409/serialnumber
echo "Stivi" > strings/0x409/manufacturer
echo "Stivis_Gadget" > strings/0x409/product
mkdir -p configs/c.1/strings/0x409
echo "Config 1: ECM network" > configs/c.1/strings/0x409/configuration
echo 250 > configs/c.1/MaxPower
# Add functions here
# see gadget configurations below
# End functions
ls /sys/class/udc > UDC
##### ETHERNET ADAPTER ##########################################
# Add functions here
mkdir -p functions/ecm.usb0
# first byte of address must be even
HOST="48:6f:73:74:50:43" # "HostPC"
SELF="42:61:64:55:53:42" # "BadUSB"
echo $HOST > functions/ecm.usb0/host_addr
echo $SELF > functions/ecm.usb0/dev_addr
ln -s functions/ecm.usb0 configs/c.1/
# End functions
ls /sys/class/udc > UDC
#put this at the very end of the file:
ifconfig usb0 192.168.2.10 netmask 255.255.255.0 up
route add -net default gw 192.168.2.1
EOF

sudo cat > /etc/network/interfaces << EOF
# interfaces(5) file used by ifup(8) and ifdown(8)

# Please note that this file is written to be used with dhcpcd
# For static IP, consult /etc/dhcpcd.conf and 'man dhcpcd.conf'

# Include files from /etc/network/interfaces.d:
source-directory /etc/network/interfaces.d

allow-hotplug usb0
auto lo usb0

auto lo
iface lo inet loopback

iface eth0 inet manual

allow-hotplug wlan0
iface wlan0 inet manual
    wpa-conf /etc/wpa_supplicant/wpa_supplicant.conf

allow-hotplug wlan1
iface wlan1 inet manual
    wpa-conf /etc/wpa_supplicant/wpa_supplicant.conf

#auto usb0
iface usb0 inet static
address 192.168.2.10
netmask 255.255.255.0
broadcast 192.168.2.255
gateway 192.168.2.1
dns-nameservers 8.8.8.8 8.8.4.4
EOF
