# Stratified Sampling: Current Implementation & Recommendations

## Current Implementation

### 1. **Is it Proportional to Size? YES ✅**

Current code in `valid_indicators_sampler.py` (lines ~300-320):

```python
def stratified_sample(self, indicators, n, seed=None):
    # Group by prefix (CME, ED, NT, DM, etc.)
    by_prefix = defaultdict(list)
    
    # Calculate proportion per prefix
    for prefix in sorted(by_prefix.keys()):
        proportion = len(by_prefix[prefix]) / total_indicators  # ← PROPORTIONAL
        count = max(1, int(n * proportion))  # ← Sample size = n × proportion
```

**Status:** Already proportional to size per dataflow prefix ✓

**Example (645 valid indicators):**
- CME: 125 indicators (19.4%) → ~194 samples per 1000 total (or ~6 per 30)
- ED: 95 indicators (14.7%) → ~147 samples per 1000 total (or ~4 per 30)
- NT: 87 indicators (13.5%) → ~135 samples per 1000 total (or ~4 per 30)
- ... (18 prefixes total)

### 2. **Is the Stratification Variable Flexible? PARTIALLY ⚠️**

Current implementation **hard-codes** stratification by dataflow prefix:

```python
prefix = code.split("_")[0]  # ← HARD-CODED to first underscore
by_prefix[prefix].append((code, metadata))
```

**Fixed stratification variable:** Dataflow prefix only

**Limitations:**
- Cannot stratify by other dimensions (e.g., by data availability, by complexity)
- Cannot stratify by combined attributes (e.g., "dataflow × geography scope")
- Cannot stratify hierarchically (e.g., first by availability, then by prefix)

---

## Recommendations

### 🎯 **Recommendation 1: Make Stratification Variable Flexible**

**Benefit:** Enable different stratification strategies without rewriting code

**Implementation:**

```python
class ValidIndicatorSampler:
    def __init__(self, stratification_key='dataflow_prefix', **kwargs):
        """
        Parameters
        ----------
        stratification_key : str or callable
            'dataflow_prefix' (default) - stratify by CME_, ED_, etc.
            'indicator_length' - stratify by short vs. long names
            callable - user-provided function(code) → stratum_label
        """
        self.stratification_key = stratification_key
    
    def stratified_sample(self, indicators, n, seed=None):
        # Group by user-specified stratification variable
        by_stratum = self._group_by_stratification(indicators)
        # ... rest of sampling logic ...
    
    def _group_by_stratification(self, indicators):
        """Group indicators using flexible stratification key"""
        by_stratum = defaultdict(list)
        
        for code, metadata in indicators.items():
            if callable(self.stratification_key):
                stratum = self.stratification_key(code, metadata)
            elif self.stratification_key == 'dataflow_prefix':
                stratum = code.split("_")[0]
            elif self.stratification_key == 'indicator_length':
                # Stratify: short (≤20 chars), medium (21-40), long (>40)
                stratum = self._classify_by_length(code)
            # Add other built-in strategies as needed...
            
            by_stratum[stratum].append((code, metadata))
        
        return by_stratum
```

**Built-in Strategies (Easy to Add):**

| Strategy | Code | Purpose | Example |
|----------|------|---------|---------|
| Dataflow prefix | `'dataflow_prefix'` | Default - ensures coverage across CME, ED, NT, etc. | `CME_MRY0T4` → `CME` |
| Indicator complexity | `'complexity'` | Short/medium/long codes | `CME_MRY0T4` → `short` |
| Geographic scope | `'geography'` | Country-level vs. regional vs. global | Based on metadata |
| Data availability | `'availability'` | High/medium/low completeness | Calculated from cache |
| Custom callable | `my_function` | User-defined grouping | Any function(code, metadata) |

---

### 🎯 **Recommendation 2: Keep Proportional Allocation (Current is Good)**

Current implementation is correct:

```python
count = max(1, int(n * proportion))
```

**Good:** Ensures small strata aren't ignored (minimum 1 per stratum)

**When to Override:**
- **Equal allocation:** All strata get equal samples (useful for small datasets)
- **Optimal allocation:** Neyman allocation (sample size proportional to √size × std_dev)
- **Custom weights:** Administrator-specified allocations per stratum

**Add as option:**

