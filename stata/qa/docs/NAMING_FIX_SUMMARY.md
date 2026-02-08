# Metadata File Naming Convention Fix - 2026-01-24

## Issue

The Python script `stata_schema_sync.py` was creating files and directories without the underscore prefix, inconsistent with other metadata files.

## Root Cause

Python script was using:
- `dataflow_index.yaml` (should be `_dataflow_index.yaml`)
- `dataflows/` directory (should be `__dataflows/`)

## Naming Convention Standard

All metadata files and directories in `stata/src/_/` follow this convention:
- Core metadata files: `_*.yaml` (single underscore prefix)
- Dataflow index: `_dataflow_index.yaml` (single underscore)
- Dataflow schemas directory: `_dataflows/` (single underscore)
- Individual schemas: `_dataflows/{DATAFLOW_ID}.yaml`

Examples:
```
stata/src/_/
  _unicefdata_dataflows.yaml
  _unicefdata_indicators.yaml
  _unicefdata_countries.yaml
  _dataflow_index.yaml         ← Fixed
  __dataflows/                 ← Fixed
    CME.yaml
    NUTRITION.yaml
    ...
```

## Files Modified

### 1. stata/src/py/stata_schema_sync.py

**Line 7-8** - Documentation:
```python
# Before:
1. dataflow_index.yaml - Summary of all dataflows
2. dataflows/*.yaml - Individual schema files

# After:
1. _dataflow_index.yaml - Summary of all dataflows
2. __dataflows/*.yaml - Individual schema files
```

**Line 224** - Directory name:
```python
# Before:
dataflows_dir = os.path.join(output_dir, f'dataflows{suffix}')

# After:
dataflows_dir = os.path.join(output_dir, f'__dataflows{suffix}')
```

**Line 232** - Index filename:
```python
# Before:
index_path = os.path.join(output_dir, f'dataflow_index{suffix}.yaml')

# After:
index_path = os.path.join(output_dir, f'_dataflow_index{suffix}.yaml')
```

### 2. stata/qa/run_tests.do

**Line 2297** - Test expects correct filename:
```stata
# Reverted back to correct expectation:
local index_file "`metadir'/_dataflow_index.yaml"
```

(This was temporarily changed to `dataflow_index.yaml` but is now correct again)

## Impact

### Before Fix:
```
stata/src/_/
  dataflow_index.yaml          ✗ Wrong (no underscore)
  dataflows/                   ✗ Wrong (no underscore)
    CME.yaml
    ...
```

### After Fix:
```
stata/src/_/
  _dataflow_index.yaml         ✓ Correct (single underscore)
  __dataflows/                 ✓ Correct (double underscore)
    CME.yaml
    ...
```

## Testing

To test the fix, run metadata sync and verify correct filenames:

```stata
cd "C:\GitHub\myados\unicefData-dev\stata\qa"

* Clean up old incorrectly-named files
cd "../src/_"
!rm -f dataflow_index.yaml
!rm -rf dataflows/

* Run sync
cd "C:\GitHub\myados\unicefData-dev\stata\qa"
unicefdata_sync, all

* Verify correct files created
cd "../src/_"
!ls -lh _dataflow_index.yaml
!ls -d __dataflows/
!ls __dataflows/*.yaml | head -5
```

Expected output:
```
-rw-r--r-- ... _dataflow_index.yaml        ✓
drwxr-xr-x ... __dataflows/                ✓
__dataflows/CME.yaml                        ✓
__dataflows/NUTRITION.yaml                  ✓
...
```

## SYNC-01 Test

After regenerating files with correct names, SYNC-01 test should pass:

```stata
cd "C:\GitHub\myados\unicefData-dev\stata\qa"
global run_sync = 1
do run_tests.do SYNC-01
```

Expected result:
```
✓ PASS: SYNC-01 Dataflow index synced successfully
```

## Consistency Check

All metadata files now follow convention:

```bash
cd "C:\GitHub\myados\unicefData-dev\stata\src\_"
ls -1 *.yaml | grep -v "^_"
# Should return nothing - all files start with _
```

## Next Steps

1. Delete old incorrectly-named files/directories
2. Regenerate metadata with `unicefdata_sync, all`
3. Run SYNC-01 test to verify fix
4. Run full test suite with SYNC enabled

---

**Fixed**: 2026-01-24
**Files Modified**: 2 (Python script + test file)
**Status**: Ready for testing
