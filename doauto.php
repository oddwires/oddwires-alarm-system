<?php
include("readvars.php");                         // common code to read variables from file STATUS.TXT     
?>

<div id="auto">
<?php // print_r($_POST);     // DIAGNOSTIC ?>
      <div class="toolbar">
       <h1>Remote control</h1>
       <a href="#" class="back">< Prev</a>
       <a href="tasklist.php" class="button cube">Next ></a>
      </div>

    <table border="0" style="width:100%; background-color:#555559;">
        <tr><td style="width:95%" colspan="2">&nbsp</td></tr>
        <tr><td style="width:95%"><ul class="rounded" style="width:100%; margin-left:0px; margin-top:0px; margin-bottom:0px;">
                <li><a href="autocfg.php?num=1"><?php echo $RCc[1]; ?></a></li></ul></td>
            <td><ul class="rounded" style="margin-top:0px; margin-bottom:0px;">
                <li><span class="toggle"><input type="checkbox" 
                    name="RC1" id="RC1" <?php if($RCs[1]=="on") { echo 'checked=\"checked\"'; } ?>
                          onclick="CreateString('1'+RC1.checked); ajaxrequest('doauto.php', 'auto');" />
        </span></li></ul></td></tr>

        <tr><td><ul class="rounded" style="width:100%; margin-left:0px; margin-top:0px; margin-bottom:0px;">
                <li><a href="autocfg.php?num=2"><?php echo $RCc[2]; ?></a></li></ul></td>
            <td><ul class="rounded" style="margin-top:0px; margin-bottom:0px;">
                <li><span class="toggle"><input type="checkbox" 
                    name="RC2" id="RC2" <?php if($RCs[2]=="on") { echo 'checked=\"checked\"'; } ?>
                          onclick="CreateString('2'+RC2.checked); ajaxrequest('doauto.php', 'auto');" />
        </span></li></ul></td></tr>

        <tr><td><ul class="rounded" style="width:100%; margin-left:0px; margin-top:0px; margin-bottom:0px;">
                <li><a href="autocfg.php?num=3"><?php echo $RCc[3]; ?></a></li></ul></td>
            <td><ul class="rounded" style="margin-top:0px; margin-bottom:0px;">
                <li><span class="toggle"><input type="checkbox" 
                    name="RC3" id="RC3" <?php if($RCs[3]=="on") { echo 'checked=\"checked\"'; } ?>
                          onclick="CreateString('3'+RC3.checked); ajaxrequest('doauto.php', 'auto');" />
        </span></li></ul></td></tr>

        <tr><td><ul class="rounded" style="width:100%; margin-left:0px; margin-top:0px; margin-bottom:0px;">
                <li><a href="autocfg.php?num=4"><?php echo $RCc[4]; ?></a></li></ul></td>
            <td><ul class="rounded" style="margin-top:0px; margin-bottom:0px;">
                <li><span class="toggle"><input type="checkbox" 
                    name="RC4" id="RC4" <?php if($RCs[4]=="on") { echo 'checked=\"checked\"'; } ?>
                          onclick="CreateString('4'+RC4.checked); ajaxrequest('doauto.php', 'auto');" />
        </span></li></ul></td></tr>

        <tr><td><ul class="rounded" style="width:100%; margin-left:0px; margin-top:0px; margin-bottom:0px;">
                <li><a href="autocfg.php?num=5"><?php echo $RCc[5]; ?></a></li></ul></td>
            <td><ul class="rounded" style="margin-top:0px; margin-bottom:0px;">
                <li><span class="toggle"><input type="checkbox" 
                    name="RC5" id="RC5" <?php if($RCs[5]=="on") { echo 'checked=\"checked\"'; } ?>
                          onclick="CreateString('5'+RC5.checked); ajaxrequest('doauto.php', 'auto');" />
        </span></li></ul></td></tr>
    </table>
    </div>
