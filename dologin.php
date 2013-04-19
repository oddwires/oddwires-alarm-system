<?php
$loginisvalid=FALSE;
$username=$_POST['username'];
$password=$_POST['password'];
$logstring="";

$file1 = fopen("/var/www/user.txt",'r');
while (!feof($file1))
{     $data = fgets($file1);
      if ($data<>"")                                              // skips any blank lines
       {   $tmp=(explode(':',$data));
           if (($_POST['username'] == $tmp[0]) and ($_POST['password'] == $tmp[1]))
            {  
//             $_SESSION['login']='1';                            // wer-hay ! - we're in !!
               setcookie('loggedin', 'true', time()+3600, '/');   // or maybe use a cookie ?
               setcookie('username', $tmp[0], time()+3600, '/');
//               setcookie('userip', $_SERVER['REMOTE_ADDR'], time()+3600, '/');
               setcookie('userip', '127.0.0.1', time()+3600, '/');
               $loginisvalid=TRUE;
//             $_SESSION['user']=$tmp[0];
            }
          else
           {   $logstring=$logstring.$tmp[0].' - '.$tmp[1].'<br>'; }
       }
  
}
fclose($file1);

if($loginisvalid){
//$tmp = $_SESSION['user'].":".$_SERVER['REMOTE_ADDR'].":logon";
$tmp = $tmp[0].":".$_SERVER['REMOTE_ADDR'].":logon";
header('Location: /alarm.php#alarm');  // go to next screen on the existing subnet

}else{
      //$tmp = $_POST['username'].":".$_SERVER['REMOTE_ADDR'].":failed logon";
      $tmp = $tmp[0].":".$_SERVER['REMOTE_ADDR'].":failed logon";
      echo '
      <div>
      <div class="toolbar">
         <h1>Logon error !</h1>
         <a href="#" class="back">Back</a>
      </div><br>
      <div class="info">
         Username or Password incorrect.<br>
         Your computers IP address is ';
         echo $_SERVER['REMOTE_ADDR'].'<br></div><br>';
         echo '<div class="info">
         Your attempt to access this system<br>
         and your IP address have been logged.<br></div>
       </div>
       ';   
      }
    exec("echo $tmp >>/var/www/input.txt");
?>
