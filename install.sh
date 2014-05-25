#!/bin/bash

clear
echo "****************************************"
echo "* Oddwires Alarm System installer      *"
echo "* Stage 1: Install updates             *"
echo "*                                      *"
echo "* Press 'C'      to Continue           *"
echo "*       'S'      to Skip               *"
echo "*       'Ctrl-C' to Quit               *"
echo "*                                      *"
echo "****************************************"
read -n1 -r key
echo

if [[ "$key" = "C" ]] || [[ "$key" = "c" ]]; then
  # Updates...
  sudo apt-get -y update
fi
echo " "

clear
echo "****************************************"
echo "* Oddwires Alarm System installer      *"
echo "* Stage 2: Install updgrades           *"
echo "*                                      *"
echo "* ( this can take a long time to run ) *"
echo "*                                      *"
echo "* Press 'C'      to Continue           *"
echo "*       'S'      to Skip               *"
echo "*       'Ctrl-C' to Quit               *"
echo "*                                      *"
echo "****************************************"
read -n1 -r key
echo

if [[ "$key" = "C" ]] || [[ "$key" = "c" ]]; then
  # Upgrades...
  sudo apt-get -y upgrade
fi
echo " "

if [[ "$key" = "C" ]] || [[ "$key" = "c" ]]; then
  # Enable root account and assign a password...
  sudo passwd root
fi
echo " "

clear
echo "****************************************"
echo "* Oddwires Alarm System installer      *"
echo "* Stage 3: Install Mail Transfer Agent *"
echo "*                                      *"
echo "* Press 'C'      to Continue           *"
echo "*       'S'      to Skip               *"
echo "*       'Ctrl-C' to Quit               *"
echo "*                                      *"
echo "****************************************"
read -n1 -r key
echo

if [[ "$key" = "C" ]] || [[ "$key" = "c" ]]; then
  # Mail Transfer Agent...
  sudo apt-get install -y heirloom-mailx
fi
echo " "

clear
echo "****************************************"
echo "* Oddwires Alarm System installer      *"
echo "* Stage 4: Install Samba               *"
echo "*                                      *"
echo "* Samba provides file services that    *"
echo "* allow Windows devices to connect to  *"
echo "* the alarm system over a LAN          *"
echo "*                                      *"
echo "* Note: This installer will configur   *"
echo "* Samba for use with Windows 7         *"
echo "* clients.                             *"
echo "*                                      *"
echo "* Press 'C'      to Continue           *"
echo "*       'S'      to Skip               *"
echo "*       'Ctrl-C' to Quit               *"
echo "*                                      *"
echo "****************************************"
read -n1 -r key
echo

if [[ "$key" = "C" ]] || [[ "$key" = "c" ]]; then
  # Samba install...
  sudo apt-get -y install samba
  # Samba common binaries...
  sudo apt-get -y install samba-common-bin
  # Configure for Windows 7 clients...
  sudo cp /home/pi/Download/oddwires-alarm-system/smb.conf /etc/samba/smb.conf
  # add password for Pi account...
  sudo smbpasswd -a pi
  # enable the password for the root account...
  sudo smbpasswd -e pi
  # restart the service...
  sudo service samba restart
fi
echo " "

clear
echo "****************************************"
echo "* Oddwires Alarm System installer      *"
echo "* Stage 5: Install Apache and PHP.     *"
echo "*                                      *"
echo "* Press 'C'      to Continue           *"
echo "*       'S'      to Skip               *"
echo "*       'Ctrl-C' to Quit               *"
echo "*                                      *"
echo "****************************************"
read -n1 -r key
echo

if [[ "$key" = "C" ]] || [[ "$key" = "c" ]]; then
  # Apache install...
  sudo apt-get install -y apache2 php5 libapache2-mod-php5
fi
echo " "

clear
echo "***************************************"
echo "* Oddwires Alarm System installer     *"
echo "* Stage 6: Install alarm web page.    *"
echo "*                                     *"
echo "* Press 'C'      to Continue          *"
echo "*       'S'      to Skip              *"
echo "*       'Ctrl-C' to Quit              *"
echo "*                                     *"
echo "***************************************"
read -n1 -r key
echo

if [[ "$key" = "C" ]] || [[ "$key" = "c" ]]; then
  # Check for previous install...
  if [ "$(ls -A /var/www)" ]; then
    echo "Previous install found."
    echo "Removing previous install."
    sudo service alarm stop
    sudo rm -Rf /var/www/*
    echo "Previous install removed."
  else
    echo "Previous install not found."
  fi
  # Check for default Apache web page....
  if [ -f /var/www/index.html ]; then
      echo "Removing default Apache web page."
      rm -f /var/www/index.html;
  fi

  echo "Installing web page"
  # Ensure web folder permissions are correct for our install. Permissions have been based on the artical here...
  # http://serverfault.com/questions/357108/what-permissions-should-my-website-files-folders-have-on-a-linux-webserver
set -x
  sudo chown -R root /var/www/                                     # file can only be edited by root
  sudo chgrp www-data /var/www/
  chmod -R 750 /var/www/                                           # Apache access limited to read and execute
  chmod g+s /var/www/                                              # Sticky bit - new files inherit attributes from parent folder
set +x
  echo "Copying web site files..."
set -x
  sudo cp -R /home/pi/Download/oddwires-alarm-system/. /var/www/   # Copy code to web page
  rm -f /var/www/install.sh                                        # tidy up...
  rm -f /var/www/README.md
set +x
  echo "Creating sub folders..."
set -x
  mkdir /var/www/logs
  chmod -R 750 /var/www/logs
  chmod g+w /var/www/logs
  mkdir /var/www/uploads
  chmod -R 750 /var/www/uploads
  chmod g+w /var/www/uploads
set +x
fi

read -n1 -r -p "Press any key to continue..." key
echo " "

clear
echo "***************************************"
echo "* Oddwires Alarm System installer     *"
echo "* Stage 7: Install alarm daemon.      *"
echo "*                                     *"
echo "* Press 'C'      to Continue          *"
echo "*       'S'      to Skip              *"
echo "*       'Ctrl-C' to Quit              *"
echo "*                                     *"
echo "***************************************"
read -n1 -r key
echo

if [ "$key" = 'C' ] || [ "$key" = 'c' ]; then

      # Check for previous alarm daemon...
      if [ "$(ls -A /etc/init.d/alarm)" ]; then
         echo "Previous alarm daemon found."
         echo "Removing previous alarm daemon."
         sudo update-rc.d -f alarm remove
         echo "Previous daemon removed"
      fi

      # install daemon...
      sudo chmod 700 /var/www/Scripts/alarm.sh
      sudo chmod 700 /var/www/Scripts/alm.sh
      sudo chmod 700 /var/www/Scripts/alarm

      # create the new daemon...
      sudo mv /var/www/Scripts/alarm /etc/init.d/
      sudo chmod 755 /etc/init.d/alarm
      chgrp root /etc/init.d/alarm

      # make daemon autostart...
      sudo update-rc.d alarm defaults
fi

read -n1 -r -p "Press any key to continue..." key
echo " "

clear
echo "***************************************"
echo "* Oddwires Alarm System installer     *"
echo "* The alarm system has been           *"
echo "* installed.                          *"
echo "*                                     *"
echo "* Press any key to exit the           *"
echo "* installer and start the alarm       *"
echo "* daemon.                             *"
echo "*                                     *"
echo "***************************************"
read -n1 -r key
echo

clear
# start the service (because there hasn't been a re-boot)
sudo service alarm start
