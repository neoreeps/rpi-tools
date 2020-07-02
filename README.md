# rpi-tools
Raspberry Pi Tools and Things

# setup.sh
This is the basic configuration of a fresh installation.

## prerequisites
```
# flash new raspberry pi os
touch /boot/SSH

# boot pi and login with pi/raspberry
```

## setup
Then copy setup.sh to the pi and execute
```
# sudo ./setup.sh
USAGE: ./setup.sh --name [hostname] --ip [ip] --dns [dns] --passwd --mount --install --reboot

	name	the hostname of this machine
	ip	the new ip address of this machine (set to eth0)
	dns	the dns name server (usually .1 of this subnet)
	passwd	prompts to set root and pi passwds
	mount	updates /etc/fstab and mounts /data
	install	installs packages
	reboot	reboot after install
```
