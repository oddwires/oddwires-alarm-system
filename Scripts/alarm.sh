#!/bin/bash
#################################################################################################################################
#                                                                                                                               #
# Oddwires alarm service.                                                                                                       #
# Latest details and build instructions... http://oddwires.co.uk/?page_id=123                                                   #
# Latest code and issues...                https://github.com/oddwires/oddwires-alarm-system                                    #
#                                                                                                                               #
#################################################################################################################################
#                                                                                                                               #
# Features:                                                                                                                     #
#     RasPi platform - compatable with Rev 1.0 and Rev 2.0 hardware                                                             #
#     8 configurable alarm zones (cabled)                                                                                       #
#     3 alarm modes: Standby, Part set, Full set                                                                                #
#     5 configurable automation channels (radio controlled)                                                                     #
#     Industry standard 12 volt interface to alarm sensors, bell boxes and strobe                                               #
#     Full (internet) remote control using iPhone 4s web app interface                                                          #
#     Animated page transitions and user controls - look and feel of a native app.                                              #
#     eMail alerts for alarm events                                                                                             #
#     Automatically detect changes to router IP address                                                                         #
#     Scheduled tasks                                                                                                           #
#                                                                                                                               #
#################################################################################################################################

# Use set -x to enable debuging
# Use set +x to disable debuging

# use an array for the RC channel status ...
declare -a RCs=('off' 'off' 'off' 'off' 'off')

# use an array for RC channel config ...
declare -a RCc=('RC channel 1' 'RC channel 2' 'RC channel 3' 'RC channel 4' 'RC channel 5')

# use three arrays for credentials. Details are loaded fro file at startup.
declare -a lgns=()
declare -a emails=()
declare -a pwds=()

# can't use a 2 dimensional array to store the alarm zone config, so use a separate array for each zone.
# format of each array is 'type', 'name','chimes','full set','part set','trigger status'
# I've assigned default values, but these will be overwritten at startup by either rhe user or factory defaults.

declare -a z1=('alarm' 'Zone 1' 'off' 'on' 'off' 'false')
declare -a z2=('alarm' 'Zone 2' 'off' 'on' 'off' 'false')
declare -a z3=('alarm' 'Zone 3' 'off' 'on' 'off' 'false')
declare -a z4=('alarm' 'Zone 4' 'off' 'on' 'off' 'false')
declare -a z5=('alarm' 'Zone 5' 'off' 'on' 'off' 'false')
declare -a z6=('alarm' 'Zone 6' 'off' 'on' 'off' 'false')
declare -a z7=('alarm' 'Zone 7' 'off' 'on' 'off' 'false')
declare -a z8=('tamper' 'Tamper loop' 'off' 'off' 'off' 'false')

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

# start defining functions ...

WriteUsers()
{ # Function to dump user credentials from memory to file.
  if [ -f /var/www/user.txt ]; then                                # clear out previous results
    rm /var/www/user.txt; fi
  count=0
  for Usr in "${lgns[@]}"; do
    echo ${Usr}":"${pwds[${count}]}":"${emails[${count}]} >>/var/www/user.txt
    ((count++))
  done
  sudo chown pi /var/www/user.txt                                  # found permissions issues on Windows 7 laptop - but this fixed it
  sudo chmod 777 /var/www/user.txt  
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
    tmp=${CURRTIME}",CheckIP,"${SETUP_routerIP}","${Current_routerIP}
    echo $tmp >> $LOGFILE                                                    # log the event
    echo $tmp                                                                # tell the user

    title="Alarm system: Router IP change"
#    msg="Event logged at: "${CURRTIME}"\n\n"                                 # build a multi line string
#    msg=$msg"Old IP: "${SETUP_routerIP}"\nNew IP: "${Current_routerIP}"\n"
#    msg=$msg"\n** Message sent from RaspPi@"${Current_routerIP}" **"
    eMail "$title"

    SETUP_routerIP=${Current_routerIP}                                       # Update variable
  fi

# Refresh the remaining hardware details. This will identify if the disk is filling up etc.
# DUPLICATE CODE - need to sort this out.

#  SETUP_localIP=$(/sbin/ifconfig eth0 | grep 'inet addr:' | cut -d: -f2 | awk '{ print $1}')
#  SETUP_diskused=$(df -h | grep rootfs | awk '{print $4}')
#  SETUP_diskperc=$(df -h | grep rootfs | awk '{print $5}')
#  SETUP_disktotal=$(df -h | grep rootfs | awk '{print $2}')
#  tmp=$(cat /proc/meminfo | grep MemTotal | awk '{print $2}')                # in KB
#  SETUP_memory=$((tmp /1024))M                                               # convert to MB
#  tmp=$(cat /proc/cpuinfo | grep Revision | awk '{print $3}')                # DUPLICATE CODE - need to sort this out.
#  case "$tmp" in
#   "0002")
#       SETUP_model="Model B Rev 1.0";;
#   "0003")
#       SETUP_model="Model B Rev 1.0 + ECN0001";;
#   "0004"|"0005"|"0006")
#       SETUP_model="Model B Rev 2.0";;
#   "000D"|"000E"|"00)f")
#       SETUP_model="Model B Rev 2.0 (512 MB)";;
#   *)
#       SETUP_model="Unknown Model";
#  esac
#  write_status_file status.txt                                               # pass updated alarm status to web page
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
CURRTIME=`date "+%H:%M:%S"`                                 # excel format
LOGFILE="/var/www/logs/"`date +%Y-%m-%d`".csv"              # name derived from date

hardware=$(cat /proc/cpuinfo | grep Revision | awk '{print $3}')           # Identify hardware we are running on.

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
if [[ $hardware = "0002" ]] || [[ $hardware = "0003" ]]; then
          PIN_13=/sys/class/gpio/gpio21                     # Rev 1.0 hardware
          str="Rev 1.0 hardware"                            # string for log file
else
          PIN_13=/sys/class/gpio/gpio27                     # Rev 2.0 hardware (and anything newer)
          str="Rev 2.0 hardware"                            # string for log file
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
echo "0" > $PIN_26/value                                    # Alarm bell         - inactive=low
echo "0" > $PIN_23/value                                    # Alarm strobe       - inactive=low

tmp=${CURRTIME}",(alarm),(RasPi),GPIO ports initialised for "${str}
echo $tmp >> $LOGFILE                                       # log the event
echo $tmp                                                   # tell the user

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
     circlist=${circlist}${usr}","
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
       tmp=$(cat /proc/cpuinfo | grep Revision | awk '{print $3}')                # DUPLICATE CODE - need to sort this out.
       case "$tmp" in
         "0002")
            SETUP_model="Model B Rev 1.0";;
         "0003")
            SETUP_model="Model B Rev 1.0 + ECN0001";;
         "0004"|"0005"|"0006")
            SETUP_model="Model B Rev 2.0";;
         "000d"|"000e"|"000f")
            SETUP_model="Model B Rev 2.0 (512 MB)";;
         *)
            SETUP_model="Unknown Model";
       esac
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

       msg=$msg'\nHardware:\t\t'${SETUP_model}
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
     set +f                                                 # Globbing back on
     tmp=${CURRTIME}",(alarm),(RasPi),"$1" - email sent"
     echo $tmp >> $LOGFILE                                  # log the event
     echo $tmp                                              # tell the user
  fi
}

