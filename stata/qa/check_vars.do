* Quick test to check variable names
clear all
unicefdata, indicator(CME_MRY0T4) countries(USA) year(2020) clear
describe, short
list in 1/5, clean
