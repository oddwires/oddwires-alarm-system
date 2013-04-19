<?php  
// Date in the past
header("Expires: Mon, 26 Jul 1997 05:00:00 GMT");
header("Cache-Control: no-cache");
header("Pragma: no-cache");

$number=$_GET['num'];                // parameter not posted to avoid race conditions with iphone interface.
$loggedin=(isset($_COOKIE['loggedin']) && $_COOKIE['loggedin']=='true')?true:false;
?>

<div id="pwdeditdiv">
       <div class="toolbar">
          <h1>Set password</h1> 
          <a href="logon.php#taskdiv" class="back">Back</a>
       </div>
       <p>&nbsp</p>
         <ul class="rounded">
             <li><input type="password" id="pwd1" placeholder="New password:" /></li>
             <li><input type="password" id="pwd2" placeholder="Confirm password:" /></li>
         </ul>
         <a href="#" onclick="validate(<?php echo $number; ?>)" class="whiteButton" style="width: 25%; margin-left: 37%">Save</a>

<!-- New users can be created by just edditing the next available number ($usercount+1) so I should be able           -->
<!-- to remove the 'add usr' command from the BASH shell script.                                                      -->
      
</div>

<script type="text/javascript">
    function validate($parm1) {
        var $tmp1 = document.getElementById('pwd1').value;
        var $tmp2 = document.getElementById('pwd2').value;

        if ($tmp1 != $tmp2) {
            $str = "The passwords do not match.\nPlease try again.";
            var r = alert($str);
            document.getElementById('pwd1').value = '';
            document.getElementById('pwd2').value = '';
        }
        else {
            $str = "Password changed.";
            alert($str);
            document.getElementById('retval').value = 'set pw:' + $parm1 + ':' + $tmp1;
            ajaxrequest('useredit.php', ''); // send it
            history.go(-2);
        }
    }
</script>
