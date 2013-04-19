<?php
include("readvars.php");                         // common code to read variables from file STATUS.TXT
$number=$_GET['num']-1;                // parameter not posted to avoid race conditions with iphone interface.
$title = "Edit Zone ".$_GET['num'];
?>

<div id="alarmeditdiv">
       <div class="toolbar">
          <h1><?php echo $title; ?></h1> 
          <a href="logon.php#taskdiv" class="back">Back</a>
<!--          <a class="button slideup" href="logon.php#about">About</a> -->
       </div>

     <div class="scroll">
           <h2>Name:</h2>
           <ul class="rounded">
              <li><input type="text" name="name" placeholder="Zone name" id="name" value="<?php echo $zone[$number][2]; ?>"/></li>
           </ul>
           <h2>Settings:</h2>
           <ul class="rounded">
               <li><table border="0" width="100%">
                     <tr><td style="width: 50%"><input type="radio" id="type" name="type" value="alarm" 
                       <?php if($zone[$number][1]=="alarm") { echo 'checked=\checked\"'; } ?> onclick="showHide('alarm');" />&nbsp&nbspAlarm</td>
                       <td><input type="radio" id="type" name="type" value="tamper" 
                       <?php if($zone[$number][1]=="tamper") { echo 'checked=\checked\"'; } ?> onclick="showHide('tamper');" />&nbsp&nbspTamper</td></tr>
                </table></li>
 
         <!-- Create a hideable div, and show/hide it depending on existing value -->
         <div id="alarmOptions" <?php if($zone[$number][1]=="alarm") { echo 'style="display:block"'; }
                                                                else { echo 'style="display:none"'; } ?> >
         <li>Full set<span class="toggle">
           <input type="checkbox" name="FS" id="FS" <?php if($zone[$number][4]=="on")
                                                              { echo 'checked=\"checked\"'; } ?> ></span></li>
         <li>Part set<span class="toggle">
           <input type="checkbox" name="PS" id="PS" <?php if($zone[$number][5]=="on")
                                                              { echo 'checked=\"checked\"'; } ?> ></span></li>
         <li>Chimes<span class="toggle">
            <input type="checkbox" name="chimes" id="chimes" <?php if($zone[$number][3]=="on")
                                                              { echo 'checked=\"checked\"'; } ?> value="on"></span></li>
        </div>
        </ul>
        <table border="0" style="width:100%"> 
        <tr><td style="width:27%">&nbsp</td>    <!-- shove the button to the middle of the screen without getting into CSS -->
            <td><a href="#" onclick="sendstring();" class="whiteButton" style="width:45%">Save</a>
        </td></tr></table>
        </div>
</div>

<script type="text/javascript">
    function showHide(zonetype) {
        if (zonetype == "alarm") { document.getElementById("alarmOptions").style.display = "block"; }
        else { document.getElementById("alarmOptions").style.display = "none"; }
    }

    function sendstring() {
        var tmp1 = 'zone config:'+<?php echo $number+1; ?>;
        var tmp2 = document.getElementsByName('type')[0].checked? 'alarm' : 'tamper';
        tmp1 = tmp1 + ':' + tmp2;
        tmp1 = tmp1 + ':' + document.getElementById('name').value;
        tmp2 = document.getElementsByName('chimes')[0].checked? 'on' : 'off';
        tmp1 = tmp1 + ':' + tmp2;
        tmp2 = document.getElementsByName('FS')[0].checked? 'on' : 'off';
        tmp1 = tmp1 + ':' + tmp2;
        tmp2 = document.getElementsByName('PS')[0].checked? 'on' : 'off';
        tmp1 = tmp1 + ':' + tmp2;
        document.getElementById('retval').value = tmp1;
        ajaxrequest('alarm.php', 'alarm');
//      jQT.goTo('#alarm')                  // goes to the right place - but doesn't give the smooth scroll
        history.go(-1);
    }
</script>
