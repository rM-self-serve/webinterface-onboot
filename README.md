![Static Badge](https://img.shields.io/badge/reMarkable-v3.13-green)
[![rm1](https://img.shields.io/badge/rM1-supported-green)](https://remarkable.com/store/remarkable)
[![rm2](https://img.shields.io/badge/rM2-supported-green)](https://remarkable.com/store/remarkable-2)
[![opkg](https://img.shields.io/badge/OPKG-webinterface--onboot-blue)](https://toltec-dev.org/)
[![Discord](https://img.shields.io/discord/385916768696139794.svg?label=reMarkable&logo=discord&logoColor=ffffff&color=7389D8&labelColor=6A7EC2)](https://discord.gg/ATqQGfu)

# WebInterface-OnBoot

This program will convince the ReMarkable Tablet to start the 
[USB Web Interface](https://remarkable.guide/tech/usb-web-interface.html) after booting without the usb cable being plugged in.
Eliminates the need to switch on the web interface setting after connecting the usb cable.
Also useful for clients that leverage the USB Web Interface for file operations,
namely access over [wifi](https://github.com/rM-self-serve/webinterface-wifi).

![demo](https://github.com/rM-self-serve/webinterface-onboot/assets/122753594/89d49258-01b9-42ff-b611-1144ce02621e)


## ReMarkable Software Version Compatibility

- ✅ <= v2.14
- ✅ >= v2.15 - Requires simple binary hack
---

### Type the following commands after ssh'ing into the ReMarkable Tablet


**It is recommended to install via the [toltec package manager](https://toltec-dev.org/).**

### With toltec

```
$ opkg update
$ opkg install webinterface-onboot
$ opkg remove webinterface-onboot
```

### No toltec

### Install

`$ wget -q https://github.com/rM-self-serve/webinterface-onboot/releases/latest/download/install-webint-ob.sh && bash install-webint-ob.sh`

### Remove

`$ wget -q https://github.com/rM-self-serve/webinterface-onboot/releases/latest/download/install-webint-ob.sh && bash install-webint-ob.sh remove`

## Binary Hack for Software Versions >= v2.15

If applying other binary modifications such as [rM-hacks](https://github.com/mb1986/rm-hacks)
or [ddvk's hacks](https://github.com/ddvk/remarkable-hacks), they will fail if webinterface-onboot has been applied.
Thus, it is necessary to apply webinterface-onboot after applying the other modifications.
If reverting other binary modifications after webinterface-onboot has been applied,
it is necessary to revert webinterface-onboot before reverting these modifications.

## Usage

### To use webinterface-onboot, run:

`$ systemctl enable webinterface-onboot`

Then restart the device.

### To stop using webinterface-onboot, run:

`$ systemctl disable --now webinterface-onboot`

### Status
`$ webinterface-onboot --status`

![demo](https://github.com/rM-self-serve/webinterface-onboot/assets/122753594/1decf76a-a03a-4ba9-b5ac-352d04d3d345)

### Tailscale
To serve the USB Web Interface over tailscale after webinterface-onboot is working, use 'webinterface-localhost' from Toltec. 

## How Does It Work?

### Definitions

**USB Web Interface:** the server/website that runs on 10.11.99.1:80 and allows file uploads/downloads

**usb0/usb1 network interface:** the device within the tablet that handles the ethernet connection

**xochitl:** the ReMarkable ereader/ewriter executable binary file at /usr/bin/xochitl 

### Webinterface-Onboot

Upon startup, Xochitl checks if 'WebInterfaceEnabled' is set to 'true' in /home/root/.config/remarkable/xochitl.conf.
If it is, the program then looks for an IP address on the usb0 network interface and,
if found, starts the USB Web Interface using that address.

Thus, before xochitl starts:
- set WebInterfaceEnabled=true in /home/root/.config/remarkable/xochitl.conf
- give the usb0 network interface the ip address 10.11.99.1/32

**This was true for versions <= 2.14**

As of v2.15, the software introduces the possibility for another network interface, usb1.
This change adds the requirement that the usb0 network interface is also connected to the computer, so we need the...

### Binary Hack

Without the hack, xochitl checks if the primary network interface *usb0*
has an IP address and is connected to a computer to start the USB Web Interface.
If not, it falls back to *usb1*, which only needs an IP address.

To make *usb0* the fallback interface, we modify the binary by changing the string *usb1* to *usb0*.
This way, xochitl will always fall back to *usb0* if it can't find the primary interface.
We also change the primary interface from the string *usb0* to *usbF* to prevent xochitl
from finding it and make the hack easier to verify and revert.

> The strings 'usb0' and 'usb1' only occur once in the binary and appear only to be used within the
function that decides on which network interface the web interface website should be started on. 

### Psudeo Code

#### Before
```
if conf.WebInterfaceEnabled == true:

    primary_interface = QNetworkInterface::interfaceFromName('usb0')
    fallback_interface = QNetworkInterface::interfaceFromName('usb1')

    if primary_interface.has_ip() and primary_interface.is_connected():
        start_web_interface( primary_interface.ip )
    
    else if fallback_interface.has_ip():
        start_web_interface( fallback_interface.ip )
```

#### After
```
if conf.WebInterfaceEnabled == true:

    primary_interface = QNetworkInterface::interfaceFromName('usbF')
    fallback_interface = QNetworkInterface::interfaceFromName('usb0')

    if primary_interface.has_ip() and primary_interface.is_connected():
        start_web_interface( primary_interface.ip )

    else if fallback_interface.has_ip():
        start_web_interface( fallback_interface.ip )
```

## How Does Persist Ip Work?

The IP address will be removed from usb0 when the cable is removed.
In order to restore the IP address, we modify an existing
script that runs every time the cord disconnects:

```/etc/ifplugd/ifplugd.action```


#### Before
```
...

if [ "$2" = "down" ]
then
    systemctl stop "busybox-udhcpd@$1.service"
fi
```

#### After
```
...

if [ "$2" = "down" ]
then
    systemctl stop "busybox-udhcpd@$1.service"
    ip addr change 10.11.99.1/32 dev usb0
fi
```
