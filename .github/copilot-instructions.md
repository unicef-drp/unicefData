# GitHub Copilot Instructions for `unicefData`

This document provides guidance for AI coding agents working within the `unicefData` repository. The goal is to ensure productive and context-aware contributions to the codebase.

## Repository Overview

The `unicefData` repository is designed for managing, validating, and analyzing UNICEF-related datasets. It includes workflows for data processing, metadata generation, and statistical analysis. The repository is structured as an R package, with additional support for Python and Stata scripts.

### Key Directories
- **`R/`**: Contains R scripts for data processing and analysis.
- **`python/`**: Python scripts for automation and data manipulation.
- **`stata/`**: Stata scripts, including metadata generation.
- **`tests/` and `testthat/`**: Unit tests for validating code functionality.
- **`docs/`**: Documentation for workflows and methodologies.
- **`metadata/`**: Stores metadata files for datasets.
- **`validation/`**: Scripts and data for validating workflows.

## Development Workflows

### 1. Setting Up the Environment

#### R Environment
- Use `unicefData.Rproj` to open the project in RStudio.
- **R Installation:**
  - Download R from https://cran.r-project.org/
  - **Windows:** Download the `.exe` installer from https://cran.r-project.org/bin/windows/base/
  - **macOS:** Download the `.pkg` installer from https://cran.r-project.org/bin/macosx/
  - **Linux (Ubuntu/Debian):**
    ```bash
    sudo apt update
    sudo apt install r-base r-base-dev
    ```
- **Current installation on this machine:**
  - **Path:** `C:\Program Files\R\R-4.5.1`
  - **Rscript:** `C:\Program Files\R\R-4.5.1\bin\Rscript.exe`
  - **Version:** R 4.5.1 (2025-06-13)
- **Add R to PATH** (required for command-line scripts):
  - **Windows:** Add `C:\Program Files\R\R-4.5.1\bin` to your system PATH environment variable
    - Or use full path: `"C:\Program Files\R\R-4.5.1\bin\Rscript.exe"`
  - **macOS:** R installer usually adds to PATH; verify with `which Rscript`
    - Common paths: `/usr/local/bin/Rscript` or `/opt/homebrew/bin/Rscript`
  - **Linux:** Usually available after installation; verify with `which Rscript`
- **Verify installation:**
  ```bash
  Rscript --version
  # Should output: R scripting front-end version 4.x.x
  ```
- **Install required R packages** by running in R or RStudio:
  ```R
  install.packages(c("httr", "readr", "dplyr", "tibble", "xml2", "memoise", 
                     "countrycode", "yaml", "jsonlite", "magrittr", "purrr", 
                     "rlang", "digest", "tidyr", "devtools", "testthat"))
  ```
- **Install package in development mode:**
  ```R
  devtools::install(".")
  # Or load without installing:
  devtools::load_all(".")
  ```

#### Python Environment
- **Current installation on this machine:**
  - **Path:** `C:\Users\jpazevedo\AppData\Local\Programs\Python\Python311\python.exe`
  - **Version:** Python 3.11.5
  - **Virtual environment:** `C:\GitHub\.venv`
- Ensure the required Python packages are installed from `python/requirements.txt`.
- Use a virtual environment (recommended: `C:\GitHub\.venv` or `<repo>\.venv`).
- **Activate virtual environment:**
  ```powershell
  & C:\GitHub\.venv\Scripts\Activate.ps1
  ```
- Install dependencies:
  ```bash
  pip install -r python/requirements.txt
  ```

#### Stata Environment
- **Current installation on this machine:**
  - **Path:** `C:\Program Files\Stata17`
  - **Executable:** `C:\Program Files\Stata17\StataMP-64.exe`
  - **Version:** Stata 17 MP (64-bit)
- Run `.do` files in Stata for metadata generation.
- The `unicefdata` ado files must be installed from `stata/src/` before running sync commands.
- Common Stata paths searched: `C:\Program Files\Stata17\`, `C:\Program Files\Stata18\`
- **Run Stata from command line:**
  ```powershell
  & "C:\Program Files\Stata17\StataMP-64.exe" /e do "path\to\script.do"
  ```

#### Stata Ado-File System (Package Distribution)

Understanding how Stata finds and loads ado-files is critical for package development:

**Search Path (`adopath`):**
Stata searches directories in this order: `BASE;SITE;.;PERSONAL;PLUS;OLDPLACE`

| Codename | Typical Windows Path | Purpose |
|----------|---------------------|---------|
| `BASE` | `C:\Program Files\Stata17\ado\base\` | Official Stata commands |
| `SITE` | `C:\Program Files\Stata17\ado\site\` | Site-wide installations |
| `.` | Current working directory | Project-specific ados |
| `PERSONAL` | `C:\ado\personal\` | User's personal ados |
| `PLUS` | `C:\ado\plus\` | User-installed packages (`ssc install`, `net install`) |
| `OLDPLACE` | `C:\ado\` | Legacy location |

**Directory Structure Convention:**
Stata uses **single-letter subdirectories** based on the first letter of the filename:
```
plus/
├── _/              ← Files starting with underscore (_helper.ado)
├── a/              ← Files starting with 'a' (alorenz.ado)
├── b/
├── ...
├── u/              ← Files starting with 'u' (unicefdata.ado)
├── y/              ← Files starting with 'y' (yaml.ado)
├── jar/            ← Java .jar files (non-letter exception)
├── py/             ← Python .py files (non-letter exception)
└── style/          ← .style files (non-letter exception)
```

**Key Rules for `unicefdata` Package:**
1. **No subfolders within letter directories** - All files are flat (no `_/unicefdata/` subfolder)
2. **Helper files use `_` prefix** - Internal programs go in `_/` directory (e.g., `_unicef_list_dataflows.ado`)
3. **Python scripts go in `py/`** - Following Stata convention for non-ado files
4. **YAML metadata goes in `_/`** - Named `_unicefdata_*.yaml` to keep with helper files
5. **File extensions matter** - `.ado` for programs, `.sthlp` for help, `.yaml` for data

**Package Installation:**
```stata
* Install from SSC (when published)
ssc install unicefdata

