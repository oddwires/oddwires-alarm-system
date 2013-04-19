<?php
include("readvars.php");             // common code to read variables from file STATUS.TXT
$number=$_GET['num'];                // parameter not posted to avoid race conditions with iphone interface.
$title = "Edit channel ".$number;
?>

<div id="autoconfig" class="selectable">
        <div class="toolbar">
           <h1><?php echo $title; ?></h1> 
           <a class="button cancel" href="#">Cancel</a>
        </div>
        <p>&nbsp</p>
        <ul class="rounded">
            <li><input type="text" id ="RCname"  value="<?php echo $RCc[$number]; ?>" /></li>
        </ul>
        <br>
        <table border="0" style="width:100%"> 
        <tr><td style="width:27%">&nbsp</td>    <!-- shove the button to the middle of the screen without getting into CSS -->
            <td><a href="#" onclick="sendstring();" class="whiteButton" style="width:45%">Save</a>
        </td></tr></table>
</div>

<script type="text/javascript">
    function sendstring() {
        var tmp = 'remote config:'+<?php echo $number; ?>+':';
        tmp = tmp + document.getElementById('RCname').value;
        document.getElementById('retval').value = tmp;
        ajaxrequest('doauto.php', 'auto');
        history.go(-1);
    }
</script>