RemoteControl()
# This is where we start banging the bits to turn stuff on/off in the real world.
# Routine is passed 2 parameters, $1=channel number, $2=on/off
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
esac
}

load_status_file()
# Routine to load configuration file to memory
{
set -f                                        # Globbing off
  while read info; do
#     echo $info                              # Diagnostic
        OLD_IFS="$IFS"                        # split the line regardless of what it is
        IFS=":"
        STR_ARRAY=( $info )
        IFS="$OLD_IFS"
        case "${STR_ARRAY[0]}" in             # Just looking at the first string
          "zc #1...........")                 # Zone 1 ...
                z1[0]=${STR_ARRAY[1]}         # Type
                z1[1]=${STR_ARRAY[2]}         # Name
                z1[2]=${STR_ARRAY[3]}         # Chimes
                z1[3]=${STR_ARRAY[4]}         # Full set
                z1[4]=${STR_ARRAY[5]}         # Part set
                z1[5]=${STR_ARRAY[6]};;       # Trigger status
          "zc #2...........")                 # Zone 2 ...
                z2[0]=${STR_ARRAY[1]}         # Type
                z2[1]=${STR_ARRAY[2]}         # Name
                z2[2]=${STR_ARRAY[3]}         # Chimes
                z2[3]=${STR_ARRAY[4]}         # Full set
                z2[4]=${STR_ARRAY[5]}         # Part set
                z2[5]=${STR_ARRAY[6]};;       # Trigger status
          "zc #3...........")                 # Zone 3 ...
                z3[0]=${STR_ARRAY[1]}         # Type
                z3[1]=${STR_ARRAY[2]}         # Name
                z3[2]=${STR_ARRAY[3]}         # Chimes
                z3[3]=${STR_ARRAY[4]}         # Full set
                z3[4]=${STR_ARRAY[5]}         # Part set
                z3[5]=${STR_ARRAY[6]};;       # Trigger status
          "zc #4...........")                 # Zone 4 ...
                z4[0]=${STR_ARRAY[1]}         # Type
                z4[1]=${STR_ARRAY[2]}         # Name
                z4[2]=${STR_ARRAY[3]}         # Chimes
                z4[3]=${STR_ARRAY[4]}         # Full set
                z4[4]=${STR_ARRAY[5]}         # Part set
                z4[5]=${STR_ARRAY[6]};;       # Trigger status
          "zc #5...........")                 # Zone 5 ...
                z5[0]=${STR_ARRAY[1]}         # Type
                z5[1]=${STR_ARRAY[2]}         # Name
                z5[2]=${STR_ARRAY[3]}         # Chimes
                z5[3]=${STR_ARRAY[4]}         # Full set
                z5[4]=${STR_ARRAY[5]}         # Part set
                z5[5]=${STR_ARRAY[6]};;       # Trigger status
          "zc #6...........")                 # Zone 6 ...
                z6[0]=${STR_ARRAY[1]}         # Type
                z6[1]=${STR_ARRAY[2]}         # Name
                z6[2]=${STR_ARRAY[3]}         # Chimes
                z6[3]=${STR_ARRAY[4]}         # Full set
                z6[4]=${STR_ARRAY[5]}         # Part set
                z6[5]=${STR_ARRAY[6]};;       # Trigger status
          "zc #7...........")                 # Zone 7 ...
                z7[0]=${STR_ARRAY[1]}         # Type
                z7[1]=${STR_ARRAY[2]}         # Name
                z7[2]=${STR_ARRAY[3]}         # Chimes
                z7[3]=${STR_ARRAY[4]}         # Full set
                z7[4]=${STR_ARRAY[5]}         # Part set
                z7[5]=${STR_ARRAY[6]};;       # Trigger status
          "zc #8...........")                 # Zone 8 ...
                z8[0]=${STR_ARRAY[1]}         # Type
                z8[1]=${STR_ARRAY[2]}         # Name
                z8[2]=${STR_ARRAY[3]}         # Chimes
                z8[3]=${STR_ARRAY[4]}         # Full set
                z8[4]=${STR_ARRAY[5]}         # Part set
                z8[5]=${STR_ARRAY[6]};;       # Trigger status
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
                rm -f /var/www/temp.txt;;
          "Users")
                FLAG="false";;                           # flag end of section (any section)
        esac
        if [[ ${FLAG} = "true" ]] && [[ ${info} != "Cron jobs:" ]]; then
                 echo ${info} >>/var/www/temp.txt        # parsing the cronjobs data - so make a temp copy
        fi
  done <$1                                               # file name passed as parameter.
