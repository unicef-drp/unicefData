## Resubmission

This is a resubmission. The previous submission was archived due to a LaTeX
error caused by Unicode characters in Rd files. Changes in this version:

* Replaced Unicode symbols in roxygen documentation with ASCII equivalents
  (U+2265 `>=`, U+2192 `-->`, smart quotes removed) to fix PDF manual
  generation on CRAN's LaTeX infrastructure.

## R CMD check results

0 errors | 0 warnings | 4 notes

* NOTE: New submission.

* NOTE: Possibly misspelled words in DESCRIPTION: SDG, SDMX, Stata, lookups,
  memoisation, trilingual. These are all correct domain-specific terms:
  SDG (Sustainable Development Goals), SDMX (Statistical Data and Metadata
  eXchange, ISO standard), Stata (statistical software), lookups (standard
  English), memoisation (British spelling), trilingual (standard English).

* NOTE: "License stub is invalid DCF" - The package uses a standard MIT license
  with a LICENSE file. The DESCRIPTION correctly specifies "MIT + file LICENSE".

* NOTE: `unlockBinding()` calls in `unicef_core.R` are intentional for
  cache invalidation of locked namespace bindings (`.INDICATORS_METADATA_YAML`,
  `.REGION_CODES_YAML`). These are wrapped in `tryCatch()` for safety.

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
