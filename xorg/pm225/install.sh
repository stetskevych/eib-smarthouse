#!/bin/bash

sudo rm -rf /usr/share/penmount
sudo rm -f /usr/share/applications/penmount.desktop
sudo rm -f /usr/share/applications/penmount0.desktop
sudo rm -f /usr/share/applications/penmount4.desktop
sudo rm -f /usr/share/applications/penmount9.desktop
sudo rm -f /usr/share/applications/penmount16.desktop
sudo rm -f /usr/share/applications/penmount25.desktop

sudo rm -f /usr/sbin/pm-setup
sudo rm -f /usr/sbin/pm-calib
sudo rm -f /usr/sbin/pm-sniff
sudo rm -f /usr/sbin/pm-sniff-usb
sudo rm -f /usr/sbin/gCal

sudo rm -f /etc/init.d/pm-setup.sh
sudo rm -f /etc/rc2.d/S08pm-setup
sudo rm -f /etc/rc3.d/S08pm-setup
sudo rm -f /etc/rc4.d/S08pm-setup
sudo rm -f /etc/rc5.d/S08pm-setup

sudo mkdir /usr/share/penmount
sudo chown -R root.root *
sudo cp -f penmount.png     /usr/share/penmount
sudo cp -f README-ubuntu804 /usr/share/penmount

sudo cp -f penmount.dat     /etc
sudo cp -f pm-setup         /usr/sbin
sudo cp -f gCal             /usr/sbin
sudo cp -f penmount.desktop /usr/share/applications

sudo /usr/sbin/pm-setup
sudo cp -f penmount_drv.so  /usr/lib/xorg/modules/input

