## Resubmission - v2.3.0

This is a resubmission addressing reviewer feedback from:
* **Benjamin Altmann (2026-02-19)** — Cache directory compliance
* **Uwe Ligges (2026-02-10)** — Software name quoting and DESCRIPTION metadata

### Changes Since Last Submission

* Moved cache directory from `.unicef_cache/` to `tempdir()` for CRAN policy compliance (primary issue)
* Replaced `cat()` with `message()` in user-facing output functions
* Changed `\dontrun{}` to `\donttest{}` for examples that require network access only; kept `\dontrun{}` for examples requiring local state
* Reworded DESCRIPTION to lead with "An R client..." (trilingual suite mentioned secondarily)
* Removed `devtools` from Suggests (development-only dependency)
* Bundled test fixtures for offline deterministic testing

### Previously Addressed (v2.2.0)

* Single-quoted software names ('Python', 'Stata') in Description
* Added UNICEF Data Warehouse URL in Description
* Fixed LICENSE file format (DCF stub)
* Removed `unlockBinding()` — refactored to use `new.env()` environments
* Replaced Unicode symbols with ASCII in roxygen documentation
* Added missing `@return` tags

## R CMD check results

0 errors | 0 warnings | 2 notes

**NOTE 1** (CRAN incoming feasibility): New submission.

**NOTE 2** (Spell check): Possibly misspelled words in DESCRIPTION:
* SDG — Sustainable Development Goals (UN framework)
* SDMX — Statistical Data and Metadata eXchange (ISO 17369 standard)
* lookups — standard English term
* memoisation — British English spelling (standard in computer science)

All terms are correct and domain-specific.

## URL Checks

URLs pointing to `https://data.unicef.org/` may return HTTP 403 to automated checkers (UNICEF uses bot detection). The URLs are valid and accessible in any browser. The SDMX API endpoint (`https://sdmx.data.unicef.org/`) responds correctly.

## Test Environments

* Windows 10 x64, R 4.5.1 (local)
* macOS (latest), R release (GitHub Actions)
* Windows (latest), R release (GitHub Actions)
* Ubuntu 22.04, R release / R devel / R oldrel-1 (GitHub Actions)

All tests pass on all platforms (0 errors | 0 warnings).

## Downstream Dependencies

None (new package).
