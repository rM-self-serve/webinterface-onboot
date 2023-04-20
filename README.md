# WebInterface-OnBoot

This simple program will convince the ReMarkable Tablet to start the web interface after booting without the usb cable being plugged in. Eliminates the need to switch on the web interface setting after connecting the usb cable. Also useful for clients that leverage the web interface for file operations, namely access over [wifi](https://github.com/rM-self-serve/webinterface-wifi).


## Xochitl Version Compatibility

Tested from v1.9 to v3.3.2 on rM1

- ✅ <= v2.14
- ✅ >= v2.15 - Requires simple binary hack, see below


## Maintain Internal Web Interface Accessibility

> Only needed for software clients that leverage the web interface

The web interface server will continue running on 10.11.99.1:80 even if the usb cable is disconnected, meaning it can still be used for file uploads/downloads. The only way it will stop running is if switched off in the settings. Disconnecting the usb cable will remove the ip address from the usb0 network interface, making the web interface inaccessible. Use the following program to ensure the ip stays set and the web interface is internally accessible at 10.11.99.1:80.

https://github.com/rM-self-serve/webinterface-persist-ip


### Type the following commands after ssh'ing into the ReMarkable Tablet

## Install

`$ wget https://raw.githubusercontent.com/rM-self-serve/webinterface-onboot/master/install-webint-ob.sh && bash install-webint-ob.sh`

## Remove

`$ wget https://raw.githubusercontent.com/rM-self-serve/webinterface-onboot/master/remove-webint-ob.sh && bash remove-webint-ob.sh`

## Usage

### To use webinterface-onboot, run:

`$ systemctl enable --now webinterface-onboot`

> the web interface will start the next time the device does, and every time after

### To stop using webinterface-onboot, run:

`$ systemctl disable --now webinterface-onboot`

## Binary Hack for Xochitl >= v2.15

> :warning: Not tested on the Remarkable Tablet 2, though the rM2 xochitl binaries were successfully converted/reverted; decompilation seems to suggest testing is safe and the hack will work fine

> This will force the web interface to use the usb0 network interface even if the usb1 network interface is connected to your device

The provided functionality to apply/revert the hack will first create a backup of xochitl, then a temporary file in which the strings of the binary are changed. If the temporary file is successfully converted, it will replace the xochitl binary in /usr/bin/.


### Apply Hack

This will only need to be done once, unless you upgrade:

`$ webinterface-onboot --apply-hack` 


### Revert Hack

Restore from backup or reverse hack:

`$ webinterface-onboot --revert-hack` 


## How Does it Work?

### Definitions

web interface:
- the server/website that runs on 10.11.99.1:80 and allows file uploads/downloads

usb0/usb1 network interface:
- the device within the tablet that handles the ethernet connection

### Webinterface-Onboot

When xochitl starts, it determines whether or not it should run the web interface. It will first check that the field 'WebInterfaceEnabled' is set to 'true' in /home/root/.config/remarkable/xochitl.conf. If so, it then checks if the usb0 network interface has an ip address. If so, it will run the web interface on that ip address.

Thus, before xochitl starts:
- set WebInterfaceEnabled=true in /home/root/.config/remarkable/xochitl.conf
- give the usb0 network interface the ip address 10.11.99.1/32

> Versions >= v2.15 also require the usb0 network interface to be connected to a computer, so we need the...

### Binary Hack

All the hack does to the xochitl binary:

- change the string 'usb0' to 'usbF'
- change the string 'usb1' to 'usb0'

The strings 'usb0' and 'usb1' only occur once in the binary and appear only to be used within the function that decides on which network interface the web interface website should be started on. 

Since we are changing hard-coded strings in the binary, the code that uses these strings will roughly be changed from:

```
primary_interface = QNetworkInterface::interfaceFromName('usb0')
fallback_interface = QNetworkInterface::interfaceFromName('usb1')
```

To:

```
primary_interface = QNetworkInterface::interfaceFromName('usbF')
fallback_interface = QNetworkInterface::interfaceFromName('usb0')
```

Without the hack, xochitl will check to see that the primary network interface, usb0, **has an ip address and is connected to a computer** in order to start the web interface on that ip address. If those conditions are not satisfied, xochitl will fallback to checking the usb1 network interface. But for the fallback interface, xochitl **only checks for an ip address** in order to start the web interface, **not if it is connected to a computer**.

We can give the usb0 network interface an ip address at any time, but we can not fake the connection to the computer as it is deduced by the network interface's operational state. This means that without the cable plugged in, the conditions necessary to start the web interface on the primary network interface, usb0, can never be satisfied. Though, this also means that if the usb0 network interface was to be evaluated as the fallback interface, we could give it an ip address to satisfy the conditions necessary to start the web interface. This is what we'll do!

In order to evaluate the usb0 network interface as the fallback network interface, all we need to do is change the string 'usb1' to 'usb0' within the xochitl binary.

I am not quite sure what the function of the usb1 network interface is, so the hack changes the initial occurrence of 'usb0' to 'usbF' so that xochitl can not find the primary network interface and will always fallback to usb0, and so that there will be only one occurrence of the string 'usb0' in the binary. It may be wiser to leave the initial occurrence of the string 'usb0' as 'usb0', or change it to 'usb1'.

