#!/bin/bash

# check for previous install...
if [ "$(ls -A /var/www)" ]; then
    echo "Removing previous install.";
    alarm stop;
    sudo rm -rf /var/www/*;
    echo "Previous install removed.";
fi

# change owner of web folder from root to pi...
sudo chown -R pi /var/www/

sudo chmod 777 /var/www
if [ -f /var/www/index.html ]; then
    echo "Removing default Samba web page.";
    rm -f /var/www/index.html;
fi

sudo cp -R oddwires-alarm-system/* /var/www
rm -f /var/www/install.sh                      # tidy up...
rm -f /var/www/README.md

sudo chown -R pi *                             # change file ownership to allow pi account to edit files

# force Samba to clear cache and load the new pages...
sudo service samba restart

# modify path to include alarm service for all future logons...
echo "export PATH=$PATH:/etc/init.d" >> ~/.bashrc

sudo chmod +x /var/www/Scripts/alarm.sh
sudo chmod +x /var/www/Scripts/alm.sh
sudo chmod +x /var/www/Scripts/alarm

# create the service...
sudo mv /var/www/Scripts/alarm /etc/init.d/

# make service autostart...
sudo update-rc.d alarm start

# modify permisions on folder to allow web page to read/write data files
cd /var
sudo chmod -R 777 www

# github won't store an empty directory (sigh !), so we need to make one manualy to store the log files
mkdir /var/www/logs

# start the service (because there hasn't been a re-boot)
alarm start
