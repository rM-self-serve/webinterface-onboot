# WebInterface-OnBoot

This simple program will convince the ReMarkable Tablet to start the web interface after booting without the usb cord being plugged in. It can then be reached internally at 10.11.99.1:80 without the usb cord.

This could easily be emulated with a bash script.

Please test on other versions and feel free to discuss! Would love to try to support every version.

You will type the following commands after ssh'ing into your ReMarkable Tablet.

## Validated Xochitl Versions

- 2.10.0.324

## Install

`wget https://raw.githubusercontent.com/rM-self-serve/webinterface-onboot/master/install-webint-ob.sh && bash install-webint-ob.sh`

## Remove

`wget https://raw.githubusercontent.com/rM-self-serve/webinterface-onboot/master/remove-webint-ob.sh && bash remove-webint-ob.sh`

## Use

To auto start the application after restarting the device, run:

- `systemctl enable --now webinterface-onboot`

Next time you restart the web interface will be running and internally accessible on 10.11.99.1:80

## Manual install

You will need docker/podman, cargo, and the cargo crate named cross. There are surely other ways to cross compile for armv7-unknown-linux-gnueabihf as well.

`cross build --target armv7-unknown-linux-gnueabihf --release`

Then copy the binary 'target/armv7-unknown-linux-gnueabihf/release/webinterface-onboot' to the device and enable/start it as a systemd service.

## How Does it Work?

First trick xochitl into thinking the web interface should be enabled by:
- setting WebInterfaceEnabled=true in /etc/remarkable.conf
- giving the usb0 interface the ip 10.11.99.1

If done fast enough, the conditions are right for xochitl to start the webserver on boot.

The actual web-interface website will continue running on 10.11.99.1:80 even if the usb0 interface does not have the 10.11.99.1 ip address. Disconnecting the usb cord will automatically remove the ip 10.11.99.1 from the usb0 interface, so this program runs in an infinite loop and will ensure the ip is set for usb0.
