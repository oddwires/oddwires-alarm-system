#!/bin/bash
#################################################################################################################################
#                                                                                                                               #
# Oddwires alarm service.  Version 2.0                                                                                          #
# Latest details and build instructions... http://oddwires.co.uk/?page_id=123                                                   #
# Latest code and issues...                https://github.com/oddwires/oddwires-alarm-system                                    #
#                                                                                                                               #
#################################################################################################################################
#                                                                                                                               #
# Features:                                                                                                                     #
#     RasPi platform - compatable with Rev 1.0 and Rev 2.0 hardware                                                             #
#     8 configurable alarm zones (cabled)                                                                                       #
#     3 alarm modes: Standby, Night mode, Day mode                                                                              #
#     5 configurable automation channels (radio controlled)                                                                     #
#     Industry standard 12 volt interface to alarm sensors, bell boxes and strobe                                               #
#     Internet remote control using iPhone 4s web app interface                                                                 #
#     Animated page transitions and user controls - look and feel of a native app.                                              #
#     eMail alerts for alarm events                                                                                             #
#     Automatically detect changes to router IP address                                                                         #
#     Scheduled tasks                                                                                                           #
#     Security logs                                                                                                             #
#                                                                                                                               #
#################################################################################################################################

# Use set -x to enable debuging
# Use set +x to disable debuging

# Going to need to make some tough decisions before we start...
MaxRC=5                                                                                       # Maximum number of RC channels
MaxAlarm=8                                                                                    # Maximum number of alarm channels

# use an array for the RC channel status ...
declare -a RCs=('off' 'off' 'off' 'off' 'off' 'off' 'off' 'off')
#declare -a RCs=()

# use an array for RC channel config ...
#declare -a RCc=('RC channel 1' 'RC channel 2' 'RC channel 3' 'RC channel 4' 'RC channel 5' 'RC channel 6' 'RC channel 7' 'RC channel 8'
#                'RC channel 9' 'RC channel 10' 'RC channel 11' 'RC channel 12' 'RC channel 13' 'RC channel 14' 'RC channel 15' 'RC channel 16')

declare -a RCc=()

# use three arrays for credentials. Details are loaded from file at startup.
declare -a lgns=()
declare -a emails=()
declare -a pwds=()

# can't use a 2 dimensional array to store the alarm zone config, so use a separate array for each zone.
# format of each array is 'type', 'name','chimes','Day mode','Night mode','trigger status'
# I've assigned default values, but these will be overwritten at startup by either the user or factory defaults.

declare -a z1=('alarm' 'Zone 1' 'off' 'on' 'off' 'false')
declare -a z2=('alarm' 'Zone 2' 'off' 'on' 'off' 'false')
declare -a z3=('alarm' 'Zone 3' 'off' 'on' 'off' 'false')
declare -a z4=('alarm' 'Zone 4' 'off' 'on' 'off' 'false')
declare -a z5=('alarm' 'Zone 5' 'off' 'on' 'off' 'false')
declare -a z6=('alarm' 'Zone 6' 'off' 'on' 'off' 'false')
declare -a z7=('alarm' 'Zone 7' 'off' 'on' 'off' 'false')
declare -a z8=('tamper' 'Tamper loop' 'off' 'off' 'off' 'false')

# Tasks are passed back as an index number. This array expands the number into a string to use in the cron job.
declare -a cmnd=('(task):(RasPi):Check ip'             \
                 '(task):(RasPi):mode:Standby'         \
                 '(task):(RasPi):mode:Night mode'      \
                 '(task):(RasPi):mode:Day mode'        \
                 '(task):(RasPi):remote control:1:on'  \
                 '(task):(RasPi):remote control:1:off' \
                 '(task):(RasPi):remote control:2:on'  \
                 '(task):(RasPi):remote control:2:off' \
                 '(task):(RasPi):remote control:3:on'  \
                 '(task):(RasPi):remote control:3:off' \
                 '(task):(RasPi):remote control:4:on'  \
                 '(task):(RasPi):remote control:4:off' \
                 '(task):(RasPi):remote control:5:on'  \
                 '(task):(RasPi):remote control:5:off' \
                 '(task):(RasPi):remote control:6:on'  \
                 '(task):(RasPi):remote control:6:off' \
                 '(task):(RasPi):remote control:7:on'  \
                 '(task):(RasPi):remote control:7:off' \
                 '(task):(RasPi):remote control:8:on'  \
                 '(task):(RasPi):remote control:8:off')

alarm="Set" ; mode="Standby"     # Note: ${alarm} has 3 states: 'Set' 'Active !' and 'Timeout !'
sw1_old="1" ; sw2_old="1" ; sw3_old="1" ; sw4_old="1" ; sw5_old="1" ; sw6_old="1" ; sw7_old="1" ; sw8_old="1"

# GLOBAL variables used by Setup ...
SETUP_routerIP=""
SETUP_localIP="?"
SETUP_duration=""
SETUP_location=""
SETUP_diskused=""
SETUP_diskperc=""
SETUP_disktotal=""
SETUP_memory=""
SETUP_model=""

# GLOBAL variables used by email ...
EMAIL_server=""
EMAIL_port=""
EMAIL_sender=""
EMAIL_password=""

hardware="unknown"

# start defining functions ...

WriteUsers()
#################################################################################################################################
#                                                                                                                               #
# Function to dump user credentials from memory to file.                                                                        #
#                                                                                                                               #
#################################################################################################################################
{ if [ -f /var/www/user.txt ]; then                                # clear out previous results
    rm /var/www/user.txt; fi
  count=0
  for Usr in "${lgns[@]}"; do
    echo ${Usr}":"${pwds[${count}]}":"${emails[${count}]} >>/var/www/user.txt
    ((count++))
  done
  chgrp root /var/www/user.txt                                     # only visible to root
}

ReadUsers()
#################################################################################################################################
#                                                                                                                               #
# Function to load user credentials from file to memory.                                                                        #
#                                                                                                                               #
#################################################################################################################################
{ echo loading
  if [ -r /var/www/user.txt ]; then
    count=0
    while read info; do
#      echo $info                                                  # Diagnostic
       OLD_IFS="$IFS"                                              # new mechanism
       IFS=":"                                                     # split the command on ':' - spaces are allowed
       set -f                                                      # Globbing off
       PARAMS=( $info )
       set +f                                                      # Globbing on
       IFS="$OLD_IFS"
       if [[ -z ${PARAMS[2]} ]] ; then                             # BASH arrays won't store a NULL character - elements following
            PARAMS[2]="(no email)"                                 # a NULL will get shuffled down one. So if we need to detect a 
       fi                                                          # NULL email, and write something in its place.
       lgns[${count}]="${PARAMS[0]}"
       pwds[${count}]="${PARAMS[1]}"
       emails[${count}]="${PARAMS[2]}"
       ((count++))
    done < /var/www/user.txt
  fi }

CheckIP()
#################################################################################################################################
#                                                                                                                               #
# Subroutine uses an external site http://checkip.dyndns.com to obtain router details.                                          #
# This routing should not be called more then one hit every five minutes (300 seconds).                                         #
#                                                                                                                               #
#################################################################################################################################
{ Current_routerIP=$(wget -q -O - checkip.dyndns.org|sed -e 's/.*Current IP Address: //' -e 's/<.*$//')
  if [[ $Current_routerIP != $SETUP_routerIP ]] ; then
    title="Alarm system: Router IP change"
    eMail "$title"
    SETUP_routerIP=${Current_routerIP}                                            # Update variable
    tmp=${CURRTIME}",(task),(RasPi),New router IP = "${SETUP_routerIP}            # string for log
  else
    tmp=${CURRTIME}",(task),(RasPi),Check router IP - no change"                  # string for log
  fi
  echo $tmp >> $LOGFILE                                                           # log the event
  echo $tmp                                                                       # copy to console
}

