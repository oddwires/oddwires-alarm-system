<?php
include("readvars.php");                         // common code to read variables from file STATUS.TXT     
?>

<div id="status" class="selectable">
<?php // print_r($_POST);     // DIAGNOSTIC ?>
      <div class="toolbar">
       <h1>Status</h1>
       <a class="button flipleft" href="#Home">Logon</a></a>
      </div>
      <table border="0" style="width:100%; background-color:#555559;">
      <tr><td style="width:30%" colspan="2"><h2>Alarm:</h2></td>
      <td style="width: 40%"><ul class="rounded" style="margin-left:0px; margin-bottom: 0px; margin-top: 0px">
            <?php switch ($status[0])
                        { case "Set":
                             echo '<li>Set';
                             break;
                           case "Active !":
                             echo '<li style="background-color: #f00;">Active !';
                             break;
                           case "Timed out !":
                             echo '<li style="background-color: #f00;">Timed out !';
                             break;
                         } ?>
      </li></ul></td><td>&nbsp</td></tr>
      </table>

      <div class="scroll">
      <?php if ($triggeredzones) { ?>        <!-- only print the section if we have some triggered zones -->
      <h2>Triggered zones:</h2>
      <ul class="rounded"><?php for ($row=0; $row<=7; $row++)
                  { if($zone[$row][6]=='true') echo '<li>'.$zone[$row][2].'</li>'; } ?>
      </ul>
      <?php } ?>
      <h2>All zones current state:</h2>
      <table border="0" style="width:100%; background-color:#555559;">
        <?php for ($row=0; $row<=7; $row++) { ?>
        <tr><td style="width:95%"><h2><?php echo $zone[$row][2];?></h2></td>
             <?php if ($znstat[$row]) echo '<td style="width:95%;"><ul class="rounded" style="margin-left:0px; margin-top:0px; margin-bottom:0px;">
                                            <li style="margin-top:0px; margin-bottom:0px; background-color: #f00;">Open';
                   else               echo '<td style="width:95%;"><ul class="rounded" style="margin-left:0px; margin-top:0px; margin-bottom:0px;">
                                            <li style="margin-top:0px; margin-bottom:0px">Closed'; ?>
            </li></ul></td></tr>
        <?php } ?>
    </table>
    </div>