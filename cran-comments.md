## Resubmission

This is a resubmission addressing reviewer feedback from Uwe Ligges
(2026-02-10):

* **Single-quoted software name**: Changed `Stata` to `'Stata'` in the
  Description field, per CRAN policy for non-R software names.

* **Added URL**: Added the UNICEF Data Warehouse URL
  `<https://data.unicef.org/>` in the Description field.

Previous changes (still included):

* **LICENSE file (invalid DCF)**: Replaced full MIT license text with proper
  2-line DCF stub (YEAR + COPYRIGHT HOLDER).

* **`unlockBinding()` removed**: Refactored mutable metadata caches to use
  dedicated `new.env()` environments instead of locked namespace bindings.

* Replaced Unicode symbols in roxygen documentation with ASCII equivalents
  to fix PDF manual generation on CRAN's LaTeX infrastructure.

* Added missing `@return` tags, removed duplicate definitions.

## R CMD check results

0 errors | 0 warnings | 2 notes

* NOTE (CRAN incoming feasibility): New submission. VignetteBuilder field
  present with pre-built vignettes in `inst/doc/`. URLs returning HTTP 403
  are explained below.

* NOTE: Possibly misspelled words in DESCRIPTION: SDG, SDMX, lookups,
  memoisation, trilingual. These are all correct domain-specific terms:
  SDG (Sustainable Development Goals), SDMX (Statistical Data and Metadata
  eXchange, ISO standard), lookups (standard English), memoisation (British
  spelling), trilingual (standard English).

## URL checks

URLs pointing to https://data.unicef.org/ return HTTP 403 to automated URL
checkers. The UNICEF Data Portal uses bot detection that blocks crawlers, but
the URLs are valid and accessible in any browser. These are permanent
institutional URLs maintained by UNICEF. The SDMX API endpoint
(https://sdmx.data.unicef.org/) used by the package responds correctly.

## Test environments

* Windows 10 x64, R 4.5.1 (local)
* macOS (latest), R release (GitHub Actions)
* Windows (latest), R release (GitHub Actions)
* Ubuntu 22.04, R release (GitHub Actions)
* Ubuntu 22.04, R devel (GitHub Actions)
* Ubuntu 22.04, R oldrel-1 (GitHub Actions)

## Vignettes

Vignettes are pre-built and included in `inst/doc/`. The source .Rmd files
(with `eval = FALSE` on all code chunks) are included in `vignettes/` for
reference but do not require network access or Pandoc for installation.

## Downstream dependencies

This is a new submission. There are no downstream dependencies.

## Additional notes

* This package provides a unified interface to UNICEF SDMX Data API across
  R, Python, and Stata. The R package includes comprehensive tests (>25 tests)
  and documentation for all exported functions.
* All examples run successfully and tests pass on all platforms.
* Package has been in development use for 6 months with positive feedback
  from UNICEF data users.
