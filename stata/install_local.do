*! install_local.do - Install unicefdata package from local repository
*! Version 1.0.0 - December 2025
*!
*! Usage: 
*!   1. Clone the repository: git clone https://github.com/unicef-drp/unicefData.git
*!   2. Open Stata and cd to the stata directory
*!   3. Run: do install_local.do
*!
*! This script copies all package files to your PLUS ado directory.

version 14.0
clear all

* Get the PLUS directory path
local plusdir : sysdir PLUS
di as text "Installing unicefdata to: " as result "`plusdir'"

* Create subdirectories if they don't exist
capture mkdir "`plusdir'u"
capture mkdir "`plusdir'_"
capture mkdir "`plusdir'y"
capture mkdir "`plusdir'py"

* Determine source directory (current directory should be stata/)
local srcdir "`c(pwd)'/src"
capture confirm file "`srcdir'/u/unicefdata.ado"
if _rc {
    di as err "Error: Cannot find source files."
    di as err "Please cd to the stata/ directory of the unicefData repository first."
    di as err ""
    di as err "Example:"
    di as err "  cd C:\GitHub\unicefData\stata"
    di as err "  do install_local.do"
    exit 601
}

di as text ""
di as text "Source directory: " as result "`srcdir'"
di as text ""

* Copy main command files (u/)
di as text "Copying main commands..."
local ufiles : dir "`srcdir'/u" files "*.ado"
foreach f of local ufiles {
    copy "`srcdir'/u/`f'" "`plusdir'u/`f'", replace
    di as text "  + `f'"
}
local uhelp : dir "`srcdir'/u" files "*.sthlp"
foreach f of local uhelp {
    copy "`srcdir'/u/`f'" "`plusdir'u/`f'", replace
    di as text "  + `f'"
}

* Copy helper programs (_/)
di as text "Copying helper programs..."
local _files : dir "`srcdir'/_" files "*.ado"
foreach f of local _files {
    copy "`srcdir'/_/`f'" "`plusdir'_/`f'", replace
    di as text "  + `f'"
}

* Copy YAML metadata files (_/)
di as text "Copying metadata files..."
local yamlfiles : dir "`srcdir'/_" files "*.yaml"
foreach f of local yamlfiles {
    copy "`srcdir'/_/`f'" "`plusdir'_/`f'", replace
    di as text "  + `f'"
}

* Copy yaml command (y/)
di as text "Copying yaml command..."
local yfiles : dir "`srcdir'/y" files "*"
foreach f of local yfiles {
    copy "`srcdir'/y/`f'" "`plusdir'y/`f'", replace
    di as text "  + `f'"
}

* Copy Python helper scripts (py/) - optional
di as text "Copying Python helpers..."
capture confirm file "`srcdir'/py/unicefdata_xml2yaml.py"
if !_rc {
    local pyfiles : dir "`srcdir'/py" files "*.py"
    foreach f of local pyfiles {
        copy "`srcdir'/py/`f'" "`plusdir'py/`f'", replace
        di as text "  + `f'"
    }
}

* Clear cached programs to load fresh versions
discard

* Verify installation
di as text ""
di as text "{hline 60}"
di as result "Installation complete!"
di as text "{hline 60}"
di as text ""

* Check if unicefdata is found
capture which unicefdata
if !_rc {
    di as text "unicefdata installed at: " as result "`r(fn)'"
} 
else {
    di as err "Warning: unicefdata not found in adopath"
}

di as text ""
di as text "To get started, try:"
di as text "  {cmd:help unicefdata}"
di as text "  {cmd:unicefdata, categories}"
di as text "  {cmd:unicefdata, search(mortality)}"
di as text ""
