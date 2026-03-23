from __future__ import annotations

import os
from pathlib import Path

import yaml


def main() -> None:
    config_path = Path(".github/workflow-config.yml")
    if not config_path.exists():
        raise FileNotFoundError(f"Missing workflow config: {config_path}")

    config = yaml.safe_load(config_path.read_text(encoding="utf-8"))
    if not isinstance(config, dict):
        raise ValueError("workflow-config.yml must contain a mapping at top level")

    paths = config.get("paths", {})
    branches = config.get("branches", {})
    sync = config.get("sync", {})
    quality_gates = config.get("quality_gates", {})

    sync_target_repo = sync.get("target_repo", "unicef-drp/unicefData")
    sync_parts = str(sync_target_repo).split("/", maxsplit=1)
    sync_owner = sync_parts[0] if len(sync_parts) == 2 else "unicef-drp"
    sync_name = sync_parts[1] if len(sync_parts) == 2 else "unicefData"

    outputs = {
        "repo_mode": config.get("repo_mode", "dev"),
        "r_pkg_dir": paths.get("r_pkg_dir", "r"),
        "py_pkg_dir": paths.get("py_pkg_dir", "python"),
        "stata_metadata_dir": paths.get("stata_metadata_dir", "stata/src/_"),
        "metadata_dir": paths.get("metadata_dir", "metadata/current"),
        "validation_script": paths.get("validation_script", "validation/scripts/validate_yaml_schema.py"),
        "stata_validation_script": paths.get("stata_validation_script", "stata/src/py/validate_yaml_schema.py"),
        "default_branch": branches.get("default", "main"),
        "integration_branch": branches.get("integration", "develop"),
        "sync_enabled": str(bool(sync.get("enabled", True))).lower(),
        "sync_target_repo": sync_target_repo,
        "sync_target_owner": sync_owner,
        "sync_target_name": sync_name,
        "sync_target_branch": sync.get("target_branch", "stage"),
        "schema_strict": str(bool(quality_gates.get("schema_strict", True))).lower(),
        "require_cross_language_tests": str(bool(quality_gates.get("require_cross_language_tests", True))).lower(),
    }

    output_path = os.getenv("GITHUB_OUTPUT")
    if output_path:
        with open(output_path, "a", encoding="utf-8") as stream:
            for key, value in outputs.items():
                stream.write(f"{key}={value}\n")
    else:
        for key, value in outputs.items():
            print(f"{key}={value}")


if __name__ == "__main__":
    main()
