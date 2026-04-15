def new shared    stream      log.
def               stream      s1.

def new shared    var         update-name    as  char  init "UPDCPM"         no-undo.
def               var         prog-name      as  char                        no-undo init "cpm.p".

def               var         fatal-error    as  log   init false            no-undo.
def               var         msg1           as  char  format "x(80)"        no-undo.
def               var         msg2           as  char  format "x(80)"        no-undo.
def               var         start-tm       as  int                         no-undo.
def               var         x              as  int                         no-undo.
def               var         returned-val   as  char                        no-undo.
def               var         upd-nm         as  char init "update/after/"   no-undo.


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
    " Update:" update-name    skip
    msg1                     skip
    msg2
with color yelblk width 80 no-labels no-box.


pause 0 before-hide.
status input off.
output stream log to swstore.lg append unbuffered.
abort1:
repeat on error undo abort1, retry abort1:
   abort2:
   repeat on error undo abort2, retry abort2:
      if fatal-error
      then do:
         put stream log update-name ": ERROR 1 occured during after.p" skip.
         output to update/ERROR.
         put "Error occured during after.p - ERR 1" skip.
         output close.
         quit.
      end.
      assign fatal-error = true.

     put stream log update-name ":Start   update/after.p" space(8)
                    today space(1)
                    string(time, "HH:MM:SS")
                    skip.

      repeat x = 1 to num-entries(prog-name):

         assign start-tm = time
                msg1 = "  Start:" + " " + string(today, "99/99/99") + " " + string(start-tm, "HH:MM:SS am")
                msg1 = msg1 + fill(" ", 80 - length(msg1))
                msg2 = "Calling: " + upd-nm + string(entry(x, prog-name)).

         hide all no-pause.
         display update-name msg1 msg2 with frame main-f1.

         compile value(upd-nm + string(entry(x,prog-name))) no-error.

         if compiler:error
         then do:
            output stream log close.
            output to update/ERROR.
            put update-name "COMPILE ERROR:" + upd-nm + string(entry(x, prog-name)) format "x(80)" skip.
            output close.
            quit.
         end.

         put stream log update-name ":Calling " + upd-nm + string(entry(x, prog-name)) format "x(30)" space(1)
                     today space(1)
                     string(time, "HH:MM:SS")
                     skip.

         run reset-return.

         run value(upd-nm + string(entry(x,prog-name))).

         returned-val = return-value.
 
         put stream log update-name ":Return  " + upd-nm + string(entry(x, prog-name)) format "x(30)" space(1)
                     today space(1)
                     string(time, "HH:MM:SS")
                     space(1)
                     "Return:" return-value
                     skip.

         if returned-val <> "OK"
         then do:
            output stream log close.
            output to update/ERROR.
            put update-name "ERROR:" + upd-nm + string(entry(x, prog-name)) + " Return " + return-value format "x(80)" skip.
            output close.
            quit.
         end.
      end. /*repeat*/

      put stream log update-name ":End     update/after.p" space(8)
                    today space(1)
                    string(time, "HH:MM:SS")
                    skip.

      output stream log close.
      unix silent rm -fr update/ERROR.
      quit.

   end. /* abort2 */
end. /* abort1 */
put stream log update-name ": ERROR 2 occured during after.p" skip.
output stream log close.
output to update/ERROR.
put update-name "ERROR: Progress reached a point after the repeats in after.p"
    skip.
output close.
quit.

PROCEDURE reset-return:
   return.
END PROCEDURE.
