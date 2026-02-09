# Contributing to unicefData

Thank you for your interest in contributing to the **unicefData** package.

## Reporting Issues

- Open an [issue](https://github.com/unicef-drp/unicefData/issues) with a clear description
- Include the platform (R, Python, or Stata), version, and steps to reproduce
- Attach sample code or error output when possible

## Development Setup

```bash
git clone https://github.com/unicef-drp/unicefData.git
cd unicefData
```

### R

```r
devtools::load_all()
devtools::test()
```

### Python

```bash
cd python
pip install -e .
pytest tests/
```

### Stata

```stata
cd stata
do install_local.do
```

## Branching Strategy

- Create feature branches from `develop` (e.g., `feature/my-change`)
- Open pull requests targeting `develop`, not `main`
- Releases are merged from `develop` to `main` with version tags

## Commit Conventions

We follow [Conventional Commits](https://www.conventionalcommits.org/):

| Prefix | Meaning | Version Impact |
|--------|---------|----------------|
| `fix:` | Bug fix | Patch |
| `feat:` | New feature | Minor |
| `feat!:` / `BREAKING CHANGE:` | Breaking change | Major |
| `docs:` | Documentation only | None |
| `test:` | Test additions/fixes | None |
| `chore:` | Maintenance | None |

## Cross-Platform Consistency

This is a trilingual package (R, Python, Stata). When modifying shared behavior:

1. Update **all three platforms** to maintain API parity
2. Run tests on all platforms before submitting
3. Update platform-specific READMEs as needed

| Platform | Primary File | Tests |
|----------|-------------|-------|
| R | `R/unicefData.R` | `devtools::test()` |
| Python | `python/unicefdata/unicefdata.py` | `pytest python/tests/` |
| Stata | `stata/src/u/unicefdata.ado` | `do stata/qa/run_tests.do` |

## Pull Request Guidelines

- Keep PRs focused on a single change
- Include a clear description of what changed and why
- Reference related issues (e.g., "Fixes #42")
- Ensure all P0/P1 tests pass before requesting review

## Documentation

- Update `NEWS.md` for user-facing changes
- For R: update roxygen2 comments and run `devtools::document()`
- For Stata: update the `.sthlp` help files manually
- For Python: update docstrings inline

## License

By contributing, you agree that your contributions will be licensed under the [MIT License](LICENSE).