InitPorts()
#################################################################################################################################
#                                                                                                                               #
# BASH uses BCM GPIO numbers (the pin names on the Broadcom chip) to define the GPIO ports.                                     #
# The code becomes a lot easier to debug if these numbers are mapped to physical pins on the RasPi GPIO header.                 #
# I've also included the path to the Broadcom ports directory ('/sys/class/gpio/') to simplify usage.                           #
#                                                                                                                               #
#################################################################################################################################
{
# Map physical pin numbers to full Broadcom ports directory + port name...
          PIN_7=/sys/class/gpio/gpio4
          PIN_26=/sys/class/gpio/gpio7                      # Alarm bell output
          PIN_24=/sys/class/gpio/gpio8
          PIN_21=/sys/class/gpio/gpio9                      # Audio mute output
          PIN_23=/sys/class/gpio/gpio11                     # Alarm strobe output
          PIN_11=/sys/class/gpio/gpio17
          PIN_12=/sys/class/gpio/gpio18
          PIN_15=/sys/class/gpio/gpio22
          PIN_16=/sys/class/gpio/gpio23
          PIN_18=/sys/class/gpio/gpio24
          PIN_22=/sys/class/gpio/gpio25
# One of the pins changed name when the RasPi went from Rev 1.0 to Rev 2.0 hardware.
if [[ $hardware = "Raspberry Pi Rev 1.0" ]]; then
          PIN_13=/sys/class/gpio/gpio21                     # Rev 1.0 hardware
else
          PIN_13=/sys/class/gpio/gpio27                     # Rev 2.0 hardware (and anything newer)
fi

# So these are the 12 physical pins we are going to use...
declare -a Allpins=('PIN_7' 'PIN_11' 'PIN_12' 'PIN_13' 'PIN_15' 'PIN_16'
                    'PIN_18' 'PIN_21' 'PIN_22' 'PIN_23' 'PIN_24' 'PIN_26')

# Initialise the Broadcom ports associated with the physical pins...
for thispin in "${Allpins[@]}"; do
   tmp=${!thispin}                                          # 'Variable indirection' (Google it - I had to !)
#  echo $tmp                                                # DIAGNOSTIC - $tmp becomes the full Broadcom name for the physical pin
   GPIOnum=${tmp:20}                                        # lose first 20 characters ('/sys/class/gpio/gpio') leaves just the number
   if [ -d $tmp ]; then                                     # if some other process is using the port...
      echo ${GPIOnum} > /sys/class/gpio/unexport            # ...grab it back
   fi
   echo ${GPIOnum} > /sys/class/gpio/export                 # now the port is free, grab it for our use
done

# Set 10 pins as outputs...
echo "out" > $PIN_7/direction                               # (gpio4)
echo "out" > $PIN_11/direction                              # (gpio17)
echo "out" > $PIN_12/direction                              # (gpio18)
echo "out" > $PIN_13/direction                              # (gpio21 or gpio27 depending on hardware)
echo "out" > $PIN_15/direction                              # (gpio22)
echo "out" > $PIN_16/direction                              # (gpio23)
echo "out" > $PIN_18/direction                              # (gpio24)
echo "out" > $PIN_21/direction                              # (gpio9)
echo "out" > $PIN_23/direction                              # (gpio11)
echo "out" > $PIN_26/direction                              # (gpio7)

# Set 2 pins as inputs...
echo "in" > $PIN_24/direction                               # (gpio8)
echo "in" > $PIN_22/direction                               # (gpio25)

# Set outputs to inactive state...
echo "0" > $PIN_7/value                                     # LED Anode output   - inactive=low
echo "0" > $PIN_11/value                                    # LED Anode output   - inactive=low
echo "0" > $PIN_12/value                                    # LED Anode output   - inactive=low
echo "0" > $PIN_13/value                                    # LED Anode output   - inactive=low
echo "1" > $PIN_15/value                                    # LED Cathode output - inactive=high
echo "1" > $PIN_16/value                                    # LED Cathode output - inactive=high
echo "1" > $PIN_18/value                                    # LED Cathode output - inactive=high
echo "1" > $PIN_21/value                                    # Audio mute         - muted=high
echo "0" > $PIN_23/value                                    # Alarm strobe       - inactive=low
echo "0" > $PIN_26/value                                    # Alarm bell         - inactive=low

# Initialise sound drivers.
sudo modprobe snd_bcm2835
tmp=${CURRTIME}",(alarm),(RasPi),Sound drivers initialised"
echo $tmp >> $LOGFILE                                       # log the event
echo $tmp                                                   # tell the user
}

eMail()
#################################################################################################################################
#                                                                                                                               #
# Performs a few basic checks on the email credentials.                                                                         #
# If everything seems ok, a standard format email is sent out.                                                                  #
# $1 = Subject                                                                                                                  #
# Note: The Mailx MTA is being used without a configuration file, so all server connection details are passed as paramteres.    #
#       This allows server details to be changed through the iPhone interface without having to get all 'Linuxy'                #
#                                                                                                                               #
#################################################################################################################################
{  # Build the circulation list...
   circlist="";                                             # clear out variable
   for usr in "${emails[@]}"; do                            # build current circulation list
     if [[ "$usr" != "(no email)" ]] ; then                 # Don't include accounts with no email - the MTA throws a dicky fit !
       circlist=${circlist}${usr}","
     fi
   done
  # Quick and dirty test for valid email configuration....
  if [[ ${EMAIL_server} == "" ]] || [[ ${EMAIL_port} == "" ]] || \
     [[ ${EMAIL_sender} == "" ]] || [[ ${EMAIL_password} == "" ]] || \
     [[ ${circlist} == "" ]] ; then
     tmp=${CURRTIME}",(alarm),(RasPi),Invalid email credentials or no circulation list - email not sent"
     echo $tmp >> $LOGFILE                                  # log the event
     echo $tmp                                              # tell the user
  else
     # Falls through here if we have some kind of email configuration and some kind of circulation list
     # We still can't guarantee the email will go, but lets try anyway...
     # Update the system info...
       SETUP_localIP=$(/sbin/ifconfig eth0 | grep 'inet addr:' | cut -d: -f2 | awk '{ print $1}')
       SETUP_diskused=$(df -h | grep rootfs | awk '{print $4}')
       SETUP_diskperc=$(df -h | grep rootfs | awk '{print $5}')
       SETUP_disktotal=$(df -h | grep rootfs | awk '{print $2}')
       tmp=$(cat /proc/meminfo | grep MemTotal | awk '{print $2}')                # in KB
       SETUP_memory=$((tmp /1024))M                                               # convert to MB

     # Build the message...
       msg='From: \t\t\t'$SETUP_location
       msg=$msg'\nEvent logged at:\t'${CURRTIME}

       msg=$msg'\n\nTriggered zones:\t'
       zones=''
       if ${z1[5]} ; then zones=$zones${z1[1]}'\n\t\t\t' ; fi # Zone 1 triggered, so add name
       if ${z2[5]} ; then zones=$zones${z2[1]}'\n\t\t\t' ; fi # Zone 2 triggered, so add name
       if ${z3[5]} ; then zones=$zones${z3[1]}"\n\t\t\t" ; fi # Zone 3 triggered, so add name
       if ${z4[5]} ; then zones=$zones${z4[1]}"\n\t\t\t" ; fi # Zone 4 triggered, so add name
       if ${z5[5]} ; then zones=$zones${z5[1]}"\n\t\t\t" ; fi # Zone 5 triggered, so add name
       if ${z6[5]} ; then zones=$zones${z6[1]}"\n\t\t\t" ; fi # Zone 6 triggered, so add name
       if ${z7[5]} ; then zones=$zones${z7[1]}"\n\t\t\t" ; fi # Zone 7 triggered, so add name
       if ${z8[5]} ; then zones=$zones${z8[1]}"\n\t\t\t" ; fi # Zone 8 triggered, so add name
       if [[ ${zones} == "" ]] ; then zones='None\n' ; fi     # default case - none triggered
       msg=$msg$zones

#       msg=$msg'\nHardware:\t\t'${SETUP_model}
       msg=$msg'\nHardware:\t\t'${hardware}
       msg=$msg'\nMemory:\t\t'${SETUP_memory}
       msg=$msg'\nDisk used:\t\t'${SETUP_diskused}' of '${SETUP_disktotal}' ('${SETUP_diskperc}' free)'
       msg=$msg'\n\nLocal IP:\t\t'http://${SETUP_localIP}
       msg=$msg'\n\nRouter IP:\t\t'http://${SETUP_routerIP}
     # Build the mailx command string...
       set -f                                               # Globbing off
       tmp='echo -e "'$msg'" | mailx -s "'$1'" -S smtp-use-starttls -S ssl-verify=ignore -S smtp-auth=login
       -S smtp=smtp://'$EMAIL_server':'$EMAIL_port' -S from="'$EMAIL_sender'"
       -S smtp-auth-user='$EMAIL_sender' -S smtp-auth-password='$EMAIL_password' '$circlist
     eval $tmp                                              # send the email without echoing all the credentials to the screen
#    echo $tmp                                              # DIAGNOSTIC - used to check MAILX command line is ok
     set +f                                                 # Globbing back on
     tmp=${CURRTIME}",(alarm),(RasPi),"$1" - email sent"
     echo $tmp >> $LOGFILE                                  # log the event
     echo $tmp                                              # tell the user
  fi
}