set +f                                                   # Globbing back on
crontab /var/www/temp.txt                                # Load cronjobs copied from status file
rm -f /var/www/temp.txt                                  # delete temp cronjobs file
}

write_status_file()

# This file is  used as a status flag by the web page.
# The web page reloads as soon as the file appears. So to prevent
# the web page from loading before the file has finished being written to,
# it is created under a temorary name, and is only changed to the status
# file when all the data has been written.

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
echo "RC channel #1..."${RCs[0]} >>/var/www/temp1.txt
echo "RC channel #2..."${RCs[1]} >>/var/www/temp1.txt
echo "RC channel #3..."${RCs[2]} >>/var/www/temp1.txt
echo "RC channel #4..."${RCs[3]} >>/var/www/temp1.txt
echo "RC channel #5..."${RCs[4]} >>/var/www/temp1.txt
echo >>/var/www/temp1.txt
echo "Remote Control config:" >>/var/www/temp1.txt
echo "RC channel #1...:"${RCc[0]} >>/var/www/temp1.txt
echo "RC channel #2...:"${RCc[1]} >>/var/www/temp1.txt
echo "RC channel #3...:"${RCc[2]} >>/var/www/temp1.txt
echo "RC channel #4...:"${RCc[3]} >>/var/www/temp1.txt
echo "RC channel #5...:"${RCc[4]} >>/var/www/temp1.txt
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
mv /var/www/temp1.txt /var/www/$1
sudo chown pi /var/www/$1                                # hit permissions issues on Windows 7 laptop - but this fixed it
sudo chmod 777 /var/www/$1
}

alm_on()
{
CURRTIME=`date "+%H:%M:%S"`                              # excel format
tmp=${CURRTIME}",(alarm),(RasPi),Alarm active"
echo $tmp >> $LOGFILE                                    # log the event
echo $tmp                                                # tell the user (like he needs to know!)

echo "1" > $PIN_26/value                                 # set bell port active
echo "1" > $PIN_23/value                                 # set strobe port active
echo "0" > $PIN_21/value                                 # Audio on

/var/www/Scripts/alm.sh &                                # start alarm background process
disown                                                   # surpress messages from shell

title="Alarm system: ACTIVE"
#msg=""                                                   # build a multi line string
#msg=$msg"Event logged at: "${CURRTIME}"\n\n"
#msg=$msg"Triggered zone(s):""\n"

#if ${z1[5]} ; then msg=$msg"     "${z1[1]}"\n" ; fi # Zone 1 triggered, so add name
#if ${z2[5]} ; then msg=$msg"     "${z2[1]}"\n" ; fi # Zone 2 triggered, so add name
#if ${z3[5]} ; then msg=$msg"     "${z3[1]}"\n" ; fi # Zone 3 triggered, so add name
#if ${z4[5]} ; then msg=$msg"     "${z4[1]}"\n" ; fi # Zone 4 triggered, so add name
#if ${z5[5]} ; then msg=$msg"     "${z5[1]}"\n" ; fi # Zone 5 triggered, so add name
#if ${z6[5]} ; then msg=$msg"     "${z6[1]}"\n" ; fi # Zone 6 triggered, so add name
#if ${z7[5]} ; then msg=$msg"     "${z7[1]}"\n" ; fi # Zone 7 triggered, so add name
#if ${z8[5]} ; then msg=$msg"     "${z8[1]}"\n" ; fi # Zone 8 triggered, so add name

#msg=$msg"\n** Message sent from RaspPi@"${SETUP_routerIP}" **"
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
  echo "(alarm):(RasPi):timeout" >>/var/www/input.txt )&
}

zoneconfig()
{
case "$1" in
   "1")                                                          # zone #1
     z1[0]=$2; z1[1]=$3;z1[2]=$4; z1[3]=$5; z1[4]=$6 z1[5]=$7;;
   "2")                                                          # zone #2
     z2[0]=$2; z2[1]=$3;z2[2]=$4; z2[3]=$5; z2[4]=$6 z2[5]=$7;;
   "3")                                                          # zone #3
     z3[0]=$2; z3[1]=$3;z3[2]=$4; z3[3]=$5; z3[4]=$6 z3[5]=$7;;
   "4")                                                          # zone #4
     z4[0]=$2; z4[1]=$3;z4[2]=$4; z4[3]=$5; z4[4]=$6 z4[5]=$7;;
   "5")                                                          # zone #5
     z5[0]=$2; z5[1]=$3;z5[2]=$4; z5[3]=$5; z5[4]=$6 z5[5]=$7;;
   "6")                                                          # zone #6
     z6[0]=$2; z6[1]=$3;z6[2]=$4; z6[3]=$5; z6[4]=$6 z6[5]=$7;;
   "7")                                                          # zone #7
     z7[0]=$2; z7[1]=$3;z7[2]=$4; z7[3]=$5; z7[4]=$6 z7[5]=$7;;
   "8")                                                          # zone #8
     z8[0]=$2; z8[1]=$3;z8[2]=$4; z8[3]=$5; z8[4]=$6 z8[5]=$7;;
