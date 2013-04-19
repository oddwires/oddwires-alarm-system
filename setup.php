<?php
include("readvars.php");                         // common code to read variables from file STATUS.TXT    
?>

       <div id="setup" class="selectable">
<?php //  print_r($_POST);             // DIAGNOSTIC ?>
      <div class="toolbar">
       <h1>Setup</h1>
       <a href="#" class="back">< Prev</a>
       <a href="alarm.php" class="button cube">Next ></a>
<!--       <a class="button slideup" href="#about">About</a> -->
      </div>

      <div class="scroll">
<!--      <form class="scroll"> -->
           <h2>Application</h2>
           <ul class="rounded">
              <li><input type="text" name="location" placeholder="Location name" id="location" value="<?php echo $location; ?>"/></li>
              <li class="arrow"><select id="period" name="period">
                 <optgroup label="Alarm duration">
                 <option <?php if (strcasecmp("15m",rtrim($duration))==0) echo "selected=\"selected\""; ?>value ="15m">15 minutes</option>
                 <option <?php if (strcasecmp("9m",rtrim($duration))==0) echo "selected=\"selected\""; ?>value ="9m">9 minutes</option>
                 <option <?php if (strcasecmp("5s",rtrim($duration))==0) echo "selected=\"selected\""; ?>value ="5s">5 seconds (test)</option>
                 </optgroup>
               </select></li>
           </ul>
           <h2>Email</h2>
           <ul class="rounded">
              <li><table border="0" style="width:100%"><tr><td style="width:65%">
                  <input type="email" name="server" placeholder="Server name" id="server" value="<?php echo $EMAIL_server; ?>" />
              </td><td>
                  <input type="text" name="port" placeholder="Server port" id="port" value="<?php echo $EMAIL_port; ?>"/>
              </td></tr></table></li>
              <li><input type="email" name="email" placeholder="Send account" id="email" value="<?php echo $EMAIL_sender; ?>"/></li>
              <li><input type="password" name="password" placeholder="Send account password" id="password" value="dummy123" /></li> <!-- use dummy password -->
           </ul>
           <table border="0" style="width:100%">
               <tr><td style="width: 50%"><a href="#" onclick="buildstring()" class="whiteButton"  style="width: 60%">Save</a></td>
               <td><a class="action whiteButton" href="index.php#setupactionsheet" style="width: 60%">Defaults</a></td></tr>
           </table>
<!--      </form> -->
      </div>
    </div>

<script type="text/javascript">
    // Difference between PC and iPhone interface mean that assigning an 'onclick' event to a button won't work on an iphone.
    // Instead we need to grab the 'ontap' event....
    function buildstring() {
        // Historically the two sections have been stored seperately,so need to do two write operations
        var $tmp = 'app setup:' + document.getElementById('location').value;
        var f = document.getElementsByName('period')[0];
        $tmp = $tmp + ':' + f.options[f.selectedIndex].value;
        document.getElementById('retval').value = $tmp;
        ajaxrequest('setup.php', '');
        $tmp = 'email setup:' + document.getElementById('server').value;
        $tmp = $tmp + ':' + document.getElementById('port').value;
        $tmp = $tmp + ':' + document.getElementById('email').value;
        $tmp = $tmp + ':' + document.getElementById('password').value;
        document.getElementById('retval').value = $tmp;
        ajaxrequest('setup.php', '');
    }
</script>