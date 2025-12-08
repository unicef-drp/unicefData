# Archived Stata Commands

This folder contains deprecated Stata ado files that are no longer used in the active codebase.

## Archived Files

| File | Original Location | Reason for Deprecation |
|------|-------------------|------------------------|
| `unicefdata_xmlmata.ado` | `src/u/` | Experimental Mata XML parser - never integrated into main flow |
| `_xmltoyaml_parse_chunked.ado` | `src/_/` | Chunked parser for large files - never called by any command |
| `_xmltoyaml_process_chunk.ado` | `src/_/` | Helper for chunked parser - only used by unused chunked parser |
| `_xmltoyaml_write_element.ado` | `src/_/` | Helper for writing YAML elements - not used by active parsers |
| `unicefdata_sync_working.ado` | `tests/` | Old backup version of sync command (v1.0.0 vs current v1.1.0) |

## Archive Date

2025-12-07

## Notes

These files were archived as part of a codebase cleanup. They may contain useful reference code or ideas for future development but are not required for current functionality.

The active parsing pipeline now uses:
- `unicefdata_xmltoyaml.ado` - Main XML→YAML wrapper
- `unicefdata_xmltoyaml_py.ado` - Python-based parser
- `_xmltoyaml_parse.ado` - Parser dispatcher
- `_xmltoyaml_parse_python.ado` - Python interface
- `_xmltoyaml_parse_stata.ado` - Pure Stata parser
- `_xmltoyaml_parse_lines.ado` - Line-by-line helper
- `_xmltoyaml_get_schema.ado` - Schema registry
