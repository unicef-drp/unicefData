# Release & Versioning Guide (Concise)

This guide standardizes how we bump versions, gate releases with tests, and publish builds.

## Conventional Commits → SemVer
- **fix:** Patch bump (X.Y.Z → X.Y.Z+1)
- **feat:** Minor bump (X.Y.Z → X.Y+1.0)
- **feat! / BREAKING CHANGE:** Major bump (X.Y.Z → X+1.0.0)
- **docs/chore/test/refactor:** No bump unless included in a release that warrants a new version

## When to Change Version
- **Bump version at release time** (develop → main), not on every merge to develop.
- Use **pre-release tags** when needed: `vX.Y.Z-rc.1`, `-beta.1`.

## Test Gating Policy
- **Required to release:** All P0 and P1 tests pass.
- **Optional:** P2 (edge/perf) may be allowed with documented issues or pre-release tags.
- Run the full suite before tagging:
  - Stata: `do stata/qa/run_tests.do`

## Release Flow (develop → main)
1. Merge feature PRs into `develop` in order:
   - `feature/qa-test-suite` → `develop`
   - `feature/qa-test-fixes` → `develop` (depends on test-suite)
   - `feature/paper-docs` and `feature/ssc-packaging` → `develop` (independent)
2. Ensure CI green on P0/P1.
3. Update versions consistently:
   - ADO headers (e.g., `*! v 1.5.2  DDMMMYYYY`)
   - `stata/ssc/stata.toc` and `stata/ssc/unicefdata.pkg`
4. Build SSC package: `stata/ssc/update_zip.ps1`.
5. Tag: `git tag -a v1.5.2 -m "Release v1.5.2"; git push origin v1.5.2`.
6. Publish GitHub Release with notes (tests status, changes). 

## PR Templates

### PR: feature/qa-test-suite → develop
- Add automated test suite (28 tests across ENV, DL, DISC, TRANS/META/MULTI, EDGE/PERF, XPLAT)
- Status: 19/28 passing, 7 failing, 2 skipped
- Docs: strategic plan, testing guide, consolidation summary

### PR: feature/qa-test-fixes → develop
- Build on test-suite; fix EDGE-01 (accept r(677)), `rc()` handling
- Diagnostics: filter checks, failing tests action plan
- Status: 20/28 passing, 6 failing, 2 skipped

### Release PR: develop → main (example)
- Title: Release v1.5.2 — Automated QA and fixes
- Summary: Adds test infrastructure, fixes error-handling, documents failures
- Tests: P0/P1 pass; remaining P2 issues documented
- No breaking changes

## Branching & Artifacts
- Feature branches from `develop`; merge to `develop`; then release to `main`.
- Track SSC `.zip` in `stata/ssc/`; ignore `stata/ssc/temp_unzip/`.
- Keep LaTeX build artifacts out of git; keep source `.tex/.bib/.sty/.cls` + final `.pdf`.

## Notes
- Prefer Conventional Commits to automate bump decisions.
- Use pre-release tags if you must share builds before all tests pass.
