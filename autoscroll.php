<?php
include("readvars.php");                         // common code to read variables from file STATUS.TXT 
?>

<!-- Scroller element of the Automation screen                               -->
<!-- kept separate to ensure AJAX updates load without breaking the scroller -->

      <div class="toolbar"><h1>Automation</h1>
         <a class="back menu" href="#menusheet">Menu</a>
      </div>
      <div id="AutoScroll" class="scroll">
      <!-- need to put a copy of autoscroll.php in here to handle the screen initialisation -->
         <table border="0" style="width:100%;">
         <?php for ($row=1; $row<=$RCnum; $row++) { ?>
          <tr><td style="width:95%"><ul class="rounded" style="width:100%; margin-left:0px; margin-top:0px; margin-bottom:0px;">
          <li><a href="#" onclick="AutoConfJmp(<?php echo $row; ?>)" id="hyplnk<?php echo $row; ?>"><?php echo $RCc[$row]; ?></a></li></ul></td>
          <td><ul class="rounded" style="margin-top:0px; margin-bottom:0px;"><li><span class="toggle">
              <input type="checkbox" name="RC<?php echo $row; ?>" id="RC<?php echo $row; ?>"
                <?php if($RCs[$row]=="on") { echo 'checked=\"checked\"'; } ?> onclick="AutoString('<?php echo $row; ?>', RC<?php echo $row; ?>.checked);" />
              </span></li></ul></td></tr>
         <?php } ?>
      </table></div>
