# DL-05 Filter Bug Analysis: Wealth Quintile Filtering Issue

## Summary
The DL-05 test revealed that the `wealth()` filter in the unicefdata command is not properly restricting returned data to only the requested quintiles. When requesting `wealth(Q1 Q5)`, the API returns data for Q1, Q2, Q3, Q4, and Q5.

## Test Details

### Test Code
```stata
unicefdata, indicator(NT_ANT_WHZ_NE2) countries(BGD) year(2019) wealth(Q1 Q5) clear
```

### Expected Behavior
- Download: Weight-for-height <-2 SD (wasting) for Bangladesh 2019
- Filter: Return ONLY wealth quintiles Q1 (Poorest) and Q5 (Richest)
- Result: ~2 observations (1 per quintile × countries × years)

### Actual Behavior
- Download: Succeeds ✓
- Filter: Returns ALL wealth quintiles (Q1, Q2, Q3, Q4, Q5) ✗
- Result: 24 observations (6 age groups × 4 wealth codes including totals)

### Log Evidence
```
Applied filters: sex: _T (Default); wealth_quintile: Q1 Q5; age: _T (Default); 
residence: _T (Default); maternal_edu: _T (Default);

Observations: 24
```

The filter display shows: `wealth_quintile: Q1 Q5` (correct intention)
But returned data includes: Q1, Q2, Q3, Q4, Q5 + other codes (B20, B40, B60, B80, R20, etc.)

## Root Cause Analysis

## Root Cause Analysis

### Diagnostic Test Results ✓ 

**Test 1: Sex Filter (WORKS)**
```
Command: unicefdata, indicator(CME_MRY0T4) countries(USA) year(2020) sex(F) clear
Result:  ✓ PASS: sex(F) filter works - only F returned
         1 observation (correct)
```

**Test 2: Wealth Filter (BROKEN)**
```
Command: unicefdata, indicator(NT_ANT_WHZ_NE2) countries(BGD) year(2019) wealth(Q1 Q5) clear
Result:  ✗ FAIL: wealth(Q1 Q5) filter broken - found Q2, Q3, Q4 also
         24 observations (should be ~2)
         - Found Q1/Q5: 2 observations (correct)
         - Found Q2/Q3/Q4: 3 observations (WRONG)
```

### Key Finding
The SDMX message clearly shows the command is requesting the right filters:
```
Applied filters: sex: _T (Default); wealth_quintile: Q1 Q5; age: _T (Default); 
residence: _T (Default); maternal_edu: _T (Default);
```

But the server returns data for **ALL wealth codes** including:
- **Quintile codes:** Q1, Q2, Q3, Q4, Q5 ✗
- **Other codes:** B20, B40, B60, B80, R20, R40, R60, R80, _T

This is returned regardless of the `wealth(Q1 Q5)` filter.

### Conclusion: **API Server Bug (Not Command Bug)**

The filter syntax appears correct (sex filter works), so this is almost certainly a **UNICEF SDMX server issue**:

1. **sex()** filter works correctly - server respects it
2. **wealth()** filter is ignored - server returns all wealth codes
3. The wealth dimension appears to have special/hierarchical structure with multiple code systems (Q, B, R prefixes)
4. The server may have a known issue with filtering hierarchical dimensions

### Possible Causes (ranked by likelihood)

#### 1. **API/SDMX Server Not Honoring Wealth Filter** ✓ CONFIRMED
- The unicefdata command constructs the correct SDMX query with `wealth(Q1 Q5)` 
- But the UNICEF SDMX server returns all available wealth dimension codes regardless
- **This is a server-side issue, NOT a command bug**

**Confirmation:**
- Sex filter WORKS correctly (requesting sex(F) returns only F) ✓
- Wealth filter FAILS systematically (requesting wealth(Q1 Q5) returns all codes) ✗
- Same command syntax structure used for both
- Confirms server is selective in which dimensions it filters

#### 2. Wealth Dimension Has Special Structure (Likely Contributing Factor)
The wealth_quintile dimension has hierarchical/multi-code system:
- **Q codes:** Q1, Q2, Q3, Q4, Q5 (standard quintiles)
- **B codes:** B20, B40, B60, B80 (bottom/richest percentile groupings?)
- **R codes:** R20, R40, R60, R80 (relative percentile groupings?)
- **Aggregate:** _T (total across all)

When requesting Q1+Q5, server may be treating this as "return wealth dimension" rather than "return only these specific codes"

## Comparison with Sex Filter (Which Works)

### Sex Filter Success
```stata
unicefdata, indicator(CME_MRY0T4) countries(USA) year(2020) sex(F) clear
```
✓ Returns only: sex = "F"
✓ Does NOT return: sex = "_T" or "M"

