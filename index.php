<?php
Header("Cache-Control: no-transform");

if (isset($_POST['retval']))                             // Test Action Sheet posts commands back here
{     exec("rm -f /var/www/status.txt");                 // remove old data
      $tmp = $_COOKIE['username'].":".$_SERVER['REMOTE_ADDR'].":".$_POST['retval'];
      exec("echo $tmp >>/var/www/input.txt");            // Pass data to the BASH shell script
}
?>
<!-- <!DOCTYPE html> -->
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html lang="en">
    <head>
        <meta charset="utf-8" />
        <meta http-equiv="Cache-Control" content="no-transform" />
        <meta name="apple-mobile-web-app-capable" content="yes" /> 
        <title>Logon page</title>
        <!-- put the stylesheets first - otherwise the Action Sheets won't scroll -->
        <link rel="stylesheet" href="jQTouch/themes/css/jqtouch.css" title="jQTouch">
        <link rel="stylesheet" href="jQTouch/themes/css/apple.css" title="Apple">


<!--    <script src="jQTouch/lib/zepto/zepto.js" type="text/javascript" charset="utf-8"></script> -->
<!--    <script src="jQTouch/src/jqtouch.js" type="text/javascript" charset="utf-8"></script> -->


        <script src="//ajax.googleapis.com/ajax/libs/jquery/1.9.1/jquery.min.js"></script>
