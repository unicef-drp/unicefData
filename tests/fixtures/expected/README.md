# Expected Output Fixtures

This directory contains expected output data that all three language implementations
(Python, R, Stata) should produce when processing the same input fixtures.

## Purpose

Cross-language validation: given the same API response CSV, all three implementations
should produce structurally equivalent output. These files define the expected
column names, data types, row counts, and value ranges.

## Files

### expected_columns.csv
Canonical column mapping from raw SDMX columns to the standardized output
columns that unicefData() should produce across all languages.

### expected_cme_albania_output.csv
Expected processed output when loading `api_responses/cme_albania_valid.csv`.
Columns use the standardized names (iso3, indicator, period, value, etc.).

### expected_nutrition_multi_output.csv
Expected processed output when loading `api_responses/nutrition_multi_country.csv`.

### expected_error_messages.csv
Expected error message patterns for common failure scenarios across all languages.

## Usage

Each cross-language validation test loads an API response fixture, processes it
through the language-specific implementation, and compares against the expected
output defined here.
