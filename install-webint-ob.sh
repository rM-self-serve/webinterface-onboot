#!/usr/bin/env bash
# Copyright (c) 2023 rM-self-serve
# SPDX-License-Identifier: MIT

webinterface_onboot_sha256sum='47d712800b01bea60281d8eadf6ca0f47e1c55309c68a5e0b2c2dde33728492f'
service_file_sha256sum='57d7f1f6ebe7bfccf435c11b12e4bec1f58f72f1a7af963e5e58e626f241ccf6'

release='v1.1.0'

installfile='./install-webint-ob.sh'
pkgname='webinterface-onboot'
localbin='/home/root/.local/bin'
binfile="${localbin}/${pkgname}"
servicefile="/lib/systemd/system/${pkgname}.service"

remove_installfile() {
	read -r -p "Would you like to remove installation script? [y/N] " response
	case "$response" in
	[yY][eE][sS] | [yY])
		printf "Exiting installer and removing script\n"
		[[ -f $installfile ]] && rm $installfile
		;;
	*)
		printf "Exiting installer and leaving script\n"
		;;
	esac
}

echo "${pkgname} ${release}"
echo "Enable the web interface on boot"
echo ''
echo "This program will be installed in ${localbin}"
echo "${localbin} will be added to the path in ~/.bashrc if necessary"
echo ''
read -r -p "Would you like to continue with installation? [y/N] " response
case "$response" in
[yY][eE][sS] | [yY])
	echo "Installing ${pkgname}"
	;;
*)
	remove_installfile
	exit
	;;
esac

mkdir -p $localbin

case :$PATH: in
*:$localbin:*) ;;
*) echo "PATH=\"${localbin}:\$PATH\"" >>/home/root/.bashrc ;;
esac

pkg_sha_check() {
	if sha256sum -c <(echo "$webinterface_onboot_sha256sum  $binfile") >/dev/null 2>&1; then
		return 0
	else
		return 1
	fi
}

srvc_sha_check() {
	if sha256sum -c <(echo "$service_file_sha256sum  $servicefile") >/dev/null 2>&1; then
		return 0
	else
		return 1
	fi
}

sha_fail() {
	echo "sha256sum did not pass, error downloading ${pkgname}"
	echo "Exiting installer and removing installed files"
	[[ -f $binfile ]] && rm $binfile
	[[ -f $servicefile ]] && rm $servicefile
	remove_installfile
	exit
}

need_bin=true
if [ -f $binfile ]; then
	if pkg_sha_check; then
		need_bin=false
		echo "Already have the right version of ${pkgname}"
	else
		rm $binfile
	fi
fi
if [ "$need_bin" = true ]; then
	wget "https://github.com/rM-self-serve/${pkgname}/releases/download/${release}/${pkgname}" \
		-O "$binfile"

	if ! pkg_sha_check; then
		sha_fail
	fi

	chmod +x "${localbin}/${pkgname}"
fi

need_service=true
if [ -f $servicefile ]; then
	if srvc_sha_check; then
		need_service=false
		echo "Already have the right version of ${pkgname}"
	else
		rm $servicefile
	fi
fi
if [ "$need_service" = true ]; then
	wget "https://github.com/rM-self-serve/${pkgname}/releases/download/${release}/${pkgname}.service" \
		-O "$servicefile"

	if ! srvc_sha_check; then
		sha_fail
	fi
fi

systemctl daemon-reload

echo ""
echo "Finished installing ${pkgname}"
echo ""
echo "To use ${pkgname}, run:"
echo "$ systemctl enable --now ${pkgname}"
echo ""

remove_installfile