esac
}

alarm_tests()
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
    if [[ $mode = "Part Set" ]]; then                        # alarm is set, so we need to dig even deeper..
      # Check zone is an alarm and circuit is active and zone is enabled in Part Set...
        if [[ ${z1[0]} = "alarm" ]] && [[ $sw1 = "0" ]] && [[ ${z1[4]} = "on" ]]; then z1[5]=true; alarm='Active !'; fi
        if [[ ${z2[0]} = "alarm" ]] && [[ $sw2 = "0" ]] && [[ ${z2[4]} = "on" ]]; then z2[5]=true; alarm='Active !'; fi
        if [[ ${z3[0]} = "alarm" ]] && [[ $sw3 = "0" ]] && [[ ${z3[4]} = "on" ]]; then z3[5]=true; alarm='Active !'; fi
        if [[ ${z4[0]} = "alarm" ]] && [[ $sw4 = "0" ]] && [[ ${z4[4]} = "on" ]]; then z4[5]=true; alarm='Active !'; fi
        if [[ ${z5[0]} = "alarm" ]] && [[ $sw5 = "0" ]] && [[ ${z5[4]} = "on" ]]; then z5[5]=true; alarm='Active !'; fi
        if [[ ${z6[0]} = "alarm" ]] && [[ $sw6 = "0" ]] && [[ ${z6[4]} = "on" ]]; then z6[5]=true; alarm='Active !'; fi
        if [[ ${z7[0]} = "alarm" ]] && [[ $sw7 = "0" ]] && [[ ${z7[4]} = "on" ]]; then z7[5]=true; alarm='Active !'; fi
        if [[ ${z8[0]} = "alarm" ]] && [[ $sw8 = "0" ]] && [[ ${z8[4]} = "on" ]]; then z8[5]=true; alarm='Active !'; fi
    elif [[ $mode = "Full Set" ]]; then                      # alarm is set, so we need to dig even deeper..
      # check zone is an alarm and circuit is active and zone is enabled in Full Set...
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

InitPorts                                                   # does what it says on the lid

CURRTIME=`date "+%H:%M:%S"`                                 # excel format
LOGFILE="/var/www/logs/"`date +%Y-%m-%d`".csv"              # name derived from date

if [ -f /var/www/user.txt ]; then                           # if we have any users defined, load them to memory
  ReadUsers
# echo 'User 0-'${lgns[0]}'-'${emails[0]}'-'${pwds[0]}      # DIAGNOSTIC
  tmp="System restart - loading user credentials."          # msg for logfile
  echo $tmp >> $LOGFILE                                     # log the event
  echo $tmp                                                 # tell the user
fi

if [ -f /var/www/default.txt ]; then                        # If we have user defaults...
  load_status_file /var/www/default.txt                     # ...load 'em
  tmp="System restart - loading user default settings."     # msg for logfile
                                                            # if we have loaded user defaults, we should now have valid
                                                            # email credentials
  echo $tmp >> $LOGFILE                                     # log the event
  echo $tmp                                                 # tell the user
  title="Alarm system: Restart"                              # Send email reporting the restart - Note: this email might
#  msg="Event logged at: "${CURRTIME}"\n\n"                  # contain out of date IP info.
#  msg=$msg$tmp2"\n"
#  msg=$msg"\n** Message sent from RaspPi@"${SETUP_routerIP}" **"
  eMail "$title"
else
  load_status_file /var/www/factory.txt                     # If user defaults aren't available, load for factory defaults.
                                                            # Note: No valid email credentials, so can't send email
  tmp="System restart - loading factory defaults settings." # msg for logfile
  echo $tmp >> $LOGFILE                                     # log the event
  echo $tmp                                                 # tell the user
fi

CheckIP                                                     # Refresh current IP and all other hardware details. If the
                                                            # IP is not the same as loaded by the defaults, an additional
                                                            # event will be logged, and an additional email will be sent
echo "Press [CTRL+C] to stop."

#################################################################################################################################
#                                                                                                                               #
# Check for any commands from the web page.                                                                                     #
# Commands are passed in the file /var/www/input.txt. The file is deleted as soon as the command is executed.                   #
#                                                                                                                               #
#################################################################################################################################

while :
do
#echo $alarm   # DIAGNOSTIC
CURRTIME=`date "+%H:%M:%S"`                                                # excel format
LOGFILE="/var/www/logs/"`date +%Y-%m-%d`".csv"                             # name derived from date
     if [ -r /var/www/input.txt ];
        then
           while read info
             do
#              echo $info                                                  # Diagnostic
               OLD_IFS="$IFS"                                              # new mechanism
               IFS=":"                                                     # split the command on ':' - spaces are allowed
               set -f                                                      # Globbing off
               PARAMS2=( $info )
               set +f                                                      # Globbing on
               IFS="$OLD_IFS"
