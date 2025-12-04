# GitHub Copilot Instructions - unicefData Repository

## Overview
This repository contains UNICEF data tools and utilities for working with UNICEF datasets, metadata, and APIs. It includes Python modules for data access and Stata commands for statistical analysis.

## Repository Structure

### Key Technologies Used
- **Python** (3.9+): Data access, API wrappers, metadata management
- **Stata** (16+): Statistical analysis commands and data utilities

### Local Environment Paths
- **Stata Executable**: `C:\Program Files\Stata17\StataMP-64.exe`
- **Python Virtual Environment**: Project-specific `.venv`

### Main Components

#### Python Modules (`python/`)
- `metadata/`: UNICEF indicator metadata management
- `api/`: API wrappers for UNICEF data portals
- `utils/`: Utility functions for data processing

#### Stata Commands (`stata/`)
- `src/y/yaml.ado`: YAML file parser for Stata (read, write, validate YAML files)
- `src/`: Additional Stata commands and utilities
- `tests/`: Test scripts for Stata commands

### Development Guidelines

#### Stata Development
- Use Stata version 16+ for frame support
- Test all ado files with the test scripts in `stata/tests/`
- Follow Stata naming conventions (lowercase, underscores)

#### Python Development
- Use type hints for function signatures
- Document functions with docstrings
- Follow PEP 8 style guidelines

### Running Tests

#### Stata Tests
```stata
* Run from Stata or use:
* "C:\Program Files\Stata17\StataMP-64.exe" /e do "stata/tests/test_yaml_unicef_metadata.do"
```

#### Python Tests
```bash
pytest python/tests/
```
