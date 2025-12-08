# Stata YAML Command

A native Stata command for reading, writing, and manipulating YAML configuration files.

## Overview

The `yaml` command provides a complete YAML 1.2 (subset) parser for Stata, enabling configuration-driven workflows, metadata management, and interoperability with other languages (R, Python, GitHub Actions).

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              yaml.ado                                        │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│   ┌─────────┐    ┌─────────┐    ┌──────────┐    ┌─────────┐                │
│   │  read   │    │  write  │    │ describe │    │  list   │                │
│   └────┬────┘    └────┬────┘    └────┬─────┘    └────┬────┘                │
│        │              │              │               │                      │
│   ┌────┴────┐    ┌────┴────┐    ┌────┴─────┐    ┌───┴────┐                 │
│   │   get   │    │validate │    │  frames  │    │  clear │                 │
│   └─────────┘    └─────────┘    └──────────┘    └────────┘                 │
│                                                                              │
├─────────────────────────────────────────────────────────────────────────────┤
│                         Internal Storage                                     │
│  ┌────────────────────────────────────────────────────────────────────┐     │
│  │  Dataset/Frame Structure:                                          │     │
│  │  ┌──────────┬────────────┬───────┬────────────┬──────────┐        │     │
│  │  │   key    │   value    │ level │   parent   │   type   │        │     │
│  │  ├──────────┼────────────┼───────┼────────────┼──────────┤        │     │
│  │  │ str244   │ str2000    │ int   │ str244     │ str32    │        │     │
│  │  └──────────┴────────────┴───────┴────────────┴──────────┘        │     │
│  └────────────────────────────────────────────────────────────────────┘     │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Subcommands

| Command | Description |
|---------|-------------|
| `yaml read` | Parse YAML file into Stata dataset or frame |
| `yaml write` | Export dataset/frame back to YAML format |
| `yaml describe` | Display structure of loaded YAML data |
| `yaml list` | List keys, values, or children of a key |
| `yaml get` | Retrieve attributes of a specific key |
| `yaml validate` | Validate required keys and types |
| `yaml frames` | List all YAML frames in memory |
| `yaml clear` | Clear YAML data from memory |

## Data Model

### Storage Structure

YAML data is stored in a flat dataset with hierarchical references:

| Column | Type | Description |
|--------|------|-------------|
| `key` | str244 | Full hierarchical key name (e.g., `indicators_CME_MRY0T4_label`) |
| `value` | str2000 | The value associated with the key |
| `level` | int | Nesting depth (1 = root level) |
| `parent` | str244 | Parent key for hierarchical lookups |
| `type` | str32 | Value type: `string`, `numeric`, `boolean`, `parent`, `list_item`, `null` |

### Key Naming Convention

Keys are flattened using underscores to represent hierarchy:

```yaml
# YAML input:
indicators:
  CME_MRY0T4:
    label: Under-five mortality rate
    unit: Deaths per 1000 live births
```

```
# Stored as:
key                              value                         parent                  type
─────────────────────────────────────────────────────────────────────────────────────────────
indicators                       (empty)                       (empty)                 parent
indicators_CME_MRY0T4            (empty)                       indicators              parent
indicators_CME_MRY0T4_label      Under-five mortality rate     indicators_CME_MRY0T4   string
indicators_CME_MRY0T4_unit       Deaths per 1000 live births   indicators_CME_MRY0T4   string
```

### List Item Storage

YAML lists are stored as indexed separate rows:

```yaml
# YAML input:
countries:
  - BRA
  - ARG
  - CHL
```

```
# Stored as:
key             value   parent      type
────────────────────────────────────────────
countries       (empty) (empty)     parent
countries_1     BRA     countries   list_item
countries_2     ARG     countries   list_item
countries_3     CHL     countries   list_item
```

## Syntax

### yaml read

```stata
yaml read using filename.yaml [, options]
```

**Options:**
- `replace` - Replace existing data
- `frame(name)` - Load into named frame (Stata 16+)
- `locals` - Store values as return locals
- `scalars` - Store numeric values as scalars
- `prefix(string)` - Prefix for local/scalar names (default: `yaml_`)
- `verbose` - Display parsing details

### yaml write

```stata
yaml write using filename.yaml [, options]
```

**Options:**
- `replace` - Overwrite existing file
- `frame(name)` - Write from named frame
- `scalars(list)` - Write specified scalars
- `indent(#)` - Indentation spaces (default: 2)
- `header(string)` - Custom header comment
- `verbose` - Display write progress

### yaml get

```stata
yaml get keyname [, options]
yaml get parent:child [, options]
```

**Options:**
- `frame(name)` - Read from named frame
- `attributes(list)` - Specific attributes to retrieve
- `quiet` - Suppress output

**Returns:**
- `r(found)` - 1 if key found
- `r(n_attrs)` - Number of attributes
- `r(key)` - Key name
- `r(parent)` - Parent name (if colon syntax used)
- `r(attr_name)` - Value for each attribute

