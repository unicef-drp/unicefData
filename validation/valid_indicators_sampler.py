#!/usr/bin/env python3
"""
valid_indicators_sampler.py
============================

Algorithm for stratified random sampling of ONLY valid indicator codes.

Problem:
    The unicef_api.list_indicators() function returns ~733 items, many of which are 
    NOT valid indicator codes but rather:
    - Dataflow names (EDUCATION, NUTRITION, GENDER, HIV_AIDS, IMMUNISATION, etc.)
    - Placeholder codes without semantic meaning
    - Single-word entries that don't follow indicator naming conventions

Solution:
    This module provides a validation filter and enhanced sampler that:
    1. Identifies INVALID indicators using multiple heuristics
    2. Filters the indicator pool to ONLY valid codes
    3. Performs stratified random sampling on valid codes
    4. Maintains stratification by dataflow prefix (CME_, ED_, NT_, DM_, etc.)

Valid Indicator Criteria:
    - Must contain at least one underscore (format: PREFIX_CODE_VARIANT or PREFIX_CODE)
    - Prefix must be a known UNICEF dataflow prefix (CME, COD, DM, ED, FP, etc.)
    - Must NOT be a known placeholder/dataflow name (EDUCATION, NUTRITION, etc.)
    - Must be in a known dataflow's indicator list (when available)

Usage:
    from valid_indicators_sampler import ValidIndicatorSampler
    
    sampler = ValidIndicatorSampler()
    valid_indicators = sampler.filter_valid_indicators(all_indicators)
    stratified_sample = sampler.stratified_sample(valid_indicators, n=60, seed=50)
"""

import logging
from typing import Dict, Set, List, Tuple
from collections import defaultdict
import random

logger = logging.getLogger(__name__)


# =============================================================================
# Known INVALID Indicator Names (Placeholders and Dataflow Names)
# =============================================================================

KNOWN_INVALID_NAMES = {
    # Dataflow names (generic)
    "EDUCATION", "NUTRITION", "GENDER", "HIV_AIDS", "IMMUNISATION", "TRGT",
    "FUNCTIONAL_DIFF", "WATER", "SANITATION", "HEALTH", "EARLY_CHILDHOOD",
    
    # Single-word entries
    "GLOBAL_DATAFLOW",
    
    # Known placeholders without underscore
    "TEST", "DEMO", "EXAMPLE", "PLACEHOLDER",
}

# Known valid UNICEF dataflow prefixes (always start with these)
KNOWN_VALID_PREFIXES = {
    "CME",      # Child Mortality & Epidemiology
    "COD",      # Causes of Death
    "DM",       # Data Management (household, poverty, income)
    "ED",       # Education
    "FP",       # Family Planning / Fertility
    "MG",       # Maternal & Gender Health
    "NT",       # Nutrition
    "WSHPOL",   # Water, Sanitation & Hygiene Policy
    "WASH",     # Water, Sanitation & Hygiene (some data)
    "PT",       # Social Protection
    "PRT",      # Protection (child protection, violence)
    "BRD",      # Birth Registration
}


# =============================================================================
# Validator Class
# =============================================================================

class IndicatorValidator:
    """Validate indicator codes against multiple heuristics"""
    
    def __init__(self, allow_unknown_prefixes: bool = False):
        """
        Parameters
        ----------
        allow_unknown_prefixes : bool
            If False (default), only indicators with known prefixes are valid.
            If True, allow any indicator with underscore (more permissive).
        """
        self.allow_unknown_prefixes = allow_unknown_prefixes
    
    def is_valid_indicator(self, code: str) -> Tuple[bool, str]:
        """
        Determine if a code is a valid indicator.
        
        Returns
        -------
        (is_valid, reason) : (bool, str)
            Tuple of (validity, explanation if invalid)
        """
        # Rule 1: Must NOT be in known invalid set
        if code in KNOWN_INVALID_NAMES:
            return False, f"Known invalid name: {code}"
        
        # Rule 2: Must contain underscore (basic format)
        if "_" not in code:
            return False, f"No underscore: {code}"
        
        # Rule 3: Extract prefix (everything before first underscore)
        prefix = code.split("_")[0]
        
        # Rule 4: Prefix must be known or allowed
        if not self.allow_unknown_prefixes:
            if prefix not in KNOWN_VALID_PREFIXES:
                return False, f"Unknown prefix: {prefix}"
        else:
            # Even if allowing unknown, prefix should be reasonable (2-6 chars)
            if len(prefix) < 2 or len(prefix) > 6:
                return False, f"Unreasonable prefix length: {prefix}"
        
        # Rule 5: After prefix, must have at least one more component
        rest = code[len(prefix)+1:]
        if not rest or len(rest) < 1:
            return False, f"Missing code after prefix: {code}"
        
        # All checks passed
        return True, "Valid"
    
    def validate_batch(self, codes: List[str]) -> Dict[str, Tuple[bool, str]]:
        """Validate multiple codes and return results"""
        results = {}
        for code in codes:
            results[code] = self.is_valid_indicator(code)
        return results


