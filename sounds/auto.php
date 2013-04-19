<!doctype html>
<html>
    <head>
        <meta charset="UTF-8" />
        <title>Alarm System</title>

<?  session_start();
    if (!empty($_POST['retval']))
     {  exec("rm -f /var/www/status.txt");                 // remove old data
        $tmp = $_SESSION['user'].":".$_SERVER['REMOTE_ADDR'].":remote control:".$_POST['retval'];
        $tmp=str_replace("true","on",$tmp);                // change 'true' to 'on'...
        $tmp=str_replace("false","off",$tmp);              // ...and change 'true' to 'on'
        exec("echo $tmp >>/var/www/input.txt");
     }

    $time = 3;                   //time in seconds to wait for the status.txt file to be created.
    $found = false;
    $filename = '/var/www/status.txt';
    for($i=0; $i<$time; $i++)
      { if (file_exists($filename))
          { // Falls through here if we have found it - so read the file ....
            $found = true;
            $file = fopen($filename,'r');
            while (!feof($file))
              { $data=fgets($file);
                  if (substr($data,0,22) == "Remote Control status:")    // skip down to the right section */
                    { for ($row=1; $row<=5; $row++)
                       { $data = fgets($file);
                         $data=substr($data, 16, -1);         // string from character 16, but skip the last
                                                              // character because its a white space. This 
                                                              // leaves us with either 'on' or 'off'
                         $RCs[$row]=$data;                    // store result
                       }
                    }
              }
          fclose ($file);
          break;
          }
        else
          { // Falls through here if no file found after specified period
            print " File not found.<br>";
            sleep(1);  // wait one second before continue looping
          }
      }
?>                             <!-- Load data from status.txt file -->

        <link rel="stylesheet" href="jQTouch/themes/css/jqtouch.css" title="jQTouch">
        <link rel="stylesheet" href="jQTouch/themes/css/apple.css" title="Apple">

        <!-- Either, (1) Zepto:  Un-comment these 2 lines (order matters)  -->
        <script src="jQTouch/lib/zepto/zepto.js" type="text/javascript" charset="utf-8"></script>
        <script src="jQTouch/src/jqtouch.js" type="text/javascript" charset="utf-8"></script>
        
        <!-- Or,     (2) jQuery: Un-comment these 3 lines (order matters)  -->
        <!-- <script src="../../lib/jquery/jquery-1.7.min.js" type="application/x-javascript" charset="utf-8"></script> -->
        <!-- <script src="../../src/jqtouch.js" type="text/javascript" charset="utf-8"></script> -->
        <!-- <script src="../../src/jqtouch-jquery.js" type="application/x-javascript" charset="utf-8"></script> -->

        <script src="jQTouch/extensions/jqt.themeswitcher.js" type="application/x-javascript" charset="utf-8"></script>
        <script src="jQTouch/extensions/jqt.actionsheet.js" type="application/x-javascript" charset="utf-8"></script>
        <script src="jQTouch/extensions/jqt.menusheet.js" type="application/x-javascript" charset="utf-8"></script>

        <script type="text/javascript" charset="utf-8">
            var jQT = new $.jQTouch({
                icon: 'jqtouch.png',
                icon4: 'jqtouch4.png',
                addGlossToIcon: false,
                startupScreen: 'jqt_startup.png',
                statusBar: 'black-translucent',
                themeSelectionSelector: '#jqt #themes ul',
                preloadImages: []
            });
          
            // Some sample Javascript functions:
            $(function(){

                // Show a swipe event on swipe test
                $('#swipeme').swipe(function(evt, data) {
                    var details = !data ? '': '<strong>' + data.direction + '/' + data.deltaX +':' + data.deltaY + '</strong>!';
                    $(this).html('You swiped ' + details );
                    $(this).parent().after('<li>swiped!</li>')
                });

                $('#tapme').tap(function(){
                    $(this).parent().after('<li>tapped!</li>')
                });

                $('a[target="_blank"]').bind('click', function() {
                    if (confirm('This link opens in a new window.')) {
                        return true;
                    } else {
                        return false;
                    }
                });

                // Page animation callback events
                $('#pageevents').
                    bind('pageAnimationStart', function(e, info){ 
                        $(this).find('.info').append('Started animating ' + info.direction + '&hellip;  And the link ' +
                            'had this custom data: ' + $(this).data('referrer').data('custom') + '<br>');
                    }).
                    bind('pageAnimationEnd', function(e, info){
                        $(this).find('.info').append('Finished animating ' + info.direction + '.<br><br>');

                    });
                
                // Page animations end with AJAX callback event, example 1 (load remote HTML only first time)
                $('#callback').bind('pageAnimationEnd', function(e, info){

                    // Make sure the data hasn't already been loaded (we'll set 'loaded' to true a couple lines further down)
                    if (!$(this).data('loaded')) {
                        
                        // Append a placeholder in case the remote HTML takes its sweet time making it back
                        // Then, overwrite the "Loading" placeholder text with the remote HTML
                        $(this).append($('<div>Loading</div>').load('ajax.html .info', function() {        
                            // Set the 'loaded' var to true so we know not to reload
                            // the HTML next time the #callback div animation ends
                            $(this).parent().data('loaded', true);  
                        }));
                    }
                });
                // Orientation callback event
                $('#jqt').bind('turn', function(e, data){
                    $('#orient').html('Orientation: ' + data.orientation);
                });
                
            });
        </script>
        <style type="text/css" media="screen">
            #jqt.fullscreen #home .info {
                display: none;
            }
            div#jqt #about {
                padding: 100px 10px 40px;
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
        </style>
    </head>

    <body>
        <form name="form1" method="post">
        <div id="jqt" class="">

            <div id="Automation" class="current">
                <div class="toolbar">
                    <h1>Automation</h1>
                    <a class="button slideup" id="infoButton" href="#about">About</a>
                </div>

                <div class="scroll">