### yaml list

```stata
yaml list [keyname] [, options]
```

**Options:**
- `keys` - Show key names
- `values` - Show values
- `children` - List child keys only
- `level(#)` - Filter by nesting level
- `frame(name)` - Read from named frame

### yaml validate

```stata
yaml validate [, options]
```

**Options:**
- `required(keylist)` - Check that keys exist
- `types(key:type ...)` - Validate key types
- `frame(name)` - Validate named frame
- `quiet` - Suppress output, only set return values

**Returns:**
- `r(valid)` - 1 if validation passed
- `r(n_errors)` - Number of errors
- `r(n_warnings)` - Number of warnings
- `r(missing_keys)` - List of missing required keys
- `r(type_errors)` - List of type validation failures

### yaml describe

```stata
yaml describe [, level(#) frame(name)]
```

### yaml frames

```stata
yaml frames [, detail]
```

### yaml clear

```stata
yaml clear [, all frame(name)]
```

## Supported YAML Features

### ✅ Supported

| Feature | Example |
|---------|---------|
| Key-value pairs | `key: value` |
| Nested mappings | Indentation-based hierarchy |
| Comments | `# This is a comment` |
| Strings | `name: "quoted"` or `name: unquoted` |
| Numbers | `count: 100`, `rate: 3.14` |
| Booleans | `debug: true`, `verbose: false` |
| Null values | `empty:` or `empty: null` |
| Lists/Sequences | `- item1`, `- item2` |

### ❌ Not Supported

| Feature | Reason |
|---------|--------|
| Anchors & Aliases | `&anchor`, `*alias` - Complex to implement |
| Multi-line blocks | `|`, `>` - Requires special handling |
| Flow style | `{a: 1, b: 2}`, `[1, 2, 3]` - JSON-like inline |
| Custom tags | `!!map`, `!!seq` - Advanced YAML |

## Examples

### Basic Usage

```stata
* Read YAML configuration
yaml read using config.yaml, replace

* View structure
yaml describe

* Get specific indicator metadata
yaml get indicators:CME_MRY0T4
return list

* Use returned values
local label = r(label)
local unit = r(unit)
di "Indicator: `label' (`unit')"
```

### Validation

```stata
* Load and validate configuration
yaml read using pipeline_config.yaml, replace

* Check required keys exist
yaml validate, required(name version database api)

* Validate types
yaml validate, types(database_port:numeric api_timeout:numeric debug:boolean)

* Check validation result
if (r(valid) == 0) {
    di as error "Configuration validation failed!"
    exit 198
}
```

### Working with Frames (Stata 16+)

```stata
* Load multiple configurations into frames
yaml read using dev_config.yaml, frame(dev)
yaml read using prod_config.yaml, frame(prod)

* List loaded frames
yaml frames, detail

* Get from specific frame
yaml get database:host, frame(dev)
local dev_host = r(host)

yaml get database:host, frame(prod)
local prod_host = r(host)

* Clear specific frame
yaml clear, frame(dev)
```

### Round-trip: Read and Write

```stata
* Read configuration
yaml read using original.yaml, replace

* Modify values
replace value = "new_value" if key == "settings_timeout"

* Write back
yaml write using modified.yaml, replace
```

### Working with Lists

```stata
* Read YAML with lists
yaml read using countries.yaml, replace

* List items in a list
yaml list countries, keys children

* Access individual list items
yaml get countries
* Returns: r(1)="BRA" r(2)="ARG" r(3)="CHL"
```

## Version Requirements

| Feature | Minimum Stata Version |
|---------|----------------------|
| Basic functionality | Stata 14.0 |
| Frame support | Stata 16.0 |

## File Location

```
unicefData/
└── stata/
    └── src/
        └── y/
            ├── yaml.ado      # Main command file
            └── README.md     # This documentation
```

## Design Principles

1. **YAML 1.2 Subset**: Implements the most commonly used YAML features that cover 95%+ of configuration use cases.

2. **JSON Compatibility**: The supported subset is fully JSON-compatible, enabling easy data exchange.

3. **Stata-Native**: Pure Stata implementation using `file read/write` - no external dependencies.

4. **Hierarchical Storage**: Flat storage with parent references enables both simple key-value access and hierarchical queries.

5. **Frame Support**: Optional frame storage keeps YAML data separate from working datasets.

6. **Validation First**: Built-in validation ensures configuration correctness before pipeline execution.

## Use Cases

- **Pipeline Configuration**: Database connections, API endpoints, timeouts
- **Metadata Management**: Indicator definitions, variable labels, units
- **Cross-language Workflows**: Share configs with R, Python, GitHub Actions
- **Reproducible Research**: Version-controlled configuration files
- **Multi-environment Support**: Dev/staging/prod configurations in separate frames

## Author

Joao Pedro Azevedo

## License

MIT License