RemoteControl()
#################################################################################################################################
#                                                                                                                               #
# This is where we start banging the bits to turn stuff on/off in the real world.                                               #
# Routine is passed 2 parameters, $1=channel number, $2=on/off                                                                  #
#                                                                                                                               #
#################################################################################################################################
{ case "$1" in
   "1")                                                     # Remote Control channel 1
    RCs[0]=$2                                               # record the new status on/off
    if [ "$2" = "on" ]; then                                # RC channel needs to turn on...
      echo "1" > $PIN_12/value                              # LED anode high
      echo "0" > $PIN_16/value                              # LED cathode low - LED goes on
      sleep 0.4                                             # duration of button push
      echo "0" > $PIN_12/value                              # LED anode low - LED goes off
      echo "1" > $PIN_16/value                              # LED cathode high
    else                                                    # RC channel needs to turn off...
      echo "1" > $PIN_11/value                              # LED anode high
      echo "0" > $PIN_16/value                              # LED cathode low - LED goes on
      sleep 0.4                                             # duration of button push
      echo "0" > $PIN_11/value                              # LED anode low - LED goes off
      echo "1" > $PIN_16/value                              # LED cathode high
    fi;;
   "2")                                                     # Remote Control channel 2
    RCs[1]=$2                                               # record the new status on/off
    if [ "$2" = "on" ]; then                                # RC channel needs to turn on...
      echo "1" > $PIN_7/value                               # LED anode high
      echo "0" > $PIN_16/value                              # LED cathode low - LED goes on
      sleep 0.4                                             # duration of button push
      echo "0" > $PIN_7/value                               # LED anode low - LED goes off
      echo "1" > $PIN_16/value                              # LED cathode high
    else                                                    #  RC channel needs to turn off...
      echo "1" > $PIN_13/value                              # LED anode high
      echo "0" > $PIN_16/value                              # LED cathode low - LED goes on
      sleep 0.4                                             # duration of button push
      echo "0" > $PIN_13/value                              # LED anode low - LED goes off
      echo "1" > $PIN_16/value                              # LED cathode high
    fi;;
   "3")                                                     # Remote Control channel 3
    RCs[2]=$2                                               # record the new status on/off
    if [ "$2" = "on" ]; then                                # RC channel needs to turn on...
      echo "1" > $PIN_13/value                              # LED anode high
      echo "0" > $PIN_15/value                              # LED cathode low - LED goes on
      sleep 0.4                                             # duration of button push
      echo "0" > $PIN_13/value                              # LED anode low - LED goes off
      echo "1" > $PIN_15/value                              # LED cathode high
    else                                                    # RC channel needs to turn off...
      echo "1" > $PIN_7/value                               # LED anode high
      echo "0" > $PIN_18/value                              # LED cathode low - LED goes on
      sleep 0.4                                             # duration of button push
      echo "0" > $PIN_7/value                               # LED anode low - LED goes off
      echo "1" > $PIN_18/value                              # LED cathode high
    fi;;
   "4")                                                     # Remote Control channel 4
    RCs[3]=$2                                               # record the new status on/off
    if [ "$2" = "on" ]; then                                # RC channel needs to turn on...
      echo "1" > $PIN_11/value                              # LED anode high
      echo "0" > $PIN_15/value                              # LED cathode low - LED goes on
      sleep 0.4                                             # duration of button push
      echo "0" > $PIN_11/value                              # LED anode low - LED goes off
      echo "1" > $PIN_15/value                              # LED cathode high
    else                                                    # RC channel needs to turn off...
      echo "1" > $PIN_12/value                              # LED anode high
      echo "0" > $PIN_18/value                              # LED cathode low - LED goes on
      sleep 0.4                                             # duration of button push
      echo "0" > $PIN_12/value                              # LED anode low - LED goes off
      echo "1" > $PIN_18/value                              # LED cathode high
    fi;;
   "5")                                                     # Remote Control channel 5
    RCs[4]=$2                                               # record the new status on/off
    if [ "$2" = "on" ]; then                                # RC channel needs to turn on...
      echo "1" > $PIN_12/value                              # LED anode high
      echo "0" > $PIN_15/value                              # LED cathode low - LED goes on
      sleep 0.4                                             # duration of button push
      echo "0" > $PIN_12/value                              # LED anode low - LED goes off
      echo "1" > $PIN_15/value                              # LED cathode high
    else                                                    # RC channel needs to turn off...
      echo "1" > $PIN_11/value                              # LED anode high
      echo "0" > $PIN_18/value                              # LED cathode low - LED goes on
      sleep 0.4                                             # duration of button push
      echo "0" > $PIN_11/value                              # LED anode low - LED goes off
      echo "1" > $PIN_18/value                              # LED cathode high
    fi;;
   "6")                                                     # Remote Control channel 6
    RCs[5]=$2;;                                             # record the new status on/off
   "7")                                                     # Remote Control channel 7
    RCs[6]=$2;;                                             # record the new status on/off
   "8")                                                     # Remote Control channel 8
    RCs[7]=$2;;                                             # record the new status on/off
esac
}

load_status_file()
#################################################################################################################################
#                                                                                                                               #
# Routine to load configuration file to memory.                                                                                 #
# Handles up to 16 RC channel names                                                                                             #
#                                                                                                                               #
#################################################################################################################################
{ set -f                                      # Globbing off
echo "load status file"
  while read info; do
#     echo "info1 - "$info                    # Diagnostic
        OLD_IFS="$IFS"                        # split the line regardless of what it is
        IFS=":"
        STR_ARRAY=( $info )
        IFS="$OLD_IFS"
        case "${STR_ARRAY[0]}" in             # Just looking at the first string
          "zc #1...........")                 # Zone 1 ...
                z1[0]=${STR_ARRAY[1]}         # Type
                z1[1]=${STR_ARRAY[2]}         # Name
                z1[2]=${STR_ARRAY[3]}         # Chimes
                z1[3]=${STR_ARRAY[4]}         # Day mode
                z1[4]=${STR_ARRAY[5]}         # Night mode
                z1[5]="false";;               # Trigger status - reset to false
          "zc #2...........")                 # Zone 2 ...
                z2[0]=${STR_ARRAY[1]}         # Type
                z2[1]=${STR_ARRAY[2]}         # Name
                z2[2]=${STR_ARRAY[3]}         # Chimes
                z2[3]=${STR_ARRAY[4]}         # Day mode
                z2[4]=${STR_ARRAY[5]}         # Night mode
                z2[5]="false";;               # Trigger status - reset to false
          "zc #3...........")                 # Zone 3 ...
                z3[0]=${STR_ARRAY[1]}         # Type
                z3[1]=${STR_ARRAY[2]}         # Name
                z3[2]=${STR_ARRAY[3]}         # Chimes
                z3[3]=${STR_ARRAY[4]}         # Day mode
                z3[4]=${STR_ARRAY[5]}         # Night mode
                z3[5]="false";;               # Trigger status - reset to false
          "zc #4...........")                 # Zone 4 ...
                z4[0]=${STR_ARRAY[1]}         # Type
                z4[1]=${STR_ARRAY[2]}         # Name
                z4[2]=${STR_ARRAY[3]}         # Chimes
                z4[3]=${STR_ARRAY[4]}         # Day mode
                z4[4]=${STR_ARRAY[5]}         # Night mode
                z4[5]="false";;               # Trigger status - reset to false
          "zc #5...........")                 # Zone 5 ...
                z5[0]=${STR_ARRAY[1]}         # Type
                z5[1]=${STR_ARRAY[2]}         # Name
                z5[2]=${STR_ARRAY[3]}         # Chimes
                z5[3]=${STR_ARRAY[4]}         # Day mode
                z5[4]=${STR_ARRAY[5]}         # Night mode
                z5[5]="false";;               # Trigger status - reset to false
          "zc #6...........")                 # Zone 6 ...
                z6[0]=${STR_ARRAY[1]}         # Type
                z6[1]=${STR_ARRAY[2]}         # Name
                z6[2]=${STR_ARRAY[3]}         # Chimes
                z6[3]=${STR_ARRAY[4]}         # Day mode
                z6[4]=${STR_ARRAY[5]}         # Night mode
                z6[5]="false";;               # Trigger status - reset to false
          "zc #7...........")                 # Zone 7 ...
                z7[0]=${STR_ARRAY[1]}         # Type
                z7[1]=${STR_ARRAY[2]}         # Name
                z7[2]=${STR_ARRAY[3]}         # Chimes
                z7[3]=${STR_ARRAY[4]}         # Day mode
                z7[4]=${STR_ARRAY[5]}         # Night mode
                z7[5]="false";;               # Trigger status - reset to false
          "zc #8...........")                 # Zone 8 ...
                z8[0]=${STR_ARRAY[1]}         # Type
                z8[1]=${STR_ARRAY[2]}         # Name
                z8[2]=${STR_ARRAY[3]}         # Chimes
                z8[3]=${STR_ARRAY[4]}         # Day mode
                z8[4]=${STR_ARRAY[5]}         # Night mode
                z8[5]="false";;               # Trigger status - reset to false
          "RC channel #1...")                 # RC channel 1 ...
                RCc[0]=${info[0]:17};;        # loose first 17 characters...
          "RC channel #2...")                 # RC channel 2 ...
                RCc[1]=${info[0]:17};;        # loose first 17 characters...
          "RC channel #3...")                 # RC channel 3 ...
                RCc[2]=${info[0]:17};;        # loose first 17 characters...
          "RC channel #4...")                 # RC channel 4 ...
                RCc[3]=${info[0]:17};;        # loose first 17 characters...
          "RC channel #5...")                 # RC channel 5 ...
                RCc[4]=${info[0]:17};;        # loose first 17 characters...
          "RC channel #6...")                 # RC channel 6 ...
                RCc[5]=${info[0]:17};;        # loose first 17 characters...
          "RC channel #7...")                 # RC channel 7 ...
                RCc[6]=${info[0]:17};;        # loose first 17 characters...
          "RC channel #8...")                 # RC channel 8 ...
                RCc[7]=${info[0]:17};;        # loose first 17 characters...
          "RC channel #9...")                 # RC channel 9 ...
                RCc[8]=${info[0]:17};;        # loose first 17 characters...
          "RC channel #10...")                # RC channel 10 ...
                RCc[9]=${info[0]:17};;        # loose first 17 characters...
          "RC channel #11...")                # RC channel 11 ...
                RCc[10]=${info[0]:17};;       # loose first 17 characters...
          "RC channel #12...")                # RC channel 12 ...
                RCc[11]=${info[0]:17};;       # loose first 17 characters...
          "RC channel #13...")                # RC channel 13 ...
                RCc[12]=${info[0]:17};;       # loose first 17 characters...
          "RC channel #14...")                # RC channel 14 ...
                RCc[13]=${info[0]:17};;       # loose first 17 characters...
          "RC channel #15...")                # RC channel 15 ...
                RCc[14]=${info[0]:17};;       # loose first 17 characters...
          "RC channel #16...")                # RC channel 16 ...
                RCc[15]=${info[0]:17};;       # loose first 17 characters...
          "Location........")
                SETUP_location=${STR_ARRAY[1]};;
          "Router IP.......")
                SETUP_routerIP=${STR_ARRAY[1]};;
          "Local IP........")
                SETUP_localIP=${STR_ARRAY[1]};;
          "Alarm duration..")
                SETUP_duration=${STR_ARRAY[1]};;
          "Disk used.......")
                SETUP_diskused=${STR_ARRAY[1]};;
          "Disk used %.....")
                SETUP_diskperc=${STR_ARRAY[1]};;
          "Disk total......")
                SETUP_disktotal=${STR_ARRAY[1]};;
          "Memory..........")
                SETUP_memory=${STR_ARRAY[1]};;
          "Hardware........")
                SETUP_model=${STR_ARRAY[1]};;
          "Email server....")
                EMAIL_server=${STR_ARRAY[1]};;
          "Email port......")
                EMAIL_port=${STR_ARRAY[1]};;
          "Email sender....")
                EMAIL_sender=${STR_ARRAY[1]};;
          "Email password..")
                EMAIL_password=${STR_ARRAY[1]};;
          "Cron jobs")
                FLAG="true"                              # flag we have found section
                echo "" >/var/www/temp.txt;;             # clear old file and create a new one. Creating it here ensures we have a file
                                                         # even if we have no data in it.
          "Users")
                FLAG="false";;                           # flag end of section (any section)
        esac
        if [[ ${FLAG} = "true" ]] && [[ ${info} != "Cron jobs:" ]] && [[ ${info} != "" ]]; then
         # parsing the cronjobs data - so make a temp copy...
                 arr=($info)                             # split info into an array...
                 trimmed=$(echo ${arr[5]})               # use echo to remove trailing /r
                 str='echo "'${cmnd[${trimmed}]}'" >>/var/www/uploads/input.txt'
                 tmp=${arr[0]}" "${arr[1]}" "${arr[2]}" "${arr[3]}" "${arr[4]}" "$str
                 echo "${tmp}" >>/var/www/temp.txt      
        fi
  done <$1                                               # file name passed as parameter.