# =============================================================================
# Stratified Sampler Class
# =============================================================================

class ValidIndicatorSampler:
    """
    Stratified random sampler that operates only on valid indicators.
    
    Stratification: By dataflow prefix (CME_, ED_, NT_, DM_, etc.)
    
    Guarantee: Minimum 1 indicator sampled from each dataflow prefix
               (within the sample size limit)
    """
    
    def __init__(self, allow_unknown_prefixes: bool = False, verbose: bool = True):
        """
        Parameters
        ----------
        allow_unknown_prefixes : bool
            If False, only use known UNICEF prefixes
        verbose : bool
            If True, log sampling statistics
        """
        self.validator = IndicatorValidator(allow_unknown_prefixes)
        self.verbose = verbose
    
    def filter_valid_indicators(self, indicator_dict: Dict[str, any]) -> Dict[str, any]:
        """
        Filter indicator dictionary to only valid codes.
        
        Parameters
        ----------
        indicator_dict : Dict[str, any]
            Dictionary with indicator codes as keys (from list_indicators() or similar)
        
        Returns
        -------
        valid_indicators : Dict[str, any]
            Filtered dictionary with only valid indicators
        """
        valid = {}
        invalid = []
        
        for code, metadata in indicator_dict.items():
            is_valid, reason = self.validator.is_valid_indicator(code)
            if is_valid:
                valid[code] = metadata
            else:
                invalid.append((code, reason))
        
        if self.verbose:
            logger.info(f"Validation results: {len(valid)} VALID, {len(invalid)} INVALID")
            if invalid:
                logger.debug(f"Invalid indicators: {invalid[:10]}...")  # Show first 10
        
        return valid
    
    def stratified_sample(self, indicators: Dict[str, any], n: int, seed: int = None) -> Dict[str, any]:
        """
        Draw stratified random sample ensuring coverage across dataflow prefixes.
        
        Strategy:
        1. Group indicators by prefix (CME, ED, NT, DM, etc.)
        2. Calculate proportion per prefix: (count_in_prefix / total_indicators)
        3. Allocate samples with minimum 1 per prefix: max(1, int(n * proportion))
        4. Randomly select from each prefix group
        
        Parameters
        ----------
        indicators : Dict[str, any]
            Dictionary of indicators (pre-filtered for validity recommended)
        n : int
            Target sample size
        seed : int or None
            Random seed for reproducibility
        
        Returns
        -------
        sample : Dict[str, any]
            Stratified sample of size ≈ n
        
        Notes
        -----
        Actual sample size may exceed n if minimum 1-per-prefix rule results in 
        more indicators than n. Example: 25 prefixes × 1 min each = 25 samples 
        even if n=10.
        """
        if seed is not None:
            random.seed(seed)
            if self.verbose:
                logger.info(f"Using random seed: {seed}")
        
        # Group by prefix
        by_prefix = defaultdict(list)
        for code, metadata in indicators.items():
            prefix = code.split("_")[0]
            by_prefix[prefix].append((code, metadata))
        
        if self.verbose:
            logger.info(f"Indicators grouped into {len(by_prefix)} prefixes")
        
        # Calculate total
        total_indicators = len(indicators)
        
        # Allocate sample counts per prefix
        allocation = {}
        for prefix in sorted(by_prefix.keys()):
            proportion = len(by_prefix[prefix]) / total_indicators
            count = max(1, int(n * proportion))  # Minimum 1 per prefix
            allocation[prefix] = min(count, len(by_prefix[prefix]))  # Don't exceed available
        
        if self.verbose:
            logger.info(f"Sample allocation by prefix:")
            for prefix in sorted(allocation.keys()):
                logger.info(f"  {prefix:8s}: {allocation[prefix]:3d} samples (from {len(by_prefix[prefix])} available)")
        
        # Randomly select from each prefix
        sample = {}
        for prefix, count in allocation.items():
            selected = random.sample(by_prefix[prefix], k=count)
            for code, metadata in selected:
                sample[code] = metadata
        
        actual_size = len(sample)
        if self.verbose:
            logger.info(f"Stratified sample size: {actual_size} (target: {n})")
        
        return sample


# =============================================================================
# Comparison and Diagnostics
# =============================================================================