* Install from GitHub
net install unicefdata, from("https://raw.githubusercontent.com/unicef-drp/unicefData/main/stata/")

* Check installation location
which unicefdata
sysdir  // Shows all directory mappings
```

**Development vs Installed Paths:**
| Context | Source Location | Installed Location |
|---------|-----------------|-------------------|
| Main command | `stata/src/u/unicefdata.ado` | `plus/u/unicefdata.ado` |
| Helpers | `stata/src/_/_unicef_*.ado` | `plus/_/_unicef_*.ado` |
| YAML metadata | `stata/src/_/_unicefdata_*.yaml` | `plus/_/_unicefdata_*.yaml` |
| Python scripts | `stata/src/py/*.py` | `plus/py/*.py` |

**Finding Files at Runtime:**
```stata
* Find file anywhere in adopath
findfile unicefdata.ado
return list  // r(fn) contains full path

* Extract directory from found file
local ado_path "`r(fn)'"
local ado_dir = substr("`ado_path'", 1, strlen("`ado_path'") - strlen("unicefdata.ado"))
```

#### Stata Ado-File Development Best Practices

**Version Declaration:**
Always declare the Stata version after `program` to ensure future compatibility:
```stata
program mycommand
    version 14.0    // First line after program
    // ... rest of code
end
```
The `version` line is more critical in ado-files than do-files because ado-files have longer lives and use more Stata features.

**Comments and Long Lines:**
```stata
* Line comment (must be first on line)
/* Block comment */
// Inline comment

* Long lines - use /// to continue
gen result = (e(N)-(e(df_m)+1)) / (e(N)-(e(df_m)+2)) * ///
    (1 - di2/(1-hii)) / (1-hii)
```

**Debugging Ado-Files:**
When modifying an ado-file while Stata is running, use `discard` to force reload:
```stata
discard     // Clear cached ado-files from memory
mycommand   // Now runs the updated version
```
Stata caches loaded ado-files for performance. Without `discard`, changes won't take effect until the next Stata session.

**Local Subroutines:**
An ado-file can contain multiple programs. Programs after the first are local subroutines:
```stata
* In mycommand.ado
program mycommand          // Main program (callable externally)
    version 14.0
    _myhelper              // Calls local subroutine
end

program _myhelper          // Local subroutine (NOT callable externally)
    // ... helper code
end
```
Local subroutines are only visible within their ado-file, even if a global ado-file with the same name exists.

**Temporary Variables:**
Use `tempvar` for working variables to avoid name conflicts:
```stata
program mycommand
    version 14.0
    tempvar hii ei result    // Declare temporary variables
    quietly {
        predict double `hii' if e(sample), hat
        predict double `ei' if e(sample), resid
        gen double `result' = (`ei'*`ei')/e(rss)
    }
    // Temporary variables auto-dropped when program ends
end
```

**Syntax Parsing:**
Use `syntax` command to parse user input:
```stata
program mycommand
    version 14.0
    syntax newvarname [if] [in], INDicator(string) [CLEAR FORCE]
    
    // After syntax:
    // `varlist' = new variable name
    // `typlist' = storage type (float, double, etc.)
    // `if' and `in' = user's conditions
    // `indicator' = required option value
    // `clear' and `force' = optional flags (empty if not specified)
end
```

**Error Handling:**
Use `error` command with standard Stata error codes:
```stata
if "`e(cmd)'" != "regress" {
    error 301    // "last estimates not found"
}
capture confirm file "`filename'"
if _rc {
    di as err "File not found: `filename'"
    error 601    // "file not found"
}
```

**Program Definition and Management:**

The `program` command defines and manipulates programs (ado-files):

```stata
* Define a program with options
program define mycommand, rclass sortpreserve properties(sw)
    version 14.0
    syntax varlist [if] [in] [, Options]
    // ... program body ...
end

* Program management commands
program dir                     // List all programs in memory
program list mycommand          // Show program code
program list _all               // List all program contents
program drop mycommand          // Remove from memory
program drop _all               // Remove ALL programs
program drop _allado            // Remove only auto-loaded ado programs
```

**Program Definition Options:**

| Option | Purpose |
|--------|---------|
| `nclass` | Does not return results in r(), e(), or s() (default) |
| `rclass` | Returns results in r() using `return` command |
| `eclass` | Returns results in e() using `ereturn` command |
| `sclass` | Returns results in s() using `sreturn` command |
| `sortpreserve` | Restores original sort order when program ends |
| `byable(recall)` | Allows by varlist: prefix (recall style) |
| `byable(onecall)` | Allows by varlist: prefix (onecall style) |
| `properties(namelist)` | Declares program properties (up to 80 chars) |
| `plugin` | Loads a C plugin |

**Program Properties:**

Properties indicate to other programs (prefix commands) that certain features are implemented:

| Property | Purpose | Required For |
|----------|---------|--------------|
| `sw` | Supports Wald tests | `stepwise`, `nestreg` |
| `swml` | Supports likelihood-ratio tests (ML estimator) | `stepwise` with `lr` option |
| `svyb` | Supports `vce(bootstrap)`, `vce(brr)`, `vce(sdr)` | `svy` prefix |
| `svyj` | Supports `vce(jackknife)` | `svy` prefix |
| `svyr` | Supports `vce(linearized)` (Taylor linearization) | `svy` prefix |
| `mi` | Supports multiple imputation | `mi estimate` prefix |
| `st` | Survival-time command (uses stset data) | Survival analysis |
| `or` | Can report odds ratios | `eform()` option |
| `hr` | Can report hazard ratios | `eform()` option |
| `shr` | Can report subhazard ratios | `eform()` option |
| `irr` | Can report incidence-rate ratios | `eform()` option |
| `rrr` | Can report relative-risk ratios | `eform()` option |

**Example with properties (like official Stata commands):**
```stata
* Definition for logit includes:
program logit, eclass properties(or svyb svyj svyr swml mi)

