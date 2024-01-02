#!/usr/bin/env bash
# Copyright (c) 2023 rM-self-serve
# SPDX-License-Identifier: MIT

webinterface_onboot_sha256sum='8795ecb9bdd18b84deab0efa1a96c08ff53559d65567babb0088400da44daf0f'
service_file_sha256sum='d720711e475676ec3c5fb81f216ebbbf239005f3ea493996873b43d8edf3637a'

release='v1.2.2'

installfile='./install-webint-ob.sh'
pkgname='webinterface-onboot'
localbin='/home/root/.local/bin'
binfile="${localbin}/${pkgname}"
aliasfile="${localbin}/webint-onboot"
servicefile="/lib/systemd/system/${pkgname}.service"

wget_path=/home/root/.local/share/rM-self-serve/wget
wget_remote=http://toltec-dev.org/thirdparty/bin/wget-v1.21.1-1
wget_checksum=c258140f059d16d24503c62c1fdf747ca843fe4ba8fcd464a6e6bda8c3bbb6b5


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

if [ -f "$wget_path" ] && ! sha256sum -c <(echo "$wget_checksum  $wget_path") > /dev/null 2>&1; then
    rm "$wget_path"
fi
if ! [ -f "$wget_path" ]; then
    echo "Fetching secure wget"
    # Download and compare to hash
    mkdir -p "$(dirname "$wget_path")"
    if ! wget -q "$wget_remote" --output-document "$wget_path"; then
        echo "Error: Could not fetch wget, make sure you have a stable Wi-Fi connection"
        exit 1
    fi
fi
if ! sha256sum -c <(echo "$wget_checksum  $wget_path") > /dev/null 2>&1; then
    echo "Error: Invalid checksum for the local wget binary"
    exit 1
fi
chmod 755 "$wget_path"


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
	[[ -f $aliasfile ]] && rm $aliasfile
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
	"$wget_path" "https://github.com/rM-self-serve/${pkgname}/releases/download/${release}/${pkgname}" \
		-O "$binfile"

	if ! pkg_sha_check; then
		sha_fail
	fi

	chmod +x "$binfile"
	ln -s "$binfile" "$aliasfile"
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
	"$wget_path" "https://github.com/rM-self-serve/${pkgname}/releases/download/${release}/${pkgname}.service" \
		-O "$servicefile"

	if ! srvc_sha_check; then
		sha_fail
	fi
fi

systemctl daemon-reload

echo ""
echo "Finished installing $pkgname"
echo ""
echo "Run '\$ $pkgname' for information on usage."
echo ""

remove_installfile