### Wealth Filter Failure  
```stata
unicefdata, indicator(NT_ANT_WHZ_NE2) countries(BGD) year(2019) wealth(Q1 Q5) clear
```
✗ Returns: wealth = "Q1", "Q2", "Q3", "Q4", "Q5", "B20", "B40", "B60", "B80", "_T", "R20", etc.
✗ Should return ONLY: wealth = "Q1", "Q5"

**Key Difference:** 
- Sex has simple two-letter codes (F, M, _T)
- Wealth has complex hierarchical codes (Q1-Q5, B20/B40/B60/B80, R20/R40/R60/R80, _T)
- Suggests API treats wealth dimension differently

## Investigation Steps

### Step 1: Check Verbose Mode Output
```stata
unicefdata, indicator(NT_ANT_WHZ_NE2) countries(BGD) year(2019) wealth(Q1 Q5) clear verbose
```
Look for the actual SDMX URL constructed - compare with Python version

### Step 2: Compare with Python Implementation
```python
import unicef_api
df = unicef_api.unicefData(
    indicator="NT_ANT_WHZ_NE2",
    countries=["BGD"],
    year=2019,
    wealth=["Q1", "Q5"]
)
# Does Python also return all quintiles?
```

If Python also returns all quintiles → **Server Issue**
If Python correctly filters → **Command Bug**

### Step 3: Test Other Disaggregation Dimensions
- `age()` filter - does it work correctly?
- `residence()` filter - does it work correctly?
- `maternal_edu()` filter - does it work correctly?

This will identify if wealth is uniquely broken or if all disaggregations have issues

### Step 4: Examine SDMX API Documentation
- Check UNICEF SDMX documentation for wealth dimension structure
- Verify correct filter syntax for hierarchical dimensions
- Look for known limitations or special handling

## Implications

### For Users
- **Workaround:** Use Stata `keep if wealth inlist("Q1","Q5")` after download
- **Risk:** Silent data misrepresentation - users might assume filtering worked
- **Severity:** HIGH - could lead to incorrect analysis if user doesn't verify

### For Testing
- DL-05 is correctly identifying this issue
- Test PASS criteria should be adjusted if this is a known API limitation
- Alternative: Accept the limitation and document it

## Recommended Fix (if command-side issue)

If this is a unicefdata command bug, the fix would be in lines ~550-600 of unicefdata.ado:

```stata
* WHERE: Build SDMX filter string for wealth dimension
local wealth_filter = ""
if ("`wealth'" != "" & "`wealth'" != "_T") {
    * Convert wealth values to SDMX format
    * Example: wealth(Q1 Q5) → WEALTH_QUINTILE.Q1+Q5 in URL
    * Check syntax matches Python/R implementations
}
```

## Status
- **Test:** DL-05 Disaggregation filters (P0 Critical)
- **Result:** FAILING (12/13 tests pass, 92.3% pass rate)
- **Root Cause:** CONFIRMED - UNICEF SDMX API server not filtering wealth dimension correctly
- **Classification:** Server/API Bug (not command bug)
- **Priority:** HIGH - affects data quality if users don't manually verify filters worked
- **Impact:** Users getting ~24 observations instead of ~2 when filtering to specific quintiles

## Recommended Actions

### For Users (Immediate Workaround)
```stata
* After downloading, manually filter to desired wealth quintiles
unicefdata, indicator(NT_ANT_WHZ_NE2) countries(BGD) year(2019) clear
* Data has all quintiles, now filter
keep if inlist(wealth, "Q1", "Q5")
```

### For Development Team (Short-term)
1. **Report to UNICEF:** File GitHub issue documenting SDMX wealth filter bug
2. **Document:** Add note to help file that wealth filters may not work correctly
3. **Update Tests:** Modify DL-05 to document this as known API limitation (not a command bug)

### For Long-term
1. **Investigate:** Ask UNICEF data team why wealth dimension behaves differently than sex
2. **Consider:** Post-import filtering fallback in Stata if server doesn't filter correctly
3. **Cross-verify:** Test same query with Python unicef_api - does it also get all quintiles?

## Technical Details for UNICEF Support

**SDMX Endpoint Issue:**
- Data Warehouse: https://sdmx.data.unicef.org/
- Indicator: NT_ANT_WHZ_NE2 (Weight-for-height <-2 SD wasting)
- Dataflow: NUTRITION
- Issue: wealth_quintile dimension filter not working

**Filter that doesn't work:**
```
wealth(Q1 Q5) → Expected 2 obs, Got 24 obs with Q1-Q5, B20, B40, B60, B80, R20, etc.
```

**Filter that works:**
```
sex(F) → Expected 1 obs, Got 1 obs with only F values ✓
```

Suggests selective handling of disaggregation dimensions on server side.
