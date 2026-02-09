unicefData: Stata module for accessing UNICEF SDMX indicators

This package contains the following files:

1. ado-files:
   - unicefdata.ado
   - unicefdata_sync.ado
   - unicefdata_xmltoyaml.ado

2. help files:
   - unicefdata.sthlp
   - unicefdata_sync.sthlp

3. Example do-files:
   - examples/unicefdata_examples.ado

4. Metadata:
   - src/_/unicefdata_codelists.yaml
   - src/_/unicefdata_indicators.yaml

5. Documentation:
   - stata/05_paper/unicefData_documentation_draft.tex

6. Tests:
   - tests/unicefdata_tests.do

Installation:
To install the package, copy the ado-files and help files to your Stata PLUS directory:

```
. net install unicefdata, from(https://github.com/unicef-drp/unicefData/stata/ssc) replace
```

Version: 1.5.1 (as referenced in the zip file: unicefdata_package.zip)

For more information, see the help files or the documentation in stata/05_paper.