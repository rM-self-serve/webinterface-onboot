echo "Remove webinterface-onboot"

rm /usr/bin/webinterface-onboot

systemctl disable webinterface-onboot --now

rm /lib/systemd/system/webinterface-onboot.service