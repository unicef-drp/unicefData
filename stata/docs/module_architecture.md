# unicefData Stata Package — Module Architecture

## Module Dependency Diagram

```mermaid
graph LR
    subgraph Entry["Entry Points"]
        UD["unicefdata.ado\n(dispatcher)"]
        GS["get_sdmx.ado\n(SDMX fetcher)"]
        EX["unicefdata_examples.ado"]
    end

    subgraph Subcommands["Subcommands"]
        FLOWS["__unicef_list_dataflows\n(list dataflows)"]
        SEARCH["__unicef_search_indicators\n(keyword search)"]
        LISTIND["__unicef_list_indicators\n(list indicators)"]
        INFO["__unicef_indicator_info\n(indicator details)"]
        DFINFO["__unicef_dataflow_info\n(dataflow details)"]
        SYNC["unicefdata_sync.ado\n(metadata sync)"]
    end

    subgraph Fetch["Data Fetching"]
        FETCH["__unicef_fetch_paged\n(paged CSV fetch)"]
        BKEY["__unicef_build_schema_key\n(SDMX key builder)"]
        FILT["__unicef_get_indicator_filters\n(schema dimensions)"]
        DFDIR["__get_dataflow_direct\n(indicator→dataflow)"]
        DISAGG["__unicef_get_disagg_totals\n(totals dimensions)"]
        RENAME["__get_sdmx_rename_year_columns\n(wide-format columns)"]
    end

    subgraph Meta["Metadata / YAML"]
        XML2Y["unicefdata_xmltoyaml.ado\n(XML→YAML converter)"]
        XML2YPY["unicefdata_xmltoyaml_py.ado\n(Python XML backend)"]
        XMLPARSE["__xmltoyaml_parse\n(parse dispatcher)"]
        XMLSCHEMA["__xmltoyaml_get_schema\n(schema registry)"]
        XMLPY["__xmltoyaml_parse_python\n(Python parser)"]
        XMLST["__xmltoyaml_parse_stata\n(Stata parser)"]
        XMLLINES["__xmltoyaml_parse_lines\n(line parser)"]
        PARSEYAML["__unicef_parse_indicator_yaml\n(single-indicator)"]
        PARSEALL["__unicef_parse_indicators_yaml\n(full catalog)"]
        PARSEV2["__unicef_parse_ind_yaml_v2\n(v2 via yaml.ado)"]
        LOADCACHE["__unicef_load_indicators_cache\n(frame cache)"]
        SYNCDF["__unicefdata_sync_dataflow_index\n(dataflow index)"]
        SYNCSCH["__unicefdata_sync_df_schema\n(schema writer)"]
        SYNCIND["__unicefdata_sync_ind_meta\n(indicator catalog)"]
        SYNCHIST["__unicefdata_update_sync_history\n(history writer)"]
        REFRESH["unicefdata_refresh_all.ado\n(full refresh)"]
    end

    subgraph Infra["Shared Infrastructure"]
        YAML["yaml.ado\n(YAML dispatcher)"]
        YREAD["yaml_read.ado"]
        YWRITE["yaml_write.ado"]
        YGET["yaml_get.ado"]
        YLIST["yaml_list.ado"]
        YDESC["yaml_describe.ado"]
        YDIR["yaml_dir.ado"]
        YCLEAR["yaml_clear.ado"]
        YFRAMES["yaml_frames.ado"]
        YVALID["yaml_validate.ado"]
        YMATA["__yaml_mataread\n(Mata bulk parser)"]
        YFAST["__yaml_fastread\n(shallow parser)"]
        YCOLL["__yaml_collapse\n(long→wide pivot)"]
        YTOK["__yaml_tokenize_line\n(streaming tokenizer)"]
        SETUP["__unicefdata_setup\n(install metadata)"]
        CHKYAML["__unicefdata_check_yaml\n(yaml.ado version)"]
        SETDF["__set_default_dataflows\n(fallback globals)"]
        LW["__linewrap\n(text wrapping)"]
        MLW["__metadata_linewrap\n(graph labels)"]
    end

    %% --- Entry → Subcommands ---
    UD --> FLOWS
    UD --> SEARCH
    UD --> LISTIND
    UD --> INFO
    UD --> DFINFO
    UD --> SYNC
    EX --> UD

    %% --- Entry → Data Fetching ---
    UD --> GS
    UD --> DFDIR
    UD --> DISAGG
    UD --> BKEY
    UD --> FILT
    GS --> FETCH
    GS --> FILT
    GS --> RENAME

    %% --- Entry → Infrastructure ---
    UD --> SETUP
    UD --> YAML

    %% --- Subcommands → helpers ---
    SEARCH --> LOADCACHE
    INFO --> PARSEYAML
    INFO --> FILT
    DFINFO --> LISTIND
    BKEY --> FILT

    %% --- Metadata cache ---
    LOADCACHE --> PARSEV2
    PARSEV2 --> CHKYAML
    PARSEV2 --> YAML

    %% --- Sync chain ---
    SYNC --> XML2Y
    SYNC --> SYNCDF
    SYNC --> SYNCIND
    SYNC --> SYNCHIST
    SYNCDF --> SYNCSCH
    SYNCIND --> XML2Y
    REFRESH --> SYNC

    %% --- XML→YAML chain ---
    XML2Y --> XMLSCHEMA
    XML2Y --> XML2YPY
    XML2Y --> XMLPARSE
    XMLPARSE --> XMLPY
    XMLPARSE --> XMLST
    XMLST --> XMLLINES

    %% --- YAML dispatcher → subcommands ---
    YAML --> YREAD
    YAML --> YWRITE
    YAML --> YGET
    YAML --> YLIST
    YAML --> YDESC
    YAML --> YDIR
    YAML --> YCLEAR
    YAML --> YFRAMES
    YAML --> YVALID

    %% --- yaml_read internals ---
    YREAD --> YMATA
    YREAD --> YFAST
    YREAD --> YCOLL
    YREAD --> YTOK

    %% --- Misc infra edges ---
    MLW --> LW

    %% --- External ---
    FETCH -.-> API
    GS -.-> API
    SYNC -.-> API
    API[("UNICEF SDMX API\nsdmx.data.unicef.org")]

    classDef entry fill:#4a90d9,stroke:#2c5f8a,color:#fff
    classDef subcmd fill:#6ab04c,stroke:#4a8a2c,color:#fff
    classDef fetch fill:#5ba85b,stroke:#3d7a3d,color:#fff
    classDef meta fill:#9b59b6,stroke:#7d3c98,color:#fff
    classDef infra fill:#e8a838,stroke:#b07a20,color:#fff
    classDef external fill:#d35400,stroke:#a04000,color:#fff

    class UD,GS,EX entry
    class FLOWS,SEARCH,LISTIND,INFO,DFINFO,SYNC subcmd
    class FETCH,BKEY,FILT,DFDIR,DISAGG,RENAME fetch
    class XML2Y,XML2YPY,XMLPARSE,XMLSCHEMA,XMLPY,XMLST,XMLLINES,PARSEYAML,PARSEALL,PARSEV2,LOADCACHE,SYNCDF,SYNCSCH,SYNCIND,SYNCHIST,REFRESH meta
    class YAML,YREAD,YWRITE,YGET,YLIST,YDESC,YDIR,YCLEAR,YFRAMES,YVALID,YMATA,YFAST,YCOLL,YTOK,SETUP,CHKYAML,SETDF,LW,MLW infra
    class API external
```