<?php//               print_r($_POST); print'<br>';                    // list all posted variables
     //               for($i=1; $i<6; $i++)
     //                  { print 'RCs['.$i.']='.$RCs[$i].'<br>'; }    // list switch status        ?>      <!-- DIAGNOSTICS -->

                    <ul class="rounded">
                        <li>Kitchen lights<span class="toggle">
                            <input type="checkbox" <?php if ($RCs[1]=="on") { echo "checked"; }?> name="RC1"
                                   onclick="document.forms['form1'].retval.value='1:'+RC1.checked;
                                   this.form.submit();" /> }
                         </span></li>
                    </ul>

                    <ul class="rounded">
                        <li>Bedroom lights<span class="toggle">
                            <input type="checkbox" <?php if ($RCs[2]=="on") { echo "checked"; }?> name="RC2"
                                   onclick="document.forms['form1'].retval.value='2:'+RC2.checked;
                                   this.form.submit();" /> }
                         </span></li>
                    </ul>

                    <ul class="rounded">
                        <li>Standard lamp<span class="toggle">
                            <input type="checkbox" <?php if ($RCs[3]=="on") { echo "checked"; }?> name="RC3"
                                   onclick="document.forms['form1'].retval.value='3:'+RC3.checked;
                                   this.form.submit();" /> }
                         </span></li>
                    </ul>

                    <ul class="rounded">
                        <li>Kettle<span class="toggle">
                            <input type="checkbox" <?php if ($RCs[4]=="on") { echo "checked"; }?> name="RC4"
                                   onclick="document.forms['form1'].retval.value='4:'+RC4.checked;
                                   this.form.submit();" /> }
                         </span></li>
                    </ul>

                    <ul class="rounded">
                        <li>(Spare)<span class="toggle">
                            <input type="checkbox" <?php if ($RCs[5]=="on") { echo "checked"; }?> name="RC5"
                                   onclick="document.forms['form1'].retval.value='5:'+RC5.checked;
                                   this.form.submit();" /> }
                         </span></li>
                    </ul>

                    <ul class="rounded">
                        <li class="arrow"><a class="menu" href="#Menusheet">Menu</a></li>
                    </ul>

                    <ul class="rounded">
                        <li class="arrow"><a href="#themes">Themes <small class="counter">3</small></a></li>
                    </ul>

                    <input type="hidden" name="retval"/>
                </div>
            </div>  <!-- Automation screen       -->

            <div id="ChannelEdit">
                <div class="toolbar">
                    <h1>Edit channel</h1>
                    <a class="button slideup" id="infoButton" href="#about">About</a>
                </div>
                <ul class="edgetoedge scroll">
                    <li><a href="#" class="dismiss">Dummy entry</a></li>
                </ul>
                <ul class="rounded">
                    <li class="arrow"><a class="menu" href="#Menusheet">Menu</a></li>
                </ul>
            </div>                 <!-- Edit Automation details -->

            <div id="Schedule">
                <div class="toolbar">
                    <a class="button" href="#Menusheet">Menu</a>
                    <h1>Schedule</h1>
                    <a class="button slideup" id="infoButton" href="#about">About</a>
                </div>
                <ul class="edgetoedge scroll">
                    <li><a href="#" class="dismiss">Task #1</a></li>
                    <li><a href="#edge" class="dissolve">Task #2</a></li>
                    <li><a href="#" class="dismiss">Task #3</a></li>
                    <li><a href="#edge" class="dissolve">Task #4</a></li>
                    <li><a href="#" class="dismiss">Task #5</a></li>
                    <li><a href="#edge" class="dissolve">Task #6</a></li>
                </ul>
                <ul class="rounded">
                    <li class="arrow"><a class="menu" href="#Menusheet">Menu</a></li>
                </ul>
            </div>                    <!-- Schedule screen         -->

            <div id="Menusheet" class="menusheet">
                <ul class="edgetoedge scroll">
                    <li><a href="#" class="dismiss">Alarm System - Menu</a></li>
                    <li><a href="#Automation" class="dissolve">Automation</a></li>
                    <li><a href="#metal" class="dissolve">Alarm</a></li>
                    <li><a href="#Schedule" class="dissolve">Schedule</a></li>
                    <li><a href="#plastic" class="dissolve">Users</a></li>
                    <li><a href="#plastic" class="dissolve">Setup</a></li>
                     <li class="sep">Development</li>
                    <li><a href="#plastic" class="dissolve">Edit auto</a></li>
                </ul>
            </div> <!-- Menu screen             -->

            <div id="about" class="selectable">
                <p><img src="jqtouch.png" /></p>
                <p><strong>Home Alarm & Automation System</strong><br>Version 1.0<br><br>

                <p><em>Monitor your home,<br>
                       mess with your lights,<br>
                       wake up your neighbours,<br>
                       from hundreds of miles away.</em></p>

                <a target="_blank" href="http://www.oddwires.co.uk">© 2013 - ODDWIRES.CO.UK</a></p>

                <p><br><a href="#" class="grayButton goback">Close</a></p>
            </div>    <!-- About screen            -->

            <div id="themes">
                <div class="toolbar">
                    <h1>Themes</h1>
                    <a href="#" class="back">Back</a>
                </div>
                <ul class="rounded">
                </ul>
            </div>                      <!-- Themes screen           -->

            <div id="callbacks">
                <div class="toolbar">
                    <h1>Events</h1>
                    <a class="back" href="#home">Home</a>
                </div>
                <div class="scroll">
                    <ul class="rounded">
                        <li id="orient">Orientation: <strong>portrait</strong></li>
                        <li><a href="#pageevents" data-custom="WOOT!">Page events</a></li>
                        <li><a href="#" id="swipeme">Swipe me!</a></li>
                        <li><a href="#" id="tapme">Tap me!</a></li>
                    </ul>
                </div>
            </div>                   <!-- Screen orientation      -->

        </div>
      </form>
    </body>
</html>
