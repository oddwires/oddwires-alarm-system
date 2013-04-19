#!/bin/sh
# Routine to repeat alarm message through audio channel.
while :
   do
     aplay -q /var/www/sounds/danger3.wav ;
     aplay -q /var/www/sounds/bank_alarm_2.wav;
     aplay -q /var/www/sounds/bank_alarm_2.wav;
     aplay -q /var/www/sounds/bank_alarm_2.wav ;
   done