### XML→YAML Parser Selection (`unicefdata_xmltoyaml.ado`)

```mermaid
graph LR
    XML2Y["unicefdata_xmltoyaml"] --> SIZE{"File > 500KB?"}
    SIZE -- yes --> PY["unicefdata_xmltoyaml_py\nPython xml2yaml script"]
    SIZE -- no --> PARSE["__xmltoyaml_parse\n(dispatcher)"]
    PARSE --> PYBACK["__xmltoyaml_parse_python\nPython backend"]
    PYBACK -. fail .-> STBACK["__xmltoyaml_parse_stata\nStata backend"]
    STBACK --> LINES["__xmltoyaml_parse_lines\nline-by-line"]
    PY -. fail .-> PARSE

    classDef meta fill:#9b59b6,stroke:#7d3c98,color:#fff
    classDef strategy fill:#f5f5f5,stroke:#999,color:#333
    class XML2Y meta
    class SIZE strategy
    class PY,PARSE,PYBACK,STBACK,LINES strategy
```

### YAML Read Paths (`yaml_read.ado`)

```mermaid
graph LR
    YREAD["yaml_read"] --> MODE{"Parse mode"}
    MODE -- "bulk (large files)" --> MATA["__yaml_mataread\nMata-accelerated"]
    MODE -- "fastread (shallow)" --> FAST["__yaml_fastread\n1-2 level files"]
    MODE -- "canonical (default)" --> TOK["__yaml_tokenize_line\nline-by-line"]
    MATA --> COLL["__yaml_collapse\nlong→wide pivot"]
    TOK --> COLL
    FAST --> COLL

    classDef infra fill:#e8a838,stroke:#b07a20,color:#fff
    classDef strategy fill:#f5f5f5,stroke:#999,color:#333
    class YREAD infra
    class MODE strategy
    class MATA,FAST,TOK,COLL strategy
```

