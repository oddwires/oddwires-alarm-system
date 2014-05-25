<?php
include("readvars.php");                         // common code to read variables from file STATUS.TXT 
?>

<!-- Scroller element of the Task screen                               -->
<!-- kept separate to ensure AJAX updates load without breaking the scroller -->

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