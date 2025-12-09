#!/usr/bin/env python3
r"""
sync_metadata_python.py - Sync Python metadata from UNICEF SDMX API
====================================================================

This is a standalone script for syncing Python metadata only.
For syncing all languages, use the orchestrator:
    python tests/orchestrator_metadata.py --all

Usage:
    python tests/sync_metadata_python.py [--verbose]

Run from repository root (e.g., C:\GitHub\others\unicefData)
Log output: tests/logs/sync_metadata_python.log
"""

import sys
import logging
from pathlib import Path
from datetime import datetime

# Setup paths
SCRIPT_DIR = Path(__file__).parent.resolve()
REPO_ROOT = SCRIPT_DIR.parent
LOG_DIR = SCRIPT_DIR / "logs"

# Ensure log directory exists
LOG_DIR.mkdir(exist_ok=True)

# Configure logging to file and console
log_file = LOG_DIR / "sync_metadata_python.log"
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler(log_file, mode='w', encoding='utf-8'),
        logging.StreamHandler(sys.stdout)
    ]
)
logger = logging.getLogger(__name__)


def clean_metadata_folder(folder: Path, verbose: bool = False) -> int:
    """Clean YAML files from a metadata folder.
    
    Returns:
        Number of files deleted
    """
    deleted = 0
    if not folder.exists():
        return 0
    
    # Clean YAML files in current folder
    for yaml_file in folder.glob("*.yaml"):
        if verbose:
            logger.info(f"  Removing: {yaml_file.name}")
        yaml_file.unlink()
        deleted += 1
    
    # Clean YAML files in dataflows subfolder
    dataflows_dir = folder / "dataflows"
    if dataflows_dir.exists():
        for yaml_file in dataflows_dir.glob("*.yaml"):
            if verbose:
                logger.info(f"  Removing: dataflows/{yaml_file.name}")
            yaml_file.unlink()
            deleted += 1
    
    return deleted


def sync_python_metadata(verbose: bool = False) -> bool:
    """Sync Python metadata from UNICEF SDMX API."""
    
    python_dir = REPO_ROOT / "python"
    metadata_dir = python_dir / "metadata" / "current"
    
    logger.info("=" * 70)
    logger.info("Python Metadata Sync")
    logger.info(f"Started: {datetime.now().isoformat()}")
    logger.info("=" * 70)
    logger.info("")
    
    # Clean existing metadata
    deleted = clean_metadata_folder(metadata_dir, verbose)
    logger.info(f"Cleaned {deleted} existing files")
    
    # Add python directory to path
    sys.path.insert(0, str(python_dir))
    
    try:
        # Import and run the metadata sync
        logger.info("Syncing metadata from UNICEF SDMX API...")
        from unicef_api.metadata import MetadataSync
        
        sync = MetadataSync(cache_dir=str(python_dir / "metadata"))
        results = sync.sync_all(verbose=verbose, create_vintage=False)
        
        # Count generated files
        file_count = len(list(metadata_dir.glob("*.yaml")))
        dataflow_count = len(list((metadata_dir / "dataflows").glob("*.yaml"))) if (metadata_dir / "dataflows").exists() else 0
        
        logger.info("")
        logger.info("-" * 70)
        logger.info("RESULTS")
        logger.info("-" * 70)
        logger.info(f"  Generated {file_count} metadata files + {dataflow_count} dataflow schemas")
        logger.info(f"  Dataflows:  {results.get('dataflows', 'N/A')}")
        logger.info(f"  Countries:  {results.get('countries', 'N/A')}")
        logger.info(f"  Regions:    {results.get('regions', 'N/A')}")
        logger.info(f"  Indicators: {results.get('indicators', 'N/A')}")
        
        errors = results.get('errors', [])
        if errors:
            logger.warning(f"  Errors: {len(errors)}")
            for err in errors[:5]:
                logger.warning(f"    - {err}")
        
        logger.info("")
        if len(errors) == 0:
            logger.info("[OK] Python metadata sync completed successfully!")
        else:
            logger.warning(f"[WARN] Completed with {len(errors)} errors")
        
        return len(errors) == 0
        
    except ImportError as e:
        logger.error(f"Import error: {e}")
        logger.error("Make sure you have the required packages: pip install requests pyyaml")
        return False
    except Exception as e:
        logger.error(f"Error: {e}")
        return False
    finally:
        # Remove from path
        if str(python_dir) in sys.path:
            sys.path.remove(str(python_dir))
        
        logger.info("")
        logger.info("=" * 70)
        logger.info(f"Finished: {datetime.now().isoformat()}")
        logger.info("=" * 70)
        logger.info(f"Log saved to: {log_file}")


def main():
    import argparse
    
    parser = argparse.ArgumentParser(
        description="Sync Python metadata from UNICEF SDMX API"
    )
    parser.add_argument("--verbose", "-v", action="store_true", help="Verbose output")
    args = parser.parse_args()
    
    success = sync_python_metadata(verbose=args.verbose)
    return 0 if success else 1


if __name__ == "__main__":
    sys.exit(main())
