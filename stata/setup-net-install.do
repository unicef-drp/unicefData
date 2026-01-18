*! Setup script to install unicefData via net install
* This ensures proper installation with all dependencies

clear all
set more off

* Install from local repository or SSC
* Adjust the path as needed for your environment

* Option 1: Install from local folder (development)
* net install unicefdata, from("C:/GitHub/myados/unicefData/stata/src/u") all replace force

* Option 2: Install from SSC (production)
net install unicefdata, from(http://www.stata-journal.com/software/sj?-?/st?????) all replace force

* Verify installation
which unicefdata
help unicefdata