<!--    <script type="text/javascript"> google.load("jquery", "1.3.2"); </script> -->
<!--    <script src="jQTouch/lib/jquery/jquery-1.7.min.js" type="application/x-javascript" charset="utf-8"></script> -->
        <script src="jQTouch/src/jqtouch.js" type="text/javascript" charset="utf-8"></script>
        <script src="jQTouch/src/jqtouch-jquery.js" type="application/x-javascript" charset="utf-8"></script>

        <script src="jQTouch/extensions/jqt.themeswitcher.js" type="application/x-javascript" charset="utf-8"></script>
        <script src="jQTouch/extensions/jqt.actionsheet.js" type="application/x-javascript" charset="utf-8"></script>

        <script type="text/javascript" charset="utf-8">
            var jQT = new $.jQTouch({
                cacheGetRequests: false,
                //                icon: 'jqtouch.png',
                //                icon4: 'jqtouch4.png',
                addGlossToIcon: false,
                useFastTouch: true,
                //                startupScreen: 'jqt_startup.png',
                statusBar: 'black-translucent',
                themeSelectionSelector: '#jqt #themes ul',
                preloadImages: []
            });
            //////
            var userAgent = navigator.userAgent.toLowerCase();
            var isiPhone = (userAgent.indexOf('iphone') != -1 || userAgent.indexOf('ipod') != -1) ? true : false;
            clickEvent = isiPhone ? 'tap' : 'click';
            //////
            // Populate the retval field
            function CreateString(parm1) {
                document.getElementById('retval').value = "";  // flush any old data
                //                alert(parm1);
                switch (parm1) {
                    case '1true':
                        document.getElementById('retval').value = "remote control:1:on"; break;
                    case '1false':
                        document.getElementById('retval').value = "remote control:1:off"; break;
                    case '2true':
                        document.getElementById('retval').value = "remote control:2:on"; break;
                    case '2false':
                        document.getElementById('retval').value = "remote control:2:off"; break;
                    case '3true':
                        document.getElementById('retval').value = "remote control:3:on"; break;
                    case '3false':
                        document.getElementById('retval').value = "remote control:3:off"; break;
                    case '4true':
                        document.getElementById('retval').value = "remote control:4:on"; break;
                    case '4false':
                        document.getElementById('retval').value = "remote control:4:off"; break;
                    case '5true':
                        document.getElementById('retval').value = "remote control:5:on"; break;
                    case '5false':
                        document.getElementById('retval').value = "remote control:5:off"; break;
                    default:
                        document.getElementById('retval').value = "";
                }
            }
            // create the XMLHttpRequest object, according to browser
            function get_XmlHttp() {
                // create the variable that will contain the instance of the XMLHttpRequest object (initially with null value)
                var xmlHttp = null;
                if (window.XMLHttpRequest) {     // for Firefox, IE7+, Opera, Safari, ...
                    xmlHttp = new XMLHttpRequest();
                }
                else if (window.ActiveXObject) {  // for Internet Explorer 5 or 6 
                    xmlHttp = new ActiveXObject("Microsoft.XMLHTTP");
                }
                return xmlHttp;
            }
            // sends data to a php file, via POST, and displays the received answer in DIV=tagID
            function ajaxrequest(php_file, tagID) {
                var request = null;
                request = get_XmlHttp();       // call the function for the XMLHttpRequest instance
                // create pairs index=value with data that must be sent to server
                var the_data = 'retval=' + document.getElementById('retval').value;
                request.open("POST", php_file, true);           // set the request
                // adds  a header to tell the PHP script to recognize the data as is sent via POST
                request.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
                request.setRequestHeader("X-Requested-With", "XMLHttpRequest");                // TEST
                request.setRequestHeader("pragma", "no-cache");                                // TEST
                request.send(the_data);     // calls the send() method with datas as parameter
                // Check request status
                // If the response is received completely, will be transferred to the HTML tag with tagID
                request.onreadystatechange = function () {
                    if (request.readyState == 4) {
                        document.getElementById(tagID).innerHTML = request.responseText;
                    }
                }
            }
            function selectchange() {
                // by the time we get here, the value has already changed, so it is too late to cancel.
                // But by hiding the previous value on the page, we can still go back.
                var f = document.getElementsByName('mode')[0];               // get first element called 'name'
                $str = "Confirm change mode to " + f.options[f.selectedIndex].value;
                var r = confirm($str);
                if (r == true) {
                    document.getElementById('retval').value = 'mode:' + f.options[f.selectedIndex].value;
                    ajaxrequest('alarm.php', 'alarm');
                }
                else {
                    var tmp2 = document.getElementById('modevaluebackup').value.toLowerCase();
                    tmp2 = tmp2.replace(/(^[\s]+|[\s]+$)/g, '');  //removeEventListener white space
                    if (tmp2 == 'full set') { document.getElementsByName('mode')[0].selectedIndex = 0; }
                    if (tmp2 == 'part set') { document.getElementsByName('mode')[0].selectedIndex = 1; }
                    if (tmp2 == 'standby') { document.getElementsByName('mode')[0].selectedIndex = 2; }
                    // only way I can clear the scroller from the iphone is to submit the stoopid form !
                    document.getElementById('retval').value = 'mode:'+tmp2;  // so set up the old data....
                    ajaxrequest('alarm.php', 'alarm');                       // ...and send it.
                }
            }
           </script>

        <style type="text/css" media="screen">
            #jqt.fullscreen #home .info {
                display: none;
            }
            div#jqt #about {
                padding: 0px 10px 40px;
                text-shadow: rgba(0, 0, 0, 0.3) 0px -1px 0;
                color: #999;
                font-size: 13px;
                text-align: center;
                background: #161618;
            }
            div#jqt #about p {
                margin-bottom: 8px;
            }
            div#jqt #about a {
                color: #fff;
                font-weight: bold;
                text-decoration: none;
            }
        </style>                                     <!-- Additional CSS for the about screen -->

    </head>

    <body>
    <div id="jqt" class="">

        <div id="about" class="selectable">
            <div class="toolbar">
               <h1>About</h1>
            <a class="back" href="#Home">Back</a>
            <a id="someId" class="button slide listButton" href="#Home">(tbd)</a>

            </div>
            <div class="scroll">