```python
def stratified_sample(
    self, indicators, n, seed=None,
    allocation_strategy='proportional'  # ← NEW
):
    """
    allocation_strategy : str
        'proportional' - Sample size ∝ stratum size (default, current)
        'equal' - Equal samples from each stratum
        'custom' - User-provided allocation dict
    """
```

---

### 🎯 **Recommendation 3: Add Hierarchical/Multi-Dimensional Stratification**

**Use Case:** Test rare combinations (e.g., "long indicator codes in small dataflows")

**Implementation:**

```python
sampler = ValidIndicatorSampler(
    stratification_key=lambda code, meta: (
        code.split("_")[0],              # Stratum 1: dataflow prefix
        'long' if len(code) > 25 else 'short'  # Stratum 2: code length
    )
)
```

This creates strata like `('CME', 'long')`, `('CME', 'short')`, etc.

---

## Decision Matrix

| Need | Current? | Recommendation |
|------|----------|-----------------|
| **Proportional to size** | ✅ Yes | **Keep as is** |
| **Flexible stratification variable** | ❌ No | **Add as priority** |
| **Equal allocation option** | ❌ No | **Add as option** |
| **Multi-dimensional stratification** | ❌ No | **Add advanced feature** |
| **Custom allocation weights** | ❌ No | **Add as advanced feature** |

---

## Implementation Priority

### Phase 1 (Recommended) - **Enable Flexibility**
```python
# Current code (1 option):
ValidIndicatorSampler()

# Phase 1 (flexible):
ValidIndicatorSampler(stratification_key='dataflow_prefix')  # Default
ValidIndicatorSampler(stratification_key='complexity')
ValidIndicatorSampler(stratification_key=my_custom_function)
```

**Effort:** Low (30-50 lines refactoring)  
**Value:** High (supports multiple research strategies without code duplication)

### Phase 2 (Optional) - **Allocation Strategies**
```python
sampler.stratified_sample(n=100, allocation_strategy='equal')
sampler.stratified_sample(n=100, allocation_strategy='custom', 
                         allocations={'CME': 20, 'ED': 15, ...})
```

**Effort:** Medium (50-100 lines)  
**Value:** Medium (supports specific testing requirements)

### Phase 3 (Advanced) - **Multi-Dimensional**
```python
sampler = ValidIndicatorSampler(
    stratification_key=[
        'dataflow_prefix',  # Primary
        'complexity'        # Secondary
    ]
)
```

**Effort:** Medium (80-120 lines)  
**Value:** Low-Medium (nice to have, not critical)

---

## Example Usage After Enhancement

```python
# Use case 1: Current behavior (backward compatible)
sampler = ValidIndicatorSampler()
sample = sampler.stratified_sample(all_indicators, n=100)

# Use case 2: Test by code length complexity
sampler = ValidIndicatorSampler(stratification_key='complexity')
sample = sampler.stratified_sample(all_indicators, n=100)

# Use case 3: Custom stratification by data tier
def get_tier(code, metadata):
    if 'tier' in metadata:
        return metadata['tier']  # TIER_1, TIER_2, etc.
    return 'UNKNOWN'

sampler = ValidIndicatorSampler(stratification_key=get_tier)
sample = sampler.stratified_sample(all_indicators, n=100)

# Use case 4: Equal allocation across prefixes
sample = sampler.stratified_sample(
    all_indicators, n=100,
    allocation_strategy='equal'  # Each prefix gets 100÷18 ≈ 5-6 samples
)
```

---

## Questions to Consider

1. **Do you want backward compatibility?** (Yes recommended - makes adoption easy)
2. **Should we cache stratification results?** (Yes - useful for reproducible test sets)
3. **Should stratification key be logged in test results?** (Yes - helps debugging)
4. **Do we need validation that stratification_key returns consistent results?** (Maybe - defensive programming)

---

## Summary

| Aspect | Current | Recommendation |
|--------|---------|-----------------|
| **Proportional to size** | ✅ Implemented | Keep as default |
| **Flexible stratification** | ❌ Hard-coded | **Add - Priority 1** |
| **Multiple allocation methods** | ❌ Fixed | Add - Priority 2 |
| **Multi-dimensional** | ❌ No | Add - Priority 3 |

**Next step:** Would you like me to implement Phase 1 (flexible stratification variable)?