# DIAGNOSTIC - echo parameters being passed from web pages
#              echo first parameter [0]=${PARAMS2[0]}                      # DIAGNOSTIC - username
#              echo second parameter [1]=${PARAMS2[1]}                     # DIAGNOSTIC - IP address
#              echo third parameter [2]=${PARAMS2[2]}                      # DIAGNOSTIC - command
#              echo fourth  parameter [3]=${PARAMS2[3]}                    # DIAGNOSTIC - parameter
#              echo fifth parameter [4]=${PARAMS2[4]}                      # DIAGNOSTIC - parameter
#              echo sixth  parameter [5]=${PARAMS2[5]}                     # DIAGNOSTIC - parameter
#              echo seventh parameter [6]=${PARAMS2[6]}                    # DIAGNOSTIC - parameter
#              echo eight parameter [7]=${PARAMS2[7]}                      # DIAGNOSTIC - parameter

               case "${PARAMS2[2]}" in
                 "logon" | "failed logon" | "logoff")                      # either way - just log it
                   tmp=${CURRTIME}","${PARAMS2[0]}","${PARAMS2[1]}","${PARAMS2[2]}
                   echo $tmp >> $LOGFILE                                   # log the event
                   echo $tmp;;                                             # tell the user
                 "mode")
                   tmp=${CURRTIME}","${PARAMS2[0]}","${PARAMS2[1]}","${PARAMS2[2]}","${PARAMS2[3]}
                   echo $tmp >> $LOGFILE                                   # log the event
                   echo $tmp                                               # tell the user
                   mode=${PARAMS2[3]}                                      # set new mode
                   alarm_tests                                             # check if this causes an alarm
                   sw1_old="1" ; sw2_old="1" ; sw3_old="1" ; sw4_old="1"   # reset zone states NB this can trigger
                   sw5_old="1" ; sw6_old="1" ; sw7_old="1" ; sw8_old="1"   # the alarm if any zone is open
                   title="Alarm system: "${PARAMS2[3]}
#                   msg=""                                                  # build a multi line string
#                   msg=$msg"Event logged at: "${CURRTIME}"\n"
#                   msg=$msg"User: "${PARAMS2[0]}"\n"
#                   msg=$msg"Location: "${PARAMS2[1]}"\n\n"
#                   msg=$msg"** Message sent from RaspPi@"${SETUP_routerIP}" **"
                   eMail "$title";;
                 "timeout")
                   # this command is created by a background task and not the web page
                   CURRTIME=`date "+%H:%M:%S"`                              # excel format
                   tmp=${CURRTIME}",(alarm),(RasPi),Alarm timeout"
                   echo $tmp >> $LOGFILE                                    # log the event
                   echo $tmp                                                # tell the user (like he needs to know!)
                   rm -f /var/www/status.txt                                # normally done by the web page, but this time
                                                                            # has to be done through BASH
                   alarm="Timed out !"
                   echo "0" > $PIN_26/value                                 # set bell port inactive
                   echo "0" > $PIN_23/value                                 # set strobe port inactive
                   if [ -n "$(pgrep alm.sh)" ]; then                        # check for sounder process running If it is ...
                      pkill alm.sh                                          # ... kill it.
                      pkill aplay
                      echo "1" > $PIN_21/value                              # Audio mute
                   fi

                   title="Alarm system: TIMEOUT"
#                   msg=""                                                   # build a multi line string
#                   msg=$msg"Event logged at: "${CURRTIME}"\n\n"
#                   msg=$msg"Triggered zone(s):""\n"

#                   if ${z1[5]} ; then msg=$msg"     "${z1[1]}"\n" ; fi # Zone 1 name
#                   if ${z2[5]} ; then msg=$msg"     "${z2[1]}"\n" ; fi # Zone 2 name
#                   if ${z3[5]} ; then msg=$msg"     "${z3[1]}"\n" ; fi # Zone 3 name
#                   if ${z4[5]} ; then msg=$msg"     "${z4[1]}"\n" ; fi # Zone 4 name
#                   if ${z5[5]} ; then msg=$msg"     "${z5[1]}"\n" ; fi # Zone 5 name
#                   if ${z6[5]} ; then msg=$msg"     "${z6[1]}"\n" ; fi # Zone 6 name
#                   if ${z7[5]} ; then msg=$msg"     "${z7[1]}"\n" ; fi # Zone 7 name
#                   if ${z8[5]} ; then msg=$msg"     "${z8[1]}"\n" ; fi # Zone 8 name

#                   msg=$msg"\n** Message sent from RaspPi@"${SETUP_routerIP}" **"
                   eMail "$title";;
