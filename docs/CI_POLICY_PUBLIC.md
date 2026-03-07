# CI/CD Reliability Policy (Public Repo)

This document defines the **public-facing reliability guarantees** for the `unicefData` repository.

## Scope

This policy covers:
- GitHub Actions workflows in `.github/workflows/`
- quality gates for merge and release paths
- metadata validation and refresh behavior

This policy does **not** include internal operational runbooks or dev-only implementation plans.

## Reliability Guarantees

1. **Required checks before merge**
   - R-CMD-check
   - Python tests
   - schema validation

2. **Deterministic metadata validation**
   - critical metadata/schema checks must fail fast on real regressions
   - warnings are allowed only for non-critical checks

3. **Scheduled metadata refresh transparency**
   - scheduled refresh failures are visible in Actions history
   - remediation should be traceable via workflow logs and issue/PR history

4. **Branch safety**
   - `main` and integration branches should be protected with required checks

## What users can expect

- Regressions in core package behavior should be caught by CI before release branches advance.
- Metadata/schema-breaking changes should be visible quickly through validation workflows.
- Public releases should reflect validated, reviewable changes.

## Incident reporting

If you identify CI/CD behavior that appears inconsistent with this policy:
- open an issue with workflow run URL(s), failing job/step, and expected behavior.

## Notes

Operational implementation details and migration plans are maintained in the development repository and are intentionally not duplicated here.
