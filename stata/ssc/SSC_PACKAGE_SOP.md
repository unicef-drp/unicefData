# SOP: Build and Release the unicefData SSC Package

**Scope:** Stata SSC distribution files in `stata/ssc/` for `unicefData`.

## 1) Preconditions
- Work in the `unicefData-dev` repo only.
- Ensure the source tree in `stata/src/` is up to date and tests/QA have passed as needed.

## 2) Update version references
1. **Source version header** (authoritative):
   - Check `stata/src/u/unicefdata.ado` header for the current SemVer (e.g., `v 2.0.4`).
2. **SSC catalog**:
   - Update `stata/ssc/stata.toc` to match the current SemVer.
3. **Package manifest**:
   - Update `stata/ssc/unicefdata.pkg`:
     - `Distribution-Date` (YYYYMMDD).
     - Include all current `.ado`, `.sthlp`, and required metadata files.

## 3) Update SSC README
- Update `stata/ssc/README.txt` with:
  - Current version/date
  - Updated features and requirements
  - Installation commands (SSC and GitHub)
  - Minimal examples and help references

## 4) Regenerate the zip package
1. Run the package build script:
   - `stata/ssc/update_zip.ps1`
2. Expected output:
   - `stata/ssc/unicefData_XXX.zip` where `XXX` matches the SemVer (e.g., `204`).

## 5) Verify the zip contents
- Confirm all `.ado`, `.sthlp`, and metadata files listed in `unicefdata.pkg` exist in the zip.
- Spot-check critical files:
  - `unicefdata.ado`, `unicefdata_sync.ado`, `unicefdata_setup.ado`
  - `yaml.ado`, core `_unicef_*.ado`, and required YAML files

## 6) Clean up
- Remove any temporary folders created by the build script (e.g., `temp_unzip`, `temp_verify`).

## 7) Final checklist
- `stata/ssc/stata.toc` matches the current SemVer
- `stata/ssc/unicefdata.pkg` lists all current files and has the correct date
- `stata/ssc/README.txt` is current
- `stata/ssc/unicefData_XXX.zip` was regenerated and verified

## 8) Notes
- Keep versioning aligned with SemVer and changelog policies.
- If new commands or metadata files are added in `stata/src/`, ensure they are reflected in `unicefdata.pkg`.
