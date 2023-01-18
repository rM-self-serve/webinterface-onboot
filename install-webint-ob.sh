installfile='./install-webint-ob.sh'
localbin='/home/root/.local/bin'
binfile="${localbin}/webinterface-onboot"
servicefile='/lib/systemd/system/webinterface-onboot.service'

printf "\nEnable the web interface on boot\n"
printf "This program will be installed in ${localbin}\n"
printf "The path will automatically be added to .bashrc if necessary\n"
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
*) echo "export PATH=\$PATH:${localbin}" >>/home/root/.bashrc ;;
esac

[[ -f $binfile ]] && rm $binfile
wget https://github.com/rM-self-serve/webinterface-onboot/releases/download/v1.0.0/webinterface-onboot \
-P $localbin

chmod +x $localbin/webinterface-onboot

[[ -f $servicefile ]] && rm $servicefile
wget https://raw.githubusercontent.com/rM-self-serve/webinterface-onboot/master/webinterface-onboot.service \
 -P /lib/systemd/system

systemctl daemon-reload

printf '\nFinished installing webinterface-onboot, removing install script\n\n'
printf 'To auto start the application after restarting the device, run:\n'
printf 'systemctl enable --now webinterface-onboot\n\n'

[[ -f $installfile ]] && rm $installfile