#!/usr/bin/env python3
"""Create LaTeX table showing raw SDMX data structure"""

import sys
sys.path.insert(0, 'C:/GitHub/myados/unicefData/python')

from unicef_api import unicefdata
import pandas as pd

print("Querying raw SDMX data for Bangladesh...\n")

# Get raw data
df = unicefdata(
    indicator='CME_MRY0T4',
    countries=['BGD'],
    raw=True
)

# Filter to Bangladesh and recent years
df_bgd = df[df['REF_AREA'] == 'BGD'].copy()
df_sample = df_bgd[df_bgd['TIME_PERIOD'].isin([2020.0, 2019.0])].copy()

# Select relevant columns to illustrate concepts
columns_to_show = [
    'REF_AREA',           # Dimension: Country
    'TIME_PERIOD',        # Dimension: Year
    'SEX',                # Dimension: Disaggregation
    'WEALTH_QUINTILE',    # Dimension: Disaggregation
    'OBS_VALUE',          # The data value
    'LOWER_BOUND',        # Attribute: Confidence interval
    'UPPER_BOUND',        # Attribute: Confidence interval
    'DATA_SOURCE',        # Attribute: Source
    'OBS_STATUS'          # Attribute: Quality flag
]

df_display = df_sample[columns_to_show].head(8)

print("Sample of raw SDMX observations:")
print("="*100)
print(df_display.to_string(index=False))
print("="*100)

# Create LaTeX table
print("\n\nLaTeX Table (landscape/small font recommended):")
print("="*100)

print("""
\\begin{table}[htbp]
\\centering
\\footnotesize
\\caption{Sample SDMX Observations: Raw API Response Structure}
\\label{tab:raw-sdmx-sample}
\\begin{tabular}{@{}llccccccl@{}}
\\toprule
\\textbf{Country} & \\textbf{Year} & \\textbf{Sex} & \\textbf{Wealth} & \\textbf{Value} & \\textbf{Lower} & \\textbf{Upper} & \\textbf{Source} & \\textbf{Status} \\\\
\\textbf{(REF\\_AREA)} & \\textbf{(TIME)} & \\textbf{(SEX)} & \\textbf{(QUINTILE)} & \\textbf{(OBS)} & \\textbf{(CI)} & \\textbf{(CI)} & \\textbf{(ATTRIB)} & \\textbf{(ATTRIB)} \\\\
\\midrule""")

for idx, row in df_display.iterrows():
    country = row['REF_AREA']
    year = int(row['TIME_PERIOD'])
    sex = row['SEX']
    wealth = row['WEALTH_QUINTILE']
    value = f"{row['OBS_VALUE']:.1f}"
    lower = f"{row['LOWER_BOUND']:.1f}" if pd.notna(row['LOWER_BOUND']) else "--"
    upper = f"{row['UPPER_BOUND']:.1f}" if pd.notna(row['UPPER_BOUND']) else "--"
    source = row['DATA_SOURCE'] if pd.notna(row['DATA_SOURCE']) else "--"
    status = row['OBS_STATUS'] if pd.notna(row['OBS_STATUS']) else "--"
    
    print(f"{country} & {year} & \\texttt{{{sex}}} & \\texttt{{{wealth}}} & {value} & {lower} & {upper} & {source} & {status} \\\\")

print("""\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\footnotesize
\\item \\textbf{Note:} Each row represents one SDMX observation. \\textbf{Dimensions} (Country, Year, Sex, Wealth Quintile) define the observation's coordinates and enable filtering. \\textbf{Attributes} (confidence intervals, source, status) provide context but are not used for query filtering. Value is under-5 mortality rate per 1,000 live births.
\\item \\textbf{Source:} UNICEF SDMX API, indicator CME\\_MRY0T4, retrieved January 6, 2026.
\\end{tablenotes}
\\end{table}
""")

print("="*100)

# Also create a simplified version
print("\n\nSimplified version (fewer columns):")
print("="*100)

print("""
\\begin{table}[htbp]
\\centering
\\small
\\caption{Raw SDMX Observations Illustrating Dimensions and Attributes}
\\label{tab:sdmx-structure}
\\begin{tabular}{@{}lcccccc@{}}
\\toprule
\\textbf{Year} & \\textbf{Sex} & \\textbf{Wealth} & \\textbf{Value} & \\textbf{Lower CI} & \\textbf{Upper CI} & \\textbf{Source} \\\\
& \\textit{(dimension)} & \\textit{(dimension)} & & \\textit{(attribute)} & \\textit{(attribute)} & \\textit{(attribute)} \\\\
\\midrule""")

for idx, row in df_display.iterrows():
    year = int(row['TIME_PERIOD'])
    sex = row['SEX']
    wealth = row['WEALTH_QUINTILE']
    value = f"{row['OBS_VALUE']:.1f}"
    lower = f"{row['LOWER_BOUND']:.1f}" if pd.notna(row['LOWER_BOUND']) else "--"
    upper = f"{row['UPPER_BOUND']:.1f}" if pd.notna(row['UPPER_BOUND']) else "--"
    source = row['DATA_SOURCE'] if pd.notna(row['DATA_SOURCE']) else "--"
    
    print(f"{year} & \\texttt{{{sex}}} & \\texttt{{{wealth}}} & {value} & {lower} & {upper} & {source} \\\\")

print("""\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\footnotesize
\\item \\textbf{Note:} Sample observations for Bangladesh (CME\\_MRY0T4: Under-5 mortality rate per 1,000 live births). \\textit{Dimensions} (Sex, Wealth Quintile) enable query filtering and disaggregation. \\textit{Attributes} (confidence intervals, data source) provide context and quality information. Source: UNICEF SDMX API, January 6, 2026.
\\end{tablenotes}
\\end{table}
""")

print("="*100)
