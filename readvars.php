<?php
// Date in the past
header("Expires: Mon, 26 Jul 1997 05:00:00 GMT");
header("Cache-Control: no-cache");
header("Pragma: no-cache");

if (isset($_POST['retval']))
{     exec("rm -f /var/www/uploads/status.txt");                 // remove old data
      $tmp = $_COOKIE['username'].":".$_SERVER['REMOTE_ADDR'].":".$_POST['retval'];
      exec("echo $tmp >>/var/www/uploads/input.txt");            // Pass data to the BASH shell script
}
     
$loggedin=(isset($_COOKIE['loggedin']) && $_COOKIE['loggedin']=='true')?true:false;
$username=$_COOKIE["username"];
$userip=$_COOKIE["userip"];
$usercount=0;                              // Global variables (stops PHP errors later on)
$jobcount=0;
$triggeredzones=0;
$openzones=0;
$closedzones=0;
$RCnum=1;
$time = 4;                             // time in seconds to wait for the status file to be created.
$found = false;
$filename = '/var/www/uploads/status.txt';
$taskname=array("Check router IP address","Set mode: Standby","Set mode: Night mode","Set mode: Day mode",
                "Switch RC1: On","Switch RC1: Off",
                "Switch RC2: On","Switch RC2: Off",
                "Switch RC3: On","Switch RC3: Off",
                "Switch RC4: On","Switch RC4: Off",
                "Switch RC5: On","Switch RC5: Off", );

// Start reading the data file....
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
//               $status[0]="Active !";                                   // DIAGNOSTIC
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
              $ZoneNum = 0;
              while (strlen($data)>1)                                     // last line of file often has no data in it, so only proceed if we have data ...
                   { $data = fgets($file);
                     $tmp=strlen($data)-16;                                // skip first 16 characters
                     $data=substr($data, -$tmp);
                     $zone[$ZoneNum]=(explode(":",$data));
//                   $zone[3][6]='true';                                   // DIAGNOSTIC - fake triggered zone
//                   $zone[0][6]='true';                                   // DIAGNOSTIC - fake triggered zone
                     if ($zone[$ZoneNum][6]=='true') { $triggeredzones++; }    // Zone triggered - bump the count
                     $label[$row]="";
                     if ($zone[$ZoneNum][4]=='on') { $label[$ZoneNum].='D'; }      // Day mode
                     if ($zone[$ZoneNum][5]=='on') { $label[$ZoneNum].='N'; }      // Night mode
                     if ($zone[$ZoneNum][3]=='on') { $label[$ZoneNum].='C'; }      // Chimes
                     if ($zone[$ZoneNum][1]=='tamper') { $label[$ZoneNum]='T'; }   // Tamper
                     $ZoneNum++;
                   }
                $ZoneNum--;                                                        // fudge factor
                }
              if (substr($data,0,22) == "Remote Control status:") {    // skip down to the right section
                   while (strlen($data)>1)                            // last line of file often has no data in it, so only proceed if we have data ...
                   {  $data = fgets($file);
                      if($RCnum < 10) {
                       // store string from character 16, but skip the last character as its a white space char
                       $data=substr($data, 16, -1);
                       $RCs[$RCnum]=$data;
                      }
                      else {
                       // store string from character 16, but skip the last character as its a white space char
                       $data=substr($data, 17, -1);
                       $RCs[$RCnum]=$data;
                      }
                      $RCnum++;
                   }
                   $RCnum=$RCnum-2;                                                    // fudge factor
                }
              if (substr($data,0,22) == "Remote Control config:") {    // skip down to the right section
              $RCnum = 1;                                              // reset and re-use variable
                   while (strlen($data)>1)                             // last line of file often has no data in it, so only proceed if we have data ...
                    { $data = fgets($file);
                      if($RCnum < 10) {
                       // store string from character 17, but skip the last character as its a white space char
                        $RCc[$RCnum]=substr($data, 17, -1);
                        $taskname[2*$RCnum+2]= "Switch ".$RCc[$RCnum].": On";    // overwrite default value with friendly name
                        $taskname[2*$RCnum+3]= "Switch ".$RCc[$RCnum].": Off";
                      }
                      else {
                       // store string from character 17, but skip the last character as its a white space char
                        $RCc[$RCnum]=substr($data, 17, -1);
                        $taskname[2*$RCnum+2]= "Switch ".$RCc[$RCnum].": On";    // overwrite default value with friendly name
                        $taskname[2*$RCnum+3]= "Switch".$RCc[$RCnum].": Off";
                      }
                    $RCnum++;                                                    // bump number of channels
                    } 
                    $RCnum--;                                                    // fudge factor
                    $RCnum--;
                }
              if (substr($data,0,14) == "Configuration:") {                      // skip down to the right section
                 $location=substr(fgets($file), 17, -1);
                 $routerIP=substr(fgets($file), 17, -1);
                 $localIP=substr(fgets($file), 17, -1);
                 $duration=substr(fgets($file), 17, -1);
                 $Diskused=substr(fgets($file), 17, -1);
                 $DiskusedPerc=substr(fgets($file), 17, -1);
                 $Disktotal=substr(fgets($file), 17, -1);
                 $Memory=substr(fgets($file), 17, -1);
                 $Hardware=substr(fgets($file), 17, -1); }
              if (substr($data,0,6) == "Email:") {                               // skip down to the right section
                 $EMAIL_server=substr(fgets($file), 17, -1);
                 $EMAIL_port=substr(fgets($file), 17, -1);
                 $EMAIL_sender=substr(fgets($file), 17, -1);
                 $EMAIL_password=substr(fgets($file), 17, -1);
                 $EMAIL_recipient=substr(fgets($file), 17, -1); }                // I DONT THINK THIS EXISTS ANYMORE - POSSIBLE TO REMOVE ?

              if (substr($data,0,10) == "Cron jobs:") {                          // skip down to the right section
                    while (strlen($data)!=1)                                     // last line of file is often blank, so only proceed if we have data ...
                    { $data = fgets($file);
                      $task[$jobcount]=preg_split('/\s+/', $data);               // At this point the array elements are the cron job parameters.
                      $task[$jobcount][6]=$taskname[$task[$jobcount][5]];        // Get friendly task name based on task number
                      $jobcount++;                                               // Counter also used when creating new cron jobs
                    }
                $jobcount--;  
                }
              if (substr($data,0,6) == "Users:") {                               // skip down to the right section
                  do { $data = fgets($file);
                       $usercount++;
                       if (strlen($data)>1)                                      // last line read is empty, only proceed if we have data..
                         { $user[$usercount]=explode(",", $data);
                         }
                     } while (strlen($data)>1);                                  // keep reading lines until we find a NULL string or just an LF
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