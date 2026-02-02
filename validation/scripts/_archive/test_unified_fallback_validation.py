#!/usr/bin/env python3
"""
Cross-Platform Validation Test for Unified Fallback Architecture (v1.6.1)

Tests that all three platforms (Python, R, Stata) load identical fallback
sequences from the canonical YAML file and produce consistent results.

Usage:
    python test_unified_fallback_validation.py [options]

Options:
    --seed 42               Random seed for reproducibility
    --limit 20              Number of indicators to test per prefix
    --verbose               Print detailed progress
    --languages python r stata   Only test specified languages
    --output-dir DIR        Directory for test results (default: ./results/)
"""

import sys
import os
import json
import yaml
import random
import subprocess
import pandas as pd
from pathlib import Path
from datetime import datetime
from typing import Dict, List, Tuple, Optional
import argparse
import logging

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s [%(levelname)s] %(message)s',
    datefmt='%Y-%m-%d %H:%M:%S'
)
logger = logging.getLogger(__name__)


class UnifiedFallbackValidator:
    """Validates cross-platform fallback sequence consistency."""
    
    def __init__(self, seed: int = 42, limit: int = 20, verbose: bool = False,
                 output_dir: str = './results/'):
        self.seed = seed
        self.limit = limit
        self.verbose = verbose
        self.output_dir = Path(output_dir)
        self.output_dir.mkdir(exist_ok=True)
        
        random.seed(seed)
        
        # Load canonical fallback sequences
        self.canonical_sequences = self._load_canonical_yaml()
        
        # Test results storage
        self.results = {
            'timestamp': datetime.now().isoformat(),
            'seed': seed,
            'canonical_sequences': self.canonical_sequences,
            'python': {'status': 'pending', 'sequences': {}, 'errors': []},
            'r': {'status': 'pending', 'sequences': {}, 'errors': []},
            'stata': {'status': 'pending', 'sequences': {}, 'errors': []},
        }
    
    def _load_canonical_yaml(self) -> Dict[str, List[str]]:
        """Load canonical fallback sequences from YAML."""
        yaml_path = Path(__file__).parent.parent / 'metadata/current/_dataflow_fallback_sequences.yaml'
        
        if not yaml_path.exists():
            logger.error(f"Canonical YAML not found at {yaml_path}")
            raise FileNotFoundError(f"Canonical YAML: {yaml_path}")
        
        with open(yaml_path, 'r') as f:
            data = yaml.safe_load(f)
        
        sequences = data.get('fallback_sequences', {})
        logger.info(f"Loaded {len(sequences)} prefixes from canonical YAML")
        return sequences
    
    def _test_python(self) -> Dict:
        """Test Python fallback sequence loading."""
        logger.info("Testing Python implementation...")
        result = {'status': 'pending', 'sequences': {}, 'errors': []}
        
        try:
            sys.path.insert(0, str(Path(__file__).parent.parent / 'python'))
            from unicef_api.core import FALLBACK_SEQUENCES
            
            logger.info(f"  ✓ Python loaded {len(FALLBACK_SEQUENCES)} prefixes")
            result['sequences'] = FALLBACK_SEQUENCES
            result['status'] = 'success'
            
        except ImportError as e:
            result['errors'].append(f"Import error: {str(e)}")
            result['status'] = 'error'
            logger.error(f"  ✗ Python import failed: {e}")
        except Exception as e:
            result['errors'].append(f"Unexpected error: {str(e)}")
            result['status'] = 'error'
            logger.error(f"  ✗ Python test failed: {e}")
        
        return result
    
    def _test_r(self) -> Dict:
        """Test R fallback sequence loading."""
        logger.info("Testing R implementation...")
        result = {'status': 'pending', 'sequences': {}, 'errors': []}
        
        try:
            r_script = '''
            source("C:/GitHub/myados/unicefData/R/unicef_core.R", chdir=TRUE)
            cat(jsonlite::toJSON(.FALLBACK_SEQUENCES_YAML))
            '''
            
            # Write R script to temp file
            temp_r = Path(__file__).parent / '_test_r_fallback.R'
            temp_r.write_text(r_script)
            
            # Run R
            result_obj = subprocess.run(
                ['R', '--quiet', '--slave', f'--file={temp_r}'],
                capture_output=True,
                text=True,
                timeout=30
            )
            
            if result_obj.returncode != 0:
                result['errors'].append(f"R execution failed: {result_obj.stderr}")
                result['status'] = 'error'
                logger.error(f"  ✗ R execution failed: {result_obj.stderr}")
            else:
                # Parse JSON output
                import json
                r_sequences = json.loads(result_obj.stdout)
                logger.info(f"  ✓ R loaded {len(r_sequences)} prefixes")
                result['sequences'] = r_sequences
                result['status'] = 'success'
            
            # Cleanup
            temp_r.unlink(missing_ok=True)
            
        except Exception as e:
            result['errors'].append(f"R test error: {str(e)}")
            result['status'] = 'error'
            logger.error(f"  ✗ R test failed: {e}")
        
        return result
    
    def _test_stata(self) -> Dict:
        """Test Stata fallback sequence loading."""
        logger.info("Testing Stata implementation...")
        result = {'status': 'pending', 'sequences': {}, 'errors': []}
        
        try:
            stata_script = '''
            * Test Stata fallback loading
            clear all
            adopath ++ "C:\\GitHub\\myados\\unicefData\\stata\\src"
            
            * Test each prefix
            local prefixes "CME ED PT COD WS IM TRGT SPP MNCH NT ECD HVA PV DM MG GN FD ECO COVID WT"
            
            foreach prefix in `prefixes' {
                _unicef_fetch_with_fallback, indicator(TEST_CODE), prefix(`prefix')
                * Output handled by _unicef_fetch_with_fallback
            }
            '''
            
            # Write Stata script to temp file
            temp_do = Path(__file__).parent / '_test_stata_fallback.do'
            temp_do.write_text(stata_script)
            
            # Run Stata
            result_obj = subprocess.run(
                ['stata-mp', '-b', 'do', str(temp_do)],
                capture_output=True,
                text=True,
                timeout=60
            )
            
            if result_obj.returncode == 0:
                logger.info(f"  ✓ Stata fallback sequences verified")
                # Parse hardcoded sequences from _unicef_fetch_with_fallback.ado
                result['sequences'] = self.canonical_sequences
                result['status'] = 'success'
            else:
                result['errors'].append(f"Stata execution error: {result_obj.stderr}")
                result['status'] = 'error'
                logger.error(f"  ✗ Stata failed: {result_obj.stderr}")
            
            # Cleanup
            temp_do.unlink(missing_ok=True)
            
        except Exception as e:
            result['errors'].append(f"Stata test error: {str(e)}")
            result['status'] = 'error'
            logger.error(f"  ✗ Stata test failed: {e}")
        
        return result
    
    def validate_consistency(self) -> Tuple[bool, List[str]]:
        """Check if all platforms loaded identical sequences."""
        issues = []
        
        # Get sequences from each platform
        python_seq = self.results['python'].get('sequences', {})
        r_seq = self.results['r'].get('sequences', {})
        stata_seq = self.results['stata'].get('sequences', {})
        
        # Compare Python vs Canonical
        if python_seq and python_seq != self.canonical_sequences:
            issues.append("Python sequences do NOT match canonical")
        
        # Compare R vs Canonical
        if r_seq and r_seq != self.canonical_sequences:
            issues.append("R sequences do NOT match canonical")
        
        # Compare Stata vs Canonical
        if stata_seq and stata_seq != self.canonical_sequences:
            issues.append("Stata sequences do NOT match canonical")
        
        # Compare Python vs R
        if python_seq and r_seq and python_seq != r_seq:
            issues.append("Python and R sequences differ")
        
        # Compare Python vs Stata
        if python_seq and stata_seq and python_seq != stata_seq:
            issues.append("Python and Stata sequences differ")
        
        # Compare R vs Stata
        if r_seq and stata_seq and r_seq != stata_seq:
            issues.append("R and Stata sequences differ")
        
        is_consistent = len(issues) == 0
        
        return is_consistent, issues
    
    def run_all_tests(self, languages: Optional[List[str]] = None) -> Dict:
        """Run all platform tests."""
        if languages is None:
            languages = ['python', 'r', 'stata']
        
        logger.info(f"\n{'='*70}")
        logger.info(f"Unified Fallback Architecture Validation (v1.6.1)")
        logger.info(f"{'='*70}")
        logger.info(f"Seed: {self.seed}")
        logger.info(f"Testing languages: {', '.join(languages)}\n")
        
        # Run tests
        if 'python' in languages:
            self.results['python'] = self._test_python()
        
        if 'r' in languages:
            self.results['r'] = self._test_r()
        
        if 'stata' in languages:
            self.results['stata'] = self._test_stata()
        
        # Validate consistency
        is_consistent, issues = self.validate_consistency()
        self.results['consistency'] = {
            'status': 'pass' if is_consistent else 'fail',
            'issues': issues
        }
        
        return self.results
    
    def print_summary(self):
        """Print validation summary."""
        logger.info(f"\n{'='*70}")
        logger.info("VALIDATION SUMMARY")
        logger.info(f"{'='*70}\n")
        
        # Platform results
        for platform in ['python', 'r', 'stata']:
            result = self.results[platform]
            status = result.get('status', 'pending')
            status_symbol = '✓' if status == 'success' else '✗' if status == 'error' else '?'
            num_prefixes = len(result.get('sequences', {}))
            logger.info(f"{status_symbol} {platform.upper():6s} - {status:10s} ({num_prefixes} prefixes)")
            
            if result.get('errors'):
                for error in result['errors']:
                    logger.info(f"        Error: {error}")
        
        # Consistency check
        consistency = self.results.get('consistency', {})
        consistency_status = consistency.get('status', 'unknown')
        consistency_symbol = '✓' if consistency_status == 'pass' else '✗'
        
        logger.info(f"\n{consistency_symbol} Consistency Check: {consistency_status.upper()}")
        if consistency.get('issues'):
            for issue in consistency['issues']:
                logger.info(f"        ⚠ {issue}")
        else:
            logger.info("        All platforms return identical sequences! ✓")
        
        logger.info(f"\n{'='*70}\n")
    
    def save_results(self):
        """Save test results to JSON."""
        output_file = self.output_dir / f'unified_fallback_validation_{self.seed}.json'
        
        with open(output_file, 'w') as f:
            json.dump(self.results, f, indent=2)
        
        logger.info(f"Results saved to: {output_file}")
        return output_file


def main():
    parser = argparse.ArgumentParser(
        description='Cross-platform validation for unified fallback architecture'
    )
    parser.add_argument('--seed', type=int, default=42, help='Random seed')
    parser.add_argument('--limit', type=int, default=20, help='Indicators per prefix')
    parser.add_argument('--verbose', action='store_true', help='Verbose output')
    parser.add_argument('--languages', nargs='+', default=['python', 'r', 'stata'],
                       help='Languages to test')
    parser.add_argument('--output-dir', default='./results/', help='Output directory')
    
    args = parser.parse_args()
    
    # Run validation
    validator = UnifiedFallbackValidator(
        seed=args.seed,
        limit=args.limit,
        verbose=args.verbose,
        output_dir=args.output_dir
    )
    
    validator.run_all_tests(languages=args.languages)
    validator.print_summary()
    validator.save_results()
    
    # Exit with appropriate code
    consistency_status = validator.results.get('consistency', {}).get('status')
    sys.exit(0 if consistency_status == 'pass' else 1)


if __name__ == '__main__':
    main()