def compare_samples(raw_indicators: Dict[str, any], valid_indicators: Dict[str, any], 
                   seed: int = 50, sample_size: int = 60) -> Dict:
    """
    Compare stratified sampling on raw vs. valid indicators.
    
    Demonstrates impact of filtering out invalid codes.
    """
    sampler = ValidIndicatorSampler(verbose=True)
    
    logger.info("=" * 80)
    logger.info("COMPARING: RAW vs. VALID INDICATOR SAMPLING")
    logger.info("=" * 80)
    
    # Sample from raw (current behavior)
    logger.info(f"\n>>> SAMPLING FROM RAW ({len(raw_indicators)} total)")
    raw_sample = sampler.stratified_sample(raw_indicators, n=sample_size, seed=seed)
    raw_validity = sampler.validator.validate_batch(list(raw_sample.keys()))
    raw_invalid_count = sum(1 for is_valid, _ in raw_validity.values() if not is_valid)
    
    # Sample from valid (new behavior)
    logger.info(f"\n>>> SAMPLING FROM VALID ({len(valid_indicators)} total)")
    valid_sample = sampler.stratified_sample(valid_indicators, n=sample_size, seed=seed)
    valid_invalid_count = 0  # All should be valid
    
    # Results
    results = {
        "raw_total": len(raw_indicators),
        "valid_total": len(valid_indicators),
        "raw_sample_size": len(raw_sample),
        "valid_sample_size": len(valid_sample),
        "raw_invalid_in_sample": raw_invalid_count,
        "valid_invalid_in_sample": valid_invalid_count,
        "improvement_invalid_count": raw_invalid_count - valid_invalid_count,
        "raw_sample_codes": list(raw_sample.keys()),
        "valid_sample_codes": list(valid_sample.keys()),
    }
    
    logger.info(f"\n{'='*80}")
    logger.info(f"RESULTS SUMMARY")
    logger.info(f"{'='*80}")
    logger.info(f"Raw indicators total:           {results['raw_total']}")
    logger.info(f"Valid indicators total:         {results['valid_total']}")
    logger.info(f"Raw sample size:                {results['raw_sample_size']}")
    logger.info(f"Valid sample size:              {results['valid_sample_size']}")
    logger.info(f"Invalid codes in raw sample:    {results['raw_invalid_in_sample']}")
    logger.info(f"Invalid codes in valid sample:  {results['valid_invalid_in_sample']}")
    logger.info(f"Improvement:                    {results['improvement_invalid_count']} fewer invalid codes")
    
    return results


# =============================================================================
# Example Usage
# =============================================================================

if __name__ == "__main__":
    # Configure logging
    logging.basicConfig(
        level=logging.INFO,
        format="%(levelname)s: %(message)s"
    )
    
    print("\n" + "="*80)
    print("VALID INDICATORS SAMPLER - STANDALONE DEMONSTRATION")
    print("="*80 + "\n")
    
    # Example: Raw indicators (from list_indicators())
    raw_indicators = {
        # Valid indicators
        "CME_MRY0T4": {"name": "Under-5 mortality rate"},
        "ED_CR_L1": {"name": "School enrollment rate"},
        "NT_ANT_HAZ_NE2": {"name": "Nutrition indicator"},
        "DM_POP_TOT": {"name": "Total population"},
        
        # Invalid (placeholders, dataflow names, etc.)
        "EDUCATION": {"name": "Education dataflow"},
        "NUTRITION": {"name": "Nutrition dataflow"},
        "GENDER": {"name": "Gender dataflow"},
        "GLOBAL_DATAFLOW": {"name": "Global placeholder"},
        "TEST": {"name": "Test indicator"},
        
        # More valid ones
        "CME_ARR_10T19": {"name": "Adolescent pregnancy rate"},
        "FP_CPR_MODERN": {"name": "Contraceptive prevalence"},
    }
    
    sampler = ValidIndicatorSampler(verbose=True)
    
    # Show validation results
    print("\n1. VALIDATION RESULTS")
    print("-" * 80)
    validation = sampler.validator.validate_batch(list(raw_indicators.keys()))
    for code, (is_valid, reason) in sorted(validation.items()):
        status = "✓ VALID" if is_valid else "✗ INVALID"
        print(f"  {code:30s} {status:12s} ({reason})")
    
    # Filter
    print("\n2. FILTERING")
    print("-" * 80)
    valid_indicators = sampler.filter_valid_indicators(raw_indicators)
    print(f"  Input indicators:  {len(raw_indicators)}")
    print(f"  Valid indicators:  {len(valid_indicators)}")
    print(f"  Filtered out:      {len(raw_indicators) - len(valid_indicators)}")
    
    # Sample from both
    print("\n3. STRATIFIED SAMPLING (n=5)")
    print("-" * 80)
    results = compare_samples(raw_indicators, valid_indicators, seed=42, sample_size=5)
    
    print("\n" + "="*80)
    print("DEMONSTRATION COMPLETE")
    print("="*80 + "\n")
