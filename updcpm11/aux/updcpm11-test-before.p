
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

message 
    "Setting store number to " + wk-store + " so " + wk-upd-name + " can be tested . "
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

message 
    "Resetting accounts 1-9 to non CPM pricing. "
    view-as alert-box .

for each cust where cust.acct-nbr < 10 :
    assign 
        cust.cpmprc = 12/31/2029 
        cust.cpmpri = 12/31/2029 .
    disp cust with 5 col title "turn cust 1-9 off of cpm pricing for test" no-error.
end.

message "Set up complete. " skip(2)
    "After " + wk-upd-name + " is applied run  " + wk-upd-name + "-after.p to confirm success. " skip
    view-as alert-box .
