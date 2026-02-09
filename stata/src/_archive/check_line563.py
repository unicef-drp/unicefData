#!/usr/bin/env python3
import sys

filepath = r"C:\GitHub\myados\unicefData\stata\src\u\unicefdata.sthlp"

with open(filepath, 'r', encoding='utf-8') as f:
    lines = f.readlines()

# Line 563 is index 562 (0-based)
line563 = lines[562]

print("Line 563 analysis:")
print(f"Length: {len(line563)} characters")
newline_chars = ('\n', '\r\n', '\r')
print(f"Contains newline at end: {line563.endswith(newline_chars)}")
print(f"Number of newlines in middle: {line563[:-2].count(chr(10))}")
print()
print("Full line:")
print(repr(line563))
print()
print("Readable:")
print(line563)
