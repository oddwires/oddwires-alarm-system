#!/bin/sh
# Routine to repeat alarm message through audio channel.
while :
   do
     aplay -q /var/www/sounds/alarm.wav;
   done