set +f                                                   # Globbing back on
sed -i -e "1d" /var/www/temp.txt                         # the first line is always blank so remove it
crontab /var/www/temp.txt                                # Load cronjobs copied from status file
rm -f /var/www/temp.txt                                  # delete temp cronjobs file
}

write_status_file()
#################################################################################################################################
#                                                                                                                               #
# This file is  used as a status flag by the web page.                                                                          #
# The web page reloads as soon as the file appears. So to prevent the web page from loading before the file has finished being  #
# written to, it is created under a temporary name, and is only changed to the status file when all the data has been written.  #
#                                                                                                                               #
#################################################################################################################################
{
echo "Alarm status:" >>/var/www/temp1.txt
echo "Alarm..........:"$alarm >>/var/www/temp1.txt
echo "Mode............"$mode >>/var/www/temp1.txt
echo >>/var/www/temp1.txt
echo "Alarm zone status:" >>/var/www/temp1.txt
echo "zs #1...........:"$sw1 >>/var/www/temp1.txt
echo "zs #2...........:"$sw2 >>/var/www/temp1.txt
echo "zs #3...........:"$sw3 >>/var/www/temp1.txt
echo "zs #4...........:"$sw4 >>/var/www/temp1.txt
echo "zs #5...........:"$sw5 >>/var/www/temp1.txt
echo "zs #6...........:"$sw6 >>/var/www/temp1.txt
echo "zs #7...........:"$sw7 >>/var/www/temp1.txt
echo "zs #8...........:"$sw8 >>/var/www/temp1.txt
echo >>/var/www/temp1.txt
echo "Alarm zone config:" >>/var/www/temp1.txt
echo "zc #1...........:"${z1[0]}":"${z1[1]}":"${z1[2]}":"${z1[3]}":"${z1[4]}":"${z1[5]}":" >>/var/www/temp1.txt
echo "zc #2...........:"${z2[0]}":"${z2[1]}":"${z2[2]}":"${z2[3]}":"${z2[4]}":"${z2[5]}":" >>/var/www/temp1.txt
echo "zc #3...........:"${z3[0]}":"${z3[1]}":"${z3[2]}":"${z3[3]}":"${z3[4]}":"${z3[5]}":" >>/var/www/temp1.txt
echo "zc #4...........:"${z4[0]}":"${z4[1]}":"${z4[2]}":"${z4[3]}":"${z4[4]}":"${z4[5]}":" >>/var/www/temp1.txt
echo "zc #5...........:"${z5[0]}":"${z5[1]}":"${z5[2]}":"${z5[3]}":"${z5[4]}":"${z5[5]}":" >>/var/www/temp1.txt
echo "zc #6...........:"${z6[0]}":"${z6[1]}":"${z6[2]}":"${z6[3]}":"${z6[4]}":"${z6[5]}":" >>/var/www/temp1.txt
echo "zc #7...........:"${z7[0]}":"${z7[1]}":"${z7[2]}":"${z7[3]}":"${z7[4]}":"${z7[5]}":" >>/var/www/temp1.txt
echo "zc #8...........:"${z8[0]}":"${z8[1]}":"${z8[2]}":"${z8[3]}":"${z8[4]}":"${z8[5]}":" >>/var/www/temp1.txt
echo >>/var/www/temp1.txt
echo "Remote Control status:" >>/var/www/temp1.txt
for (( i=0; i<MaxRC; i++ )) ; {
    echo "RC channel #${i}..."${RCs[${i}]} >>/var/www/temp1.txt
}
echo >>/var/www/temp1.txt
echo "Remote Control config:" >>/var/www/temp1.txt
for (( i=0; i<MaxRC; i++ )) ; {
    echo "RC channel #"$((${i}+1))"...:"${RCc[${i}]} >>/var/www/temp1.txt
}
echo >>/var/www/temp1.txt
echo "Configuration:" >>/var/www/temp1.txt
echo "Location........:"${SETUP_location} >>/var/www/temp1.txt
echo "Router IP.......:"${SETUP_routerIP} >>/var/www/temp1.txt
echo "Local IP........:"${SETUP_localIP} >>/var/www/temp1.txt
echo "Alarm duration..:"${SETUP_duration} >>/var/www/temp1.txt
echo "Disk used.......:"${SETUP_diskused} >>/var/www/temp1.txt
echo "Disk used %.....:"${SETUP_diskperc} >>/var/www/temp1.txt
echo "Disk total......:"${SETUP_disktotal} >>/var/www/temp1.txt
echo "Memory..........:"${SETUP_memory} >>/var/www/temp1.txt
echo "Hardware........:"${SETUP_model} >>/var/www/temp1.txt
echo >>/var/www/temp1.txt
echo "Email:" >>/var/www/temp1.txt
echo "Email server....:"${EMAIL_server} >>/var/www/temp1.txt
echo "Email port......:"${EMAIL_port} >>/var/www/temp1.txt
echo "Email sender....:"${EMAIL_sender} >>/var/www/temp1.txt
echo "Email password..:"${EMAIL_password} >>/var/www/temp1.txt
echo >>/var/www/temp1.txt
echo "Cron jobs:" >>/var/www/temp1.txt
sudo crontab -l >>/var/www/temp2.txt
sed -i -e 's/^M//g' /var/www/temp2.txt                      # remove any Ctrl-M's NOTE THIS IS A REAL CTRL-M not just a ^M
# Substitute the full task string for a task number - this makes subsequent processing in PHP a lot easier...
sed -i -e 's/echo \"(task):(RasPi):Check ip\" >>\/var\/www\/uploads\/input.txt/0/g' /var/www/temp2.txt
sed -i -e 's/echo \"(task):(RasPi):mode:Standby\" >>\/var\/www\/uploads\/input.txt/1/g' /var/www/temp2.txt
sed -i -e 's/echo \"(task):(RasPi):mode:Night mode\" >>\/var\/www\/uploads\/input.txt/2/g' /var/www/temp2.txt
sed -i -e 's/echo \"(task):(RasPi):mode:Day mode\" >>\/var\/www\/uploads\/input.txt/3/g' /var/www/temp2.txt
sed -i -e 's/echo \"(task):(RasPi):remote control:1:on\" >>\/var\/www\/uploads\/input.txt/4/g' /var/www/temp2.txt
sed -i -e 's/echo \"(task):(RasPi):remote control:1:off\" >>\/var\/www\/uploads\/input.txt/5/g' /var/www/temp2.txt
sed -i -e 's/echo \"(task):(RasPi):remote control:2:on\" >>\/var\/www\/uploads\/input.txt/6/g' /var/www/temp2.txt
sed -i -e 's/echo \"(task):(RasPi):remote control:2:off\" >>\/var\/www\/uploads\/input.txt/7/g' /var/www/temp2.txt
sed -i -e 's/echo \"(task):(RasPi):remote control:3:on\" >>\/var\/www\/uploads\/input.txt/8/g' /var/www/temp2.txt
sed -i -e 's/echo \"(task):(RasPi):remote control:3:off\" >>\/var\/www\/uploads\/input.txt/9/g' /var/www/temp2.txt
sed -i -e 's/echo \"(task):(RasPi):remote control:4:on\" >>\/var\/www\/uploads\/input.txt/10/g' /var/www/temp2.txt
sed -i -e 's/echo \"(task):(RasPi):remote control:4:off\" >>\/var\/www\/uploads\/input.txt/11/g' /var/www/temp2.txt
sed -i -e 's/echo \"(task):(RasPi):remote control:5:on\" >>\/var\/www\/uploads\/input.txt/12/g' /var/www/temp2.txt
sed -i -e 's/echo \"(task):(RasPi):remote control:5:off\" >>\/var\/www\/uploads\/input.txt/13/g' /var/www/temp2.txt
# remove any comment lines...
grep -v "#" /var/www/temp2.txt >>/var/www/temp1.txt
echo >>/var/www/temp1.txt
echo "Users:" >>/var/www/temp1.txt
count=0
for Usr in "${lgns[@]}"
do
    echo ${Usr}","${emails[${count}]} >>/var/www/temp1.txt
#   echo ${count}' - '${Usr}","${emails[${count}]}                 # DIAGNOSTIC
    ((count++))
done
rm /var/www/temp2.txt
mv /var/www/temp1.txt $1
}

