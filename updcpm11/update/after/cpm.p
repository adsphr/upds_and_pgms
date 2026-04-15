def    shared    stream      log.
def               stream      s1.

def    shared    var         update-name    as  char                                               no-undo.
def               var         fatal-error    as  log   init false                                   no-undo.
def               var         msg1           as  char  format "x(80)"                               no-undo.
def               var         msg2           as  char  format "x(80)"                               no-undo.
def               var         start-tm       as  int                                                no-undo.
def               var         prog-name      as  char format "x(22)" init "update/after/cpm.p"  no-undo.
def var this-store as c no-undo.
def stream instream.

def temp-table store-list
    field cost-center as c
    field cpm-active as da
    index cpmix is unique
	cost-center.

def frame main-f1
    skip(2)
    "DO NOT TURN OFF THE POS COMPUTER" at 24
    skip(2)
    "PLEASE WAIT" at 34
    skip(1)
    "CONTACT THE STORE COMPUTER OPERATIONS HELP DESK AT" at 15
    skip(1)
    "(216) 566-2740" at 33
    skip(1)
    "WITH ANY PROBLEMS OR QUESTIONS" at 25
    skip(7)
    " Update:" update-name
    msg1 skip
    msg2
with color yelblk width 80 no-labels no-box.


pause 0 before-hide.
status input off.
abort1:
repeat on error undo abort1, retry abort1:
   abort2:
   repeat on error undo abort2, retry abort2:
      if fatal-error
      then do:
         put stream log update-name ": ERROR 1 occured during "  prog-name skip.
         output to update/ERROR.
         put "Error occured during " + prog-name + " - ERR 1" skip.
         output close.
         return "ERROR".
      end.
      assign fatal-error = true.

      put stream log update-name ":Start   "  prog-name
                    today space(1)
                    string(time, "HH:MM:SS")
                    skip.

      do for pos-parm:
	 find last pos-parm where pos-parm.p-eff-dt <= today
	    no-lock no-error.
	 if avail pos-parm
	 then this-store = pos-parm.cost-center.
	 else this-store = "999999".
      end.

      input stream instream from update/cpmdates.csv no-echo.
      repeat:
	 create store-list.
	 import stream instream delimiter ","
		store-list.cost-center
		store-list.cpm-active.
      end.
      input stream instream close.

      output stream instream to /usr/preserve/cust.cpm.dates.
      for each cust where cust.acct-nbr < 10 or cust.acct-nbr > 10000000:
	 if cust.cpmPriceAssignDate = ? or cust.cpmPriceAssignDate > today
	 then do:
	    if cust.acct-nbr < 10
	    then find store-list
		    where store-list.cost-center = this-store
		    no-lock no-error.
	    else find store-list
		    where store-list.cost-center = cust.par-store-ccn
		    no-lock no-error.
	    if avail store-list
	    then do:
	        if store-list.cpm-active <> ?
	        then do:
	           export stream instream 
			  cust.acct-nbr
			  cust.par-store-ccn
			  cust.cpmPriceAssignDate
			  cust.cpmPrcMaintDate.
	           assign cust.cpmPrcMaintDate = store-list.cpm-active
		          cust.cpmPriceAssignDate = store-list.cpm-active.
	       end. // store-list.cpm-active <> ?
	    end. // avail store-list
	 end. // current cpm dates in the future
      end. // for each cust
      output stream instream close.

      put stream log update-name ":End     "  prog-name
                  today space(1)
                  string(time, "HH:MM:SS")
                  skip.


      return "OK".

   end. /* abort2 */
end. /* abort1 */
put stream log update-name ": ERROR 2 occured during "  prog-name skip.
output to update/ERROR.
put "ERROR: Progress reached a point after the repeats in " + prog-name
    skip.
output close.
return "ERROR".
