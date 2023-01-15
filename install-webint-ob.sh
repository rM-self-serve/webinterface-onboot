echo "Enable the web interface on boot"

wget https://github.com/rM-self-serve/webinterface-onboot/releases/download/v1.0.0/webinterface-onboot \
-P /usr/bin

chmod +x /usr/bin/webinterface-onboot

wget https://raw.githubusercontent.com/rM-self-serve/webinterface-onboot/master/webinterface-onboot.service \
 -P /lib/systemd/system

systemctl daemon-reload
systemctl enable webinterface-onboot --now