alm_on()
#################################################################################################################################
#                                                                                                                               #
# Actions required when the alarm activates.                                                                                    #
#                                                                                                                               #
#################################################################################################################################
{ CURRTIME=`date "+%H:%M:%S"`                              # excel format
  tmp=${CURRTIME}",(alarm),(RasPi),Alarm active"
  echo $tmp >> $LOGFILE                                    # log the event
  echo $tmp                                                # tell the user (like he needs to know!)
  echo "1" > $PIN_26/value                                 # set bell port active
  echo "1" > $PIN_23/value                                 # set strobe port active
  echo "0" > $PIN_21/value                                 # Audio on

  /var/www/Scripts/alm.sh &                                # start alarm background process
  disown                                                   # suppress messages from shell

  title="Alarm system: ACTIVE"
  eMail "${title}"

  case "$SETUP_duration" in
   "5s")
       tmp=5;;
   "9m")
       tmp=$((9 * 60));;
   *)                                                    # default case - ensures something will happen
       tmp=$((15 * 60));;
  esac
  ( sleep ${tmp}                                           # setup timeout job
    echo "(alarm):(RasPi):timeout" >>/var/www/uploads/input.txt )&
}

zoneconfig()
#################################################################################################################################
#                                                                                                                               #
# Update the array storing the zone configuration details.                                                                      #
#                                                                                                                               #
#################################################################################################################################
{ case "$1" in
   "1")                                                                                    # zone #1
     z1[0]=$2; z1[1]=$3;z1[2]=$4; z1[3]=$5; z1[4]=$6 z1[5]="false";;
   "2")                                                                                    # zone #2
     z2[0]=$2; z2[1]=$3;z2[2]=$4; z2[3]=$5; z2[4]=$6 z2[5]="false";;
   "3")                                                                                    # zone #3
     z3[0]=$2; z3[1]=$3;z3[2]=$4; z3[3]=$5; z3[4]=$6 z3[5]="false";;
   "4")                                                                                    # zone #4
     z4[0]=$2; z4[1]=$3;z4[2]=$4; z4[3]=$5; z4[4]=$6 z4[5]="false";;
   "5")                                                                                    # zone #5
     z5[0]=$2; z5[1]=$3;z5[2]=$4; z5[3]=$5; z5[4]=$6 z5[5]="false";;
   "6")                                                                                    # zone #6
     z6[0]=$2; z6[1]=$3;z6[2]=$4; z6[3]=$5; z6[4]=$6 z6[5]="false";;
   "7")                                                                                    # zone #7
     z7[0]=$2; z7[1]=$3;z7[2]=$4; z7[3]=$5; z7[4]=$6 z7[5]="false";;
   "8")                                                                                    # zone #8
     z8[0]=$2; z8[1]=$3;z8[2]=$4; z8[3]=$5; z8[4]=$6 z8[5]="false";;
  esac
}

alarm_tests()
#################################################################################################################################
#                                                                                                                               #
# Execution is directed here when an alarm zone has changed state. So this code decides what action, if any, to take.           #
#                                                                                                                               #
#################################################################################################################################
{ # Check Tamper circuits...
  # Check if zone is a tamper and the circuit is active...
    if [[ ${z1[0]} = "tamper" ]] &&  [[ $sw1 = "0" ]]; then z1[5]=true; alarm='Active !'; fi
    if [[ ${z2[0]} = "tamper" ]] &&  [[ $sw2 = "0" ]]; then z2[5]=true; alarm='Active !'; fi
    if [[ ${z3[0]} = "tamper" ]] &&  [[ $sw3 = "0" ]]; then z3[5]=true; alarm='Active !'; fi
    if [[ ${z4[0]} = "tamper" ]] &&  [[ $sw4 = "0" ]]; then z4[5]=true; alarm='Active !'; fi
    if [[ ${z5[0]} = "tamper" ]] &&  [[ $sw5 = "0" ]]; then z5[5]=true; alarm='Active !'; fi
    if [[ ${z6[0]} = "tamper" ]] &&  [[ $sw6 = "0" ]]; then z6[5]=true; alarm='Active !'; fi
    if [[ ${z7[0]} = "tamper" ]] &&  [[ $sw7 = "0" ]]; then z7[5]=true; alarm='Active !'; fi
    if [[ ${z8[0]} = "tamper" ]] &&  [[ $sw8 = "0" ]]; then z8[5]=true; alarm='Active !'; fi
    
  # Check for alarms...
    if [[ $mode = "Night mode" ]]; then                        # alarm is set, so we need to dig even deeper..
      # Check zone is an alarm and circuit is active and zone is enabled in Night mode...
        if [[ ${z1[0]} = "alarm" ]] && [[ $sw1 = "0" ]] && [[ ${z1[4]} = "on" ]]; then z1[5]=true; alarm='Active !'; fi
        if [[ ${z2[0]} = "alarm" ]] && [[ $sw2 = "0" ]] && [[ ${z2[4]} = "on" ]]; then z2[5]=true; alarm='Active !'; fi
        if [[ ${z3[0]} = "alarm" ]] && [[ $sw3 = "0" ]] && [[ ${z3[4]} = "on" ]]; then z3[5]=true; alarm='Active !'; fi
        if [[ ${z4[0]} = "alarm" ]] && [[ $sw4 = "0" ]] && [[ ${z4[4]} = "on" ]]; then z4[5]=true; alarm='Active !'; fi
        if [[ ${z5[0]} = "alarm" ]] && [[ $sw5 = "0" ]] && [[ ${z5[4]} = "on" ]]; then z5[5]=true; alarm='Active !'; fi
        if [[ ${z6[0]} = "alarm" ]] && [[ $sw6 = "0" ]] && [[ ${z6[4]} = "on" ]]; then z6[5]=true; alarm='Active !'; fi
        if [[ ${z7[0]} = "alarm" ]] && [[ $sw7 = "0" ]] && [[ ${z7[4]} = "on" ]]; then z7[5]=true; alarm='Active !'; fi
        if [[ ${z8[0]} = "alarm" ]] && [[ $sw8 = "0" ]] && [[ ${z8[4]} = "on" ]]; then z8[5]=true; alarm='Active !'; fi
    elif [[ $mode = "Day mode" ]]; then                      # alarm is set, so we need to dig even deeper..
      # check zone is an alarm and circuit is active and zone is enabled in Day mode...
        if [[ ${z1[0]} = "alarm" ]] && [[ $sw1 = "0" ]] && [[ ${z1[3]} = "on" ]]; then z1[5]=true; alarm='Active !'; fi
        if [[ ${z2[0]} = "alarm" ]] && [[ $sw2 = "0" ]] && [[ ${z2[3]} = "on" ]]; then z2[5]=true; alarm='Active !'; fi
        if [[ ${z3[0]} = "alarm" ]] && [[ $sw3 = "0" ]] && [[ ${z3[3]} = "on" ]]; then z3[5]=true; alarm='Active !'; fi
        if [[ ${z4[0]} = "alarm" ]] && [[ $sw4 = "0" ]] && [[ ${z4[3]} = "on" ]]; then z4[5]=true; alarm='Active !'; fi
        if [[ ${z5[0]} = "alarm" ]] && [[ $sw5 = "0" ]] && [[ ${z5[3]} = "on" ]]; then z5[5]=true; alarm='Active !'; fi
        if [[ ${z6[0]} = "alarm" ]] && [[ $sw6 = "0" ]] && [[ ${z6[3]} = "on" ]]; then z6[5]=true; alarm='Active !'; fi
        if [[ ${z7[0]} = "alarm" ]] && [[ $sw7 = "0" ]] && [[ ${z7[3]} = "on" ]]; then z7[5]=true; alarm='Active !'; fi
        if [[ ${z8[0]} = "alarm" ]] && [[ $sw8 = "0" ]] && [[ ${z8[3]} = "on" ]]; then z8[5]=true; alarm='Active !'; fi
    fi
  # Check for chimes...
    if [[ ${alarm} = "Set" ]] || [[ ${alarm} = "Timed out !" ]]; then  #  don't chime if alarm is already active
      if [[ ${z1[2]} = "on" && $sw1 = "0" && $sw1_old = "1" ]] || \
         [[ ${z2[2]} = "on" && $sw2 = "0" && $sw2_old = "1" ]] || \
         [[ ${z3[2]} = "on" && $sw3 = "0" && $sw3_old = "1" ]] || \
         [[ ${z4[2]} = "on" && $sw4 = "0" && $sw4_old = "1" ]] || \
         [[ ${z5[2]} = "on" && $sw5 = "0" && $sw5_old = "1" ]] || \
         [[ ${z6[2]} = "on" && $sw6 = "0" && $sw6_old = "1" ]] || \
         [[ ${z7[2]} = "on" && $sw7 = "0" && $sw7_old = "1" ]] || \
         [[ ${z8[2]} = "on" && $sw8 = "0" && $sw8_old = "1" ]]; then chimes=true
      fi
    fi
    # Save new circuit state...
      if [[ "$sw1" -ne "$sw1_old" ]]; then sw1_old=$sw1; fi
      if [[ "$sw2" -ne "$sw2_old" ]]; then sw2_old=$sw2; fi
      if [[ "$sw3" -ne "$sw3_old" ]]; then sw3_old=$sw3; fi
      if [[ "$sw4" -ne "$sw4_old" ]]; then sw4_old=$sw4; fi
      if [[ "$sw5" -ne "$sw5_old" ]]; then sw5_old=$sw5; fi
      if [[ "$sw6" -ne "$sw6_old" ]]; then sw6_old=$sw6; fi
      if [[ "$sw7" -ne "$sw7_old" ]]; then sw7_old=$sw7; fi
      if [[ "$sw8" -ne "$sw8_old" ]]; then sw8_old=$sw8; fi
}

