<?php  
include("readvars.php");             // common code to read variables from file STATUS.TXT    

$number=$_GET['num'];                // parameter not posted to avoid race conditions with iphone interface.
$title = "Edit task ".($number+1);

if ($number >= $jobcount) {          // falls through here if we are creating a new task
$task[$number][0]='*';               // so need to initialise default values...
$task[$number][1]='*';
$task[$number][2]='*';
$task[$number][3]='*';
$task[$number][4]='*'; }
?>

<div id="taskeditdiv">
       <div class="toolbar">
          <h1><?php echo $title; ?></h1> 
          <a href="logon.php#taskdiv" class="back">Back</a>
       </div>

       <div class="scroll">
       <p>&nbsp</p>
       <table border="0" style="width:100%;">
           <tr><td style="width: 27%; text-align: right;"><h2 style="margin-right: 10px">Hours</h2></td>
               <td style="width: 20%">
                   <ul class="rounded" style="width:100%; margin-left:0px; margin-top:0px; margin-bottom:0px;">
                     <li><select id="hour"><option value="*"<?php if (strcmp("*",$task[$number][1])==0) echo " selected=\"selected\""; ?>>*</option>
                           <?php for ($i=0; $i<=23; $i++ )
                                   { echo "\n<option value=\"".$i."\"";
                                     if (strcmp($i,$task[$number][1])==0) echo " selected=\"selected\"";
                                     echo ">".$i."</option>"; } ?>
                     </select></li></ul>
               </td>
               <td style="width: 6%"><h2 style="margin-right: 0px; margin-left: 6px">:</h2></td>
               <td style="width: 20%">
               <ul class="rounded" style="width:100%; margin-left:0px; margin-top:0px; margin-bottom:0px;">
                     <li><select id="min"><option value="*"<?php if (strcmp("*",$task[$number][0])==0) echo " selected=\"selected\""; ?>>*</option>
                           <?php for ($i=0; $i<=59; $i++ )
                                   { echo "\n<option value=\"".$i."\"";
                                     if (strcmp($i,$task[$number][0])==0) echo " selected=\"selected\"";
                                     echo ">".$i."</option>"; } ?>
                     </select></li></ul>
               </td>
               <td style="width: 27%; text-align: left"><h2 style="margin-left: 10px">Minutes</h2></td>
           </tr><tr>
               <td style="text-align: right;"><h2 style="margin-right: 10px">Day</h2></td>
               <td>
               <ul class="rounded" style="width:100%; margin-left:0px; margin-top:0px; margin-bottom:0px;">
                     <li><select id="day"><option value="*"<?php if (strcmp("*",$task[$number][2])==0) echo " selected=\"selected\""; ?>>*</option>
                           <?php for ($i=1; $i<=31; $i++ )
                                   { echo "\n<option value=\"".$i."\"";
                                     if (strcmp($i,$task[$number][2])==0) echo " selected=\"selected\"";
                                     echo ">".$i."</option>"; } ?>
                     </select></li></ul>
               </td>
               <td>&nbsp</td>
               <td style="width: 15%">
               <ul class="rounded" style="width:100%; margin-left:0px; margin-top:0px; margin-bottom:0px;">
                     <li><select id="month"><option value="*"<?php if (strcmp("*",$task[$number][3])==0) echo " selected=\"selected\""; ?>>*</option>
                           <?php $months=array("Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec");
                                 for ($i=1; $i<=12; $i++ )
                                   { echo "\n<option value=\"".$i."\"";
                                     if (strcmp($i,$task[$number][3])==0) echo " selected=\"selected\"";
                                     echo ">".$months[$i-1]."</option>"; } ?>
                     </select></li></ul>
                   </td>
                   <td style="text-align: left"><h2 style="margin-left: 10px">Month</h2></td>
       </table>

       <table border="0" style="width:100%;">
           <tr><td style="width: 38%; text-align: right;"><h2 style="margin-right: 10px">Weekday</h2></td>
               <td style="width: 20%">
               <ul class="rounded" style="width:100%; margin-left:0px; margin-top:0px; margin-bottom:0px;">
                     <li><select id="weekday"><option value="*"<?php if (strcmp("*",$task[$number][4])==0) echo " selected=\"selected\""; ?>>*</option>
                           <?php $days=array("Sun","Mon","Tue","Wed","Thur","Fri","Sat");
//                                 for ($i=1; $i<=7; $i++ )
                                 for ($i=0; $i<=6; $i++ )
                                   { echo "\n<option value=\"".$i."\"";
                                     if (strcmp($i,$task[$number][4])==0) echo " selected=\"selected\"";
                                     echo ">".$days[$i]."</option>"; } ?>
