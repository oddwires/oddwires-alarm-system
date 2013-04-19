<?php  
include("readvars.php");             // common code to read variables from file STATUS.TXT    

$number=$_GET['num'];                // parameter not posted to avoid race conditions with iphone interface.
$title = "Edit account ".$number;

if ($number > $usercount) {          // falls through here if we are creating a new account
$user[$number][0]='';                  // so need to initialise default values...
$user[$number][1]=''; }
?>

<div id="usereditdiv">
       <div class="toolbar">
          <h1><?php echo $title; ?></h1> 
          <a href="logon.php#taskdiv" class="back">Back</a>
<!--          <a class="button slideup" href="logon.php#about">About</a> -->
       </div>
       <p>&nbsp</p>
         <form class="scroll">
         <ul class="rounded">
<!-- Here's a clever bit....                                                                                          -->
<!-- If we are editing an existing user, 'value' will contain data, so overwrite the default 'placeholder'            -->
<!-- But if we are adding a new user, 'value' will be blank, so the default 'placeholder' will be displayed.          -->
             <li><input type="text" name="name" placeholder="Username:" id="username" value="<?php echo $user[$number][0]; ?>" /></li>
             <li><input type="text" name="email" placeholder="Email:" id="useremail" value="<?php echo $user[$number][1]; ?>" /></li>
         </ul>
         <div align="center">
         <table border="0">
             <tr><td><a href="#" onclick="tmp='edt usr:'+
                                   <?php echo $number; ?>+':'+
                                   document.getElementById('username').value+':'+
                                   document.getElementById('useremail').value;
                                   document.getElementById('retval').value = tmp;
                                   ajaxrequest('userlist.php','userlist');
                                   history.go(-1);"
                        class="whiteButton" style="width: 50%; margin-right: 0px">Save</a></td>
             <td><a href="#" onclick="tmp='del usr:'+
                                   <?php echo $number; ?>;
                                   document.getElementById('retval').value = tmp;
                                   ajaxrequest('userlist.php','userlist');
                                   history.go(-1);" class="redButton" style="width: 50%">Delete</a>
             </td><td><a href="pwdedit.php?num=<?php echo $number; ?>" class="whiteButton" style="width: 50%; margin-left: 0px">Pwd</a>
             </td></tr>
         </table>
         </div>
<!-- New users can be created by just edditing the next available number ($usercount+1) so I should be able           -->
<!-- to remove the 'add usr' command from the BASH shell script.                                                      -->

       </form>
       <input type='hidden' name="retval" id="retval" />
</div>
