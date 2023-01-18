removefile='./remove-webint-ob.sh'

echo "Remove webinterface-onboot"
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

rm /home/root/.local/bin/webinterface-onboot

systemctl disable webinterface-onboot --now

rm /lib/systemd/system/webinterface-onboot.service

[[ -f $removefile ]] && rm $removefile

echo "Successfully removed webinterface-onboot"