* Definition for regress includes:
program regress, eclass properties(svyb svyj svyr sw mi)

* Definition for qreg (quantile regression):
program qreg, eclass properties(sw)    // Wald test only, not ML
```

**Requirements for properties:**
- **sw/swml**: Must be `eclass`, store `e(b)`, `e(N)`, `e(sample)`; for ML also `e(ll)`, `e(df_m)`
- **svyb/svyj/svyr**: Must be `eclass`, allow `iweight`, store `e(b)`, `e(N)`, `e(sample)`, `e(V)`
- **svyr** also requires: `predict` must support `scores` option for Taylor linearization
- **mi**: Must be `eclass`, store `e(cmd)`, `e(b)`, `e(V)`, `e(N)`, `e(sample)`, `e(k_aux)`

**Checking program properties:**
```stata
local props : properties logit
display "`props'"            // Shows: or svyb svyj svyr swml mi bayes
```

**Local Subroutines in Ado-Files:**

An ado-file can contain multiple programs. Programs after the first are local subroutines not visible outside the file:

```stata
* In mycommand.ado - first program must match filename
program mycommand, rclass       // Main program (callable externally)
    version 14.0
    _myhelper `0'               // Call local subroutine
end

program _myhelper              // Local subroutine (NOT visible externally)
    syntax varlist [if] [in]
    // ... helper code ...
    // Even if _myhelper.ado exists, THIS version is used inside mycommand
end
```

**Debugging with `program dir`:**
```stata
program dir                    // Shows loaded programs with sizes
// Output shows:
//   ado  5296  logit_p       <- Auto-loaded from logit_p.ado
//   ado   827  logit         <- Auto-loaded from logit.ado
//        286  smooth         <- User-defined (not from ado-file)
```

The `ado` prefix indicates auto-loaded programs that Stata can drop if memory is scarce.

**Storing Results (r(), e(), s()):**

Stata programs store results in three classes that other programs can access:

| Class | Purpose | Declared With | Used By |
|-------|---------|---------------|---------|
| `r()` | General results | `program name, rclass` | Most commands |
| `e()` | Estimation results | `program name, eclass` | Estimation commands |
| `s()` | Parsing results | `program name, sclass` | Parsing subroutines |
| `c()` | System constants | (read-only) | `c(adopath)`, `c(os)`, etc. |

**Returning r-class results:**
```stata
program mycommand, rclass
    version 14.0
    syntax varname [if] [in]
    
    // ... calculations ...
    
    // Store results in return()
    return scalar N = `n_obs'
    return scalar mean = `avg'
    return local varname "`varlist'"
    return matrix results = mymatrix    // Moves matrix (destroys original)
    return matrix results = mymatrix, copy  // Copies matrix (keeps original)
end
```

**Returning e-class results (estimation commands):**
```stata
program myestcmd, eclass
    version 14.0
    syntax varlist [if] [in]
    
    // ... estimation ...
    
    // Post coefficient vector and VCE matrix
    tempname b V
    matrix `b' = ...
    matrix `V' = ...
    ereturn post `b' `V', esample(`touse') obs(`n')
    
    // Store additional results
    ereturn scalar N = `n'
    ereturn scalar df_m = `df_model'
    ereturn scalar ll = `loglik'
    ereturn local cmd "myestcmd"        // MUST be last e() stored
    ereturn local cmdline "myestcmd `0'"
    ereturn local depvar "`depvar'"
    ereturn local predict "myestcmd_p"
    ereturn local properties "b V"
end
```

**Key e-class macros to store:**
| Macro/Scalar | Purpose |
|--------------|---------|
| `e(cmd)` | Command name (store LAST) |
| `e(cmdline)` | Full command user typed |
| `e(depvar)` | Dependent variable name(s) |
| `e(N)` | Number of observations |
| `e(df_m)` | Model degrees of freedom |
| `e(df_r)` | Residual degrees of freedom (if non-asymptotic) |
| `e(ll)` | Log-likelihood |
| `e(chi2)` | Chi-squared statistic |
| `e(r2)` | R-squared |
| `e(vce)` | VCE type (robust, cluster, etc.) |
| `e(predict)` | Predict command name |
| `e(properties)` | Usually "b V" |

**Returning s-class results (parsing):**
```stata
program myparser, sclass
    version 14.0
    sreturn clear              // Clear previous s() results
    
    // ... parsing logic ...
    
    sreturn local varlist "`parsed_vars'"
    sreturn local options "`parsed_opts'"
end
```

**Important notes:**
- `r()` is cleared when your program ends; results are copied from `return()` to `r()`
- `e()` is cleared by `ereturn post`; results persist until next estimation command
- `s()` is NOT automatically cleared; use `sreturn clear` at start
- Use `return add` to copy all current `r()` results into your `return()`

**Accessing stored results:**
```stata
// After running: summarize price
display r(mean)           // Access r-class result
local avg = r(mean)       // Store in local macro

// After running: regress mpg weight
display e(N)              // Number of observations
matrix list e(b)          // Coefficient vector
matrix list e(V)          // Variance-covariance matrix
predict yhat if e(sample) // Use estimation sample marker

// System constants (read-only)
display c(os)             // Operating system
display c(adopath)        // Ado-file search path
display c(pi)             // Pi constant
```

**Naming conventions for stored results:**
| Prefix | Meaning | Example |
|--------|---------|---------|
| `N` | Count of observations | `N`, `N_1`, `N_clust` |
| `df` | Degrees of freedom | `df_m`, `df_r` |
| `k` | Parameter count | `k`, `k_eq` |
| `chi2` | Chi-squared | `chi2`, `chi2_c` |
| `p` | P-value | `p`, `p_chi2` |
| `ll` | Log-likelihood | `ll`, `ll_0` |
| `r2` | R-squared | `r2`, `r2_p` |
| `lb`/`ub` | Confidence bounds | `lb_95`, `ub_95` |

**Help File Structure (.sthlp):**
Help files use SMCL (Stata Markup and Control Language). The file must be named `command.sthlp` and placed in the same directory as `command.ado`.

**Complete Help File Template:**
```smcl
{smcl}
{* *! version 1.0.0 17Dec2025}{...}
{vieweralsosee "[R] regress" "help regress"}{...}
{viewerjumpto "Syntax" "mycommand##syntax"}{...}
{viewerjumpto "Description" "mycommand##description"}{...}
{viewerjumpto "Options" "mycommand##options"}{...}
{viewerjumpto "Examples" "mycommand##examples"}{...}


{title:Title}

{phang}
{bf:mycommand} {hline 2} Brief one-line description of command


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:mycommand} {newvar} {ifin}{cmd:,} {opt ind:icator(code)} [{it:options}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Main}
{synopt:{opt ind:icator(code)}}indicator code (required){p_end}
{synopt:{opt clear}}replace data in memory{p_end}
{synoptline}
{p2colreset}{...}


