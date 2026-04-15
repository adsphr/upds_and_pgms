
/* 
    updcpm10-test-before.p  
        change store number to 701015 
*/
def var wk-store like pos-parm.cost-center no-undo.
def var wk-upd-name as char format "x(15)" no-undo.

wk-store = "701001" .
wk-upd-name = "updcpm11" .

def var file-name as char format "x(255)" no-undo. 
file-name = "/usr/preserve/" + wk-upd-name + ".pos-parm.d" .

unix silent value("cp " + file-name  + " " + file-name  + ".bkuplast.$(date '+%Y%m%d%H%M%S') 2>/dev/null").

message " before test " skip 
    "this program will update the pos-parm file to set store number to " + wk-store + " " skip
    "so that you can test " + wk-upd-name + " with this POS. " skip
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

pos-parm.cost-center = wk-store .

disp pos-parm with frame aaa title "Position Parameter" no-error.

for each cust where cust.acct-nbr < 10 :
    assign 
        cust.cpmprc = 12/31/2029 
        cust.cpmpri = 12/31/2029 .
    dist cust with 1 col title "turn cust 1-9 off of cpm pricing for test" no-error.
end.

message "pos-parm file updated with store number " + wk-store + " for " + wk-upd-name + " test. " skip 
    "Remember to restore the original file after the test by running " + wk-upd-name + "-after.p" skip
    view-as alert-box .
