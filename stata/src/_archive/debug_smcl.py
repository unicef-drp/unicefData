#!/usr/bin/env python
"""Deep SMCL debug script to find issues in unicefdata.sthlp"""

import re
import sys

def analyze_smcl(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
        lines = content.split('\n')
    
    problems = []
    
    for i, line in enumerate(lines):
        lineno = i + 1
        
        # Check basic brace balance on each line
        opens = line.count('{')
        closes = line.count('}')
        if opens != closes:
            problems.append(f"Line {lineno}: BRACE MISMATCH {opens} open, {closes} close")
            problems.append(f"  Content: {line[:100]}")
        
        # Check for unclosed formatting tags
        for tag in ['{ul:', '{bf:', '{it:', '{cmd:', '{opt:']:
            if tag in line:
                # Find the tag and check if it has a closing brace before next open brace
                idx = line.find(tag)
                rest = line[idx + len(tag):]
                # Look for closing brace
                close_idx = rest.find('}')
                open_idx = rest.find('{')
                if close_idx == -1:
                    problems.append(f"Line {lineno}: {tag} has no closing brace")
                    problems.append(f"  Content: {line[:100]}")
    
    # Check for {ul: specifically that might span lines
    ul_pattern = re.compile(r'\{ul:([^}]*)\}', re.MULTILINE)
    ul_matches = list(ul_pattern.finditer(content))
    print(f"Found {len(ul_matches)} {'{'}ul:...{'}'} tags")
    
    # Check for any line that has {ul: but no closing }
    for i, line in enumerate(lines):
        if '{ul:' in line and line.count('{') != line.count('}'):
            problems.append(f"Line {i+1}: {'{'}ul: with unbalanced braces: {line}")
    
    # Look for the specific problem area around Example 3
    print("\n=== Lines 560-580 (Example 3 area) ===")
    for i in range(559, min(580, len(lines))):
        print(f"Line {i+1}: {lines[i][:90]}")
    
    return problems

if __name__ == '__main__':
    filepath = r'C:\GitHub\myados\unicefData\stata\src\u\unicefdata.sthlp'
    print(f"Analyzing: {filepath}\n")
    
    problems = analyze_smcl(filepath)
    
    print(f"\n=== Found {len(problems)} issues ===")
    for p in problems:
        print(p)
