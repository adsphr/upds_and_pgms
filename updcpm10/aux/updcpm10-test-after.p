/* 
    updcpm10-test-after.p  

        validate walkin accoount cpm dates are set to 3/23/2026 

        if successful then
            restore original store number 
*/


for each cust no-lock 
    where cust.acct-nbr < 10 :
    
    disp cust with 1 col . 

    if cust.cpmPri = 3/23/2026 
        and cust.cpmPrc = 3/23/2026 then 
        message "cpm dates are correct for walkin account " skip 
            cust.acct-nbr skip 
            view-as alert-box .
    else
        message "cpm dates are NOT correct for walkin account " skip
            cust.acct-nbr skip 
            view-as alert-box .
end.

def var wk-log as logical no-undo . 

def var file-name as char format "x(255)" no-undo. 
file-name = "/usr/preserve/updcpm10-test.pos-parm.d" .  

message "Do you want to restore the original position parameter file?" 
    view-as alert-box question buttons yes-no update wk-log.

if wk-log then do:
    if search(file-name + ".original") <> ? then do:
        find last pos-parm . 
        delete pos-parm .
        input from value(file-name + ".original") .
        create pos-parm .
        import pos-parm .
        input close .   
        disp pos-parm with 1 col frame aaa title "Position Parameter Restored" no-error.
        update pos-parm.cost-center with frame aaa .

        message "Original file restored." view-as alert-box.
    end.
    else
        message "Original file not found. Manual intervention needed to restore the file." view-as alert-box.
end.
else
    message "Original file not restored. Remember to restore it before running any other tests." view-as alert-box.