{marker description}{...}
{title:Description}

{pstd}
{cmd:mycommand} does something useful. Briefly describe what the command
does without burdening the user with details.


{marker options}{...}
{title:Options}

{phang}
{opt indicator(code)} specifies the indicator code to download. This option
is required.

{phang}
{opt clear} specifies that it is okay to replace the data in memory.


{marker examples}{...}
{title:Examples}

{phang}{cmd:. mycommand result, indicator(CME_MRY0T4)}{p_end}

{phang}{cmd:. mycommand result, indicator(MNCH_ANC4) clear}{p_end}


{title:Author}

{pstd}
Your Name, Organization{break}
Email: your@email.org


{title:Also see}

{psee}
{help regress}, {help predict}
{p_end}
```

**Key SMCL Directives:**
| Directive | Purpose | Example |
|-----------|---------|---------|
| `{smcl}` | First line - declares SMCL format | Required |
| `{* *! version ...}` | Version comment (hidden) | `{* *! version 1.0.0 17Dec2025}{...}` |
| `{viewerjumpto}` | Jump To menu item | `{viewerjumpto "Syntax" "cmd##syntax"}` |
| `{vieweralsosee}` | Also See menu item | `{vieweralsosee "[R] help" "help help"}` |
| `{title:...}` | Section title | `{title:Syntax}` |
| `{marker ...}` | Anchor for jumpto links | `{marker syntax}{...}` |
| `{cmd:...}` | Command/code formatting | `{cmd:unicefdata}` |
| `{opt ...}` | Option name (abbreviated) | `{opt ind:icator(code)}` |
| `{it:...}` | Italic (user-supplied) | `{it:varname}` |
| `{bf:...}` | Bold | `{bf:Important}` |
| `{help ...}` | Hyperlink to help | `{help regress}` |
| `{phang}` | Hanging indent paragraph | Option descriptions |
| `{pstd}` | Standard paragraph | Body text |
| `{pmore}` | Continued paragraph | Multi-para options |
| `{p_end}` | End paragraph | After synopt entries |
| `{hline 2}` | Horizontal line (2 chars) | Title separator |
| `{break}` | Line break | Author info |
| `{synoptset}` | Options table setup | `{synoptset 20 tabbed}` |
| `{synopthdr}` | Options table header | Column headers |
| `{synoptline}` | Options table line | Top/bottom borders |
| `{syntab:...}` | Options table tab | `{syntab:Main}` |
| `{synopt:...}` | Options table entry | `{synopt:{opt clear}}desc{p_end}` |
| `{...}` | Suppress blank line | After comments |

**Help File Guidelines:**
1. First line must be `{smcl}`
2. Second line: version comment `{* *! version #.#.# date}{...}`
3. Include `{viewerjumpto}` links for navigation
4. Two blank lines between major sections
5. Use `{phang}` for option descriptions (hanging indent)
6. Use `{pstd}` for body paragraphs
7. Examples are crucial - show real usage
8. Use `{hi:...}` sparingly for highlighting

**Redirecting Help Files:**
To make `help abc` display `xyz.sthlp`, create `abc.sthlp` containing only:
```smcl
.h xyz
```

**Viewing Examples:**
```stata
viewsource examplehelpfile.sthlp    // View SMCL source
help examplehelpfile                 // View rendered help
```

#### PyStata Integration (Python ↔ Stata)

Stata provides bidirectional Python integration called **PyStata**:
1. **Python from Stata** - Embed Python code in do-files and ado-files
2. **Stata from Python** - Call Stata from Python via the `pystata` package

**This is how `unicefdata` handles large XML files that exceed Stata's macro limits.**

##### Calling Python from Stata (in ado-files)

**Interactive Python Environment:**
```stata
python              // Enter Python (stays in Python despite errors)
python:             // Enter Python (returns to Stata on error)
>>> end             // Exit Python environment
```

**Execute Python Statements:**
```stata
python: import sys; print(sys.version)    // Single statement
python: calcsum("`varlist'", "`touse'")   // Call function with Stata macros
```

**Run Python Script:**
```stata
python script myscript.py                           // Run script
python script myscript.py, args(`a' `b')           // Pass arguments
python script myscript.py, global                   // Keep objects in namespace
python script myscript.py, userpaths("C:\mylib")   // Add module search path
```

**Configure Python:**
```stata
python query                              // Show current Python settings
python search                             // Find Python installations
python set exec "C:\Python311\python.exe" // Set Python executable
python set exec "/usr/bin/python3", permanently
python which numpy                        // Check if module available
```

##### Embedding Python in Ado-Files

**Pattern 1: Python code directly in ado-file:**
```stata
* mycommand.ado
program mycommand
    version 14.0
    syntax varname [if] [in]
    marksample touse
    python: calcsum("`varlist'", "`touse'")    // Call Python function
    display as txt " sum: " as res r(sum)
end

version 14.0
python:
from sfi import Data, Scalar

def calcsum(varname, touse):
    x = Data.get(varname, None, touse)
    Scalar.setValue("r(sum)", sum(x))
end
```

**Pattern 2: Import from external .py file (recommended for complex code):**
```stata
* mycommand.ado
program mycommand
    version 14.0
    syntax varname [if] [in]
    marksample touse
    python: calcsum("`varlist'", "`touse'")
    display as txt " sum: " as res r(sum)
end

version 14.0
python:
from mymodule import calcsum    // Import from mymodule.py
end
```

**The corresponding Python module (mymodule.py):**
```python
from sfi import Data, Scalar

def calcsum(varname, touse):
    x = Data.get(varname, None, touse)
    Scalar.setValue("r(sum)", sum(x))
```

##### Stata Function Interface (sfi) Module

The `sfi` module allows Python to interact with Stata's core features:

| Class | Purpose | Common Functions |
|-------|---------|------------------|
| `Data` | Access current dataset | `get()`, `store()`, `getVarCount()` |
| `Frame` | Access data frames | `connect()`, `getData()` |
| `Macro` | Access macros | `getLocal()`, `getGlobal()`, `setLocal()` |
| `Scalar` | Access scalars | `getValue()`, `setValue()` |
| `Matrix` | Access matrices | `get()`, `store()` |
| `Mata` | Access Mata matrices | `get()`, `store()` |
| `SFIToolkit` | Core utilities | `stata()`, `display()`, `error()`, `exit()` |
| `Missing` | Handle missing values | `getValue()`, `isAnalytical()` |

**Example - Pass data between Stata and Python:**
```python
from sfi import Data, Macro, Scalar, SFIToolkit

# Get Stata local macro
varname = Macro.getLocal("varlist")

# Get data from Stata variable
x = Data.get(varname)

# Return result to Stata
Scalar.setValue("r(result)", sum(x))

# Execute Stata command from Python
SFIToolkit.stata("summarize " + varname)

# Display output in Stata Results window
SFIToolkit.displayln("Processing complete")

# Exit with error code
SFIToolkit.exit(198)  # Custom error
```

##### Python Module Search Paths

When Python is initialized in Stata, these paths are automatically added to `sys.path`:
```
C:\Program Files\Stata17\
C:\Program Files\Stata17\ado\base\
C:\Program Files\Stata17\ado\base\py\    ← py/ subdirectory
C:\Program Files\Stata17\ado\site\
C:\Program Files\Stata17\ado\site\py\
C:\ado\plus\
C:\ado\plus\py\                          ← Where unicefdata Python scripts go
C:\ado\personal\
C:\ado\personal\py\
```

**Add custom paths:**
```stata
python set userpath "C:\mymodules", permanently
python set userpath "C:\mymodules", prepend    // Search first
```

##### PyStata Error Codes

| Code | Meaning |
|------|---------|
| 7100 | Error loading Python library |
| 7101 | Tried to change Python settings after initialization |
| 7102 | Error in Python interactive environment |
| 7103 | Error running Python script or importing module |

##### Output Control: quietly and noisily

**Suppress output:**
```stata
quietly regress mpg weight foreign    // No output
quietly {
    regress mpg weight
    predict resid, resid
    summarize resid, detail
}
```

**Force output inside quiet block:**
```stata
quietly {
    regress mpg weight
    noisily display "Regression complete"    // This line displays
    predict resid, resid
}
```

**Check if output allowed (in programs):**
```stata
program mycommand
    if c(noisily) {
        // Only execute if output is allowed
        display "Processing..."
    }
end
```

##### unicefdata Python Integration Pattern

The `unicefdata` package uses Python helpers for XML parsing because Stata has a ~645KB macro length limit. Here's the pattern:

```stata
* In unicefdata_sync.ado - find and call Python script
local script_name "stata_schema_sync.py"
local script_path ""

* Search in py/ subdirectory of adopath
foreach path in `c(adopath)' {
    local trypath = "`path'/py/`script_name'"
    capture confirm file "`trypath'"
    if (_rc == 0) {
        local script_path "`trypath'"
        continue, break
    }
}

* Call Python with arguments
shell python "`script_path'" "`outdir'" --verbose > "`pyout'" 2>&1
```

**Key files in unicefdata:**
| File | Location | Purpose |
|------|----------|---------|
| `unicefdata_xml2yaml.py` | `stata/src/py/` | XML→YAML parser |
| `stata_schema_sync.py` | `stata/src/py/` | Dataflow schema sync |
| `python_xml_helper.py` | `stata/src/py/` | XML parsing utilities |

### 2. Running Tests
- **R Tests**: Use `testthat` to run unit tests:
  ```R
  library(testthat)
  test_dir("tests")
  ```
- **Python Tests**: If Python scripts include tests, use `pytest`:
  ```bash
  pytest
  ```

### 3. Validating Metadata
- Use the `validation/` directory for scripts to validate dataset metadata.
- Follow instructions in `TODO_yaml_metadata.md` for YAML-based metadata validation.

### 4. Regenerating Metadata
Use the PowerShell script `tests/regenerate_metadata.ps1` to regenerate metadata across platforms:

```powershell
# Interactive mode (prompts if files exist)
.\tests\regenerate_metadata.ps1 -All          # All platforms
.\tests\regenerate_metadata.ps1 -Python       # Python only
.\tests\regenerate_metadata.ps1 -R            # R only
.\tests\regenerate_metadata.ps1 -Stata        # Stata only

# Force overwrite without prompts
.\tests\regenerate_metadata.ps1 -All -Force

# Verbose mode for debugging
.\tests\regenerate_metadata.ps1 -All -Verbose
```

**Prompt options when files exist:**
- **Y** = Overwrite existing files
- **N** = Abort regeneration
- **S** = Skip this platform

### 5. Comparing Metadata Across Platforms
Use the comparison script to verify consistency:

```powershell
python tests/generate_metadata_status.py --compare --detailed
```

This compares record counts, line counts, and attributes between Python, R, and Stata outputs.

---

## Metadata Generation Architecture

The repository generates YAML metadata files from the UNICEF SDMX API across three platforms (Python, R, Stata). Each platform has specialized modules that fetch, parse, and save metadata to platform-specific directories.

### Directory Structure

```
unicefData/
├── python/
│   ├── metadata/current/           # Python-generated metadata
│   │   ├── _unicefdata_*.yaml      # Core metadata (5 files)
│   │   ├── unicef_indicators_metadata.yaml  # Full indicator codelist
│   │   └── dataflows/*.yaml        # Individual dataflow schemas
│   └── unicef_api/
│       ├── run_sync.py             # Main entry point
│       ├── schema_sync.py          # Dataflow schema sync
│       └── indicator_registry.py   # Indicator codelist sync
├── R/
│   ├── metadata/current/           # R-generated metadata
│   │   ├── _unicefdata_*.yaml      # Core metadata (5 files)
│   │   ├── unicef_indicators_metadata.yaml  # Full indicator codelist
│   │   ├── dataflow_index.yaml     # Dataflow summary
│   │   └── dataflows/*.yaml        # Individual dataflow schemas
│   ├── metadata_sync.R             # Core metadata sync
│   ├── schema_sync.R               # Dataflow schema sync
│   └── indicator_registry.R        # Indicator codelist sync
└── stata/
    ├── metadata/current/           # Stata-generated metadata
    │   ├── _unicefdata_*.yaml      # Core metadata (5 files)
    │   ├── unicef_indicators_metadata.yaml  # Full indicator codelist
    │   └── dataflow_index.yaml     # Dataflow summary
    └── src/u/
        └── unicefdata_sync.ado     # All-in-one sync command
```

### Generated Files Overview

| File | Description | Records | Python | R | Stata |
|------|-------------|---------|--------|---|-------|
| `_unicefdata_dataflows.yaml` | Dataflow definitions | ~69 | ✅ | ✅ | ✅ |
| `_unicefdata_codelists.yaml` | Dimension codelists | ~5 | ✅ | ✅ | ✅ |
| `_unicefdata_countries.yaml` | Country ISO3 codes | ~453 | ✅ | ✅ | ✅ (via Python) |
| `_unicefdata_regions.yaml` | Regional aggregates | ~111 | ✅ | ✅ | ✅ (via Python) |
| `_unicefdata_indicators.yaml` | Indicator→dataflow map | ~25 | ✅ | ✅ | ✅ |
| `unicef_indicators_metadata.yaml` | Full indicator codelist | ~733 | ✅ | ✅ | ✅ (requires Python) |
| `dataflow_index.yaml` | Dataflow summary index | ~69 | ❌ | ✅ | ⚠️ (macro limit) |
| `dataflows/*.yaml` | Individual dataflow schemas | ~69 | ✅ | ✅ | ❌ |

**Notes:**
- Stata files marked "(via Python)" use the Python helper for robust XML parsing
- Stata's `unicef_indicators_metadata.yaml` **requires** Python due to macro length limitations
- Stata's `dataflow_index.yaml` may fail due to macro length limits on large XML responses

### Platform-Specific Scripts

#### Python (`python/unicef_api/`)

| Script | Function | Output Files |
|--------|----------|--------------|
| `run_sync.py` | **Main entry point** - orchestrates all sync operations | Calls other modules |
| `schema_sync.py` | Fetches dataflow DSDs, samples data for dimension values | `dataflows/*.yaml` |
| `indicator_registry.py` | Fetches `CL_UNICEF_INDICATOR` codelist, caches with 30-day staleness | `unicef_indicators_metadata.yaml` |

**Key functions:**
```python
# schema_sync.py
sync_dataflow_schemas()  # Main sync function

# indicator_registry.py
refresh_indicator_cache()  # Force refresh from API
get_dataflow_for_indicator(code)  # Lookup with override table
get_cache_info()  # Check cache status
```

#### R (`R/`)

| Script | Function | Output Files |
|--------|----------|--------------|
| `metadata_sync.R` | Fetches core metadata (dataflows, codelists, countries, regions, indicators) | `_unicefdata_*.yaml` (5 files) |
| `schema_sync.R` | Fetches dataflow DSDs, samples data for dimension values | `dataflow_index.yaml`, `dataflows/*.yaml` |
| `indicator_registry.R` | Fetches `CL_UNICEF_INDICATOR` codelist, caches with 30-day staleness | `unicef_indicators_metadata.yaml` |

**Key functions:**
```r
# metadata_sync.R
sync_all_metadata(verbose = TRUE, output_dir = "R/metadata/current")

# schema_sync.R
sync_dataflow_schemas(verbose = TRUE, output_dir = "R/metadata/current")

# indicator_registry.R
refresh_indicator_cache()  # Force refresh from API
get_dataflow_for_indicator(code)  # Lookup with override table
get_cache_info()  # Check cache status
```

#### Stata (`stata/src/u/`)

| Script | Function | Output Files |
|--------|----------|--------------|
| `unicefdata_sync.ado` | **All-in-one** - contains all sync logic in subprograms | All files |

**Subprograms within `unicefdata_sync.ado`:**

| Subprogram | Function |
|------------|----------|
| `_unicefdata_sync_dataflows` | Fetches dataflow list |
| `_unicefdata_sync_codelists` | Fetches dimension codelists |
| `_unicefdata_sync_countries` | Fetches `CL_REF_AREA` country codes |
| `_unicefdata_sync_regions` | Filters regional aggregates |
| `_unicefdata_sync_indicators` | Creates indicator→dataflow mapping |
| `_unicefdata_sync_ind_meta` | Fetches full `CL_UNICEF_INDICATOR` codelist (uses Python helper) |

**Python Helper Infrastructure:**

Stata has a fundamental limitation with macro length (~645,216 characters max) that prevents parsing large XML files inline. To work around this, Stata uses Python helper scripts for large files:

| Component | Location | Purpose |
|-----------|----------|---------|
| `unicefdata_xmltoyaml.ado` | `stata/src/u/` | Wrapper that auto-selects Python for files >500KB |
| `unicefdata_xmltoyaml_py.ado` | `stata/src/u/` | Stata-to-Python bridge |
| `unicefdata_xml2yaml.py` | `stata/src/u/` | Python XML parser (handles all SDMX types) |
| `_xmltoyaml_get_schema.ado` | `stata/src/_/` | Schema registry for XML element mappings |

**Important:** When running Stata sync, ensure the adopath includes all required directories:
```stata
adopath ++ "stata/src/u"
adopath ++ "stata/src/p"
adopath ++ "stata/src/_"
```

**Usage:**
```stata
// Full sync (all files)
unicefdata_sync, verbose

// Force refresh (bypass 30-day cache)
unicefdata_sync, verbose force

// Use Python XML parser (recommended for large files)
unicefdata_sync, verbose forcepython

// Use pure Stata parser (limited to small files only)
unicefdata_sync, verbose forcestata
```

**Parser Selection:**
- `forcepython`: Always use Python (required for `unicef_indicators_metadata.yaml`)
- `forcestata`: Always use Stata (will fail on large XML files like the indicator codelist)
- Default: Auto-select based on file size (>500KB → Python)

### Indicator Registry Architecture

The `unicef_indicators_metadata.yaml` file is special - it contains the full UNICEF indicator codelist (~733 indicators) with metadata. All three platforms now generate this file with aligned structure:

#### File Format (all platforms)
```yaml
metadata:
  version: '1.0'
  source: UNICEF SDMX Codelist CL_UNICEF_INDICATOR
  url: https://sdmx.data.unicef.org/ws/public/sdmxapi/rest/codelist/UNICEF/CL_UNICEF_INDICATOR/1.0
  last_updated: '2025-12-08T10:30:00Z'
  description: Comprehensive UNICEF indicator codelist with metadata (auto-generated)
indicators:
  CME_MRY0T4:
    code: CME_MRY0T4
    name: 'Under-five mortality rate'
    description: '...'
    urn: 'urn:sdmx:org.sdmx.infomodel.codelist.Code=UNICEF:CL_UNICEF_INDICATOR(1.0).CME_MRY0T4'
    category: CME
```

#### Caching Behavior

All platforms implement 30-day staleness checking:

| Platform | Cache Check | Force Refresh |
|----------|-------------|---------------|
| Python | Reads `last_updated` from file, skips if < 30 days | `refresh_indicator_cache()` always fetches |
| R | Reads `last_updated` from file, skips if < 30 days | `refresh_indicator_cache()` always fetches |
| Stata | Reads `last_updated` from file, skips if < 30 days | `unicefdata_sync, force` option |

#### Dataflow Override Table

Some indicators exist in different dataflows than their prefix suggests. All platforms maintain an override table:

```python
# Example overrides (same in Python, R, Stata)
"PT_F_20-24_MRD_U18_TND" -> "PT_CM"      # Child Marriage (not PT)
"PT_F_15-49_FGM" -> "PT_FGM"              # FGM (not PT)
"ED_CR_L1_UIS_MOD" -> "EDUCATION_UIS_SDG" # UIS indicators (not EDUCATION)
```

### yaml.ado Key Format and Best Practices

**CRITICAL:** yaml.ado stores YAML data as a flattened key-value dataset with **underscores** as separators, NOT colons.

#### Data Storage Format

When you load YAML with `yaml read`, it creates a dataset with these columns:

| Column | Type | Example |
|--------|------|---------|
| `key` | str244 | `indicators_CME_MRY0T4_category` |
| `value` | str2000 | `CME` |
| `level` | int | `2` |
| `parent` | str244 | `indicators_CME_MRY0T4` |
| `type` | str32 | `scalar` |

**Key Format:** `parent_child_attribute` (underscores, NOT colons)
- ✅ Correct: `indicators_CME_MRY0T4_category`
- ❌ Wrong: `indicators:CME_MRY0T4:category`

#### Recommended Pattern: Direct Dataset Queries

**DON'T** loop through items calling `yaml get` repeatedly (slow, buggy with frames):

```stata
* BAD: 733 yaml get calls, very slow
foreach ind of local all_indicators {
    yaml get indicators:`ind', attributes(category)  // WRONG separator!
}
```

**DO** use direct dataset operations (fast, robust):

```stata
* GOOD: Single pass through dataset
frame yaml_frame {
    * Filter to category rows
    keep if regexm(key, "^indicators_[A-Za-z0-9_]+_category$")
    
    * Count by category
    rename value category
    gen count = 1
    collapse (sum) count, by(category)
}
```

#### Common Patterns

**Get all categories with counts:**
```stata
keep if regexm(key, "^indicators_[A-Za-z0-9_]+_category$")
collapse (count) n=key, by(value)
```

**Search indicators by keyword:**
```stata
keep if regexm(key, "^indicators_[A-Za-z0-9_]+_(code|name|category)$")
gen ind_id = regexs(1) if regexm(key, "^indicators_(.+)_(code|name|category)$")
reshape wide value, i(ind_id) j(attribute) string
* Now search: gen found = strpos(lower(valuename), "mortality") > 0
```

**Get info for specific indicator:**
```stata
local indicator "CME_MRY0T4"
keep if regexm(key, "^indicators_`indicator'_(code|name|category|description|urn)$")
* Extract values from matching rows
```

#### Performance Comparison

| Approach | Time | Method |
|----------|------|--------|
| 733 `yaml get` calls | ~10+ seconds | Loop + frame context issues |
| Direct dataset query | ~0.7 seconds | Single `regexm` + `collapse` |

**Why it's faster:** Stata's dataset operations are highly optimized; `yaml get` has to search the dataset for each call plus handle frame context switching.

### Orchestration Script

The PowerShell script `tests/regenerate_metadata.ps1` orchestrates metadata generation across all platforms:

```
regenerate_metadata.ps1
├── Regenerate-PythonMetadata()
│   └── Calls: python -m unicef_api.run_sync
│       ├── schema_sync.sync_dataflow_schemas()
│       └── indicator_registry.refresh_indicator_cache()
│
├── Regenerate-RMetadata()
│   ├── Step 1: Rscript metadata_sync.R → sync_all_metadata()
│   ├── Step 2: Rscript schema_sync.R → sync_dataflow_schemas()
│   └── Step 3: Rscript indicator_registry.R → refresh_indicator_cache()
│
└── Regenerate-StataMetadata()
    └── Runs Stata: unicefdata_sync, verbose forcepython force
        └── Requires adopath: stata/src/u, stata/src/p, stata/src/_
```

**Stata Setup for Manual Testing:**
```stata
* Ensure all required directories are in adopath
cd "C:\GitHub\others\unicefData"
adopath ++ "stata/src/u"
adopath ++ "stata/src/p"
adopath ++ "stata/src/_"

* Run sync with Python helper
unicefdata_sync, verbose forcepython force
```

### API Endpoints Used

| Endpoint | Purpose | Used By |
|----------|---------|---------|
| `/dataflow/UNICEF` | List all dataflows | All platforms |
| `/dataflow/UNICEF/{id}?references=all` | Get dataflow DSD | Python, R (schemas) |
| `/codelist/UNICEF/CL_REF_AREA` | Country/region codes | All platforms |
| `/codelist/UNICEF/CL_UNICEF_INDICATOR` | Full indicator list | All platforms |
| `/data/UNICEF/{dataflow}?...` | Sample data for dimension values | Python, R (schemas) |

---

## Project-Specific Conventions

### File Naming
- Use descriptive and consistent names for scripts and outputs.
- Follow R package conventions for function and file names.

### Documentation
- Update `README.md` and `docs/` for any significant changes.
- Use `NEWS.md` to log updates.

### Metadata Management
- YAML is the preferred format for metadata.
- Ensure metadata files are validated before use.

## Integration Points
- **R and Python**: Ensure seamless integration between R and Python scripts.
- **Stata**: Use Stata scripts for metadata generation and validation.

## External Dependencies
- R packages listed in `DESCRIPTION`.
- Python packages (if any) should be listed in a `requirements.txt` file.
- Stata software for `.do` file execution.

## Contribution Guidelines
- Follow the repository's coding conventions.
- Write unit tests for new features.
- Document changes in `NEWS.md`.

## Notes for AI Agents
- Focus on maintaining compatibility between R, Python, and Stata components.
- Prioritize metadata validation and consistency.
- Ensure outputs adhere to UNICEF data standards.
- **Stata Limitation**: Stata has a ~645,216 character macro length limit. Large XML files (like the indicator codelist) MUST be parsed via the Python helper infrastructure (`unicefdata_xmltoyaml`), not inline Stata code.
- When modifying Stata sync code, always consider whether the XML response might exceed macro limits.

For further clarification, refer to the `README.md` or `docs/` directory.

## Additional Guidance for AI Agents

### Preventing Hallucinations
- Ensure all code suggestions are grounded in the repository's existing patterns and workflows.
- Avoid introducing new methodologies or dependencies unless explicitly requested.
- Cross-reference outputs and metadata with existing files to ensure consistency.

### Reproducibility Focus
- Prioritize reproducibility in all Python, R, and Stata scripts.
- Ensure that all scripts can be executed independently with minimal setup.
- Validate outputs against expected results to maintain accuracy.

### Output Handling
- Outputs generated by Python, R, and Stata scripts are never to be edited by Copilot.
- Focus on improving the scripts themselves, not the generated outputs.
- If output modifications are required, defer to human review and approval.

### Reference for Stata Scripts
- The `wbopendata` Stata ado scripts located in `C:\GitHub\myados\wbopendata` can be used as a reference for designing similar scripts in Stata.
- Review these scripts to understand best practices for structuring and documenting Stata code.

### Locating the Repository Root
- To ensure scripts work regardless of the current working directory, dynamically locate the repository root by searching for the `.git` folder.
- Example for PowerShell:
  ```powershell
  function Get-RepoRoot {
      $currentDir = Get-Location
      while (-Not (Test-Path "$currentDir\.git")) {
          $parentDir = $currentDir.Parent
          if (-Not $parentDir) {
              throw "Unable to locate repository root. Ensure the script is run within a Git repository."
          }
          $currentDir = $parentDir
      }
      return $currentDir
  }
  $RepoRoot = Get-RepoRoot
  ```
- Use `$RepoRoot` to construct relative paths for scripts and commands.

## Contact and Support
For any questions or further assistance, please refer to the repository maintainers or the documentation provided within the `docs/` directory.   