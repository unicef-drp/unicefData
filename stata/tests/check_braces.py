import re

file_path = r"C:\GitHub\myados\unicefData-dev\stata\src\g\get_sdmx.ado"

with open(file_path, 'r', encoding='utf-8') as f:
    lines = f.readlines()

brace_stack = []
line_num = 0

for line in lines:
    line_num += 1
    # Count opening braces
    if re.search(r'\{$', line):
        brace_stack.append((line_num, line.strip()[:60]))
    
    # Count closing braces
    if re.match(r'^\s*\}', line):
        if brace_stack:
            brace_stack.pop()
        else:
            print(f"Line {line_num}: Extra closing brace (no matching open)")

if brace_stack:
    print(f"\nUnclosed braces ({len(brace_stack)}):")
    for line_num, line_text in brace_stack:
        print(f"  Line {line_num}: {line_text}")
else:
    print("\nAll braces matched!")
