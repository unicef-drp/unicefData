# GitHub Actions Workflows

This directory contains automated CI/CD workflows for the unicefdata package.

## Workflows

### 1. Validate Metadata Schemas (`validate-schemas.yml`)

**Purpose**: Validates YAML metadata files against expected schemas.

**Triggers**:
- Push to main, xcross-platform-validation, or development branches
- Pull requests to main
- Changes to metadata YAML files or validator script
- Manual dispatch

**What it validates**:
- ✓ Indicator metadata has complete enrichment (tier, disaggregations)
- ✓ tier_counts accuracy matches actual distribution
- ✓ Dataflow index structure
- ✓ All metadata files have proper YAML structure

**Runtime**: ~30 seconds

**Benefits**:
- Catches schema regressions before merge
- No Stata license required
- Fast feedback loop
- Prevents bad metadata from reaching main branch

**Exit codes**:
- 0 = All validations passed
- 1 = At least one validation failed

### 2. Validate Python Scripts (`validate-python.yml`)

**Purpose**: Validates Python script syntax and imports.

**Triggers**:
- Push to main, xcross-platform-validation, or development branches
- Pull requests to main
- Changes to Python scripts
- Manual dispatch

**What it validates**:
- ✓ Python syntax (py_compile)
- ✓ Import statements work
- ✓ Scripts can be imported without errors
- ✓ Key scripts have help functionality

**Runtime**: ~20 seconds

**Benefits**:
- Catches Python syntax errors early
- Validates import dependencies
- Ensures scripts are executable
- Quick sanity check before deployment

## Running Workflows Locally

### Validate Schemas
```bash
cd C:\GitHub\myados\unicefData-dev
python stata/src/py/validate_yaml_schema.py indicators stata/src/_/_unicefdata_indicators_metadata.yaml
python stata/src/py/validate_yaml_schema.py dataflow_index stata/src/_/_dataflow_index.yaml
```

### Validate Python Syntax
```bash
cd C:\GitHub\myados\unicefData-dev
python -m py_compile stata/src/py/*.py
```

## Stata Tests (Not in CI)

Full Stata test suite (37 tests) is **not** in GitHub Actions because:
- Requires Stata license
- Requires API access to UNICEF SDMX endpoint
- Takes ~10 minutes to run
- More appropriate for local testing or nightly runs

To run full Stata tests:
```stata
cd "C:\GitHub\myados\unicefData-dev\stata\qa"
global run_sync = 1
do run_tests.do
```

## Future Enhancements

Potential additional workflows:

1. **Nightly Full Tests**:
   - Use self-hosted runner with Stata
   - Run complete test suite
   - Report to Slack/email

2. **API Health Check**:
   - Ping UNICEF SDMX endpoint
   - Verify key dataflows accessible
   - Alert if API down

3. **Package Build**:
   - Test package installation
   - Verify all files present in .pkg
   - Build distribution archive

4. **Documentation Check**:
   - Validate .sthlp files compile
   - Check for broken links
   - Verify examples run

## Viewing Results

GitHub Actions results are visible at:
`https://github.com/your-org/unicefData-dev/actions`

Each workflow run shows:
- ✅ Pass/Fail status for each step
- Detailed logs
- Summary with validation results
- Artifacts (if any)

## Troubleshooting

### Schema validation fails
1. Check which file failed in workflow logs
2. Run validator locally to see detailed errors
3. Re-sync metadata if corrupted: `unicefdata_sync, all`

### Python validation fails
1. Check syntax error line in logs
2. Verify imports are available: `pip install pyyaml requests`
3. Test script locally: `python stata/src/py/<script>.py`

### Workflow doesn't trigger
1. Check file path filters in `on.push.paths`
2. Verify branch name matches trigger
3. Manually trigger with `workflow_dispatch`

## Contributing

When adding new workflows:
1. Test locally first
2. Use meaningful names and descriptions
3. Add summary output using `$GITHUB_STEP_SUMMARY`
4. Document in this README
5. Set appropriate triggers (don't spam on every commit)
