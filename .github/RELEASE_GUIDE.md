# Release & Versioning Guide (Concise)

This guide standardizes how we bump versions, gate releases with tests, and publish builds.

## Conventional Commits → SemVer
- **fix:** Patch bump (X.Y.Z → X.Y.Z+1) — critical bug fixes only (see Minimum Bump Rule)
- **feat:** Minor bump (X.Y.Z → X.Y+1.0)
- **feat! / BREAKING CHANGE:** Major bump (X.Y.Z → X+1.0.0)
- **docs/chore/test/refactor:** No bump unless included in a release that warrants a new version

## Minimum Bump Rule

**Every platform release must increment at least the minor version.**

- Bug fixes, improvements, and CI changes accumulate on `develop` and ship together as a minor release (`X.Y+1.0`).
- **Patch releases** (`X.Y.Z+1`) are reserved exclusively for **critical fixes**: data integrity issues, broken installs, or security vulnerabilities that cannot wait for the next minor release.
- Never release a patch just because it is ready — wait and bundle it into a minor release.

This prevents micro-release noise (e.g., shipping `2.2.1` and `2.2.2` on the same day) and ensures every release is meaningful to users.

## Monotonic Version Rule

**Platform versions may never decrease.** Once a version is published to a registry (PyPI, CRAN, SSC) or tagged on GitHub:
- You cannot re-release the same version number with different content.
- You cannot release a lower version number on the same platform.
- If a release is mistakenly tagged, create a new incremented tag — never delete and re-tag.
- PyPI, CRAN, and SSC all enforce this at the registry level; GitHub tags must follow the same principle.

## GitHub Release Tag Policy

The GitHub release tag represents the **repository release**, independent of any individual platform version.

- Tag format: `vMAJOR.MINOR.PATCH` (e.g., `v2.4.0`)
- The tag increments whenever any platform ships a new release.
- MAJOR.MINOR tracks the highest shared minor version across platforms; PATCH increments with each release bundle.
- Release notes must document the current version of **each platform**:
  ```
  R:      X.Y.Z
  Python: X.Y.Z
  Stata:  X.Y.Z
  ```
- The GitHub tag must also be strictly increasing — never lower than the previous tag.

## Platform Version Locations

| Platform | Version file(s) |
|---|---|
| R | `r/DESCRIPTION` (`Version:` field) |
| Python | `python/unicefdata/__init__.py` (`__version__`) and `python/pyproject.toml` |
| Stata | `stata/src/unicefdata.pkg` (`v` line) and ADO headers (`*! v X.Y.Z  DDMMMYYYY`) |

## When to Change Version
- **Bump version at release time** (develop → main), not on every merge to develop.
- Use **pre-release tags** when needed: `vX.Y.Z-rc.1`, `-beta.1`.

## Test Gating Policy
- **Required to release:** All P0 and P1 tests pass.
- **Optional:** P2 (edge/perf) may be allowed with documented issues or pre-release tags.
- Run the full suite before tagging:
  - Stata: `do stata/qa/run_tests.do`

## Release Flow (develop → main)
1. Merge feature PRs into `develop`.
2. Ensure CI green on P0/P1.
3. Update versions consistently in all platform version files (see table above).
4. Build SSC package: `stata/ssc/update_zip.ps1`.
5. Tag: `git tag -a vX.Y.Z -m "Release vX.Y.Z"; git push origin vX.Y.Z`.
6. Publish GitHub Release with notes documenting each platform's version, changes, and test status.

## Branching & Artifacts
- Feature branches from `develop`; merge to `develop`; then release to `main`.
- Track SSC `.zip` in `stata/ssc/`; ignore `stata/ssc/temp_unzip/`.
- Keep LaTeX build artifacts out of git; keep source `.tex/.bib/.sty/.cls` + final `.pdf`.

## Notes
- Prefer Conventional Commits to automate bump decisions.
- Use pre-release tags if you must share builds before all tests pass.