# ...end of function definitions.

#################################################################################################################################
#                                                                                                                               #
# Start initialising the machine...                                                                                             #
#                                                                                                                               #
#################################################################################################################################

CURRTIME=`date "+%H:%M:%S"`                                 # excel format
LOGFILE="/var/www/logs/"`date +%d-%m-%Y`".csv"              # name derived from date

# Check if we are on a RHEL virtual machine....
tmp=$(cat /proc/cpuinfo | grep 'model name' | awk '{print $4}')
if [[ "$tmp" = "QEMU" ]]; then hardware="QEMU virtual machine"; fi

# Now check if we are on a Raspberry Pi....
tmp=$(cat /proc/cpuinfo | grep Revision | awk '{print $3}')
if [[ $tmp = "0002" ]] || [[ $hardware = "0003" ]]; then
    hardware='Raspberry Pi Rev 1.0'
    InitPorts                                               # we are on a PI so initialise the ports
fi
if [[ $tmp = "000d" ]] || [[ $tmp = "000e" ]] || [[ $hardware = "000f" ]]; then
    hardware='Raspberry Pi Rev 2.0'
    InitPorts                                               # we are on a PI so initialise the ports
fi
tmp=${CURRTIME}",(alarm),(RasPi),GPIO ports initialised for "${hardware}
echo $tmp >> $LOGFILE                                       # log the event
echo $tmp                                                   # tell the user

if [ -f /var/www/user.txt ]; then                           # if we have any users defined, load them to memory
  ReadUsers
# echo 'User 0-'${lgns[0]}'-'${emails[0]}'-'${pwds[0]}      # DIAGNOSTIC
  tmp=${CURRTIME}",(alarm),(RasPi),Loading user credentials."
  echo $tmp >> $LOGFILE                                     # log the event
  echo $tmp                                                 # tell the user
fi

if [ -f /var/www/uploads/status.txt ]; then                 # If we have the status from the previous session...
  load_status_file /var/www/uploads/status.txt              # ...load it
  tmp=${CURRTIME}",(alarm),(RasPi),Settings: Restoring last session."
  echo $tmp >> $LOGFILE                                     # log the event
  echo $tmp                                                 # tell the user
  title="System restart"                                    # Send email reporting the restart
  eMail "$title"
elif [ -f /var/www/default.txt ]; then                      # Failing that, do we have user defaults...
  load_status_file /var/www/default.txt                     # ...load 'em
  tmp=${CURRTIME}",(alarm),(RasPi),Settings: Loading user defaults"
  echo $tmp >> $LOGFILE                                     # log the event
  echo $tmp                                                 # tell the user
  title="System restart"                                    # Send email reporting the restart
  eMail "$title"
else
  load_status_file /var/www/factory.txt                     # No session data, or user defaults available, so fail back to factory defaults.
                                                            # Note: No valid email credentials, so can't send email
  tmp=${CURRTIME}",(alarm),(RasPi),Settings: Loading factory defaults"
  echo $tmp >> $LOGFILE                                     # log the event
  echo $tmp                                                 # tell the user
fi

CheckIP                                                     # Refresh current IP and all other hardware details. If the
                                                            # IP is not the same as loaded by the defaults, an additional
                                                            # event will be logged, and an additional email will be sent

write_status_file /var/www/uploads/status.txt               # This shouldn't be needed in normal operation, but during dev work,
                                                            # a system crash will leave the system without a status file, which in
                                                            # turn means the web page won't load. So this ensures a system restart
                                                            # also restarts the web page.
if [ -f /var/www/uploads/input.txt ]; then                          # ... and while we are at it, the most likely reason for a system crash
  rm /var/www/uploads/input.txt                                     # is an incorrectly formated message from the web page, so nuke it.
fi

#################################################################################################################################
#                                                                                                                               #
# Check for any commands from the web page.                                                                                     #
# Commands are passed in the file /var/www/uploadsinput.txt. The file is deleted as soon as the command is executed.            #
#                                                                                                                               #
#################################################################################################################################

while :
do
CURRTIME=`date "+%H:%M:%S"`                                                # excel format
LOGFILE="/var/www/logs/"`date +%d-%m-%Y`".csv"                             # name derived from date
     if [ -r /var/www/uploads/input.txt ];
        then
           while read info
             do
#              echo $info                                                  # Diagnostic
               OLD_IFS="$IFS"                                              # new mechanism
               IFS=":"                                                     # split the command on ':' - spaces are allowed
               set -f                                                      # Globbing off
               PARAMS=( $info )
               set +f                                                      # Globbing on
               IFS="$OLD_IFS"
# DIAGNOSTIC - echo parameters being passed from web pages
#              echo first parameter [0]=${PARAMS[0]}                       # DIAGNOSTIC - username
#              echo second parameter [1]=${PARAMS[1]}                      # DIAGNOSTIC - IP address
#              echo third parameter [2]=${PARAMS[2]}                       # DIAGNOSTIC - command
#              echo fourth  parameter [3]=${PARAMS[3]}                     # DIAGNOSTIC - parameter
#              echo fifth parameter [4]=${PARAMS[4]}                       # DIAGNOSTIC - parameter
#              echo sixth  parameter [5]=${PARAMS[5]}                      # DIAGNOSTIC - parameter
#              echo seventh parameter [6]=${PARAMS[6]}                     # DIAGNOSTIC - parameter
#              echo eight parameter [7]=${PARAMS[7]}                       # DIAGNOSTIC - parameter

               case "${PARAMS[2]}" in
                 "logon" | "failed logon" | "logoff")                      # either way - just log it
                   tmp=${CURRTIME}","${PARAMS[0]}","${PARAMS[1]}","${PARAMS[2]}
                   echo $tmp >> $LOGFILE                                   # log the event
                   echo $tmp;;                                             # tell the user
                 "mode")
                   tmp=${CURRTIME}","${PARAMS[0]}","${PARAMS[1]}","${PARAMS[2]}","${PARAMS[3]}
                   echo $tmp >> $LOGFILE                                   # log the event
                   echo $tmp                                               # tell the user
                   if [[ $mode != ${PARAMS[3]} ]]; then
                   # falls through here if we need to change the alarm mode...
                       mode=${PARAMS[3]}                                       # set new mode
                       alarm_tests                                             # check if this causes an alarm
                       sw1_old="1" ; sw2_old="1" ; sw3_old="1" ; sw4_old="1"   # reset zone states NB this can trigger
                       sw5_old="1" ; sw6_old="1" ; sw7_old="1" ; sw8_old="1"   # the alarm if any zone is open
