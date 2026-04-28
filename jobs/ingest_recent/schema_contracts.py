import json
import logging
from dataclasses import dataclass, field
from pathlib import Path

import pandas as pd
import yaml

logger = logging.getLogger(__name__)

CONTRACTS_DIR = Path(__file__).resolve().parent.parent.parent / "contracts"


@dataclass
class ValidationResult:
    valid: bool
    errors: list[str] = field(default_factory=list)


def load_contract(source: str, dataset: str) -> dict:
    contract_file = CONTRACTS_DIR / f"{source}_{dataset}.yml"
    if not contract_file.exists():
        logger.warning("No contract found for %s/%s at %s", source, dataset, contract_file)
        return {}
    with open(contract_file) as f:
        return yaml.safe_load(f)


def validate(df: pd.DataFrame, source: str, dataset: str) -> ValidationResult:
    contract = load_contract(source, dataset)
    if not contract:
        return ValidationResult(valid=True)

    errors = []
    required_columns = contract.get("required_columns", [])

    for col_def in required_columns:
        col_name = col_def["name"]
        if col_name not in df.columns:
            errors.append(f"Missing required column: {col_name}")

    if errors:
        logger.warning("Validation failed for %s/%s: %s", source, dataset, errors)
        return ValidationResult(valid=False, errors=errors)

    logger.info("Validation passed for %s/%s (%d rows)", source, dataset, len(df))
    return ValidationResult(valid=True)


def format_quarantine_error(source: str, dataset: str, result: ValidationResult) -> str:
    return json.dumps(
        {
            "source": source,
            "dataset": dataset,
            "errors": result.errors,
        }
    )
