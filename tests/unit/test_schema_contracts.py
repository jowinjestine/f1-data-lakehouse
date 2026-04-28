import pandas as pd
import pytest

from jobs.ingest_recent.schema_contracts import format_quarantine_error, validate


@pytest.mark.unit
class TestSchemaContracts:
    def test_validate_valid_data(self):
        df = pd.DataFrame(
            {
                "driver_number": ["1", "44"],
                "lap_number": [1, 2],
                "lap_time": [90.5, 91.2],
                "sector1_time": [28.1, 28.5],
                "sector2_time": [31.0, 31.2],
                "sector3_time": [31.4, 31.5],
                "compound": ["SOFT", "MEDIUM"],
                "tyre_life": [1.0, 2.0],
                "is_accurate": [True, True],
            }
        )
        result = validate(df, "fastf1", "laps")
        assert result.valid
        assert len(result.errors) == 0

    def test_validate_missing_required_column(self):
        df = pd.DataFrame(
            {
                "lap_number": [1, 2],
                "lap_time": [90.5, 91.2],
            }
        )
        result = validate(df, "fastf1", "laps")
        assert not result.valid
        assert any("driver_number" in e for e in result.errors)

    def test_validate_no_contract(self):
        df = pd.DataFrame({"col": [1]})
        result = validate(df, "unknown", "unknown")
        assert result.valid

    def test_format_quarantine_error(self):
        from jobs.ingest_recent.schema_contracts import ValidationResult

        result = ValidationResult(valid=False, errors=["Missing: col_a"])
        error_json = format_quarantine_error("fastf1", "laps", result)
        import json

        parsed = json.loads(error_json)
        assert parsed["source"] == "fastf1"
        assert "Missing: col_a" in parsed["errors"]