#                      alarm_tests                                             # check if this causes an alarm
                       title="Alarm system: "${PARAMS[3]}
                       eMail "$title"
                   else
                   # falls through here if the alarm is already in the selected mode.
                   #  i.e. we have already set the alarm, so we want an early night and don't want to be disturbed by emails...
                       tmp='Alarm system already in '${PARAMS[3]}' - email suppressed.'
                       echo $tmp >> $LOGFILE                                   # log the event
                       echo $tmp                                               # tell the user
                   fi;;
                 "timeout")
                   # this command is created by a background task and not the web page
                   CURRTIME=`date "+%H:%M:%S"`                              # excel format
                   tmp=${CURRTIME}",(alarm),(RasPi),Alarm timeout"
                   echo $tmp >> $LOGFILE                                    # log the event
                   echo $tmp                                                # tell the user (like he needs to know!)
                   rm -f /var/www/uploads/status.txt                        # normally done by the web page, but this time
                                                                            # has to be done through BASH
                   alarm="Timed out !"
                   echo "0" > $PIN_26/value                                 # set bell port inactive
                   echo "0" > $PIN_23/value                                 # set strobe port inactive
                   if [ -n "$(pgrep alm.sh)" ]; then                        # check for sounder process running If it is ...
                      pkill alm.sh                                          # ... kill it.
                      pkill aplay
                      echo "1" > $PIN_21/value                              # Audio mute
                   fi
                   alarm_tests                                              # tamper zones can still re-trigger
                   title="Alarm system: TIMEOUT"
                   eMail "$title";;
                 "app setup")
                   tmp=${CURRTIME}","${PARAMS[0]}","${PARAMS[1]}","${PARAMS[2]}","${PARAMS[3]}","${PARAMS[4]}
                   echo $tmp >> $LOGFILE                                   # log the event
                   echo $tmp                                               # tell the user
                   SETUP_location=${PARAMS[3]}
                   SETUP_duration=${PARAMS[4]};;
                 "email setup")
                   tmp=${CURRTIME}","${PARAMS[0]}","${PARAMS[1]}","${PARAMS[2]}","${PARAMS[3]}","${PARAMS[4]}","
                   tmp=$tmp${PARAMS[5]}",********,"${PARAMS[7]}","${PARAMS[8]}","${PARAMS[9]}
                   echo $tmp >> $LOGFILE                                   # log the event
                   echo $tmp                                               # tell the user
                   EMAIL_server=${PARAMS[3]}
                   EMAIL_port=${PARAMS[4]}
                   EMAIL_sender=${PARAMS[5]}
                   if [ "${PARAMS[6]}" != "dummy123" ]; then              # has the password feild been ovewritten....
                      tmp=${CURRTIME}","${PARAMS[0]}","${PARAMS[1]}","${PARAMS[2]}",password changed"
                      echo $tmp >> $LOGFILE                                # log the event
                      echo $tmp                                            # tell the user
                      EMAIL_password=${PARAMS[6]}                          # ...update password
                   fi
                   EMAIL_recipient=${PARAMS[7]};;                          # (is this still neede ?)
                 "save user defaults")
                   tmp=${CURRTIME}","${PARAMS[0]}","${PARAMS[1]}","${PARAMS[2]}
                   echo $tmp >> $LOGFILE                                   # log the event
                   echo $tmp                                               # tell the user
                   write_status_file /var/www/default.txt;;                # Save current user defaults to file
                 "edt usr")                                                # This section edits existing, and adds new users
                   tmp=${CURRTIME}","${PARAMS[0]}","${PARAMS[1]}","${PARAMS[2]}","${PARAMS[3]}","
                   tmp=$tmp${PARAMS[4]}","${PARAMS[5]}
                   echo $tmp >> $LOGFILE                                   # log the event
                   echo $tmp                                               # tell the user
                   if [[ -z ${PARAMS[5]} ]] ; then                         # BASH arrays won't store a NULL character - elements following
                      PARAMS[5]="(no email)"                               # a NULL will get shuffled down one. So if we need to detect a 
                   fi                                                      # NULL email, and write something in its place.
                   pos=$((${PARAMS[3]}-1))
                   lgns[$pos]=${PARAMS[4]}
                   emails[$pos]=${PARAMS[5]}
                   WriteUsers;;                                            # write changes to disk
                 "del usr")
                   tmp=${CURRTIME}","${PARAMS[0]}","${PARAMS[1]}","${PARAMS[2]}","${PARAMS[3]}
                   echo $tmp >> $LOGFILE                                   # log the event
                   echo $tmp                                               # tell the user
                   pos=$((${PARAMS[3]}-1))                                 # array zero is first user so bump value
                   if [ ${#lgns[*]} -gt 1 ]; then                          # don't allow delete last user
                     lgns=("${lgns[@]:0:$pos}" "${lgns[@]:$(($pos + 1))}") # remove element from all 3 arrays...
                     emails=("${emails[@]:0:$pos}" "${emails[@]:$(($pos + 1))}")
                     pwds=("${pwds[@]:0:$pos}" "${pwds[@]:$(($pos + 1))}")
                   fi
                   WriteUsers;;                                            # write changes to disk
                 "set pw")
                   tmp=${CURRTIME}","${PARAMS[0]}","${PARAMS[1]}","${PARAMS[2]}","${PARAMS[3]}",********"
                   echo $tmp >> $LOGFILE                                   # log the event
                   echo $tmp                                               # tell the user
                   pwds[((${PARAMS[3]}-1))]=${PARAMS[4]}                   # set password
                   WriteUsers;;                                            # write changes to disk
                 "load user defaults")
                   tmp=${CURRTIME}","${PARAMS[0]}","${PARAMS[1]}","${PARAMS[2]}
                   echo $tmp >> $LOGFILE                                   # log the event
                   echo $tmp                                               # tell the user
                   load_status_file /var/www/default.txt                   # Load user defaults from file
                   CheckIP                                                 # refresh hardware details
                   alarm_tests;;                                           # check if this causes an alarm
                 "load factory defaults")
                   tmp=${CURRTIME}","${PARAMS[0]}","${PARAMS[1]}","${PARAMS[2]}
                   echo $tmp >> $LOGFILE                                   # log the event
                   echo $tmp                                               # tell the user
                   load_status_file /var/www/factory.txt                   # Load factory defaults from file
                   CheckIP                                                 # refresh hardware details
                   alarm_tests;;                                           # check if this causes an alarm
                 "reset")
                   tmp=${CURRTIME}","${PARAMS[0]}","${PARAMS[1]}","${PARAMS[2]}
                   echo $tmp >> $LOGFILE                                   # log the event
                   echo $tmp                                               # tell the user
                   if [ -n "$(pgrep alm.sh)" ]; then                       # is the sounder running ? ...
                     pkill alm.sh                                          # ... kill it
                     echo "1" > $PIN_21/value                              # ... and audio mute
                   fi
                   echo "0" > $PIN_26/value                                # set bell port inactive
                   echo "0" > $PIN_23/value                                # set strobe port inactive
#                   echo "0" > $PIN_21/value                                # set audio mute
                   echo "1" > $PIN_21/value                                # set audio mute
                   mode="Standby"
                   alarm="Set"                                             # clear any alarm condition
                   z1[5]="false" ; z2[5]="false" ; z3[5]="false"           # clear any triggered zones...
                   z4[5]="false" ; z5[5]="false" ; z6[5]="false"
                   z7[5]="false" ; z8[5]="false"
                   sw1_old="1" ; sw2_old="1" ; sw3_old="1" ; sw4_old="1"   # reset zone states NB this can trigger
                   sw5_old="1" ; sw6_old="1" ; sw7_old="1" ; sw8_old="1"   # the alarm if any zone is open
                   alarm_tests                                             # tamper zones can still cause a trigger
                   title="Alarm system: Reset"
                   eMail "$title";;
                 "test bell")
                   tmp=${CURRTIME}","${PARAMS[0]}","${PARAMS[1]}","${PARAMS[2]}
                   echo $tmp >> $LOGFILE                                   # log the event
                   echo $tmp                                               # tell the user
                   echo "1" > $PIN_26/value                                # Set bell port active
                   # set up background task to cancel the test in 4 seconds
                   ( sleep 4
                     echo "0" > $PIN_26/value                              # Set bell port inactive
                     break )&
                   ;;
                 "test strobe")
                   tmp=${CURRTIME}","${PARAMS[0]}","${PARAMS[1]}","${PARAMS[2]}
                   echo $tmp >> $LOGFILE                                   # log the event
                   echo $tmp                                               # tell the user
                   echo "1" > $PIN_23/value                                # Set strobe port active
                   # set up background task to cancel the test in 5 secs
                   ( sleep 5
                     echo "0" > $PIN_23/value                              # Set strobe port inactive
                     break )&
                   ;;
                 "test sounder")
                   tmp=${CURRTIME}","${PARAMS[0]}","${PARAMS[1]}","${PARAMS[2]}
                   echo $tmp >> $LOGFILE                                   # log the event
                   echo $tmp                                               # tell the user
                   echo "0" > $PIN_21/value                                # Audio on (mute off)
                   if [ -z "$(pgrep alm.sh)" ]; then                       # check sounder NOT running ...
                     /var/www/Scripts/alm.sh &                             # start alarm background process
                     disown                                                # suppress messages from shell
                   else
                     tmp=${CURRTIME}","${PARAMS[0]}","${PARAMS[1]}",sounder already running"
                     echo $tmp >> $LOGFILE
                     echo $tmp
                   fi
                   # It's possible that the process may get killed by a manual reset, so the following
                   # routine only kills the process if it is still running.
                   ( sleep 10
                   if [ -n "$(pgrep alm.sh)" ]; then                       # check sounder IS running ...
                       pkill alm.sh
                       echo "1" > $PIN_21/value                            # Audio off (mute on)
                   fi ) &
                   ;;
                 "remote control")
