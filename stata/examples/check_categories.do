version 17.0
capture log close
cd "c:\GitHub\others\unicefData\stata"
cap mkdir "outputs"
log using "outputs/categories.log", replace text
unicefdata, categories
log close
exit, clear
