<?php
include("readvars.php");                         // common code to read variables from file STATUS.TXT     
?>

<div id="status" class="selectable">
      <div class="toolbar">
       <h1>Status</h1>
       <a class="button flipleft" href="#Home">Logon</a></a>
      </div>
      <table border="0" style="width:100%">
      <tr><td style="width:50%" colspan="2"><h2>Alarm mode:</h2></td>
      <td style="text-align:center">
      <ul class="rounded" style="margin-left:0px; margin-bottom: 0px; margin-top: 5px">
            <?php echo ($status[0] !='Set') ? '<li style="background:#f00;">' : '<li>' ?>
                   <?php echo $status[1]; ?></li></td><td style="width:5%">&nbsp</td></tr>
      </table>

      <?php if ($triggeredzones) { ?>        <!-- only print the section if we have some triggered zones -->
      <h2>Triggered zones:</h2>
      <ul class="rounded"><?php for ($row=0; $row<=7; $row++)
                  { if($zone[$row][6]=='true') echo '<li>'.$zone[$row][2].'</li>'; } ?>
      </ul>
      <?php } ?>

          <h2>Zones:</h2>
          <div class="scroll">
          <ul class="edgetoedge scroll" style="margin-top: 0">
            <?php for ($row=0; $row<$ZoneNum; $row++) { ?>
                     <li><?php echo $zone[$row][2];?><small class="counter"
                             <?php echo ($znstat[$row]) ? ' style="background: #f00;">Open' : '>Closed'; ?></small></li>
            <?php } ?></ul>
          </div>
    </div>