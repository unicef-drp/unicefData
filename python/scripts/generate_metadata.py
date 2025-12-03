"""
Generate Metadata Script
========================

This script uses the MetadataSync class to generate the full set of metadata files
required to replicate the R package structure:
- dataflows.yaml
- codelists.yaml
- indicators.yaml
- current/ (dataflow schemas)

Usage:
    python python/scripts/generate_metadata.py
"""

import sys
import os
import logging

# Add python directory to path
sys.path.append(os.path.join(os.path.dirname(__file__), '..'))

from unicef_api.metadata import MetadataSync
from unicef_api.schema_sync import sync_dataflow_schemas

def main():
    print("Starting metadata generation...")
    
    # Define metadata directory
    # We want it to be in python/metadata relative to the repo root
    repo_root = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
    metadata_dir = os.path.join(repo_root, 'python', 'metadata')
    current_dir = os.path.join(metadata_dir, 'current')
    
    print(f"Target directory: {metadata_dir}")
    
    # 1. Run high-level sync (dataflows.yaml, codelists.yaml, indicators.yaml)
    print("\n--- Step 1: High-level Metadata Sync ---")
    sync = MetadataSync(cache_dir=metadata_dir)
    results = sync.sync_all(verbose=True, create_vintage=True)
    
    # 2. Run deep sync (individual dataflow schemas)
    print("\n--- Step 2: Deep Schema Sync (Dataflow Definitions) ---")
    # We only sync a few key dataflows to save time, or all if needed.
    # For replication, we should probably sync all, but it takes time.
    # Let's sync the ones we know are important + a few others.
    # Or just run it for all if the user wants full replication.
    # The user asked to "check if the scripts... are up and running".
    # Running for all might take too long for this interaction.
    # Let's run for the ones in the examples + a few more.
    
    # Actually, let's check if we can run it for all but maybe it's fast enough?
    # schema_sync.py has a delay of 0.2s per dataflow. 69 dataflows * 0.2 = 14s.
    # Plus fetching time. It might take 1-2 mins. That's acceptable.
    
    sync_dataflow_schemas(output_dir=current_dir, verbose=True)
    
    print("\nMetadata generation complete!")
    print(f"Output directory: {current_dir}")

if __name__ == "__main__":
    main()