### Metadata Sync Pipeline (`unicefdata_sync.ado`)

```mermaid
graph LR
    SYNC["unicefdata_sync"] --> DF["Sync dataflows\n(XML → YAML)"]
    SYNC --> CL["Sync codelists\n(countries, regions)"]
    SYNC --> IND["Sync indicators\n(CL_UNICEF_INDICATOR)"]
    SYNC --> IDX["Sync dataflow index\n(all DSD schemas)"]
    SYNC --> HIST["Update sync history"]

    DF --> X2Y["unicefdata_xmltoyaml"]
    CL --> X2Y
    IND --> X2Y
    IDX --> SCHEMA["__unicefdata_sync_df_schema\n(per-dataflow YAML)"]
    HIST --> HISTW["__unicefdata_update_sync_history"]

    IDX -.-> API
    DF -.-> API
    CL -.-> API
    IND -.-> API
    API[("UNICEF SDMX API")]

    classDef subcmd fill:#6ab04c,stroke:#4a8a2c,color:#fff
    classDef meta fill:#9b59b6,stroke:#7d3c98,color:#fff
    classDef strategy fill:#f5f5f5,stroke:#999,color:#333
    classDef external fill:#d35400,stroke:#a04000,color:#fff
    class SYNC subcmd
    class DF,CL,IND,IDX,HIST strategy
    class X2Y,SCHEMA,HISTW meta
    class API external
```

### Dataflow Resolution (`unicefdata.ado`)

```mermaid
graph LR
    UD["unicefdata"] --> T1["1: __get_dataflow_direct\nYAML metadata lookup"]
    T1 -. miss .-> T2["2: yaml read\nfull YAML scan"]
    T2 -. miss .-> T3["3: GLOBAL_DATAFLOW\nhardcoded fallback"]

    classDef entry fill:#4a90d9,stroke:#2c5f8a,color:#fff
    classDef strategy fill:#f5f5f5,stroke:#999,color:#333
    class UD entry
    class T1,T2,T3 strategy
```

## Module Summary

