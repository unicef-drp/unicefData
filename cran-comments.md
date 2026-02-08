## R CMD check results

0 errors | 0 warnings | 2 notes

* NOTE: `unlockBinding()` calls in `unicef_core.R` are intentional for
  cache invalidation of locked namespace bindings (`.INDICATORS_METADATA_YAML`,
  `.REGION_CODES_YAML`). These are wrapped in `tryCatch()` for safety.

* NOTE: `lastMiKTeXException` in temp directory is a local MiKTeX artifact,
  not produced by the package.

## Test environments

* Windows 10 x64, R 4.5.1 (local)
* macOS (latest), R release (GitHub Actions)
* Windows (latest), R release (GitHub Actions)
* Ubuntu 22.04, R release (GitHub Actions)
* Ubuntu 22.04, R devel (GitHub Actions)
* Ubuntu 22.04, R oldrel-1 (GitHub Actions)

## Downstream dependencies

This is a new submission. There are no downstream dependencies.
