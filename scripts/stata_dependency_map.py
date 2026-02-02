"""Build a dependency map for Stata ado programs.

The script scans a Stata source tree (default: stata/src) to find all
program definitions in .ado files and maps which programs call each other.
Outputs a JSON summary and optionally a Graphviz DOT file.
"""

from __future__ import annotations

import argparse
import json
import re
from dataclasses import dataclass, field
from pathlib import Path
from typing import Dict, Iterable, List, Mapping, MutableMapping, MutableSet, Set

PROGRAM_DEF_RE = re.compile(r"^\s*program\s+define\s+([A-Za-z0-9_]+)", re.IGNORECASE | re.MULTILINE)
BLOCK_COMMENT_RE = re.compile(r"/\*.*?\*/", re.DOTALL)
LINE_COMMENT_RE = re.compile(r"(^\s*\*.*?$)|((?<!\S)//.*?$)", re.MULTILINE)


@dataclass
class ProgramInfo:
    file: Path
    depends_on: MutableSet[str] = field(default_factory=set)
    dependents: MutableSet[str] = field(default_factory=set)
    is_commented: bool = False

    def to_dict(self, root: Path) -> Mapping[str, object]:
        return {
            "file": str(self.file.relative_to(root)),
            "depends_on": sorted(self.depends_on),
            "dependents": sorted(self.dependents),
            "is_commented": self.is_commented,
        }


def strip_comments(text: str) -> str:
    """Remove common Stata comment styles to reduce false positives."""

    without_block = BLOCK_COMMENT_RE.sub(" ", text)
    return LINE_COMMENT_RE.sub(" ", without_block)


def is_line_commented(text: str, match_start: int) -> bool:
    """Check if a match position is within a comment."""
    # Find the line containing this match
    line_start = text.rfind('\n', 0, match_start) + 1
    line_prefix = text[line_start:match_start]
    
    # Check if line starts with * (Stata line comment)
    if re.match(r'^\s*\*', line_prefix):
        return True
    
    # Check if inside /* ... */ block comment
    # Count block comment starts/ends before this position
    blocks_before = text[:match_start]
    open_count = blocks_before.count('/*')
    close_count = blocks_before.count('*/')
    return open_count > close_count


def find_programs(file_path: Path) -> Dict[str, bool]:
    """Return dict of program names to is_commented status."""

    text = file_path.read_text(encoding="utf-8", errors="ignore")
    programs = {}
    for match in PROGRAM_DEF_RE.finditer(text):
        name = match.group(1).lower()
        is_commented = is_line_commented(text, match.start())
        programs[name] = is_commented
    return programs


def build_search_regex(program_names: Iterable[str]) -> re.Pattern[str]:
    """Compile a regex that matches any known program name as a whole word."""

    escaped = [re.escape(name) for name in sorted(program_names, key=len, reverse=True)]
    if not escaped:
        return re.compile(r"^$")
    return re.compile(r"\b(" + "|".join(escaped) + r")\b", re.IGNORECASE)


def find_dependencies(file_path: Path, search_re: re.Pattern[str]) -> Set[str]:
    """Find program references in a file using the provided regex."""

    text = file_path.read_text(encoding="utf-8", errors="ignore")
    cleaned = strip_comments(text)
    return {m.group(1).lower() for m in search_re.finditer(cleaned)}


def collect_programs(ado_files: List[Path]) -> Dict[str, ProgramInfo]:
    """Build initial program-to-file map from the list of ado files."""

    programs: Dict[str, ProgramInfo] = {}
    for ado_path in ado_files:
        defined = find_programs(ado_path)
        for name, is_commented in defined.items():
            programs[name] = ProgramInfo(file=ado_path, is_commented=is_commented)
    return programs


def map_dependencies(root: Path, include_archive: bool) -> Dict[str, ProgramInfo]:
    """Collect dependency information for all ado programs under root."""

    ado_files = sorted(root.rglob("*.ado"))
    if not include_archive:
        ado_files = [p for p in ado_files if "_archive" not in p.parts]

    programs = collect_programs(ado_files)
    if not programs:
        return {}

    search_re = build_search_regex(programs.keys())

    # Map dependencies per file, then assign to each program defined in that file.
    for ado_path in ado_files:
        dependencies_in_file = find_dependencies(ado_path, search_re)
        defined_here = {name for name, info in programs.items() if info.file == ado_path}
        for program_name in defined_here:
            info = programs[program_name]
            info.depends_on.update(dep for dep in dependencies_in_file if dep != program_name)

    # Populate dependents from depends_on relationships.
    for name, info in programs.items():
        for dep in info.depends_on:
            if dep in programs:
                programs[dep].dependents.add(name)

    return programs


def emit_json(programs: Mapping[str, ProgramInfo], root: Path) -> str:
    commented_count = sum(1 for info in programs.values() if info.is_commented)
    payload = {
        "programs": {name: info.to_dict(root) for name, info in sorted(programs.items())},
        "counts": {
            "programs": len(programs),
            "active": len(programs) - commented_count,
            "commented": commented_count,
            "edges": sum(len(info.depends_on) for info in programs.values()),
        },
        "commented_programs": sorted([name for name, info in programs.items() if info.is_commented]),
    }
    return json.dumps(payload, indent=2)


def emit_graphviz(programs: Mapping[str, ProgramInfo], root: Path) -> str:
    lines = ["digraph stata_deps {", "  rankdir=LR;", "  node [shape=box, style=rounded];"]
    for name, info in sorted(programs.items()):
        label = f"{name}\n{info.file.relative_to(root)}"
        lines.append(f"  \"{name}\" [label=\"{label}\"];" )
    for name, info in sorted(programs.items()):
        for dep in sorted(info.depends_on):
            if dep in programs:
                lines.append(f"  \"{name}\" -> \"{dep}\";")
    lines.append("}")
    return "\n".join(lines)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Map dependencies between Stata ado programs.")
    parser.add_argument("--root", type=Path, default=Path("stata/src"), help="Root directory to scan (default: stata/src)")
    parser.add_argument("--include-archive", action="store_true", help="Include _archive directories in the scan")
    parser.add_argument("--exclude-commented", action="store_true", help="Exclude commented-out program definitions")
    parser.add_argument("--json-out", type=Path, help="Optional path to write JSON output")
    parser.add_argument("--graphviz-out", type=Path, help="Optional path to write a Graphviz DOT file")
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    root = args.root.resolve()
    if not root.exists():
        raise SystemExit(f"Root path not found: {root}")

    programs = map_dependencies(root, include_archive=args.include_archive)
    if not programs:
        raise SystemExit("No programs found.")

    # Filter commented programs if requested
    if args.exclude_commented:
        programs = {name: info for name, info in programs.items() if not info.is_commented}
        if not programs:
            raise SystemExit("No active programs found after filtering commented ones.")

    json_output = emit_json(programs, root)

    if args.json_out:
        args.json_out.write_text(json_output, encoding="utf-8")
        print(f"Wrote JSON to {args.json_out}")
    else:
        print(json_output)

    if args.graphviz_out:
        dot_output = emit_graphviz(programs, root)
        args.graphviz_out.write_text(dot_output, encoding="utf-8")
        print(f"Wrote Graphviz DOT to {args.graphviz_out}")


if __name__ == "__main__":
    main()
