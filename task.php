<?php
include("readvars.php");                         // common code to read variables from file STATUS.TXT    
?>

<div id="tasklist" class="selectable">
            <div class="toolbar">
                <h1>Tasks</h1>
                <a class="back menu" href="#menusheet">Menu</a>
                <a class="button slide" href="#" onclick="newtask()">New</a>
            </div>
            <div id="taskscroll" class="scroll">
            <ul class="edgetoedge scroll" style="margin-top: 0">
               <?php // default format for cron job is rather messy, so tidy it up a bit...
                     $months=array("January","February","March","April","May","June","July","August","September","October","November","December");
                     $days=array("Sunday","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday");
                     for($j=0; $j<$jobcount; $j++) { 
                       $tmp="";
                       if ((strlen($task[$j][0])==1) && ($task[$j][0]!="*"))
                          { $task[$j][0] = "0".$task[$j][0]; }                                     // put in leading zero minutes
                       if ((strlen($task[$j][1])==1) && ($task[$j][1]!="*"))
                          { $task[$j][1] = "0".$task[$j][1]; }                                     // put in leading zero hours

                       // check for common levels of recurrence...
                       if (($task[$j][3]!="*") && ($task[$j][2]=="*"))                             // value for month, but not for day of month.
                          {  $tmp="During ".$months[$task[$j][3]-1]."<br>"; }                      // Monthly recourance (eg During March)

                       if ($task[$j][4]!="*")                                                      // weekday has been specified
                          { $tmp.="On ".$days[$task[$j][4]]."s <br>"; }

                       if (($task[$j][0]!="*") && ($task[$j][1]=="*"))                             // value for minutes but not for hours
                          { $tmp.="Hourly at ".$task[$j][0]." minutes<br>".$task[$j][6]; }         // Hourly recourance
                       else
                          {   if ($task[$j][4]!="*")                                               // if a day is specified but no hours...
                                { $tmp.="at ".$task[$j][1].":".$task[$j][0]."<br>".$task[$j][6]; } // add the task info
                             else                                                                  // day and hours not specified...
                                { $tmp.="Daily at ";                                               // every day
                                  $tmp.=$task[$j][1].":".$task[$j][0]."<br>".$task[$j][6]; }       // add the task info
                          }
                         if ($task[$j][2]!="*")                                                    // recurrence by date
                          { $tmp=$task[$j][0]." ".$task[$j][1]." ".$task[$j][2]." ";               // worst case scenario just show raw data
                            $tmp.=$task[$j][3]." ".$task[$j][4]."<br>".$task[$j][6]; }
               ?>
               <li><a href="#" onclick="taskedit(<?php echo $j; ?>)"><?php echo $tmp; ?></a></li>
               <?php } ?>
            </ul>
<!-- Make all task configuration data available on the page just in case we want to drill down and start editing -->
<!-- Note added a spare entry at the end in case we want to create a new task                                    -->
           <input type="hidden" id="taskcount" value="<?php echo $jobcount; ?>">
           <?php for ($row=0; $row<$jobcount+1; $row++) { ?>
           <input type="hidden" id="minutes_<?php echo $row; ?>" value="<?php echo $task[$row][0]; ?>">
           <input type="hidden" id="hours_<?php echo $row; ?>" value="<?php echo $task[$row][1]; ?>">
           <input type="hidden" id="dom_<?php echo $row; ?>" value="<?php echo $task[$row][2]; ?>">
           <input type="hidden" id="month_<?php echo $row; ?>" value="<?php echo $task[$row][3]; ?>">
           <input type="hidden" id="weekday_<?php echo $row; ?>" value="<?php echo $task[$row][4]; ?>">
           <input type="hidden" id="tasknum_<?php echo $row; ?>" value="<?php echo $task[$row][5]; ?>">
           <input type="hidden" id="taskname_<?php echo $row; ?>" value="<?php echo $task[$row][6]; ?>">
        <?php } ?>
        </div>
</div>

<!-- Numeric keypad sub menu -->
<div id="numpad">
    <div class="toolbar"><h1 id="NumPadHead">tbd</h1>
           <a href="#" onclick="numpadret()" class="back">Back</a>
    </div>
    <div style="text-align: center;" onmousedown="return false;">
           <input id='numval' value="tbd" size="2" style="font-size: 45pt; background: transparent; text-align:center;"></br>
           <div style="margin-left:10px;">
                 <?php for ($count=0; $count<=9; $count++) { ?>
                          <div class="RoundButton"><a href="#" onclick="numpadupdate('<?php echo $count; ?>')" style="text-decoration: none"><?php echo $count; ?></a></div>
                 <?php } ?>
               <div class="RoundButton">
                    <a href="#" onclick="numpadupdate('*')" style="text-decoration: none">*</a>
               </div>
           </div>
    </div>
</div>

<!-- Task List Edit sub menu -->
<div id="taskedit">
       <div class="toolbar"><h1 id="TaskConfHead">tbd</h1>
              <a class="back2div slideright" onclick="TaskSend()" href="#tasklist">Back</a>
              <a class="button slide" onclick="TaskDel()" href="#">Delete</a>
       </div>
       <div class="scroll">
          <ul class="plastic">
               <li class="arrow"><a href="#" onclick="numpadinit('Select hours')">Hours<small class="small" id="edt_hours">tbd</small></a></li>
               <li class="arrow"><a href="#" onclick="numpadinit('Select minutes')">Minutes<small class="small" id="edt_minutes">tbd</small></a></li>
               <li class="arrow"><a href="#" onclick="numpadinit('Select date')">Day of Month<small class="small" id="edt_dom">tbd</small></a></li>
        <!-- Text values for the user to read                              -->
               <li class="arrow"><a href="#selectmonth">Month<small class="small" id="edt_month_str">tbd</small></a></li>
               <li class="arrow"><a href="#selectday">Weekday<small class="small" id="edt_wday_str">tbd</small></a></li>
               <li class="arrow"><a href="#selecttask">Task<small class="small" id="edt_task_str">tbd</small></a></li>
          </ul>
        <!-- Numeric values required to pass back to the alarm service     -->
        <input type="hidden" id="edt_month">
        <input type="hidden" id="edt_wday">
        <input type="hidden" id="edt_task">
        </div>
 </div>

