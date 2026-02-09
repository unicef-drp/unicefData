#!/usr/bin/env python3
"""
SMCL Syntax Validator for Stata Help Files
Checks for common SMCL formatting errors that cause rendering issues.
"""

import re
import sys
from pathlib import Path
from typing import List, Tuple


class SMCLValidator:
    def __init__(self, filepath: str):
        self.filepath = Path(filepath)
        self.errors = []
        self.warnings = []
        self.line_count = 0
        
    def validate(self) -> bool:
        """Run all validation checks."""
        print(f"Validating SMCL file: {self.filepath}")
        print("=" * 70)
        
        with open(self.filepath, 'r', encoding='utf-8') as f:
            lines = f.readlines()
        
        self.line_count = len(lines)
        
        # Run checks
        self.check_opening_smcl(lines)
        self.check_brace_balance(lines)
        self.check_line_brace_matching(lines)
        self.check_paragraph_endings(lines)
        self.check_stata_links(lines)
        self.check_common_typos(lines)
        
        # Report results
        self.print_results()
        
        return len(self.errors) == 0
    
    def check_opening_smcl(self, lines: List[str]):
        """Check if file starts with {smcl}."""
        if not lines:
            self.errors.append((1, "File is empty"))
            return
        
        if not lines[0].strip() == "{smcl}":
            self.errors.append((1, "File must start with {smcl}"))
    
    def check_brace_balance(self, lines: List[str]):
        """Check overall brace balance."""
        open_count = 0
        close_count = 0
        
        for i, line in enumerate(lines, 1):
            open_count += line.count('{')
            close_count += line.count('}')
        
        if open_count != close_count:
            self.errors.append((
                0,
                f"BRACE MISMATCH: {open_count} opening {{ vs {close_count} closing }}"
            ))
    
    def check_line_brace_matching(self, lines: List[str]):
        """Check that braces match on the same line for SMCL directives."""
        for i, line in enumerate(lines, 1):
            # Skip comment lines
            if line.strip().startswith('*'):
                continue
            
            # Find all SMCL directives (starting with {)
            directives = re.finditer(r'\{[^}]*', line)
            for match in directives:
                directive = match.group()
                # Check if directive is complete (has closing brace)
                if '}' not in directive:
                    # Look ahead to see if brace is on same line
                    rest_of_line = line[match.end():]
                    if '}' not in rest_of_line:
                        self.errors.append((
                            i,
                            f"Unclosed SMCL directive on line: {directive[:50]}..."
                        ))
    
    def check_paragraph_endings(self, lines: List[str]):
        """Check for missing {p_end} tags."""
        in_paragraph = False
        para_start_line = 0
        
        for i, line in enumerate(lines, 1):
            # Check for paragraph start
            if re.search(r'\{(pstd|phang|p\s+\d+)', line):
                if in_paragraph:
                    self.warnings.append((
                        i,
                        f"New paragraph started without {'{p_end}'} from line {para_start_line}"
                    ))
                in_paragraph = True
                para_start_line = i
            
            # Check for paragraph end
            if '{p_end}' in line:
                in_paragraph = False
    
    def check_stata_links(self, lines: List[str]):
        """Check {stata} link syntax."""
        for i, line in enumerate(lines, 1):
            # Find all {stata} directives
            stata_links = re.finditer(r'\{stata\s+"([^"]+)"\s*:\.([^}]+)\}', line)
            for match in stata_links:
                command = match.group(1)
                display = match.group(2)
                
                # Check if display text matches command
                if display.strip() != command.strip():
                    # This is OK - display can differ from command
                    pass
                
                # Check for missing closing brace
                if not match.group().endswith('}'):
                    self.errors.append((
                        i,
                        f"Incomplete {'{stata}'} link: {match.group()[:50]}..."
                    ))
    
    def check_common_typos(self, lines: List[str]):
        """Check for common SMCL typos."""
        typos = [
            (r'clearp_end', "Typo: 'clearp_end' should be 'clear}{p_end}'"),
            (r'\{p_ned\}', "Typo: '{p_ned}' should be '{p_end}'"),
            (r'\{pend\}', "Typo: '{pend}' should be '{p_end}'"),
            (r'\{pdst\}', "Typo: '{pdst}' should be '{pstd}'"),
        ]
        
        for i, line in enumerate(lines, 1):
            for pattern, message in typos:
                if re.search(pattern, line):
                    self.errors.append((i, message))
    
    def print_results(self):
        """Print validation results."""
        print(f"\nValidation Results for {self.filepath.name}")
        print("=" * 70)
        print(f"Total lines: {self.line_count}")
        print(f"Errors: {len(self.errors)}")
        print(f"Warnings: {len(self.warnings)}")
        
        if self.errors:
            print("\n❌ ERRORS:")
            for line_num, msg in self.errors:
                if line_num == 0:
                    print(f"   GLOBAL: {msg}")
                else:
                    print(f"   Line {line_num}: {msg}")
        
        if self.warnings:
            print("\n⚠️  WARNINGS:")
            for line_num, msg in self.warnings:
                print(f"   Line {line_num}: {msg}")
        
        if not self.errors and not self.warnings:
            print("\n✅ No issues found!")
        
        print("=" * 70)


def main():
    if len(sys.argv) < 2:
        filepath = r"C:\GitHub\myados\unicefData\stata\src\u\unicefdata.sthlp"
        print(f"No file specified, using default: {filepath}")
    else:
        filepath = sys.argv[1]
    
    validator = SMCLValidator(filepath)
    success = validator.validate()
    
    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()
