![Static Badge](https://img.shields.io/badge/reMarkable-v3.10.2-green)
[![rm1](https://img.shields.io/badge/rM1-supported-green)](https://remarkable.com/store/remarkable)
[![rm2](https://img.shields.io/badge/rM2-supported-green)](https://remarkable.com/store/remarkable-2)
[![opkg](https://img.shields.io/badge/OPKG-webinterface--onboot-blue)](https://toltec-dev.org/)
[![Discord](https://img.shields.io/discord/385916768696139794.svg?label=reMarkable&logo=discord&logoColor=ffffff&color=7389D8&labelColor=6A7EC2)](https://discord.gg/ATqQGfu)

# WebInterface-OnBoot

This program will convince the ReMarkable Tablet to start the web interface after booting without the usb cable being plugged in. Eliminates the need to switch on the web interface setting after connecting the usb cable. Also useful for clients that leverage the web interface for file operations, namely access over [wifi](https://github.com/rM-self-serve/webinterface-wifi).

![demo](https://github.com/rM-self-serve/webinterface-onboot/assets/122753594/89d49258-01b9-42ff-b611-1144ce02621e)


## ReMarkable Software Version Compatibility

- ✅ <= v2.14
- ✅ >= v2.15 - Requires simple binary hack, see below

---

### Type the following commands after ssh'ing into the ReMarkable Tablet


**It is recommended to install via the [toltec package manager](https://toltec-dev.org/).** Toltec will automate the binary and persist ip modification.

### With toltec

```
$ opkg update
$ opkg install webinterface-onboot
$ opkg remove webinterface-onboot
```

### No toltec

### Install

`$ wget https://raw.githubusercontent.com/rM-self-serve/webinterface-onboot/master/install-webint-ob.sh && bash install-webint-ob.sh && source ~/.bashrc`

### Remove

`$ wget https://raw.githubusercontent.com/rM-self-serve/webinterface-onboot/master/remove-webint-ob.sh && bash remove-webint-ob.sh`

## Binary Hack for Software Versions >= v2.15

The provided functionality to apply/revert the hack will first create a backup, then a temporary file in which the hack is applied. If the temporary file is successfully converted, it will replace the xochitl binary in /usr/bin/.

> If applying other binary modifications such as [rM-hacks](https://github.com/mb1986/rm-hacks) or [ddvk's hacks](https://github.com/ddvk/remarkable-hacks), they will fail if webinterface-onboot has been applied. Thus, it is necessary to apply webinterface-onboot after applying the other modifications. If reverting other binary modifications after webinterface-onboot has been applied, it is necessary to revert webinterface-onboot before reverting these modifications.


### Apply Hack

This will only need to be done once, unless you upgrade:

`$ webinterface-onboot apply-hack`

### Revert Hack

Restore from backup or reverse hack:

`$ webinterface-onboot revert-hack` 


## Maintain Internal Web Interface Accessibility

> Only needed for software clients that leverage the web interface. If the hack was just applied/reverted, you will need to run 'systemctl restart xochitl' first.

Disconnecting the usb cable will remove the ip address from the usb0 network interface, making the web interface inaccessible. To fix: 

### Apply Persist Ip

`$ webinterface-onboot apply-prstip` 

### Revert Persist Ip

`$ webinterface-onboot revert-prstip` 


## Usage

### To use webinterface-onboot, run:

`$ systemctl enable --now webinterface-onboot`

> the web interface will start the next time the device does, and every time after

### To stop using webinterface-onboot, run:

`$ systemctl disable --now webinterface-onboot`


### Status
`$ webinterface-onboot --status`

![demo](https://github.com/rM-self-serve/webinterface-onboot/assets/122753594/1decf76a-a03a-4ba9-b5ac-352d04d3d345)

### Tailscale
To serve the webinterface over tailscale after webinterface-oboot is working, use 'webinterface-localhost' from Toltec. 

## How Does It Work?

### Definitions

**web interface:** the server/website that runs on 10.11.99.1:80 and allows file uploads/downloads

**usb0/usb1 network interface:** the device within the tablet that handles the ethernet connection

**xochitl:** the ReMarkable ereader/ewriter executable binary file at /usr/bin/xochitl 

### Webinterface-Onboot

When xochitl starts, it determines whether or not to run the web interface. It will first check that the field 'WebInterfaceEnabled' is set to 'true' in /home/root/.config/remarkable/xochitl.conf. If so, it then checks if the usb0 network interface has an ip address. If so, it will run the web interface on that ip address.

Thus, before xochitl starts:
- set WebInterfaceEnabled=true in /home/root/.config/remarkable/xochitl.conf
- give the usb0 network interface the ip address 10.11.99.1/32

**This was true for versions <= 2.14**

As of v2.15, the software introduces the possibility for another network interface, usb1. While unused to my understanding, it was added as a fallback option to the algorithm which determines whether or not to run the web interface. While the algorithm is otherwise the same, this change adds the requirement that the usb0 network interface is also connected to the computer, so we need the...

### Binary Hack

All the hack does to the xochitl binary:

- change the string 'usb0' to 'usbF'
- change the string 'usb1' to 'usb0'

> The strings 'usb0' and 'usb1' only occur once in the binary and appear only to be used within the function that decides on which network interface the web interface website should be started on. 

Without the hack, xochitl will check to see that the **primary network interface**, *usb0*, **has an ip address** and **is connected to a computer** in order to start the web interface on that ip address. If those conditions are not satisfied, xochitl will fallback to checking the *usb1* network interface. But for the **fallback interface**, xochitl **only checks for an ip address** in order to start the web interface, **not if it is connected to a computer**.

We can give the usb0 network interface an ip address at any time, but we can not fake the connection to the computer as it is deduced by the network interface's operational state. If the usb0 network interface was to be evaluated as the fallback interface, we could give it an ip address to satisfy the conditions necessary to start the web interface. Lets do that.

We need to change the string 'usb1' to 'usb0' within the xochitl binary. Then xochitl will search for the fallback interface by name and see if it has a valid ip address to start the web interface. The hack changes the initial occurrence of 'usb0' to 'usbF'. This is so that xochitl can not find the new primary usbF network interface, will always fallback to usb0, and so the binary is easier to verify/revert.

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


We modify an existing script that runs every time the cord disconnects:

```/etc/ifplugd/ifplugd.action```

To give usb0 the ip address:

```ip addr change 10.11.99.1/32 dev usb0```


#### Before
```
if [ -z "$1" ] || [ -z "$2" ] ; then
    echo "Wrong arguments" > /dev/stderr
    exit 1
fi

if [ "$2" = "up" ]
then
    systemctl start "busybox-udhcpd@$1.service"
fi

if [ "$2" = "down" ]
then
    systemctl stop "busybox-udhcpd@$1.service"
fi
```

#### After
```
if [ -z "$1" ] || [ -z "$2" ] ; then
    echo "Wrong arguments" > /dev/stderr
    exit 1
fi

if [ "$2" = "up" ]
then
    systemctl start "busybox-udhcpd@$1.service"
fi

if [ "$2" = "down" ]
then
    systemctl stop "busybox-udhcpd@$1.service"
    ip addr change 10.11.99.1/32 dev usb0
fi
```