#                   echo $alarm;;                                               # DIAGNOSTIC
                 "app setup")
                   tmp=${CURRTIME}","${PARAMS2[0]}","${PARAMS2[1]}","${PARAMS2[2]}","${PARAMS2[3]}","${PARAMS2[4]}
                   echo $tmp >> $LOGFILE                                   # log the event
                   echo $tmp                                               # tell the user
                   SETUP_location=${PARAMS2[3]}
                   SETUP_duration=${PARAMS2[4]};;
                 "email setup")
                   tmp=${CURRTIME}","${PARAMS2[0]}","${PARAMS2[1]}","${PARAMS2[2]}","${PARAMS2[3]}","${PARAMS2[4]}","
                   tmp=$tmp${PARAMS2[5]}",********,"${PARAMS2[7]}","${PARAMS2[8]}","${PARAMS2[9]}
                   echo $tmp >> $LOGFILE                                   # log the event
                   echo $tmp                                               # tell the user
                   EMAIL_server=${PARAMS2[3]}
                   EMAIL_port=${PARAMS2[4]}
                   EMAIL_sender=${PARAMS2[5]}
                   if [ "${PARAMS2[6]}" != "dummy123" ]; then              # has the password feild been ovewritten....
                      tmp=${CURRTIME}","${PARAMS2[0]}","${PARAMS2[1]}","${PARAMS2[2]}",password changed"
                      echo $tmp >> $LOGFILE                                # log the event
                      echo $tmp                                            # tell the user
                      EMAIL_password=${PARAMS2[6]}                         # ...update password
                   fi
                   EMAIL_recipient=${PARAMS2[7]};;                         # (is this still neede ?)
                 "save user defaults")
                   tmp=${CURRTIME}","${PARAMS2[0]}","${PARAMS2[1]}","${PARAMS2[2]}
                   echo $tmp >> $LOGFILE                                   # log the event
                   echo $tmp                                               # tell the user
                   write_status_file default.txt;;                         # Save current user defaults to file
                 "edt usr")                                                # This section edits existing, and adds new users
                   tmp=${CURRTIME}","${PARAMS2[0]}","${PARAMS2[1]}","${PARAMS2[2]}","${PARAMS2[3]}","
                   tmp=$tmp${PARAMS2[4]}","${PARAMS2[5]}
                   echo $tmp >> $LOGFILE                                   # log the event
                   echo $tmp                                               # tell the user
                   if [[ -z ${PARAMS2[5]} ]] ; then                        # BASH arrays won't store a NULL character - elements following
                      PARAMS2[5]="(no email)"                              # a NULL will get shuffled down one. So if we need to detect a 
                   fi                                                      # NULL email, and write something in its place.
                   pos=$((${PARAMS2[3]}-1))
                   lgns[$pos]=${PARAMS2[4]}
                   emails[$pos]=${PARAMS2[5]}
                   WriteUsers;;                                            # write changes to disk
                 "del usr")
                   tmp=${CURRTIME}","${PARAMS2[0]}","${PARAMS2[1]}","${PARAMS2[2]}","${PARAMS2[3]}
                   echo $tmp >> $LOGFILE                                   # log the event
                   echo $tmp                                               # tell the user
                   pos=$((${PARAMS2[3]}-1))                                # array zero is first user so bump value
                   if [ ${#lgns[*]} -gt 1 ]; then                          # don't allow delete last user
                     lgns=("${lgns[@]:0:$pos}" "${lgns[@]:$(($pos + 1))}") # remove element from all 3 arrays...
                     emails=("${emails[@]:0:$pos}" "${emails[@]:$(($pos + 1))}")
                     pwds=("${pwds[@]:0:$pos}" "${pwds[@]:$(($pos + 1))}")
                   fi
                   WriteUsers;;                                            # write changes to disk
                 "set pw")
                   tmp=${CURRTIME}","${PARAMS2[0]}","${PARAMS2[1]}","${PARAMS2[2]}","${PARAMS2[3]}",********"
                   echo $tmp >> $LOGFILE                                   # log the event
                   echo $tmp                                               # tell the user
                   pwds[((${PARAMS2[3]}-1))]=${PARAMS2[4]}                 # set password
                   WriteUsers;;                                            # write changes to disk
                 "load user defaults")
                   tmp=${CURRTIME}","${PARAMS2[0]}","${PARAMS2[1]}","${PARAMS2[2]}
                   echo $tmp >> $LOGFILE                                   # log the event
                   echo $tmp                                               # tell the user
                   load_status_file /var/www/default.txt                   # Load user defaults from file
                   CheckIP                                                 # refresh hardware details
                   alarm_tests;;                                           # check if this causes an alarm
                 "load factory defaults")
                   tmp=${CURRTIME}","${PARAMS2[0]}","${PARAMS2[1]}","${PARAMS2[2]}
                   echo $tmp >> $LOGFILE                                   # log the event
                   echo $tmp                                               # tell the user
                   load_status_file /var/www/factory.txt                   # Load factory defaults from file
                   CheckIP                                                 # refresh hardware details
                   alarm_tests;;                                           # check if this causes an alarm
                 "reset")
                   tmp=${CURRTIME}","${PARAMS2[0]}","${PARAMS2[1]}","${PARAMS2[2]}
                   echo $tmp >> $LOGFILE                                   # log the event
                   echo $tmp                                               # tell the user
                   if [ -n "$(pgrep alm.sh)" ]; then                       # is the sounder running ? ...
                     pkill alm.sh                                          # ... kill it
                     echo "1" > $PIN_21/value                              # ... and audio mute
                   fi
                   echo "0" > $PIN_26/value                                # set bell port inactive
                   echo "0" > $PIN_23/value                                # set strobe port inactive
                   echo "0" > $PIN_21/value                                # set audio mute
                   mode="Standby"
                   alarm="Set"                                             # clear any alarm condition
                   z1[5]="false" ; z2[5]="false" ; z3[5]="false"           # clear any triggered zones...
                   z4[5]="false" ; z5[5]="false" ; z6[5]="false"
                   z7[5]="false" ; z8[5]="false"
                   sw1_old="1" ; sw2_old="1" ; sw3_old="1" ; sw4_old="1"   # reset zone states NB this can trigger
                   sw5_old="1" ; sw6_old="1" ; sw7_old="1" ; sw8_old="1"   # the alarm if any zone is open
                   alarm_tests                                             # tamper zones can still cause a trigger
                   title="Alarm system: Reset"