<div id="selectday">
      <div class="toolbar"><h1>Select day</h1>
          <a class="back" href="#taskedit">Back</a>
      </div>
      <div class="scroll">
      <p>&nbsp</p>
         <ul class="rounded">
               <li><a href="#taskedit" onclick="stringret('weekday','1','Monday')">Monday</a></li>
               <li><a href="#taskedit" onclick="stringret('weekday','2','Tuesday')">Tuesday</a></li>
               <li><a href="#taskedit" onclick="stringret('weekday','3','Wednesday')">Wednesday</a></li>
               <li><a href="#taskedit" onclick="stringret('weekday','4','Thursday')">Thursday</a></li>
               <li><a href="#taskedit" onclick="stringret('weekday','5','Friday')">Friday</a></li>
               <li><a href="#taskedit" onclick="stringret('weekday','6','Saturday')">Saturday</a></li>
               <li><a href="#taskedit" onclick="stringret('weekday','0','Sunday')">Sunday</a></li>
               <li><a href="#taskedit" onclick="stringret('weekday','*','*')">any day</a></li>
         </ul>
      </div>
</div>

<div id="selectmonth">
      <div class="toolbar"><h1>Select month</h1>
          <a class="back" href="#">Back</a>
      </div>
      <div class="scroll">
      <p>&nbsp</p>
         <ul class="rounded">
               <li><a href="#" onclick="stringret('month','1','January');">January</a></li>
               <li><a href="#" onclick="stringret('month','2','February');">February</a></li>
               <li><a href="#" onclick="stringret('month','3','March');">March</a></li>
               <li><a href="#" onclick="stringret('month','4','April');">April</a></li>
               <li><a href="#" onclick="stringret('month','5','May');">May</a></li>
               <li><a href="#" onclick="stringret('month','6','June');">June</a></li>
               <li><a href="#" onclick="stringret('month','7','July');">July</a></li>
               <li><a href="#" onclick="stringret('month','8','August');">August</a></li>
               <li><a href="#" onclick="stringret('month','9','September');">September</a></li>
               <li><a href="#" onclick="stringret('month','10','October');">October</a></li>
               <li><a href="#" onclick="stringret('month','11','November');">November</a></li>
               <li><a href="#" onclick="stringret('month','12','December');">December</a></li>
               <li><a href="#" onclick="stringret('month','*','*');">any month</a></li>
         </ul>
      </div>
</div>

<div id="selecttask">
      <div class="toolbar"><h1>Select task</h1>
          <a class="back" href="#taskedit">Back</a>
      </div>
      <div class="scroll">
      <p>&nbsp</p>
         <ul class="rounded">
               <li><a href="#" onclick="stringret('task','0','Check router IP');">Check router IP</a></li>
               <li><a href="#" onclick="stringret('task','1','Alarm Standby');">Alarm Standby mode</a></li>
               <li><a href="#" onclick="stringret('task','2','Alarm Night mode');">Alarm Night mode</a></li>
               <li><a href="#" onclick="stringret('task','3','Alarm Day mode');">Alarm Day mode</a></li>
<!-- TBD need to link number of available tasks to number of remote channels - so need to replace next bit with a loop             -->
               <li><a href="#" onclick="stringret('task','4','<?php echo $RCc[1]; ?> on');">Switch <?php echo $RCc[1]; ?> on</a></li>
               <li><a href="#" onclick="stringret('task','5','<?php echo $RCc[1]; ?> off');">Switch <?php echo $RCc[1]; ?> off</a></li>
               <li><a href="#" onclick="stringret('task','6','<?php echo $RCc[2]; ?> on');">Switch <?php echo $RCc[2]; ?> on</a></li>
               <li><a href="#" onclick="stringret('task','7','<?php echo $RCc[2]; ?> off');">Switch <?php echo $RCc[2]; ?> off</a></li>
               <li><a href="#" onclick="stringret('task','8','<?php echo $RCc[3]; ?> on');">Switch <?php echo $RCc[3]; ?> on</a></li>
               <li><a href="#" onclick="stringret('task','9','<?php echo $RCc[3]; ?> off');">Switch <?php echo $RCc[3]; ?> off</a></li>
               <li><a href="#" onclick="stringret('task','10','<?php echo $RCc[4]; ?> on');">Switch <?php echo $RCc[4]; ?> on</a></li>
               <li><a href="#" onclick="stringret('task','11','<?php echo $RCc[4]; ?> off');">Switch <?php echo $RCc[4]; ?> off</a></li>
               <li><a href="#" onclick="stringret('task','12','<?php echo $RCc[5]; ?> on');">Switch <?php echo $RCc[5]; ?> on</a></li>
               <li><a href="#" onclick="stringret('task','13','<?php echo $RCc[5]; ?> off');">Switch <?php echo $RCc[5]; ?> off</a></li>
         </ul>
      </div>
</div>