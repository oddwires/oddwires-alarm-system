///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
// Log functions...
//
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// logs.php hyperlinks redirect here...
function LogSelect(date) {
    $('#LogsHead').text("Log " + date);
    var tmp = 'logscroll.php?date=' + date;
    ajaxrequest(tmp,'LogScroll');                                     // syncronous send
    jQT.goTo('#logview', 'slideleft');
}

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
// User functions...
//
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// userlist.php hyperlinks redirect here
function UserConf(number) {
    $('#UserConfHead').text("Edit user " + (number));                 // update the title
    $('#UserName').val($('#user_' + (number)).val());                 // scrape user name and pass to config screen
    $('#UserEmail').val($('#email_' + (number)).val());               // scrape email details and pass to config screen
    jQT.goTo('#useredit', 'slideleft');                               // ...and go to task edit screen
    return false;                                                     // returning false cancels the original hyperlink
}

// User has changed, so populate the retval field...
function UserSend() {
    var tmp = 'edt usr:';
    tmp += ($('#UserConfHead').text().substring(10)) + ':';           // retrieve the user number from the header
    tmp += $('#UserName').val() + ':';                                // scrape user name and pass to config screen
    tmp += $('#UserEmail').val();                                     // scrape email details and pass to config screen
    console.log(tmp);
    $('#retval').val(tmp);
    ajaxrequest('userlist.php','userlist');                            // syncronous send
    return false;
}
function UserDel() {
    var tmp = 'del usr:';
    tmp += ($('#UserConfHead').text().substring(10)) + ':';            // retrieve the user number from the header
    console.log(tmp);
    $('#retval').val(tmp);
    ajaxrequest('userlist.php','userlist');                            // syncronous send
    jQT.goTo('#userlist', 'slideright');                               // ...and go to user list screen
}
function Password() {
      var $tmp1 = $('#Pwd1').val();
      var $tmp2 = $('#Pwd2').val();
      if ($tmp1 != $tmp2) {
             alert("The passwords do not match.\nPlease try again.");
             $('#Pwd1').val() = '';
             $('#Pwd2').val() = '';
             return false;
        }
        else {
            tmp = 'set pw:';
            tmp += ($('#UserConfHead').text().substring(10)) + ':';    // retrieve the user number from the header
            tmp += $tmp1;
            $('#retval').val(tmp);
            ajaxrequest('userlist.php','userlist');
            jQT.goTo('#useredit', 'slideright');                       // ...and go to user edit screen
        }    
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
// Alarm functions...
//
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

            // alarm.php hyperlinks redirect here, so we can get a lot jiggy with the titles and parameters
            function AlarmConfJmp(number) {
                $('#AlarmConfHead').text("Edit zone " + (number + 1));            // update the title
                $('#AlarmConfName').val($('#ZoneName' + (number)).val());         // scrape zone name and pass to config screen
                if ($('#ZoneType' + number).val() == "alarm") {
                    $('#AlarmZone').prop('checked', true);                        // set radio button values alarm/tamper
                    $('#TamperZone').prop('checked', false);
                    $('#alarmOptions').show();                                    // show alarm options
                } else {
                    $('#AlarmZone').prop('checked', false);
                    $('#TamperZone').prop('checked', true);
                    $('#alarmOptions').hide();                                    // hide alarm options
                }
                if ($('#ZoneFset' + number).val() == "on") {
                    $('#ZoneFS').prop('checked', true);                           // Full set switch
                } else {
                    $('#ZoneFS').prop('checked', false);
                }
                if ($('#ZonePset' + number).val() == "on") {
                    $('#ZonePS').prop('checked', true);                           // Part set switch
                } else {
                    $('#ZonePS').prop('checked', false);
                }
                if ($('#ZoneChim' + number).val() == "on") {
                    $('#ZoneCH').prop('checked', true);                           // Chimes switch
                } else {
                    $('#ZoneCH').prop('checked', false);
                }
                jQT.goTo('#alarmconfig', 'slideleft')                             // ...and go to config screen
                return false;                                                     // returning false cancels the original hyperlink
            }
            function AlarmCfgSend() {
                   var tmp = 'zone config:';
                   tmp += $('#AlarmConfHead').text().substring(10) + ':';         // retrieve the zone number from the header
                   tmp +=  $('input[name=ZoneMode]:checked').val() + ':';
                   tmp += $('#AlarmConfName').val() + ':';
                   if ($('#ZoneCH').is(":checked")) { tmp += "on:" }              // add chimes config
                   else { tmp += "off:"; }
                   if ($('#ZoneFS').is(":checked")) { tmp += "on:" }              // add day mode config
                   else { tmp += "off:"; }
                   if ($('#ZonePS').is(":checked")) { tmp += "on" }               // add night mode config
                   else { tmp += "off"; }
                   console.log(tmp);
                   $('#retval').val(tmp);
                   ajaxrequest('alarmscroll.php','alarm');                         // syncronous send
                   return false;
            }
            // changing the zone alarm/tamper setting redirects here
            function showHide(zonetype) {
                if (zonetype == "alarm") {
                    $('#alarmOptions').show(500);
                } else {
                    $('#alarmOptions').hide(500);
                }
            }
            function AlarmMode(NewMode) {
                $('#retval').val(NewMode);
                   ajaxrequest('alarmscroll.php','alarm');                          // syncronous send
            }

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
// Automation functions...
//
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

            // RC On/Off switch has changed, so populate the retval field...
            function AutoString(channel, status) {
                tmp = "remote control:" + channel + ":"
                if (status) { tmp = tmp + "on"; } else { tmp = tmp + "off"; }
                $('#retval').val(tmp);
                ajaxrequest('writedata.php','');                                  // doesn't matter where we send the data as long as
                                                                                  // it goes through 'readvars' to make it go
            }
            // RC channel name has changed, so populate the retval field...
            function AutoCfgSend(number) {
                var tmp = 'remote config:';
                tmp += $('#AutoConfHead').text().substring(13) + ':';             // retrieve the channel number from the header
                tmp += $('#AutoConfVal').val();
                $('#retval').val(tmp);
                ajaxrequest('autoscroll.php','auto');                             // syncronous send
                return false;
            }

            // auto.php hyperlinks redirect here, so we can get a bit jiggy with the titles and parameters
            function AutoConfJmp(number) {
                $('#AutoConfHead').text("Edit channel " + number);                // update the title
                $('#AutoConfVal').val($('#hyplnk' + number).text());              // scrape current channel name and pass to config screen
                $('#retval').val(number);                                         // pass channel number to config screen
                jQT.goTo('#autocfg', 'slideleft')                                 // ...and go to config screen
                return false;                                                     // returning false cancels the original hyperlink
            }

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
// Task functions...
//
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

            // task.php hyperlinks redirect here
            function taskedit(tasknum) {
                var weekday = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
                var month = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
                $('#TaskConfHead').text("Edit task " + (tasknum + 1));            // update the title
                $('#edt_hours').text($('#hours_' + (tasknum)).val());             // scrape values and pass to config screen
                $('#edt_minutes').text($('#minutes_' + (tasknum)).val());
                $('#edt_dom').text($('#dom_' + (tasknum)).val());

                var tmp = $('#month_' + (tasknum)).val();
                $('#edt_month').val(tmp);                                         // store numeric in hidden field
                if (tmp == "*") { $('#edt_month_str').text("*"); }                 // any (*)
                else { $('#edt_month_str').text(month[tmp - 1]); }                 // expand month

                tmp = $('#weekday_' + (tasknum)).val();
                $('#edt_wday').val(tmp);                                          // store numeric in hidden field
                if (tmp == "*") { $('#edt_wday_str').text("*"); }                  // any (*)
                else { $('#edt_wday_str').text(weekday[tmp]); }                    // expand weekday

                tmp = $('#tasknum_' + (tasknum)).val();
                $('#edt_task').val(tmp);                                          // store numeric in hidden field
                $('#edt_task_str').text($('#taskname_' + (tasknum)).val());
                jQT.goTo('#taskedit', 'slideleft');                               // ...and go to task edit screen
                return false;                                                     // returning false cancels the original hyperlink
            }
            function newtask() {
                var tasknum = $('#taskcount').val();
                $('#edt_hours').text("*");                                        // set default values
                $('#hours_' + (tasknum)).val("*");                                // set default values
                $('#edt_minutes').text("*");
                $('#minutes_' + (tasknum)).val("*");                              // set default values
                $('#edt_dom').text("*");
                $('#dom_' + (tasknum)).val("*");                                  // set default values
                $('#edt_month').text("*");
                $('#month_' + (tasknum)).val("*");                                // set default values
                $('#edt_wday').text("*");
                $('#weekday_' + (tasknum)).val("*");                              // set default values
                $('#edt_task').text("tbd");
                $('#taskname_' + (tasknum)).val("*");                             // set default
                tasknum++;
                $('#TaskConfHead').text("Edit task " + (tasknum));                // update the title
                $('#taskcount').val(tasknum);
                jQT.goTo('#taskedit', 'slideleft');                               // ...and go to task edit screen
                return false;                                                     // returning false cancels the original hyperlink
            }
            // Task has changed, so populate the retval field and send it...
            function TaskSend() {
                var tasknum = ($('#TaskConfHead').text().substring(10)-1);        // retrieve the task number from the header
                // create data string to send to alarm service...
                var tmp = 'edit task:'+ (tasknum+1) + ':';
                tmp += ($('#minutes_' + (tasknum)).val()) + ':';
                tmp += ($('#hours_' + (tasknum)).val()) + ':';
                tmp += ($('#dom_' + (tasknum)).val()) + ':';
                tmp += ($('#month_' + (tasknum)).val()) + ':';
                tmp += ($('#weekday_' + (tasknum)).val()) + ':';
                tmp += ($('#tasknum_' + (tasknum)).val());
                console.log(tmp);
                $('#retval').val(tmp);
                ajaxrequest('taskscroll.php','taskscroll');                         // syncronous send
//                jQT.goTo('#tasklist', 'slideright');
//                return false;
            }
            function TaskDel() {
                var tasknum = ($('#TaskConfHead').text().substring(10)-1);        // retrieve the task number from the header
                var tmp = 'delete task:' + (tasknum+1);
                $('#retval').val(tmp);
                ajaxrequest('taskscroll.php','tasklist');                         // syncronous send
                jQT.goTo('#tasklist', 'slideright');                              // ...and go to task edit screen
            }

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
// Numpad functions...
//
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

            function numpadinit(title) {
                // creates a multi purpose numeric keypad...
                switch (title) {
                    case "Select hours":
                        $('#numval').val($('#edt_hours').text());
                        break;
                    case "Select minutes":
                        $('#numval').val($('#edt_minutes').text());
                        break;
                    case "Select date":
                        $('#numval').val($('#edt_dom').text());
                        break;
                    case "Select month":
                        $('#numval').val($('#edt_month').text());
                        break;
                }
                $('#NumPadHead').text(title);
                jQT.goTo('#numpad', 'slideleft');                                     // ...and go to task edit screen
                return false;                                                         // returning false cancels the original hyperlink
            }
            function numpadret() {
                // returns value from numeric keypad
                var tasknum = ($('#TaskConfHead').text().substring(10)-1);           // retrieve the task number from the header
                var taskprop = ($('#NumPadHead').text());                            // retrieve the task property from the header
                switch (taskprop){
                    case "Select hours":
                        $('#edt_hours').text($('#numval').val());
                        $('#hours_' + (tasknum)).val($('#numval').val());            // update hidden table
                        break;
                    case "Select minutes":
                        $('#edt_minutes').text($('#numval').val());
                        $('#minutes_' + (tasknum)).val($('#numval').val());          // update hidden table
                        break;
                    case "Select date":
                        $('#edt_dom').text($('#numval').val());
                        $('#dom_' + (tasknum)).val($('#numval').val());              // update hidden table
                        break;
                }
            }
            function stringret(type,value,string) {
                // returns string values from days, months and tasks
                var tasknum = ($('#TaskConfHead').text().substring(10)-1);        // retrieve the task number from the header
                switch (type) {
                    case "month":
                        $('#edt_month').val(value);                               // update hidden numeric
                        $('#month_' + (tasknum)).val(value);                      // update hidden table
                        $('#edt_month_str').text(string);                         // update visible string
                        break;
                    case "weekday":
                        $('#edt_wday').val(value);                                // update hidden numeric
                        $('#weekday_' + (tasknum)).val(value);                    // update hidden table
                        $('#edt_wday_str').text(string);                          // update visible string
                        break;
                    case "task":
                        $('#edt_task').val(value);                                // update hidden numeric
                        $('#tasknum_' + (tasknum)).val(value);                    // update hidden table
                        $('#edt_task_str').text(string);                          // update visible string
                        break;
                }
                jQT.goTo('#taskedit', 'slideright');
            }
            function numpadupdate(newval) {
                // updates the numpad screen each time a button is pressed
                if (newval == "*") {
                    tmp = "*";
                } else {
                    tmp = $('#numval').val();                                          // current val
                    if (tmp == "*") { tmp = 0; }
                    tmp = tmp % 10;                                                    // shuffle left
                    tmp += newval;
                }
                $('#numval').val(tmp);
            }

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
// Setup functions...
//
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

            // setup.php alarm period hyperlinks redirect here
            function SetupAppSend() {
               var tmp = "app setup:";
               tmp += $('#location').val() + ":";
               tmp += $('#durtxt').text();
               $('#retval').val(tmp);
               $('#SetupLoc').val($('#location').val());                         // push the new values back up a level
               $('#SetupDur').val($('#durtxt').text());
               ajaxrequest('writedata.php','');                                  // doesn't matter where we send the data as long as
                                                                                 // it goes through 'readvars' to make it go
               return false;                                                     // returning false cancels the original hyperlink
            }

            function SetupEmailSend() {
               var tmp = "email setup:";
               tmp += $('#SMTP_server').val() + ":";
               tmp += $('#SMTP_port').val() + ":";
               tmp += $('#email_account').val() + ":";
               tmp += $('#email_pwd').val();
               $('#retval').val(tmp);
               $('#SetupEserv').val($('#SMTP_server').val());                    // push the new values back up a level
               $('#SetupEport').val($('#SMTP_port').val());
               $('#SetupEsend').val($('#email_account').val());
               $('#SetupEpass').val($('#email_pwd').val());
               ajaxrequest('writedata.php','');                                  // doesn't matter where we send the data as long as
                                                                                 // it goes through 'readvars' to make it go
               return false;                                                     // returning false cancels the original hyperlink
            }

            function SetupAppInit () {
                 $('#location').val($('#SetupLoc').val());                       // Ensure all data fields are current
                 $('#durtxt').text($('#SetupDur').val());
            }

            function SetupEmailInit () {
                 $('#SMTP_server').val($('#SetupEserv').val());                  // Ensure all data fields are current
                 $('#SMTP_port').val($('#SetupEport').val());
                 $('#email_account').val($('#SetupEsend').val());
                 $('#email_pwd').val($('#SetupEpass').val());
            }

            function Defaults(parm1) {
                $('#retval').val(parm1);
                ajaxrequest('setupscroll.php','setup');                           // this needs to be syncronous - we need all the new 
                                                                                  // config data to be transferred to the web page
                jQT.goTo('#setup', 'slideright');                                 // ...and go to task edit screen
                return false;                                                     // returning false cancels the original hyperlink
            }

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
// Other functions...
//
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

            // sends data to a php file, via POST, and displays the received answer in DIV=tagID
            function ajaxrequest(php_file, tagID) {
                var request = null;
                request = get_XmlHttp();
                var the_data = 'retval=' + $('#retval').val();
                request.open("POST", php_file, true);
                request.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
                request.setRequestHeader("X-Requested-With", "XMLHttpRequest");                // TEST
                request.setRequestHeader("pragma", "no-cache");                                // TEST
                request.send(the_data);
                request.onreadystatechange = function () {
                    if (request.readyState == 4 && tagID != '') {
                        // only update the screen if we have specified the div - this allows asyncronous sends.
                        $("#" + tagID).html(request.responseText);
                    }
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
            function getCookie(cname) {
                   var name = cname + "=";
                   var ca = document.cookie.split(';');
                   for (var i = 0; i < ca.length; i++) {
                      var c = ca[i].trim();
                      if (c.indexOf(name) == 0) return c.substring(name.length, c.length);
                   }
                   return "";
            }

            function passval2(parm1,parm2) {
                $('#'+parm1).text(parm2)
                jQT.goTo('#setup', 'slideright');                                 // ...and go to task edit screen
                return false;                                                     // returning false cancels the original hyperlink
            }
