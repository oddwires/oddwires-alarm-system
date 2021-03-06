<?php
include("readvars.php");                         // common code to read variables from file STATUS.TXT 
?>

<div id="alarm" class="selectable">
    <div class="toolbar"><h1>Alarm</h1>
        <a class="back menu" href="#menusheet">Menu</a>
    </div>
    <!-- Alarm status panel is contained in a table -->
        <table border="0" style="margin: 0px auto; align: center">
        <tr><td style="width: 15%;">
               <div class="RoundButton" style="font-size: 25px">
                   <a href="#set" class="action" style="text-decoration: none">Set</a>
               </div></td>
            <td><ul class="rounded" style="margin-bottom: 0px; margin-top: 0px; margin-left: 0px; margin-right: 0px; text-align: center">
                    <?php if ($status[0]=="Set") echo '<li>'.$status[1].'</li>';
                          else                   echo '<li style="background-color: #f00;">'.$status[1].'</li>';  ?>
            </ul></td>
            <td style="width: 15%">
               <div class="RoundButton" style="font-size: 25px">
                   <a href="#test" class="action" style="text-decoration: none">Test</a>
            </div></td>
        </tr></table>

    <div id="alarmscroll" class="scroll">
        <h2 style="margin-top: 0px">Zones:</h2>
        <ul class="rounded">
        <?php for ($row=0; $row<=7; $row++) { ?>
            <li class="arrow" <?php echo ($zone[$row][6]=="true") ? 'style="background-color: #f00;">' : '>'; ?>
                <a href="#" onclick="AlarmConfJmp(<?php echo $row; ?>)" id="AlrmHlnk<?php echo $row; ?>">
                     <?php echo $zone[$row][2];?> <small><?php echo $label[$row]; ?></small></a>
            </li>
        <?php } ?>
    </div>

    <!-- Make all zone configuration data available on the page just in case we want to drill down and start
     editing the zone configurations                                                                        -->
        <?php for ($row=0; $row<=7; $row++) { ?>
           <input type="hidden" id="ZoneType<?php echo $row; ?>" value="<?php echo $zone[$row][1]; ?>">
           <input type="hidden" id="ZoneName<?php echo $row; ?>" value="<?php echo $zone[$row][2]; ?>">
           <input type="hidden" id="ZoneChim<?php echo $row; ?>" value="<?php echo $zone[$row][3]; ?>">
           <input type="hidden" id="ZoneFset<?php echo $row; ?>" value="<?php echo $zone[$row][4]; ?>">
           <input type="hidden" id="ZonePset<?php echo $row; ?>" value="<?php echo $zone[$row][5]; ?>">
           <input type="hidden" id="ZoneTrig<?php echo $row; ?>" value="<?php echo $zone[$row][6]; ?>">
        <?php } ?>
    </div>

<!--
<div id="set" class="actionsheet">
    <div class="actionchoices">
           <a href="#" class="dismiss whiteButton" onclick="AlarmMode('mode:Day mode')">Day mode</a>
           <a href="#" class="dismiss whiteButton" onclick="AlarmMode('mode:Night mode')">Night mode</a>
           <a href="#" class="dismiss whiteButton" onclick="AlarmMode('mode:Standby')">Standby</a>
           <a href="#" class="dismiss greenButton" onclick="AlarmMode('reset')">Reset</a>
           <a href="#" class="redButton dismiss">Cancel</a>
    </div>
</div> -->

<!--
<div id="test" class="actionsheet">
    <div class="actionchoices">
           <a href="#" class="dismiss whiteButton" onclick="AlarmMode('test bell')">External siren</a>
           <a href="#" class="dismiss whiteButton" onclick="AlarmMode('test strobe')">External strobe</a>
           <a href="#" class="dismiss whiteButton" onclick="AlarmMode('test sounder')">Internal sounder</a>
           <a href="#" class="redButton dismiss">Cancel</a>
    </div>
</div> -->

<!-- Alarm zone configuration sub menu -->
<div id="alarmconfig" class="selectable">
      <div class="toolbar"><h1 id="AlarmConfHead">tbd</h1>
          <a class="back slideright" onclick="AlarmCfgSend()" href="#alarm">Back</a>
      </div>

      <div class="scroll">
         <h2>Name:</h2>
         <ul class="rounded">
            <li><input type="text" id="AlarmConfName" placeholder="Zone name" value="tbd"/></li>
         </ul>
         <h2>Settings:</h2>
           <ul class="rounded">
               <li><table border="0" width="100%">
                     <tr><td style="width: 50%">
                             <input type="radio" name="ZoneMode" id="AlarmZone" value="alarm" onclick="showHide('alarm');" />&nbsp&nbspAlarm</td>
                         <td><input type="radio" name="ZoneMode" id="TamperZone" value="tamper" onclick="showHide('tamper');" />&nbsp&nbspTamper</td></tr>
               </table></li>
 
         <!-- Create a hideable div -->
         <div id="alarmOptions">
            <li>Day mode<span class="toggle">
                <input type="checkbox" name="FS" id="ZoneFS" ></span></li>
            <li>Night mode<span class="toggle">
                <input type="checkbox" name="PS" id="ZonePS"></span></li>
            <li>Chimes<span class="toggle">
                <input type="checkbox" name="chimes" id="ZoneCH"></span></li>
         </div>
        </ul>
      </div>