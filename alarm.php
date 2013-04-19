<?php
include("readvars.php");                         // common code to read variables from file STATUS.TXT 
?>

<div id="alarm" class="selectable">
<?php //  print_r($_POST);             // DIAGNOSTIC ?>
           <div class="toolbar">
             <h1>Alarm</h1>
             <a href="#" class="back">< Prev</a>
             <a href="doauto.php" class="button cube">Next ></a>
           </div>

          <form><ul class="edit rounded" style="margin-top: 5px; margin-bottom: 5px">
            <table border="0" style="width: 100%">
            <tr><td style="width: 20%"><h2 style="margin-left: 15px; margin-right: 10px">Status:</h2></td>
                <td><ul class="rounded" style="margin-bottom: 0px; margin-top: 0px; margin-left: 0px; margin-right: 0px">
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
                </li></ul></td><td>
                <a href="#" onclick="document.getElementById('retval').value='reset';
                                     ajaxrequest('alarm.php', 'alarm');"
                            class="greenButton" style="margin-bottom:5px; margin-top:5px; margin-left:15px; margin-right: 5px">
                Reset</a>        
                </td>
            </tr>
            <tr><td align="center"><h2 style="margin-left: 15px; margin-right: 10px">Mode:</h2></td>
            <td><ul class="rounded" style="margin-top: 0px; margin-bottom: 0px; margin-left: 0px; margin-right: 0px">
                <li class="arrow">
                  <select name="mode" id="modew" onchange="selectchange()">  // passing current value alows for canceling operation
                    <optgroup label="Select alarm mode:">
                      <option <?php if (strcasecmp("Full Set",rtrim($status[1]))==0) echo "selected=\"selected\""; ?>>Full Set</option>
                      <option <?php if (strcasecmp("Part Set",rtrim($status[1]))==0) echo "selected=\"selected\""; ?>>Part Set</option>
                      <option <?php if (strcasecmp("Standby",rtrim($status[1]))==0) echo "selected=\"selected\""; ?>>Standby</option>
                    </optgroup>
                  </select>
                </li>
            </ul></td>
            <td><a href="index.php#alarmactionsheet" class="action whiteButton"
                   style="margin-bottom: 5px; margin-top: 5px; margin-left: 15px; margin-right: 5px">
                   &nbspTest&nbsp
            </a></td>
            </tr></table></ul></form>

           <div class="scroll">
            <h2 style="margin-top: 0px">Zones:</h2>
            <ul class="rounded">
            
            <?php if ($zone[0][6]=="true") echo '<li class="arrow" style="background-color: #f00;">';
            else                           echo '<li class="arrow">'; ?>
            <a href="alarmcfg.php?num=1"><?php echo $zone[0][2];?> <small><?php echo $label[0]; ?></small></a></li>

            <?php if ($zone[1][6]=="true") echo '<li class="arrow" style="background-color: #f00;">';
            else                           echo '<li class="arrow">'; ?>
            <a href="alarmcfg.php?num=2"><?php echo $zone[1][2];?> <small><?php echo $label[1]; ?></small></a></li>

            <?php if ($zone[2][6]=="true") echo '<li class="arrow" style="background-color: #f00;">';
            else                           echo '<li class="arrow">'; ?>
            <a href="alarmcfg.php?num=3"><?php echo $zone[2][2];?> <small><?php echo $label[2]; ?></small></a></li>

            <?php if ($zone[3][6]=="true") echo '<li class="arrow" style="background-color: #f00;">';
            else                           echo '<li class="arrow">'; ?>
            <a href="alarmcfg.php?num=4"><?php echo $zone[3][2];?> <small><?php echo $label[3]; ?></small></a></li>

            <?php if ($zone[4][6]=="true") echo '<li class="arrow" style="background-color: #f00;">';
            else                           echo '<li class="arrow">'; ?>
            <a href="alarmcfg.php?num=5"><?php echo $zone[4][2];?> <small><?php echo $label[4]; ?></small></a></li>

            <?php if ($zone[5][6]=="true") echo '<li class="arrow" style="background-color: #f00;">';
            else                           echo '<li class="arrow">'; ?>
            <a href="alarmcfg.php?num=6"><?php echo $zone[5][2];?> <small><?php echo $label[5]; ?></small></a></li>

            <?php if ($zone[6][6]=="true") echo '<li class="arrow" style="background-color: #f00;">';
            else                           echo '<li class="arrow">'; ?>
            <a href="alarmcfg.php?num=7"><?php echo $zone[6][2];?> <small><?php echo $label[6]; ?></small></a></li>

            <?php if ($zone[7][6]=="true") echo '<li class="arrow" style="background-color: #f00;">';
            else                           echo '<li class="arrow">'; ?>
            <a href="alarmcfg.php?num=8"><?php echo $zone[7][2];?> <small><?php echo $label[7]; ?></small></a></li>
            </ul>
            <input type="hidden" name="retval" id ="retval" />
            <input type="hidden" id="modevaluebackup" value="<?php echo $status[1]; ?>" />
          </div>
</div>              <!-- Alarm screen             -->