<!--             <p><img src="jqtouch.png" /></p> -->
            <p>&nbsp</p>
            <p>&nbsp</p>
            <p>&nbsp</p>
            <p>&nbsp</p>
            <p><strong>Home Alarm & Automation System</strong><br>Version 1.0<br><br>

            <p><em>Monitor your home,<br>
                   mess with your lights,<br>
                   ring your alarm bells<br>
                   and wake up your neighbours.<br><br>
                   All from hundreds of miles away.</em></p>
                <a target="_blank" href="http://www.oddwires.co.uk">© 2013 - ODDWIRES.CO.UK</a></p>
            <p>&nbsp</p>
            <p>&nbsp</p>
            <p>&nbsp</p>
            <p>&nbsp</p>
            <p>&nbsp</p>
            <p>&nbsp</p>
            <p>&nbsp</p>
          </div>
        </div>              <!-- About screen             -->
        <div id="Home" class="current">
            <form id="login" action="dologin.php" method="POST" class="form">
            <div class="toolbar">
               <h1>Logon</h1>
                <a class="button flipright" href="dostatus.php">Status</a></a>
            </div>
            <ul class="rounded">
                <li><input type="text" name="username" placeholder="Username"/></li>
                <li><input type="password" name="password" placeholder="Password"/></li>
            </ul>
             <table border="0" style="width: 100%">
             <tr><td style="width: 30%">&nbsp</td>
                 <td style="width: 30%">
            <a style="color:rgba(0,0,0,.9)" href="#" class="submit whiteButton">Submit</a>
                 </td><td>&nbsp</td></tr></table>
            <br />
            <div class="info">
            This is a monitored system.<br>
            Do not attempt to log on<br>
            unless authorised to do so.
            </div>
            </form>
        </div>                  <!-- Logon screen             -->
        <div id="alarm" class="selectable">
           <!-- Where's my code        ???       -->
           <div class="toolbar">
             <h1>Yikes !</h1>
             <a href="#" class="back">Back</a>
             <a class="button slide" href="alarm.php">Next</a>
           </div>
           <!-- look in the alarm.php file      -->
        </div>              <!-- Alarm screen             -->
        <div id="alarmactionsheet" class="actionsheet">
                <div class="actionchoices">
                    <a href="#" class="dismiss whiteButton" id="buttn01">External siren</a>
                    <a href="#" class="dismiss whiteButton" id="buttn02">External strobe</a>
                    <a href="#" class="dismiss whiteButton" id="buttn03">Internal sounder</a>
                    <a href="#" class="redButton dismiss">Cancel</a>
                </div>
            </div>
        <div id="auto" class="selectable">
           <!-- Where's my code        ???       -->
             <div class="toolbar">
             <h1>Yikes !</h1>
             <a href="#" class="back">Back</a>
         </div>
           <!-- look in the doauto.php file      -->
        </div>               <!-- Control screen           -->
        <div id="status" class="selectable">
            <!-- Where's my code        ???       -->
             <div class="toolbar">
             <h1>Yikes !</h1>
          <a class="button flipleft" href="#Home">Logon</a></a>
         </div>
           <!-- look in the dostatus.php file      -->
            </div>             <!-- list of zone status -->
        <div id="userlist" class="selectable">
            <!-- Where's my code        ???       -->
             <div class="toolbar">
             <h1>Yikes !</h1>
             <a href="#" class="back">Back</a>
         </div>
           <!-- look in the userlist.php file      -->
        </div>           <!-- User list screen         -->
        <div id="setup" class="selectable">
        <!-- Where's my code        ???       -->
             <div class="toolbar">
             <h1>Yikes !</h1>
             <a href="#" class="back">Back</a>
         </div>
           <!-- look in the setup.php file      -->
        </div>              <!-- Application setup screen -->
        <div id="setupactionsheet" class="actionsheet">
                <div class="actionchoices">
                    <a href="#" class="dismiss greenButton" id="buttn04">Load user defaults</a>
                    <a href="#" class="dismiss greenButton" id="buttn05">Save user defaults</a>
                    <a href="#" class="dismiss blueButton" id="buttn06">Load factory defaults</a>
                    <a href="#" class="redButton dismiss">Cancel</a>
                </div>
            </div>
        <div id="action_performed">
                <div class="toolbar">
                    <h1>Action</h1>
                    <a class="back" href="#">Back</a>
                </div>
        </div>

     </div>

     <script type="text/javascript">
         // Difference between PC and iPhone interface mean that assigning an 'onclick' event to a button won't work on an iphone.
         // Instead we need to grab the 'ontap' event....
         $('#buttn01').bind(clickEvent, function (e) {
         //alert('Yay! You just ' + clickEvent + 'ed me!');
             document.getElementById('retval').value = 'test bell';
             ajaxrequest('index.php', ''); });
         $('#buttn02').bind(clickEvent, function (e) {
             document.getElementById('retval').value = 'test strobe';
             ajaxrequest('index.php', ''); });
         $('#buttn03').bind(clickEvent, function (e) {
             document.getElementById('retval').value = 'test sounder';
             ajaxrequest('index.php', ''); });
         $('#buttn04').bind(clickEvent, function (e) {
             document.getElementById('retval').value = 'load user defaults';
             ajaxrequest('setup.php', 'setup'); });
         $('#buttn05').bind(clickEvent, function (e) {
             document.getElementById('retval').value = 'save user defaults';
             ajaxrequest('setup.php', 'setup'); });
         $('#buttn06').bind(clickEvent, function (e) {
             document.getElementById('retval').value = 'load factory defaults';
             ajaxrequest('setup.php', 'setup'); });
      </script>
    </body>
</html>