#                  tmp=${CURRTIME}","${PARAMS[0]}","${PARAMS[1]}","${PARAMS[2]}","${PARAMS[3]}","${PARAMS[4]}
                   tmp=${CURRTIME}","${PARAMS[0]}","${PARAMS[1]}","${RCc[${PARAMS[3]}-1]}","${PARAMS[4]}
                   echo $tmp >> $LOGFILE                                   # log the event
                   echo $tmp                                               # tell the user
                   RemoteControl "${PARAMS[3]}" "${PARAMS[4]}";;           # pass to subroutine to sort out
                 "zone config")
                   tmp=${CURRTIME}","${PARAMS[0]}","${PARAMS[1]}","${PARAMS[2]}","${PARAMS[3]}","
                   tmp=$tmp${PARAMS[4]}","${PARAMS[5]}","${PARAMS[6]}","${PARAMS[7]}","${PARAMS[8]}","${PARAMS[9]}
                   echo $tmp >> $LOGFILE                                   # log the event
                   echo $tmp                                               # tell the user
                   zoneconfig "${PARAMS[3]}" "${PARAMS[4]}" "${PARAMS[5]}" \
                              "${PARAMS[6]}" "${PARAMS[7]}" "${PARAMS[8]}"
                   alarm_tests;;                                           # check if this causes an alarm
                 "remote config")
                   tmp=${CURRTIME}","${PARAMS[0]}","${PARAMS[1]}","${PARAMS[2]}","${PARAMS[3]}","${PARAMS[4]}
                   echo $tmp >> $LOGFILE                                   # log the event
                   echo $tmp                                               # tell the user
                   RCc[${PARAMS[3]}-1]="${PARAMS[4]}";;                    # set array element to new string value
                 "Check ip")
                   CheckIP;;                                               # pass to subroutine to sort out
                 "delete task")
                   tmp=${CURRTIME}","${PARAMS[0]}","${PARAMS[1]}","${PARAMS[2]}","${PARAMS['3']}
                   echo $tmp >> $LOGFILE                                   # log the event
                   echo $tmp                                               # tell the user
                   if [ -f /var/www/cronjobs.txt ]; then                   # clear out previous results
                        rm /var/www/cronjobs.txt
                   fi
                   if [ -f /var/www/cronjobs2.txt ]; then
                        rm /var/www/cronjobs2.txt
                   fi
                   crontab -l >>/var/www/cronjobs.txt                      # Make a copy of the current file
                   sed '/^#/ d' </var/www/cronjobs.txt >/var/www/uploads/cronjobs2.txt # remove any comments from file
                   sed -i ${PARAMS[3]}d /var/www/cronjobs2.txt             # Delete the selected line
                   crontab /var/www//cronjobs2.txt                         # Re-install new cron file
                   rm /var/www/cronjobs.txt                                # tidy up
                   rm /var/www/cronjobs2.txt;;
                 "edit task")
                   # This creates a new line in the crontab file at the same place as the original, then deletes
                   # the original which has been shifted up one line. This routine also handles requests to create
                   # a new task by the same mechanism.
                   set -f                                                  # Globbing off
                   tmp=${CURRTIME}","${PARAMS[0]}","${PARAMS[1]}","${PARAMS[2]}","${PARAMS[3]}","
                   tmp=$tmp${PARAMS[4]}","${PARAMS[5]}","${PARAMS[6]}","${PARAMS[7]}","${PARAMS[8]}","${PARAMS[9]}
                   echo $tmp >> $LOGFILE                                   # log the event
                   echo $tmp                                               # tell the user
                   if [ -f /var/www/cronjobs.txt ]; then                   # clear out previous results
                        rm /var/www/cronjobs.txt
                   fi
                   # create the new line to be added...
                   tmpstr=${PARAMS[4]}" "${PARAMS[5]}" "${PARAMS[6]}" "${PARAMS[7]}" "
                   tmpstr=$tmpstr${PARAMS[8]}" echo \""${cmnd[${PARAMS[9]}]}
                   tmpstr=$tmpstr"\" >>/var/www/uploads/input.txt"         # This is the new line to be added
                                                                           # to the cron jobs file
                   crontab -l >>/var/www/cronjobs.txt                      # Make a copy of the current crontab file
                   sed -i '/^#/ d' /var/www/cronjobs.txt                   # remove all comments from file

                   # NOTE: SED is very pedantic, so won't insert a line at the very end of the file.
                   # This causes issuse when creating a new job, which would normally be tagged on at the end.
                   # To get around this, a dummy line is written to the end of the file, then removed at the
                   # end of the calculations.
                   echo dummy >>/var/www/cronjobs.txt                      # stick an extra line in for SED
                   set -f                                                  # Globbing off
                   tststr2="${PARAMS[3]}"i'\'                              # First part of sed command
                   tststr=$tmpstr                                          # second part of sed command
                   sed -i "${tststr2}${tststr}" /var/www/cronjobs.txt
                   set +f                                                  # Globbing back on
                   sed -i '$d' /var/www/cronjobs.txt                       # processing finished so remove the dummy line
                   ((PARAMS[3]++))                                         # point to the line after the one we have just inserted
                   sed -i ${PARAMS[3]}d /var/www/cronjobs.txt              # Delete the selected line - removes old version of the task

                   crontab /var/www/cronjobs.txt                           # Install the new cron file
                   rm /var/www/cronjobs.txt                                # tidy up
                   ;;
                *)
                   tmp=${CURRTIME}","${PARAMS[0]}",unknown command,"$info
                   echo $tmp >> $LOGFILE                                   # log the event
                   echo $tmp;;                                             # tell the user
               esac
               write_status_file /var/www/uploads/status.txt               # ...then report back to the web page
             done </var/www/uploads/input.txt
         rm /var/www/uploads/input.txt
      fi

#################################################################################################################################
#                                                                                                                               #
# Read the status of the input circuits and flag any changes.                                                                   #
#                                                                                                                               #
#################################################################################################################################
#                                                                                                                               #
# Note:-                                                                                                                        #
# Input circuits are active low because...                                                                                      #
#     the door switch opens,                                                                                                    #
#     the LED turns off,                                                                                                        #
#     the photo transistor stops conducting                                                                                     #
#     the input line disconnects from GPIO 4, 17, 18 or 21 output line                                                          #
#     the GPIO 4, 17, 18 and 21 output lines are active high so the input becomes active low.                                   #
#                                                                                                                               #
#################################################################################################################################

      chimes=false
      changed=""

      echo "1" > $PIN_13/value                                     # enable inputs 1 and 2
      sw1=$(cat $PIN_22/value)                                     # read first input
      if [[ "$sw1" -ne "$sw1_old" ]]; then
          changed=${z1[1]}                                         # get the name of the zone
          if [[ $sw1 = "0" ]]; then
            changed=${changed}" open"
          else
            changed=${changed}" closed"
          fi
      fi
      sw2=$(cat $PIN_24/value)                                     # read second input
      if [[ "$sw2" -ne "$sw2_old" ]]; then
          changed=${z2[1]}                                         # get the name of the zone
          if [[ $sw2 = "0" ]]; then
            changed=${changed}" open"
          else
            changed=${changed}" closed"
          fi
      fi
      echo "0" > $PIN_13/value                                     # disable inputs 1 and 2

      echo "1" > $PIN_11/value                                     # enable inputs 3 and 4
      sw3=$(cat $PIN_22/value)                                     # read third input
      if [[ "$sw3" -ne "$sw3_old" ]]; then
          changed=${z3[1]}                                         # get the name of the zone
          if [[ $sw3 = "0" ]]; then
            changed=${changed}" open"
          else
            changed=${changed}" closed"
          fi
      fi
      sw4=$(cat $PIN_24/value)                                     # read fourth input
      if [[ "$sw4" -ne "$sw4_old" ]]; then
          changed=${z4[1]}                                         # get the name of the zone
          if [[ $sw4 = "0" ]]; then
            changed=${changed}" open"
          else
            changed=${changed}" closed"
          fi
      fi
      echo "0" > $PIN_11/value                                     # disable inputs 3 and 4

      echo "1" > $PIN_12/value                                     # enable inputs 5 and 6
      sw5=$(cat $PIN_22/value)                                     # read fifth input
      if [[ "$sw5" -ne "$sw5_old" ]]; then
          changed=${z5[1]}                                         # get the name of the zone
          if [[ $sw5 = "0" ]]; then
            changed=${changed}" open"
          else
            changed=${changed}" closed"
          fi
      fi
      sw6=$(cat $PIN_24/value)                                     # read sixth input
      if [[ "$sw6" -ne "$sw6_old" ]]; then
          changed=${z6[1]}                                         # get the name of the zone
          if [[ $sw6 = "0" ]]; then
            changed=${changed}" open"
          else
            changed=${changed}" closed"
          fi
      fi
      echo "0" > $PIN_12/value                                     # disable inputs 5 and 6

      echo "1" > $PIN_7/value                                      # enable inputs 7 and 8
      sw7=$(cat $PIN_22/value)                                     # read seventh input
      if [[ "$sw7" -ne "$sw7_old" ]]; then
          changed=${z7[1]}                                         # get the name of the zone
          if [[ $sw7 = "0" ]]; then
            changed=${changed}" open"
          else
            changed=${changed}" closed"
          fi
      fi
      sw8=$(cat $PIN_24/value)                                     # read eigth input
      if [[ "$sw8" -ne "$sw8_old" ]]; then
          changed=${z8[1]}                                         # get the name of the zone
          if [[ $sw8 = "0" ]]; then
            changed=${changed}" open"
          else
            changed=${changed}" closed"
          fi
      fi
      echo "0" > $PIN_7/value                                      # disable inputs 7 and 8

                                                                   # If no circuits have changed, then there's nothing to do.
      if [ -n "$changed" ]; then                                   # but if we have a string, then a circuit has changed and we need to dig deeper...

         tmp=${CURRTIME}",(alarm),(RasPi),"${changed}
         echo $tmp >> $LOGFILE                                    # log the event
         echo $tmp                                                # tell the user
         write_status_file /var/www/uploads/status.txt
         alarm_tests                                              # Check input circuits and set alarms accordingly
      fi
      # End of circuit tests - now pick up any outstanding actions ...

      if [ "$alarm" = "Active !" ]; then
      # THIS WAS CAUSING THE SOUNDER (APLAY COMMAND) TO RE_TRIGGER BEFORE IT WAS COMPLETE. THIS IN TURN WOULD KILL THE PI.
        if [ -z "$(pgrep alm.sh)" ]; then                        # check sounder process NOT running  ...
        # falls through here if we have an active alarm zone and the alarm has NOT already been triggered ...
        # and the sounder has finished playing any WAV files.
           alm_on                                                # Trigger / re-trigger (also updates status file)
        fi
      fi

      if $chimes ; then                                          # thanks Ron
        tmp=${CURRTIME}",(alarm),(RasPi),door chime"
        echo $tmp >> $LOGFILE                                    # log the event
        echo $tmp                                                # tell the user
        ( # avoid click at start of wav file playback...
          # ...background task to wait for 0.1 seconds before enabling the audio
          sleep 0.2
          echo "0" > $PIN_21/value                               # audio on (mute off)
        ) &
        ( # avoid click at end of wav file playback...
          # background task to wait for 0.9 seconds then disable the audio
          sleep 0.9
          echo "1" > $PIN_21/value                               # audio off (mute on)
        ) &
        ( # and start the wav file playing, again as a background task so the main loop can keep scanning
          aplay -q '/var/www/sounds/chimes.wav'
          echo "1" > $PIN_21/value                               # audio off (mute on)
        ) &
      fi
done
