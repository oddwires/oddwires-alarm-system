<?php
include("readvars.php");                         // common code to read variables from file STATUS.TXT    
?>

<div id="tasklist">
<?php // print_r($_POST);                          //DIAGNOSTIC  ?>
            <div class="toolbar">
                <h1>Tasks</h1>
                <a href="#" class="back">< Prev</a>
                <a href="userlist.php" class="button cube">Next ></a>
<!--                <a class="button slide" href="taskedit.php?num=<?php echo $jobcount+1; ?>">New</a> -->
<!--            <a class="button slideup" href="#about">About</a> -->
            </div>
            <ul class="edgetoedge scroll">
               <?php // default format for cron job is rather messy, so tidy it up a bit...
                     $months=array("January","February","March","April","May","June","July","August","September","October","November","December");
                     $days=array("Sunday","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday");
                     for($j=0; $j<$jobcount; $j++) { 
                       $tmp="";
                       if ((strlen($task[$j][0])==1) && ($task[$j][0]!="*"))
                          { $task[$j][0] = "0".$task[$j][0]; }                                  // put in leading zero minutes
                       if ((strlen($task[$j][1])==1) && ($task[$j][1]!="*"))
                          { $task[$j][1] = "0".$task[$j][1]; }                                  // put in leading zero hours

                       if (($task[$j][3]!="*") && ($task[$j][2]=="*"))                          // value for month, but not for day of month.
                          {  $tmp="During ".$months[$task[$j][3]-1]."...<br>..."; }             // Monthly recourance (eg During March)

                       if (($task[$j][0]!="*") && ($task[$j][1]=="*"))                          // value for minutes but not for hours
                          { $tmp.="Hourly at ".$task[$j][0]." minutes<br>".$task[$j][5]; }      // Hourly recourance
                       else
                          {  if ($task[$j][4]!="*")                                             // if a day is specified but no hours...
                                { $tmp.=$tmp."On ".$days[$task[$j][4]-1]."s...<br>...at ";      // ...daily recourance (eg on Mondays)
                                  $tmp.=$task[$j][1].":".$task[$j][0]."<br>".$task[$j][5]; }    // add the task info
                             else                                                               // day and hours not specified...
                                { $tmp.="Daily at ";                                            // every day
                                  $tmp.=$task[$j][1].":".$task[$j][0]."<br>".$task[$j][5]; }    // add the task info
                          }
                         if ($task[$j][2]!="*")                                                 // recourance by date
                          { $tmp=$task[$j][0]." ".$task[$j][1]." ".$task[$j][2]." ";            // worst case scenario just show raw data
                            $tmp.=$task[$j][3]." ".$task[$j][4]."<br>".$task[$j][5]; }
               ?>
               <li><a href="taskedit.php?num=<?php echo $j; ?>"><?php echo $tmp; ?></a></li>
               <?php } ?>
            </ul>
            <input type="hidden" name="tasknum" id="tasknum2">
            <a class="button slide" href="taskedit.php?num=<?php echo $jobcount; ?>">New task</a>
</div>           <!-- list of tasks (cronjobs) -->
