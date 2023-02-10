#!/usr/bin/env bash

webinterface_onboot_sha256sum='5072b216774f2ca24ac0933d4633a6e2d64e5b7426bcbcac48f74cc56f9c3ab0'
service_file_sha256sum='224fe11abdc0bd332c9946ffda3fe38687038dbf4bd65982b88815ab90f5a8cf'

installfile='./install-webint-ob.sh'
localbin='/home/root/.local/bin'
binfile="${localbin}/webinterface-onboot"
servicefile='/lib/systemd/system/webinterface-onboot.service'

printf "\nwebinterface-onboot\n"
printf "\nEnable the web interface on boot\n"
printf "This program will be installed in %s\n" "${localbin}"
printf "%s will be added to the path in ~/.bashrc if necessary\n" "${localbin}"

read -r -p "Would you like to continue with installation? [y/N] " response
case "$response" in
[yY][eE][sS] | [yY])
	printf "Installing webinterface-onboot\n"
	;;
*)
	printf "Exiting installer and removing script\n"
	[[ -f $installfile ]] && rm $installfile
	exit
	;;
esac

mkdir -p $localbin

case :$PATH: in
*:$localbin:*) ;;
*) echo "PATH=\"${localbin}:\$PATH\"" >>/home/root/.bashrc ;;
esac

function sha_fail() {
	echo "sha256sum did not pass, error downloading webinterface-onboot"
	echo "Exiting installer and removing installed files"
	[[ -f $binfile ]] && rm $binfile
	[[ -f $installfile ]] && rm $installfile
	[[ -f $servicefile ]] && rm $servicefile
	exit
}

[[ -f $binfile ]] && rm $binfile
wget https://github.com/rM-self-serve/webinterface-onboot/releases/download/v1.0.0/webinterface-onboot \
	-P $localbin

if ! sha256sum -c <(echo "$webinterface_onboot_sha256sum  $binfile") >/dev/null 2>&1; then
	sha_fail
fi

chmod +x $localbin/webinterface-onboot

[[ -f $servicefile ]] && rm $servicefile
wget https://raw.githubusercontent.com/rM-self-serve/webinterface-onboot/master/webinterface-onboot.service \
	-P /lib/systemd/system

if ! sha256sum -c <(echo "$service_file_sha256sum  $servicefile") >/dev/null 2>&1; then
	sha_fail
fi

systemctl daemon-reload

printf '\nFinished installing webinterface-onboot, removing install script\n\n'
printf 'To auto start the application after restarting the device, run:\n'
printf 'systemctl enable --now webinterface-onboot\n\n'

[[ -f $installfile ]] && rm $installfile
