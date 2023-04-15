# WebInterface-OnBoot

> bash-hack branch

This simple program will convince the ReMarkable Tablet to start the web interface after booting without the usb cord being plugged in. It can then be reached internally at 10.11.99.1:80 without the usb cord.


## Xochitl Version Compatibility

Tested from v1.9 to v3.3.2-beta on rM1

- ✅ <= v2.14
- ✅ >= v2.15 - Requires simple binary hack, see below

### Type the following commands after ssh'ing into the ReMarkable Tablet


## Install

`wget https://raw.githubusercontent.com/rM-self-serve/webinterface-onboot/bash-hack/install-webint-ob.sh && bash install-webint-ob.sh`

## Remove

`wget https://raw.githubusercontent.com/rM-self-serve/webinterface-onboot/bash-hack/remove-webint-ob.sh && bash remove-webint-ob.sh`

## Use

To use the application, run:

- `systemctl enable --now webinterface-onboot`

Each time webinterface-onboot is enabled, the web-interface setting  will need to be enabled within the settings menu via a cord sometime between when the device was turned on and before it is turned off. After that, the web interface will be running and internally accessible on 10.11.99.1:80 every time the device is started.


## How Does it Work?

If the field 'WebInterfaceEnabled' is set to 'true' in /etc/remarkable.conf, xochitl will see if the 'usb0' network interface has an ip address and run the web-interface website on that ip address if so.

Thus, before xochitl starts:
- set WebInterfaceEnabled=true in /etc/remarkable.conf
- set the usb0 interface ip address to 10.11.99.1/32

The actual web-interface website will continue running on 10.11.99.1:80 even if the usb0 interface does not have the 10.11.99.1 ip address. Disconnecting the usb cord will automatically remove the 10.11.99.1 ip from the usb0 interface, so this program runs in an infinite loop and will ensure the ip stays set.


## Binary Hack for >= 2.15

> :warning: Not tested on the Remarkable Tablet 2

The provided functions to apply/revert the hack will first create a backup of xochitl, then a temporary file in which the strings of the binary are changed. If the temporary file is successfully converted, it will replace the xochitl binary in /usr/bin/.

### Apply Hack

This will only need to be done once unless you upgrade.

- `webinterface-onboot --apply-hack` 

### Revert Hack

Try to restore from backup or reverse hack.

- `webinterface-onboot --revert-hack` 

### Info

All the hack does to the xochitl binary:

 - change the string 'usb0' to 'usbF'
 - change the string 'usb1' to 'usb0'

The strings 'usb0' and 'usb1' appear only to be used when deciding on which network interface the web-interface website will be started on. 

Without the hack, xochitl will check to see that the 'usb0' interface has an ip address and is connected to a device in order to start the web-interface. If not it will fallback to the 'usb1' interface, but then only check for an ip address in order to start the web-interface.

If the interface name string, i.e. 'usb0', is changed in the binary, xochitl will look for a network interface with that new name instead. Since webinterface-onboot ensures that the 'usb0' interface always has an ip address, we can change the 'usb1' string to 'usb0' so that the 'usb0' interface is the fallback and only needs an ip for the web-interface to start on it. I am not quite sure of the function of the 'usb1' interface, so I changed the inital occurance of 'usb0' to 'usbF', so that xochitl can not find the network interface and will always fallback to 'usb0'. It may be wiser to leave the intial occurance of 'usb0' as 'usb0'.

