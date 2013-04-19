<?php
// Date in the past
header("Expires: Mon, 26 Jul 1997 05:00:00 GMT");
header("Cache-Control: no-cache");
header("Pragma: no-cache");
     
$loggedin=(isset($_COOKIE['loggedin']) && $_COOKIE['loggedin']=='true')?true:false;
$username=$_COOKIE["username"];
$userip=$_COOKIE["userip"];
$usercount=0;                              // Global variables (stops PHP errors later on)
$jobcount=0;
$triggeredzones=0;
$openzones=0;
$closedzones=0;

if (isset($_POST['retval']))
{     exec("rm -f /var/www/status.txt");                 // remove old data
      $tmp = $_COOKIE['username'].":".$_SERVER['REMOTE_ADDR'].":".$_POST['retval'];
      exec("echo $tmp >>/var/www/input.txt");            // Pass data to the BASH shell script
}

if (isset($_POST['settings']))
{     exec("rm -f /var/www/status.txt");               // remove old data
      $tmp = $_COOKIE['username'].":".$_SERVER['REMOTE_ADDR'].":load factory defaults";
      exec("echo $tmp >>/var/www/input.txt");        // Send message to alarm service
}

// Read in data required to create this page .....
$time = 4;                             // time in seconds to wait for the status file to be created.
$found = false;
$filename = '/var/www/status.txt';
for($i=0; $i<$time; $i++)
  { if (file_exists($filename))
      { // Falls through here if we have found it - so read the file ....
        $found = true;
        $file = fopen($filename,'r');
        if (!$file) {                  // Sometimes the stoopid file still won't open !
            $found=false;              // ( e.g. permission issues or freaky timing issues )
            break; }                   // so trap any remaining errors
        while (!feof($file))
          { $data=fgets($file);
              if (substr($data,0,13) == "Alarm status:") {                // skip down to the right section
                 $data = fgets($file);
                 $tmp=strlen($data)-16;                                   // skip first 16 characters
                 $status[0]=substr($data, -$tmp, -1);                     // Alarm status (white space removed from line end)
                 $data = fgets($file);
                 $tmp=strlen($data)-16;                                   // skip first 16 characters
                 $status[1]=substr($data, -$tmp); }                       // Alarm mode
              if (substr($data,0,18) == "Alarm zone status:") {           // skip down to the right section
                 for ($row=0; $row<=7; $row++)
                  { $data = fgets($file);
                    $tmp=strlen($data)-17;                                // skip first 17 characters
                    $data=substr($data, -$tmp);
                    $znstat[$row] = !filter_var($data, FILTER_VALIDATE_BOOLEAN);
//                  $znstat[0]=TRUE;                                      // DIAGNOSTIC - fake open zone
//                  $znstat[1]=FALSE;                                     // DIAGNOSTIC - fake closed zone
//                  $znstat[2]=TRUE;                                      // DIAGNOSTIC - fake open zone
//                  $znstat[3]=FALSE;                                     // DIAGNOSTIC - fake closed zone
//                  $znstat[4]=FALSE;                                     // DIAGNOSTIC - fake closed zone
//                  $znstat[5]=TRUE;                                      // DIAGNOSTIC - fake open zone
//                  $znstat[6]=TRUE;                                      // DIAGNOSTIC - fake open zone
//                  $znstat[7]=TRUE;                                      // DIAGNOSTIC - fake open zone
                    if ($znstat[$row]) { $openzones++; }                  // Zone open   - bump counter
                    else               { $closedzones++; }                // Zone closed - bump counter
                  }
               }
              if (substr($data,0,18) == "Alarm zone config:") {           // skip down to the right section
                 for ($row=0; $row<=7; $row++)
                   { $data = fgets($file);
                     $tmp=strlen($data)-16;                                // skip first 16 characters
                     $data=substr($data, -$tmp);
                     $zone[$row]=(explode(":",$data));
//                   $zone[8][6]='true';                                   // DIAGNOSTIC - fake triggered zone
                     if ($zone[$row][6]=='true') { $triggeredzones++; }    // Zone triggered - bump the count
                     $label[$row]="";
                     if ($zone[$row][4]=='on') { $label[$row].='F'; }      // Full set
                     if ($zone[$row][5]=='on') { $label[$row].='P'; }      // Part set
                     if ($zone[$row][3]=='on') { $label[$row].='C'; }      // Chimes
                     if ($zone[$row][1]=='tamper') { $label[$row]='T'; }   // Tamper
                   }
                }
              if (substr($data,0,22) == "Remote Control status:") {    // skip down to the right section
                  for ($row=1; $row<=5; $row++)
                   { $data = fgets($file);
                     $data=substr($data, 16, -1);                      // string from character 16, but skip the last
                                                                       // character because its a white space. This 
                                                                       // leaves us with either 'on' or 'off'
                     $RCs[$row]=$data;                                 // store result
                   }
                }
              if (substr($data,0,22) == "Remote Control config:") {    // skip down to the right section
                  for ($row=1; $row<=5; $row++)
                  { $data = fgets($file);
                    $data=substr($data, 17, -1);                       // string from character 16, but skip the last
                                                                       // character because its a white space char.
                                                                       // This leaves us with the name of the zone
                    $RCc[$row]=$data;                                  // store result
                   }
                }
              if (substr($data,0,14) == "Configuration:") {            // skip down to the right section
                 $location=substr(fgets($file), 17, -1);
                 $routerIP=substr(fgets($file), 17, -1);
                 $localIP=substr(fgets($file), 17, -1);
                 $duration=substr(fgets($file), 17, -1);
                 $Diskused=substr(fgets($file), 17, -1);
                 $DiskusedPerc=substr(fgets($file), 17, -1);
                 $Disktotal=substr(fgets($file), 17, -1);
                 $Memory=substr(fgets($file), 17, -1);
                 $Hardware=substr(fgets($file), 17, -1); }
              if (substr($data,0,6) == "Email:") {                     // skip down to the right section
                 $EMAIL_server=substr(fgets($file), 17, -1);
                 $EMAIL_port=substr(fgets($file), 17, -1);
                 $EMAIL_sender=substr(fgets($file), 17, -1);
                 $EMAIL_password=substr(fgets($file), 17, -1);
                 $EMAIL_recipient=substr(fgets($file), 17, -1); }
              if (substr($data,0,10) == "Cron jobs:") {                // skip down to the right section
                    while (strlen($data)!=1)                           // last line of file often has no data in it, so only proceed if we have data ...
                    { $data = fgets($file);
                      $task[$jobcount]=preg_split('/\s+/', $data);     // At this point the array elements are the cron job parameters.



                      $tmp=strlen($data) -  // So to find the length of the string containing just the cron job parameters...
                      strlen($task[$jobcount][0]) -
                      strlen($task[$jobcount][1]) -
                      strlen($task[$jobcount][2]) -
                      strlen($task[$jobcount][3]) - 6;                 // find the length of the string containing just the cron job parameters.
                                                                       // 6 is the fiddle factor - allows for spaces and white space characters.

                      $task[$jobcount][5]=substr($data,-$tmp);         // Get the string, without the cron job parameters - this gives just the command.
                      $task[$jobcount][5] = str_replace('"', "", $task[$jobcount][5]);  // loose any speech marks
                      $task[$jobcount][5] = substr($task[$jobcount][5], 0, -1);         // loose white space char at end
                                                                                        // and now we are ready for action.
                      $tmp=strtolower(substr($task[$jobcount][5], 30, -21));            // all strings start with...
                                                                                        //  'echo (scheduled task):(RasPi):'
                                                                                        // and end with...
                                                                                        //  ': >>/var/www/input.txt'
                                                                                        // ...so loose it, and make it all lower case
                                                                        // Strings are now all lower case, but still a little bit 'Linuxy', so substitute suitable strings.
                      switch ($tmp) {
                        case "remote control:1:on":
                        $task[$jobcount][5]="Switch ".$RCc[1]." on";
                        $task[$jobcount][6]="0";
                        break;
                        case "remote control:1:off":
                        $task[$jobcount][5]="Switch ".$RCc[1]." off";
                        $task[$jobcount][6]="1";
                        break;
                        case "remote control:2:on":
                        $task[$jobcount][5]="Switch ".$RCc[2]." on";
                        $task[$jobcount][6]="2";
                        break;
                        case "remote control:2:off":
                        $task[$jobcount][5]="Switch ".$RCc[2]." off";
                        $task[$jobcount][6]="3";
                        break;
                        case "remote control:3:on":
                        $task[$jobcount][5]="Switch ".$RCc[3]." on";
                        $task[$jobcount][6]="4";
                        break;
                        case "remote control:3:off":
                        $task[$jobcount][5]="Switch ".$RCc[3]." off";
                        $task[$jobcount][6]="5";
                        break;
                        case "remote control:4:on":
                        $task[$jobcount][5]="Switch ".$RCc[4]." on";
                        $task[$jobcount][6]="6";
                        break;
                        case "remote control:4:off":
                        $task[$jobcount][5]="Switch ".$RCc[4]." off";
                        $task[$jobcount][6]="7";
                        break;
                        case "remote control:5:on":
                        $task[$jobcount][5]="Switch ".$RCc[5]." on";
                        $task[$jobcount][6]="8";
                        break;
                        case "remote control:5:off":
                        $task[$jobcount][5]="Switch ".$RCc[5]." off";
                        $task[$jobcount][6]="9";
                        break;
                        case "mode:standby":
                        $task[$jobcount][5]="Set alarm to standby";
                        $task[$jobcount][6]="10";
                        break;
                        case "mode:part set":
                        $task[$jobcount][5]="Set alarm to part set";
                        $task[$jobcount][6]="11";
                        break;
                        case "mode:full set":
                        $task[$jobcount][5]="Set alarm to full set";
                        $task[$jobcount][6]="12";
                        break;
                        case "check ip":
                        $task[$jobcount][5]="Check router IP address";
                        $task[$jobcount][6]="13";
                        break;
                      }
                      $jobcount++;                                                      // also used for new cron jobs
                    }
                $jobcount--;  
                }
              if (substr($data,0,6) == "Users:") {          // skip down to the right section
                  do { $data = fgets($file);
                       $usercount++;
                       if (strlen($data)>1)              // last line read is empty, only proceed if we have data..
                         { $user[$usercount]=explode(",", $data);
                         }
                     } while (strlen($data)>1);          // keep reading lines until we find a NULL string or just an LF
                  $usercount--;   
                }
          }
      fclose ($file);
      break;          // at this point we have successfully read the data, so break out of 'for' loop.
      }
    else
      { // Falls through here if no file found after specified period
        sleep(1);  // wait one second before trying again
      }
  }
if ($found == false) { header('Location: /fault.php#fault'); } // Hello Houston...
?>