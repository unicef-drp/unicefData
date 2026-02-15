# unicefData Versioning Policy

This document describes the versioning rules for the unicefData trilingual package
(R, Python, Stata) and the package release process.

Adapted from the wbopendata versioning policy (`wbopendata-dev/doc/VERSIONING_POLICY.md`).

## Principles

- Maintain two version tracks:
  - **Package-level (per-platform)**: Each platform (R, Python, Stata) has its own
    package version that advances independently.
  - **Component-level (per-file)**: Every source file keeps a version header.
- Platform package versions only need to align when the same substantive changes
  are made across platforms. A Stata-only bugfix bumps only the Stata package version;
  an R-only feature bumps only the R version. Cross-platform releases that touch all
  three should use the same version number.

## Package-Level Version Sources

| Platform | File | Field |
|----------|------|-------|
| R | `DESCRIPTION` | `Version:` |
| Python | `python/pyproject.toml` | `version =` |
| Python | `python/unicefdata/__init__.py` | `__version__` |
| Stata | `stata/src/u/unicefdata.ado` | `*! v X.Y.Z` header |
| All | `CITATION.cff` | `version:` |
| All | `CHANGELOG.md` | Section header |

Within each platform, its canonical locations must agree. Cross-platform alignment
is only required when the release includes equivalent substantive changes on all
platforms.

## Per-File Versioning

Use Semantic Versioning semantics per file:
- **Patch**: Bugfix or non-behavioral changes.
- **Minor**: Backward-compatible feature additions.
- **Major**: Breaking API changes.

### Header format by language

**Stata (.ado)**:
```
*! v 2.2.0  10Feb2026               by Joao Pedro Azevedo (UNICEF)
```

**Python (.py)** — in the module docstring or as a comment in the first 10 lines:
```python
# Version: 2.1.0 (2026-02-07)
```

**R (.R)** — as a comment in the first 10 lines:
```r
# Version: 2.1.0 (2026-02-07)
```

**YAML (.yaml)** — as a top-level field or comment:
```yaml
# version: 2.0.0
```

### Normalization

- Normalize legacy headers (e.g., `v 16.3` or `v 10`) to `X.Y.Z` format
  when editing the file. `v 16.3` becomes `16.3.0`; `v 10` becomes `10.0.0`.
- Don't mass-rewrite historic files. Normalize when you touch a file.

## Package Release Rules

1. Any file modified in a release MUST have its header version bumped appropriately.
2. Within each platform, canonical version locations must match (e.g., `pyproject.toml`
   and `__init__.py` for Python). Cross-platform alignment is needed only for releases
   with equivalent substantive changes on all three platforms.
3. Release type (patch/minor/major) is determined by the highest-impact change.
4. Use Conventional Commits: `feat:`, `fix:`, `feat!:` / `BREAKING CHANGE:`.

## Automation

Two scripts in `scripts/`:

- **`update_component_versions.py`** — scans all source files across R, Python,
  and Stata for version headers and generates `doc/__COMPONENT_VERSIONS.yaml`.
- **`check_versions.py <base-ref>`** — compares modified files in a git diff
  against `<base-ref>` and exits non-zero if any modified file lacks a version bump.

## Workflow Checklist for Contributors

### Before opening a PR

1. Bump headers for every modified source file (R, Python, or Stata).
2. Run:
   ```
   python scripts/update_component_versions.py
   ```
   This writes `doc/__COMPONENT_VERSIONS.yaml`. Commit the updated file.
3. Add an entry to `CHANGELOG.md` with component versions and user-facing notes.

### For release PRs

1. Update the canonical version locations for each affected platform.
2. Ensure `CHANGELOG.md` and `NEWS.md` have the release entry.
3. Tag with `git tag -a vX.Y.Z -m "Release vX.Y.Z"` and push.
   For platform-specific releases, use platform-prefixed tags (e.g.,
   `stata-v2.2.0`, `python-v2.1.1`) or a unified tag if all platforms advance.

## CI Recommendations

- Add a CI job that runs `python scripts/check_versions.py origin/main` and
  fails when modified files don't bump version headers.
- Run `update_component_versions.py` in CI and diff against the committed
  `__COMPONENT_VERSIONS.yaml` to catch uncommitted version changes.

## Current State (as of 2026-02-13)

| Platform | Package Version | Per-File Coverage |
|----------|----------------|-------------------|
| R | 2.1.0 | 0/18 .R files have headers |
| Python | 2.1.1 | 2/15 .py files have headers |
| Stata | 2.2.0 | 35+ .ado files have headers |

**Note**: Platform versions are intentionally independent. R=2.1.0 reflects the
last R release, Python=2.1.1 reflects a Python-only bugfix, Stata=2.2.0 reflects
Stata-only features. Add headers to R/Python files as they are touched (don't
mass-rewrite).

## Contact

- Author: Joao Pedro Azevedo
- Repo: https://github.com/unicef-drp/unicefData
