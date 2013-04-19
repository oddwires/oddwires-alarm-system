<?php
include("readvars.php");                         // common code to read variables from file STATUS.TXT    
?>

<div id="userlist">
<?php // print_r($_POST);                          //DIAGNOSTIC  ?>
            <div class="toolbar">
                <h1>Users</h1>
                <a href="#" class="back">< Prev</a>
                <a href="setup.php" class="button cube">Next ></a>
<!--                <a class="button slide" href="useredit.php?num=<?php echo $usercount+1; ?>">New</a> -->
<!--            <a class="button slideup" href="#about">About</a> -->
            </div>
            <ul class="edgetoedge scroll">
               <?php for($j=1; $j<=$usercount; $j++) { 
                 $tmp = $user[$j][0].'<br>'.$user[$j][1];
               ?>
                  <li class="arrow"><a href="useredit.php?num=<?php echo $j; ?>"><?php echo $tmp; ?></a></li>
               <?php } ?>
            <input type="hidden" name="tasknum" id="tasknum2">
            </ul>
            <a class="button slide" href="useredit.php?num=<?php echo $usercount+1; ?>">New user</a>
</div>