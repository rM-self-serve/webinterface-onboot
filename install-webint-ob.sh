#!/usr/bin/env bash
# Copyright (c) 2024 rM-self-serve
# SPDX-License-Identifier: MIT

# --- Values replaced in github actions ---
version='VERSION'
webinterface_onboot_sha256sum='WEBINTERFACE_ONBOOT_SHA256SUM'
service_file_sha256sum='SERVICE_FILE_SHA256SUM'
# -----------------------------------------

installfile='./install-webint-ob.sh'
pkgname='webinterface-onboot'
localbin='/home/root/.local/bin'
binfile="${localbin}/${pkgname}"
servicefile="/lib/systemd/system/${pkgname}.service"
aliasfile="${localbin}/webint-onboot"

wget_path=/home/root/.local/share/rM-self-serve/wget
wget_remote=http://toltec-dev.org/thirdparty/bin/wget-v1.21.1-1
wget_checksum=c258140f059d16d24503c62c1fdf747ca843fe4ba8fcd464a6e6bda8c3bbb6b5

main() {
	case "$@" in
	'install' | '')
		install
		;;
	'remove')
		remove
		;;
	*)
		echo 'input not recognized'
		cli_info
		exit 0
		;;
	esac
}

cli_info() {
	echo "${pkgname} installer ${version}"
	echo -e "${CYAN}COMMANDS:${NC}"
	echo '  install'
	echo '  remove'
	echo ''
}

pkg_sha_check() {
	sha256sum -c <(echo "$webinterface_onboot_sha256sum  $binfile") >/dev/null 2>&1
}

srvc_sha_check() {
	sha256sum -c <(echo "$service_file_sha256sum  $servicefile") >/dev/null 2>&1
}

sha_fail() {
	echo "sha256sum did not pass, error downloading ${pkgname}"
	echo "Exiting installer and removing installed files"
	[[ -f $binfile ]] && rm $binfile
	[[ -f $servicefile ]] && rm $servicefile
	exit 1
}

install() {
	echo "Install ${pkgname} ${version}"
	echo ''
	echo "This program will be installed in ${localbin}"
	echo "${localbin} will be added to the path in ~/.bashrc if necessary"
	echo ''

	if [ -f "$wget_path" ] && ! sha256sum -c <(echo "$wget_checksum  $wget_path") >/dev/null 2>&1; then
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
	if ! sha256sum -c <(echo "$wget_checksum  $wget_path") >/dev/null 2>&1; then
		echo "Error: Invalid checksum for the local wget binary"
		exit 1
	fi
	chmod 755 "$wget_path"

	mkdir -p $localbin

	case :$PATH: in
	*:$localbin:*) ;;
	*) echo "PATH=\"${localbin}:\$PATH\"" >>/home/root/.bashrc ;;
	esac

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
		"$wget_path" -q "https://github.com/rM-self-serve/${pkgname}/releases/download/${version}/${pkgname}" \
			-O "$binfile"

		if ! pkg_sha_check; then
			sha_fail
		fi

		chmod +x "$binfile"
		echo "Fetched ${pkgname}"
	fi

	need_service=true
	if [ -f $servicefile ]; then
		if srvc_sha_check; then
			need_service=false
			echo "Already have the right version of ${pkgname}.service"
		else
			rm $servicefile
		fi
	fi
	if [ "$need_service" = true ]; then
		"$wget_path" -q "https://github.com/rM-self-serve/${pkgname}/releases/download/${version}/${pkgname}.service" \
			-O "$servicefile"

		if ! srvc_sha_check; then
			sha_fail
		fi

		echo "Fetched ${pkgname}.service"
	fi

	systemctl daemon-reload

	echo ''
	echo "Applying usb0 ip persistence"
	if ! "$binfile" apply-prstip -y >/dev/null; then
		echo "Error, exiting"
		exit 1
	fi
	echo "Success"
	if "$binfile" is-hack-version >/dev/null; then
		echo ''
		echo "Applying binary modification"
		if ! "$binfile" apply-hack -y >/dev/null; then
			echo "Error, exiting"
			exit 1
		fi
		echo "Success"
	fi

	echo ''
	echo "Finished installing $pkgname"
	echo ''
	echo "Run the following command to use ${pkgname}"
	echo "$ systemctl enable ${pkgname} --now"
	echo ''

	[[ -f $installfile ]] && rm $installfile
}

remove() {
	echo "Remove ${pkgname}"
	echo ''
	echo "This will not remove the /home/root/.local/bin directory nor the path in .bashrc"
	echo ''

	if "$binfile" is-prstip-applied >/dev/null; then
		if ! "$binfile" revert-prstip -y >/dev/null; then
			echo "Error, exiting"
			exit 1
		fi
	fi
	echo "Reverted persist-ip"
	if  "$binfile" is-hack-applied >/dev/null; then
		if ! "$binfile" revert-hack --reverse -y >/dev/null; then
			echo "Error, exiting"
			exit 1
		fi
	fi
	echo "Reverted binary hack"

	if systemctl --quiet is-active "$pkgname" 2>/dev/null; then
		echo "Stopping $pkgname"
		systemctl stop "$pkgname"
	fi
	if systemctl --quiet is-enabled "$pkgname" 2>/dev/null; then
		echo "Disabling $pkgname"
		systemctl disable "$pkgname"
	fi

	[[ -f $binfile ]] && rm $binfile
	[[ -f $servicefile ]] && rm $servicefile
	[[ -f $aliasfile ]] && rm $aliasfile
	[[ -f $installfile ]] && rm $installfile

	echo "Successfully reverted and removed ${pkgname}"
}

main "$@"