//                                   echo ">".$days[$i-1]."</option>"; } 
                     </select></li></ul>
               </td>
               <td>&nbsp</td>
           </tr>
           </table>
       <p>&nbsp</p>
       <table border="0" style="width:100%;">
           <tr><td style="width: 8%; text-align: right;"><h2 style="margin-right: 10px;margin-left: 10px">Task</h2></td>
               <td style="width: 55%">
               <ul class="rounded" style="width:100%; margin-left:0px; margin-top:0px; margin-bottom:0px;">
                     <li><select id="selection">
                     <?php // Building the drop down data for the tasks...
                           // Current RC channel names are read each time the page loads.
                           // All logic is performed on the constant RC channel number ( eg "RC2 On" )
                           // But the web page displays the variable RC channel name ( eg "Kitchen lights -> On" )
                           echo"\n<option value=\"0\"";
                           if ($task[$number][6]==0) echo " selected=\"selected\"";
                           echo ">".$RCc[1]." on</option>";
                           echo"\n<option value=\"1\"";
                           if ($task[$number][6]==1) echo " selected=\"selected\"";
                           echo ">".$RCc[1]." off</option>";
                           echo"\n<option value=\"2\"";
                           if ($task[$number][6]==2) echo " selected=\"selected\"";
                           echo ">".$RCc[2]." on</option>";
                           echo"\n<option value=\"3\"";
                           if ($task[$number][6]==3) echo " selected=\"selected\"";
                           echo ">".$RCc[2]." off</option>";
                           echo"\n<option value=\"4\"";
                           if ($task[$number][6]==4) echo " selected=\"selected\"";
                           echo ">".$RCc[3]." on</option>";
                           echo"\n<option value=\"5\"";
                           if ($task[$number][6]==5) echo " selected=\"selected\"";
                           echo ">".$RCc[3]." off</option>";
                           echo"\n<option value=\"6\"";
                           if ($task[$number][6]==6) echo " selected=\"selected\"";
                           echo ">".$RCc[4]." on</option>";
                           echo"\n<option value=\"7\"";
                           if ($task[$number][6]==7) echo " selected=\"selected\"";
                           echo ">".$RCc[4]." off</option>";
                           echo"\n<option value=\"8\"";
                           if ($task[$number][6]==8) echo " selected=\"selected\"";
                           echo ">".$RCc[5]." on</option>";
                           echo"\n<option value=\"9\"";
                           if ($task[$number][6]==9) echo " selected=\"selected\"";
                           echo ">".$RCc[5]." off</option>";
                           echo"\n<option value=\"10\"";
                           if ($task[$number][6]==10) echo " selected=\"selected\"";
                           echo ">Alarm Standby</option>";
                           echo"\n<option value=\"11\"";
                           if ($task[$number][6]==11) echo " selected=\"selected\"";
                           echo ">Alarm Part Set</option>";
                           echo"\n<option value=\"12\"";
                           if ($task[$number][6]==12) echo " selected=\"selected\"";
                           echo ">Alarm Full Set</option>";
                           echo"\n<option value=\"13\"";
                           if ($task[$number][6]==13) echo " selected=\"selected\"";
                           echo ">Check router IP</option>"; ?>
               </select></li></ul>              
               </td>
               <td>&nbsp</td>
           </tr>
           </table>
       <p>&nbsp</p>
       <div align="center">
       <table border="0">
           <tr><td><a href="#" onclick="tmp='edit task:'+
                                   <?php echo $number+1; ?>+':'+
                                   document.getElementById('min').value+':'+
                                   document.getElementById('hour').value+':'+
                                   document.getElementById('day').value+':'+
                                   document.getElementById('month').value+':'+
                                   document.getElementById('weekday').value+':'+
                                   document.getElementById('selection').value;
                                   document.getElementById('retval').value = tmp;
                                   ajaxrequest('tasklist.php','tasklist');
                                   history.go(-1);" class="whiteButton" width="50%">Save</a></td>
           <td><a href="#" onclick="tmp='delete task:'+
                                   <?php echo $number+1; ?>;
                                   document.getElementById('retval').value = tmp;
                                   ajaxrequest('tasklist.php','tasklist');
                                   history.go(-1);" class="redButton" width="50%">Delete</a>
           </td></tr>
       </table>
       </div>
       <input type='hidden' name="retval" id="retval" />
     </div>
</div>
