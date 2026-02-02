
            * Test Stata fallback loading
            clear all
            adopath ++ "C:\GitHub\myados\unicefData\stata\src"
            
            * Test each prefix
            local prefixes "CME ED PT COD WS IM TRGT SPP MNCH NT ECD HVA PV DM MG GN FD ECO COVID WT"
            
            foreach prefix in `prefixes' {
                _unicef_fetch_with_fallback, indicator(TEST_CODE), prefix(`prefix')
                * Output handled by _unicef_fetch_with_fallback
            }
            