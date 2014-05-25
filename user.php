<?php
include("readvars.php");                         // common code to read variables from file STATUS.TXT    
?>

<div id="userlist" class="selectable">
    <div class="toolbar">
         <h1>Users</h1>
         <a class="back menu" href="#menusheet">Menu</a>
         <a class="button slide" href="#" onclick="UserConf(<?php echo $usercount+1; ?>)">New</a>
    </div>
    <ul class="edgetoedge scroll">
         <?php for($j=1; $j<=$usercount; $j++) { 
              $tmp = $user[$j][0].'<br>'.$user[$j][1];
         ?>
         <li class="arrow"><a href="#" onclick="UserConf(<?php echo $j; ?>)"><?php echo $tmp; ?></a></li>
              <?php } ?>
    </ul>

<!-- Make all user data available on the page just in case we want to drill down and start editing -->
    <?php for ($row=1; $row<=$usercount; $row++) { ?>
         <input type="hidden" id="user_<?php echo $row; ?>" value="<?php echo $user[$row][0]; ?>">
         <input type="hidden" id="email_<?php echo $row; ?>" value="<?php echo $user[$row][1]; ?>">
    <?php } ?>
</div>