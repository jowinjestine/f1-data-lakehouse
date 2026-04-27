import pytest

from jobs.ingest_recent.fastf1_client import _to_snake_case, _normalize_columns

import pandas as pd


@pytest.mark.unit
class TestFastF1Client:
    def test_to_snake_case(self):
        assert _to_snake_case("LapTime") == "lap_time"
        assert _to_snake_case("IsAccurate") == "is_accurate"
        assert _to_snake_case("Sector1Time") == "sector1_time"
        assert _to_snake_case("DriverNumber") == "driver_number"
        assert _to_snake_case("already_snake") == "already_snake"

    def test_normalize_columns(self):
        df = pd.DataFrame({"LapTime": [1], "DriverNumber": [44]})
        result = _normalize_columns(df)
        assert "lap_time" in result.columns
        assert "driver_number" in result.columns
        assert "LapTime" not in result.columns
