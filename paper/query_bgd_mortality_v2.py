#!/usr/bin/env python3
"""Query UNICEF data for Bangladesh under-5 mortality by sex in 2020"""

import sys
sys.path.insert(0, 'C:/GitHub/myados/unicefData/python')

from unicef_api import unicefdata
import pandas as pd

print("Querying UNICEF data via unicef_api package...")
print("Indicator: CME_MRY0T4 (Under-5 mortality rate)")
print("Country: Bangladesh (BGD)")
print("Disaggregation: Sex (Total, Male, Female)")
print()

# Query the data
df = unicefdata(
    indicator='CME_MRY0T4',
    countries=['BGD'],
    sex=['_T', 'M', 'F']  # Total, Male, Female
)

print(f"Retrieved {len(df)} observations\n")

if df is not None and not df.empty:
    # Check available years
    available_years = sorted(df['period'].unique(), reverse=True)
    print(f"Available years: {[int(y) for y in available_years[:10]]}...\n")
    
    # Get 2020 data or closest year
    target_year = 2020.0
    closest_year = min(available_years, key=lambda x: abs(x - target_year))
    
    df_year = df[df['period'] == closest_year].copy()
    
    if not df_year.empty:
        print(f"Data for year {int(closest_year)}:")
        print("-" * 70)
        
        # Sort by sex (total first, then M, F)
        sex_order = {'_T': 0, 'M': 1, 'F': 2}
        df_year['sex_order'] = df_year['sex'].map(sex_order)
        df_year = df_year.sort_values('sex_order')
        
        for _, row in df_year.iterrows():
            sex_code = row['sex']
            value = row['value']
            sex_label = {'_T': 'Total', 'M': 'Male', 'F': 'Female'}.get(sex_code, sex_code)
            print(f"  {sex_label:10} ({sex_code:3}): {value:6.1f} deaths per 1,000 live births")
        
        # Extract values for LaTeX
        total_val = df_year[df_year['sex'] == '_T']['value'].values[0]
        male_val = df_year[df_year['sex'] == 'M']['value'].values[0]
        female_val = df_year[df_year['sex'] == 'F']['value'].values[0]
        
        print()
        print("LaTeX snippet for paper:")
        print("=" * 70)
        print(f"For example, the under-5 mortality rate for Bangladesh in {int(closest_year)} disaggregated by sex yields three observations: ")
        print(f"the total rate (\\texttt{{_T}} = {total_val:.1f} deaths per 1,000 live births), ")
        print(f"the rate for males (\\texttt{{M}} = {male_val:.1f}), ")
        print(f"and the rate for females (\\texttt{{F}} = {female_val:.1f}).")
        print("=" * 70)
    else:
        print(f"No data found for {int(closest_year)}")
else:
    print("No data retrieved")

print("\n" + "=" * 70)
print("COMPLETE DISAGGREGATION TABLE")
print("=" * 70)
print("\nQuerying all disaggregations for Bangladesh 2020...")
print("(Sex × Wealth Quintile combinations)\n")

# Query with raw=True to get all disaggregations
df_all = unicefdata(
    indicator='CME_MRY0T4',
    countries=['BGD'],
    raw=True  # Get all disaggregations without filtering
)

if df_all is not None and not df_all.empty:
    # Filter for Bangladesh and 2020 (raw format uses uppercase columns)
    df_bgd = df_all[df_all['REF_AREA'] == 'BGD'].copy()
    df_2020 = df_bgd[df_bgd['TIME_PERIOD'] == 2020.0].copy()
    
    if not df_2020.empty:
        print(f"Found {len(df_2020)} observations for Bangladesh in 2020\n")
        
        # Create pivot table: Sex (rows) × Wealth Quintile (columns)
        pivot = df_2020.pivot_table(
            values='OBS_VALUE',
            index='SEX',
            columns='WEALTH_QUINTILE',
            aggfunc='first'
        )
        
        # Reorder rows and columns
        sex_order = ['_T', 'M', 'F']
        wealth_order = ['_T', 'Q1', 'Q2', 'Q3', 'Q4', 'Q5']
        
        # Filter to available values
        available_sex = [s for s in sex_order if s in pivot.index]
        available_wealth = [w for w in wealth_order if w in pivot.columns]
        
        pivot = pivot.reindex(index=available_sex, columns=available_wealth)
        
        print("Under-5 Mortality Rate (per 1,000 live births)")
        print("Bangladesh, 2020")
        print()
        print(pivot.to_string())
        print()
        
        # Create LaTeX table
        print("\nLaTeX Table:")
        print("-" * 70)
        print("\\begin{table}[htbp]")
        print("\\centering")
        print("\\caption{Under-5 Mortality Rate for Bangladesh in 2020 by Sex and Wealth Quintile}")
        print("\\label{tab:bgd-mortality-disagg}")
        print("\\begin{tabular}{lcccccc}")
        print("\\hline")
        print("Sex & Total & Q1 & Q2 & Q3 & Q4 & Q5 \\\\")
        print("    & (\\texttt{\\_T}) & (\\texttt{Q1}) & (\\texttt{Q2}) & (\\texttt{Q3}) & (\\texttt{Q4}) & (\\texttt{Q5}) \\\\")
        print("    & (All) & (Poorest) & & & & (Richest) \\\\")
        print("\\hline")
        
        sex_labels = {'_T': 'Total', 'M': 'Male', 'F': 'Female'}
        for sex in available_sex:
            label = sex_labels.get(sex, sex)
            row_label = f"{label} (\\texttt{{{sex}}})"
            row_values = []
            for wq in available_wealth:
                val = pivot.loc[sex, wq] if (sex in pivot.index and wq in pivot.columns) else None
                if pd.notna(val):
                    row_values.append(f"{val:.1f}")
                else:
                    row_values.append("--")
            print(f"{row_label:25} & " + " & ".join(row_values) + " \\\\")
        
        print("\\hline")
        print("\\end{tabular}")
        print("\\end{table}")
        print("-" * 70)
    else:
        print("No data for 2020")
else:
    print("No data retrieved")