| Module                                 | Role                              | Layer          | Calls                                                                                                                                                                                                                                                                                                                       |
| -------------------------------------- | --------------------------------- | -------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `unicefdata.ado`                       | Main entry point & dispatcher     | Entry          | `get_sdmx`, `__unicef_list_dataflows`, `__unicef_search_indicators`, `__unicef_list_indicators`, `__unicef_indicator_info`, `__unicef_dataflow_info`, `unicefdata_sync`, `__get_dataflow_direct`, `__unicef_get_disagg_totals`, `__unicef_build_schema_key`, `__unicef_get_indicator_filters`, `__unicefdata_setup`, `yaml` |
| `get_sdmx.ado`                         | Low-level SDMX data fetcher       | Entry          | `__unicef_fetch_paged`, `__unicef_get_indicator_filters`, `__get_sdmx_rename_year_columns`                                                                                                                                                                                                                                  |
| `unicefdata_examples.ado`              | Interactive examples (12)         | Entry          | `unicefdata`                                                                                                                                                                                                                                                                                                                |
| `unicefdata_sync.ado`                  | Metadata sync orchestrator        | Subcommand     | `unicefdata_xmltoyaml`, `__unicefdata_sync_dataflow_index`, `__unicefdata_sync_ind_meta`, `__unicefdata_update_sync_history`                                                                                                                                                                                                |
| `unicefdata_refresh_all.ado`           | Full refresh orchestrator         | Subcommand     | `unicefdata_sync`, Python scripts                                                                                                                                                                                                                                                                                           |
| `__unicef_list_dataflows.ado`          | List available dataflows          | Subcommand     | (leaf)                                                                                                                                                                                                                                                                                                                      |
| `__unicef_list_indicators.ado`         | List indicators for a dataflow    | Subcommand     | (leaf)                                                                                                                                                                                                                                                                                                                      |
| `__unicef_search_indicators.ado`       | Keyword search over indicators    | Subcommand     | `__unicef_load_indicators_cache`                                                                                                                                                                                                                                                                                            |
| `__unicef_indicator_info.ado`          | Display indicator metadata        | Subcommand     | `__unicef_parse_indicator_yaml`, `__unicef_get_indicator_filters`                                                                                                                                                                                                                                                           |
| `__unicef_dataflow_info.ado`           | Display dataflow schema details   | Subcommand     | `__unicef_list_indicators`                                                                                                                                                                                                                                                                                                  |
| `get_sdmx.ado`                         | SDMX REST API client              | Fetch          | `__unicef_fetch_paged`, `__unicef_get_indicator_filters`, `__get_sdmx_rename_year_columns`                                                                                                                                                                                                                                  |
| `__unicef_fetch_paged.ado`             | Paged CSV download from API       | Fetch          | (leaf — calls API directly)                                                                                                                                                                                                                                                                                                 |
| `__unicef_build_schema_key.ado`        | Build SDMX filter key             | Fetch          | `__unicef_get_indicator_filters`                                                                                                                                                                                                                                                                                            |
| `__unicef_get_indicator_filters.ado`   | Read schema dimensions from YAML  | Fetch          | (leaf)                                                                                                                                                                                                                                                                                                                      |
| `__get_dataflow_direct.ado`            | Indicator → dataflow YAML lookup  | Fetch          | (leaf)                                                                                                                                                                                                                                                                                                                      |
| `__unicef_get_disagg_totals.ado`       | Get dimensions with \_T totals    | Fetch          | (leaf)                                                                                                                                                                                                                                                                                                                      |
| `__get_sdmx_rename_year_columns.ado`   | Rename year columns (wide format) | Fetch          | (leaf)                                                                                                                                                                                                                                                                                                                      |
| `unicefdata_xmltoyaml.ado`             | XML→YAML converter (dispatcher)   | Metadata       | `__xmltoyaml_get_schema`, `unicefdata_xmltoyaml_py`, `__xmltoyaml_parse`                                                                                                                                                                                                                                                    |
| `unicefdata_xmltoyaml_py.ado`          | Python XML backend                | Metadata       | Python script `unicefdata_xml2yaml.py`                                                                                                                                                                                                                                                                                      |
| `__xmltoyaml_parse.ado`                | Parse dispatcher (Python→Stata)   | Metadata       | `__xmltoyaml_parse_python`, `__xmltoyaml_parse_stata`                                                                                                                                                                                                                                                                       |
| `__xmltoyaml_parse_stata.ado`          | Stata XML parser                  | Metadata       | `__xmltoyaml_parse_lines`                                                                                                                                                                                                                                                                                                   |
| `__xmltoyaml_parse_lines.ado`          | Line-by-line XML element parser   | Metadata       | (leaf)                                                                                                                                                                                                                                                                                                                      |
| `__xmltoyaml_parse_python.ado`         | Python XML parser wrapper         | Metadata       | Python script `unicefdata_xml2yaml.py`                                                                                                                                                                                                                                                                                      |
| `__xmltoyaml_get_schema.ado`           | SDMX type schema registry         | Metadata       | (leaf)                                                                                                                                                                                                                                                                                                                      |
| `__unicef_parse_indicator_yaml.ado`    | Single-indicator YAML parser      | Metadata       | (leaf)                                                                                                                                                                                                                                                                                                                      |
| `__unicef_parse_indicators_yaml.ado`   | Full catalog YAML parser (v1)     | Metadata       | (leaf)                                                                                                                                                                                                                                                                                                                      |
| `__unicef_parse_ind_yaml_v2.ado`       | Full catalog YAML parser (v2)     | Metadata       | `__unicefdata_check_yaml`, `yaml`                                                                                                                                                                                                                                                                                           |
| `__unicef_load_indicators_cache.ado`   | Frame-cached indicator loader     | Metadata       | `__unicef_parse_ind_yaml_v2`                                                                                                                                                                                                                                                                                                |
| `__unicefdata_sync_dataflow_index.ado` | Sync all dataflow schemas         | Metadata       | `__unicefdata_sync_df_schema`                                                                                                                                                                                                                                                                                               |
| `__unicefdata_sync_df_schema.ado`      | Write single dataflow schema YAML | Metadata       | (leaf)                                                                                                                                                                                                                                                                                                                      |
| `__unicefdata_sync_ind_meta.ado`       | Sync indicator catalog            | Metadata       | `unicefdata_xmltoyaml`                                                                                                                                                                                                                                                                                                      |
| `__unicefdata_update_sync_history.ado` | Write sync history YAML           | Metadata       | (leaf)                                                                                                                                                                                                                                                                                                                      |
| `yaml.ado`                             | YAML subcommand dispatcher        | Infrastructure | `yaml_read`, `yaml_write`, `yaml_get`, `yaml_list`, `yaml_describe`, `yaml_dir`, `yaml_clear`, `yaml_frames`, `yaml_validate`                                                                                                                                                                                               |
| `yaml_read.ado`                        | YAML file reader (3 parse paths)  | Infrastructure | `__yaml_mataread`, `__yaml_fastread`, `__yaml_collapse`, `__yaml_tokenize_line`                                                                                                                                                                                                                                             |
| `yaml_write.ado`                       | YAML file writer                  | Infrastructure | (leaf)                                                                                                                                                                                                                                                                                                                      |
| `yaml_get.ado`                         | Retrieve YAML key values          | Infrastructure | (leaf)                                                                                                                                                                                                                                                                                                                      |
| `yaml_list.ado`                        | List YAML keys/values             | Infrastructure | (leaf)                                                                                                                                                                                                                                                                                                                      |
| `yaml_describe.ado`                    | Show YAML structure               | Infrastructure | (leaf)                                                                                                                                                                                                                                                                                                                      |
| `yaml_dir.ado`                         | List YAML data in memory          | Infrastructure | (leaf)                                                                                                                                                                                                                                                                                                                      |
| `yaml_clear.ado`                       | Clear YAML data from memory       | Infrastructure | (leaf)                                                                                                                                                                                                                                                                                                                      |
| `yaml_frames.ado`                      | List YAML frames                  | Infrastructure | (leaf)                                                                                                                                                                                                                                                                                                                      |
| `yaml_validate.ado`                    | Validate YAML against schema      | Infrastructure | (leaf)                                                                                                                                                                                                                                                                                                                      |
| `__yaml_mataread.ado`                  | Mata-accelerated bulk parser      | Infrastructure | (leaf)                                                                                                                                                                                                                                                                                                                      |
| `__yaml_fastread.ado`                  | Shallow YAML fast parser          | Infrastructure | (leaf)                                                                                                                                                                                                                                                                                                                      |
| `__yaml_collapse.ado`                  | Long→wide YAML pivot              | Infrastructure | (leaf)                                                                                                                                                                                                                                                                                                                      |
| `__yaml_tokenize_line.ado`             | YAML line tokenizer               | Infrastructure | (leaf)                                                                                                                                                                                                                                                                                                                      |
| `__unicefdata_setup.ado`               | First-run metadata installer      | Infrastructure | (leaf)                                                                                                                                                                                                                                                                                                                      |
| `__unicefdata_check_yaml.ado`          | Check/install yaml.ado version    | Infrastructure | (leaf)                                                                                                                                                                                                                                                                                                                      |
| `__set_default_dataflows.ado`          | Hardcoded fallback dataflows      | Infrastructure | (leaf)                                                                                                                                                                                                                                                                                                                      |
| `__linewrap.ado`                       | Text line wrapping                | Infrastructure | (leaf)                                                                                                                                                                                                                                                                                                                      |
| `__metadata_linewrap.ado`              | Graph-label line wrapping         | Infrastructure | `__linewrap`                                                                                                                                                                                                                                                                                                                |

