
/* 
    updcpm10-test-before.p  
        change store number to 701015 
*/

def var file-name as char format "x(255)" no-undo. 
file-name = "/usr/preserve/updcpm10-test.pos-parm.d" .

unix silent value("cp " + file-name  + " " + file-name  + ".bkuplast.$(date '+%Y%m%d%H%M%S') 2>/dev/null").

message " before test " skip 
    "this program will update the pos-parm file to set store number to 701015 " skip
    "so that you can test CPM10 with this store. " skip
    "after running this, you can run updcpm10-test-after.p to restore the original file. " skip
    view-as alert-box .

output to value(file-name) .

find last pos-parm .
export pos-parm . 

output close .

/* don't clobber original file */
if search(file-name + ".original" ) = ? then 
    unix silent value("cp " + file-name  + " " + file-name  + ".original").

disp pos-parm with 1 col frame aaa title "Position Parameter" no-error.
pause 1 . 

pos-parm.cost-center = "701015" .

disp pos-parm with frame aaa title "Position Parameter" no-error.

message "pos-parm file updated with store number 701015 for CPM10 test. " skip 
    "Remember to restore the original file after the test by running updcpm10-test-after.p" skip
    view-as alert-box .

