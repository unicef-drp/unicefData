clear all
discard
adopath ++ './stata/src'

noisily di _newline(2) '=== TESTING CATEGORIES COMMAND ==='
noisily di _newline '* TIER 1 only (default):'
unicefdata categories

noisily di _newline '* SHOWALL (all tiers):'
unicefdata categories, showall

noisily di _newline '* SHOWTIER2:'
unicefdata categories, showtier2

noisily di _newline '* SHOWTIER3:'
unicefdata categories, showtier3

noisily di _newline(2) 'Done.'