#                   msg=""                                                  # build a multi line string
#                   msg=$msg"Event logged at: "${CURRTIME}"\n"
#                   msg=$msg"User: "${PARAMS2[0]}"\n"
#                   msg=$msg"Location: "${PARAMS2[1]}"\n\n"
#                   msg=$msg"** Message sent from RaspPi@"${SETUP_routerIP}" **"
                   eMail "$title";;
                 "test bell")
                   tmp=${CURRTIME}","${PARAMS2[0]}","${PARAMS2[1]}","${PARAMS2[2]}
                   echo $tmp >> $LOGFILE                                   # log the event
                   echo $tmp                                               # tell the user
                   echo "1" > $PIN_26/value                                # Set bell port active
                   # set up background task to cancel the test in 5 seconds
                   ( sleep 5
                     echo "0" > $PIN_26/value                              # Set bell port inactive
                     break )&
                   ;;
                 "test strobe")
                   tmp=${CURRTIME}","${PARAMS2[0]}","${PARAMS2[1]}","${PARAMS2[2]}
                   echo $tmp >> $LOGFILE                                   # log the event
                   echo $tmp                                               # tell the user
                   echo "1" > $PIN_23/value                                # Set strobe port active
                   # set up background task to cancel the test in 10 secs
                   ( sleep 10
                     echo "0" > $PIN_23/value                              # Set strobe port inactive
                     break )&
                   ;;
                 "test sounder")
                   tmp=${CURRTIME}","${PARAMS2[0]}","${PARAMS2[1]}","${PARAMS2[2]}
                   echo $tmp >> $LOGFILE                                   # log the event
                   echo $tmp                                               # tell the user
                   echo "0" > $PIN_21/value                                # Audio on (mute off)
                   if [ -z "$(pgrep alm.sh)" ]; then                       # check sounder NOT running ...
                     /var/www/Scripts/alm.sh &                             # start alarm background process
                     disown                                                # surpress messages from shell
                   else
                     tmp=${CURRTIME}","${PARAMS2[0]}","${PARAMS2[1]}",sounder already running"
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
                   tmp=${CURRTIME}","${PARAMS2[0]}","${PARAMS2[1]}","${PARAMS2[2]}","${PARAMS2[3]}","${PARAMS2[4]}
                   echo $tmp >> $LOGFILE                                   # log the event
                   echo $tmp                                               # tell the user
                   RemoteControl "${PARAMS2[3]}" "${PARAMS2[4]}";;         # pass to subroutine to sort out
                 "zone config")
                   tmp=${CURRTIME}","${PARAMS2[0]}","${PARAMS2[1]}","${PARAMS2[2]}","${PARAMS2[3]}","
                   tmp=$tmp${PARAMS2[4]}","${PARAMS2[5]}","${PARAMS2[6]}","${PARAMS2[7]}","${PARAMS2[8]}","${PARAMS2[9]}
                   echo $tmp >> $LOGFILE                                   # log the event
                   echo $tmp                                               # tell the user
                   zoneconfig "${PARAMS2[3]}" "${PARAMS2[4]}" "${PARAMS2[5]}" \
                              "${PARAMS2[6]}" "${PARAMS2[7]}" "${PARAMS2[8]}"
                   alarm_tests;;                                           # check if this causes an alarm
                 "remote config")
                   tmp=${CURRTIME}","${PARAMS2[0]}","${PARAMS2[1]}","${PARAMS2[2]}","${PARAMS2[3]}","${PARAMS2[4]}
                   echo $tmp >> $LOGFILE                                   # log the event
                   echo $tmp                                               # tell the user
                   RCc[${PARAMS2[3]}-1]="${PARAMS2[4]}";;                  # set array element to new string value
                 "check ip")
                   CheckIP;;                                               # pass to subroutine to sort out
                 "delete task")
                   tmp=${CURRTIME}","${PARAMS2[0]}","${PARAMS2[1]}","${PARAMS2[2]}","${PARAMS2['3']}
                   echo $tmp >> $LOGFILE                                   # log the event
                   echo $tmp                                               # tell the user
                   if [ -f /var/www/cronjobs.txt ]; then                   # clear out previous results
                        rm /var/www/cronjobs.txt
                   fi
                   if [ -f /var/www/cronjobs2.txt ]; then
                        rm /var/www/cronjobs2.txt
                   fi
                   crontab -l >>/var/www/cronjobs.txt                          # Make a copy of the current file
                   sed '/^#/ d' </var/www/cronjobs.txt >/var/www/cronjobs2.txt # remove any comments from file
                   sed -i ${PARAMS2[3]}d /var/www/cronjobs2.txt            # Delete the selected line
                   crontab /var/www/cronjobs2.txt                          # Re-install new cron file
                   rm /var/www/cronjobs2.txt
                   ;;
                 "edit task")
                   # This creates a new line in the crontab file at the same place as the original, then deletes
                   # the original which has been shifted up one line. This routine also handles requests to create
                   # a new task by the same mechanism.
                   set -f                                                  # Globbing off
                   tmp=${CURRTIME}","${PARAMS2[0]}","${PARAMS2[1]}","${PARAMS2[2]}","${PARAMS2[3]}","
                   tmp=$tmp${PARAMS2[4]}","${PARAMS2[5]}","${PARAMS2[6]}","${PARAMS2[7]}","${PARAMS2[8]}","${PARAMS2[9]}
                   echo $tmp >> $LOGFILE                                   # log the event
                   echo $tmp                                               # tell the user
                   if [ -f /var/www/cronjobs.txt ]; then                   # clear out previous results
                        rm /var/www/cronjobs.txt
                   fi
                   declare -a cmnd=('(scheduled task):(RasPi):remote control:1:on'  \
                                    '(scheduled task):(RasPi):remote control:1:off' \
                                    '(scheduled task):(RasPi):remote control:2:on'  \
                                    '(scheduled task):(RasPi):remote control:2:off' \
                                    '(scheduled task):(RasPi):remote control:3:on'  \
                                    '(scheduled task):(RasPi):remote control:3:off' \
                                    '(scheduled task):(RasPi):remote control:4:on'  \
                                    '(scheduled task):(RasPi):remote control:4:off' \
                                    '(scheduled task):(RasPi):remote control:5:on'  \
                                    '(scheduled task):(RasPi):remote control:5:off' \
                                    '(scheduled task):(RasPi):mode:Standby'         \
                                    '(scheduled task):(RasPi):mode:Part Set'        \
                                    '(scheduled task):(RasPi):mode:Full Set'        \
                                    '(scheduled task):(RasPi):check ip' )
                   # create the new line to be added...
                   tmpstr=${PARAMS2[4]}" "${PARAMS2[5]}" "${PARAMS2[6]}" "${PARAMS2[7]}" "
                   tmpstr=$tmpstr${PARAMS2[8]}" echo \""${cmnd[${PARAMS2[9]}]}
                   tmpstr=$tmpstr"\" >>/var/www/input.txt"                 # This is the new line to be added
                                                                           # to the cron jobs file
                   crontab -l >>/var/www/cronjobs.txt                      # Make a copy of the current crontab file
                   sed -i '/^#/ d' /var/www/cronjobs.txt                   # remove all comments from file

                   # NOTE: SED is very pedantic, so won't insert a line at the very end of the file.
                   # This causes issuse when creating a new job, which would normally be tagged on at the end.
                   # To get around this, a dummy line is written to the end of the file, then removed at the
                   # end of the calculations.
                   echo dummy >>/var/www/cronjobs.txt                      # stick an extra line in for SED
                   set -f                                                  # Globbing off
                   tststr2="${PARAMS2[3]}"i'\'                             # First part of sed command
                   tststr=$tmpstr                                          # second part of sed command
                   sed -i "${tststr2}${tststr}" /var/www/cronjobs.txt
                   set +f                                                  # Globbing back on
                   sed -i '$d' /var/www/cronjobs.txt                       # processing finished so remove the dummy line
                   ((PARAMS2[3]++))                                        # point to the line after the one we have just inserted
                   sed -i ${PARAMS2[3]}d /var/www/cronjobs.txt             # Delete the selected line - removes old version of the task

                   crontab /var/www/cronjobs.txt                           # Install the new cron file
                   ;;
                *)
                   tmp=${CURRTIME}","${PARAMS2[0]}",unknown command,"$info
                   echo $tmp >> $LOGFILE                                   # log the event
                   echo $tmp;;                                             # tell the user
               esac
               write_status_file status.txt                                # ...then report back to the web page
             done </var/www/input.txt
         rm /var/www/input.txt
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

      input_change=false                                           # set default
      chimes=false

      echo "1" > $PIN_13/value                                     # enable inputs 1 and 2
      sw1=$(cat $PIN_22/value)                                     # read first input
      if [[ "$sw1" -ne "$sw1_old" ]]; then input_change=true; fi   # flag any changes
      sw2=$(cat $PIN_24/value)                                     # read second input
      if [[ "$sw2" -ne "$sw2_old" ]]; then input_change=true; fi   # flag any changes
      echo "0" > $PIN_13/value                                     # disable inputs

      echo "1" > $PIN_11/value                                     # enable inputs 3 and 4
      sw3=$(cat $PIN_22/value)                                     # read third input
      if [[ "$sw3" -ne "$sw3_old" ]]; then input_change=true; fi   # flag any changes
      sw4=$(cat $PIN_24/value)                                     # read fourth input
      if [[ "$sw4" -ne "$sw4_old" ]]; then input_change=true; fi   # flag any changes
      echo "0" > $PIN_11/value                                     # disable inputs

      echo "1" > $PIN_12/value                                     # enable inputs 5 and 6
      sw5=$(cat $PIN_22/value)                                     # read fifth input
      if [[ "$sw5" -ne "$sw5_old" ]]; then input_change=true; fi   # flag any changes
      sw6=$(cat $PIN_24/value)                                     # read sixth input
      if [[ "$sw6" -ne "$sw6_old" ]]; then input_change=true; fi   # flag any changes
      echo "0" > $PIN_12/value                                     # disable inputs

      echo "1" > $PIN_7/value                                      # enable inputs 7 and 8
      sw7=$(cat $PIN_22/value)                                     # read seventh input
      if [[ "$sw7" -ne "$sw7_old" ]]; then input_change=true; fi   # flag any changes
      sw8=$(cat $PIN_24/value)                                     # read eigth input
      if [[ "$sw8" -ne "$sw8_old" ]]; then input_change=true; fi   # flag any changes
      echo "0" > $PIN_7/value                                      # enable inputs

                                                                   # if no circuits have changed, then there's nothing to do.
      if $input_change; then                                       # but if any circuit has changed, we need to dig deeper...

         tmp=${CURRTIME}",(alarm),(RasPi),zone status,"$sw1","$sw2","$sw3","$sw4","$sw5","$sw6","$sw7","$sw8
         echo $tmp >> $LOGFILE                                    # log the event
         echo $tmp                                                # tell the user
         write_status_file status.txt
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
