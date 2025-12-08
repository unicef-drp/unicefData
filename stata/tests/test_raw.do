* Test to see raw column names from API
clear all
set more off

adopath + "."

* Test basic download with RAW option
unicefdata, indicator(CME_MRY0T4) countries(ALB) clear verbose raw

* Check variables - this shows what the API returns before any renaming
describe, fullnames
