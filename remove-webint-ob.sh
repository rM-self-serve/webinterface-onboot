#!/usr/bin/env bash

pkgname='webinterface-onboot'
removefile='./remove-webint-ob.sh'
localbin='/home/root/.local/bin'
binfile="${localbin}/${pkgname}"
servicefile="/lib/systemd/system/${pkgname}.service"

printf "\nRemove webinterface-onboot\n"
echo "This will not remove the /home/root/.local/bin directory nor the path in .bashrc"

read -r -p "Would you like to continue with removal? [y/N] " response
case "$response" in
[yY][eE][sS] | [yY])
    echo "Removing webinterface-onboot"
    ;;
*)
    echo "exiting removal"
    [[ -f $removefile ]] && rm $removefile
    exit
    ;;
esac

[[ -f $binfile ]] && rm $binfile

if systemctl --quiet is-active "$pkgname" 2>/dev/null; then
	echo "Stopping $pkgname"
	systemctl stop "$pkgname"
fi
if systemctl --quiet is-enabled "$pkgname" 2>/dev/null; then
	echo "Disabling $pkgname"
	systemctl disable "$pkgname"
fi

[[ -f $servicefile ]] && rm $servicefile

[[ -f $removefile ]] && rm $removefile

echo "Successfully removed webinterface-onboot"