## Call Flow Example

```
User: unicefdata, indicator(MNCH_SAB) country(BRA;IND) year(2010/2020)

  unicefdata.ado
    ├─ __unicefdata_setup             (ensure YAML metadata installed)
    ├─ parse subcommand → data retrieval mode
    ├─ __get_dataflow_direct          (look up MNCH_SAB → MNCH dataflow)
    │    └─ reads _unicefdata_indicators_metadata.yaml
    ├─ __unicef_get_disagg_totals     (SEX has _T → auto-filter SEX=_T)
    ├─ __unicef_get_indicator_filters (read MNCH schema dimensions)
    ├─ __unicef_build_schema_key      (build key: MNCH.MNCH_SAB.BRA+IND._T...)
    │    └─ __unicef_get_indicator_filters
    └─ get_sdmx                       (fetch data from SDMX API)
         ├─ __unicef_get_indicator_filters (validate dimensions)
         ├─ build URL: sdmx.data.unicef.org/ws/public/sdmxapi/rest/data/MNCH/...
         ├─ __unicef_fetch_paged      (page 1: import CSV)
         │    └─ HTTP GET → API (100K rows/page)
         ├─ page 2... (if needed)
         └─ return to unicefdata.ado
    unicefdata.ado
    ├─ label variables, apply value labels
    ├─ store char _dta[unicef_*] metadata
    └─ return r(N), r(indicator), r(dataflow)
```
