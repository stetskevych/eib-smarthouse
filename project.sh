#!/bin/bash
#
# project.sh -- unattended install of a smart house system based on Slack 13.0
# $Id$
#

set -e 
set -x
exec 2>log

# Check the script is being run by root
if [ "$(id -u)" != "0" ]; then
	echo "You must be root to run this."
	exit 1
fi

initial() {
#echo "Applying Slackware patches..."
#upgradepkg patches/packages/*.tgz || :
#find / -name "*.new" -print0 | while read -r -d $'\0'  f; do
#	mv -- "$f" "${f%.new}"; done
echo "Setting up slackpkg..."
	echo 'http://192.168.0.125/slackware/slackware-13.0/' \
		>> /etc/slackpkg/mirrors
	slackpkg update && slackpkg upgrade-all && slackpkg install-new && \
	slackpkg clean-system && slackpkg new-config
echo "Setting up logrotate..."
	sed -i 's/rotate 4/rotate 12/' /etc/logrotate.conf
	cp etc/eiblogs /etc/logrotate.d/eiblogs
echo "Creating eib:eib user and group..."
	groupadd eib
	useradd -d /usr/local/eib -g eib -G audio -m -s /bin/bash \
		-p '$1$jbqF1PW4LNxWpu3D4IHfA0' eib
echo "Copying sudoers..."
	cp etc/sudoers /etc/sudoers
	chmod 0440 /etc/sudoers
echo "Now set up lilo.conf and run lilo."
echo "Enter all hosts in /etc/hosts."
echo "Also enable smartd, sensors-detect, hddtemp."
echo "Also build a new kernel."
echo "Also download sbopkg and sync it."
echo "Finished."
}

server() {
echo "Installing required packages..."
	upgradepkg --install-new packages/eibd* packages/pthsem* \
		packages/sqlite2* || :
echo "Copying programs and scripts..."
	#install -m 0755 tools/rc.eib /etc/rc.d
	#install -m 0755 tools/rc.eibwatch /etc/rc.d
	#install -m 0755 tools/eibwatch2.sh /usr/local/bin
	install -m 0755 tools/rc.kennel /etc/rc.d
	install -m 0755 tools/netdog /usr/local/bin
	install -m 0755 tools/telelogger /usr/local/bin
echo "Adjusting rc.local..."
cat >>/etc/rc.d/rc.local << EOT
#
# Start eibwatch.sh
if [ -x /etc/rc.d/rc.eibwatch ] ; then
  /etc/rc.d/rc.eibwatch start
fi
EOT
#echo "Copying httpd and php configuration..."
#cp etc/httpd.conf etc/php.ini /etc/httpd/
echo "Cleaning up /var/www/htdocs and chowning it eib:eib..."
	rm -R /var/www/htdocs/*
	chown -Rv eib:eib /var/www/htdocs
echo "Filling up /usr/local/eib with content and setting up permissions..."
	mkdir -pv /usr/local/eib/databases
	mkdir -pv /usr/local/eib/databases/images
	chown -Rv eib:eib /usr/local/eib
	chgrp -Rv apache /usr/local/eib/databases
	chmod -Rv g+sw /usr/local/eib/databases
echo "Copying /etc/syslog.conf..."
	install -m 0644 etc/syslog.conf-server /etc/syslog.conf
echo "Now set up apache."
echo "Edit rc.syslog, add -r for remote reception."
echo "Don't forget to set the ip address and the HDD serial number in rc.eib."
echo "Finished."
}


panel() {
echo "Installing required packages..."
	upgradepkg --install-new packages/flash* packages/matchbox* \
       	packages/xtruss* || :
echo "Creating screen:screen user and group..."
	groupadd screen
	useradd -d /home/screen -g screen -m -s /bin/bash screen
echo "Filling up /usr/local/eib with content and setting up permissions..."
	cp -Rv eibpanelskel/visual /usr/local/eib/
	chown -Rv eib:eib /usr/local/eib/visual
echo "Copying empty cursor font..."
	( cd /usr/X11R6/lib/X11/fonts/misc
	cp -v cursor.pcf.gz cursor.pcf.gz.dist )
	cp -v xorg/cursor.pcf.gz /usr/X11R6/lib/X11/fonts/misc/
echo "Copying xinitrc..."
	cp -v etc/xinitrc /etc/X11/xinit/xinitrc.screen
	( cd /etc/X11/xinit; ln -sf xinitrc.screen xinitrc )
echo "Installing sosmonkey.sh and creating it's logfile..."
	install -m 0755 tools/sosmonkey.sh /usr/local/bin
	touch /var/log/sosmonkey.log
	chown -v screen:screen /var/log/sosmonkey.log
echo "Writing FlashPlayerTrust..."
	mkdir -pv /etc/adobe/FlashPlayerTrust
	echo "/usr/local/eib/visual" > /etc/adobe/FlashPlayerTrust/visual.cfg
echo "Copying inittab..."
	cp -v etc/inittab /etc/inittab
echo "Copying /etc/syslog.conf..."
	install -m 0644 etc/syslog.conf-client /etc/syslog.conf
echo "Edit servername in /etc/syslog.conf"
echo "Don't forget to configure xorg (touchscreen and video driver)."
echo "Finished."
}

internet() {
	echo "Installing internet support..."

	echo "Installing OpenVPN support..."

}

vnc() {
  # Set up manually
	true
}

# GIRA, eGalax, TSC-10
xorg_proface() {
installpkg packages/xf86-input-evtouch* || :
cp -v xorg/xorg.conf.proface /etc/X11/xorg.conf
echo "See /proc/bus/input/devices and change xorg.conf accordingly."
}

# elographics
xorg_advantech() {
cp -v xorg/xorg.conf.advantech /etc/X11/xorg.conf
echo "See /proc/bus/input/devices and change xorg.conf accordingly."
}

# penmount - slackware 12.2
xorg_penmount() {
echo "Doing PenMount installation..."
( cd xorg/pm225
cp penmount.dat /etc
cp pm-setup gCalib gCal /usr/sbin
cp penmount_drv.so  /usr/lib/xorg/modules/input )
echo "Copying xorg.conf.penmount..."
cp -v xorg/xorg.conf.penmount /etc/X11/xorg.conf
echo "Running calibration..."
echo << 'EOF' > /root/.xinitrc
#!/bin/sh
/usr/bin/matchbox-window-manager &
/usr/sbin/gCal 4
EOF
startx
echo "Finished."
}

case "$1" in
  'initial')
    initial
  ;;
  'server')
    server
  ;;
  'panel')  
    panel
  ;;
  'internet')  
    internet
  ;;
  'vnc')  
    vnc
  ;;
  'xorg_proface')  
    xorg_proface
  ;;
  'xorg_advantech')
    xorg_advantech
  ;;
  'xorg_penmount')
    xorg_penmount
  ;;
  *)
    echo "Usage: $0 {initial|server|panel|xorg_proface|xorg_advantech|xorg_penmount}"
  ;;
esac
