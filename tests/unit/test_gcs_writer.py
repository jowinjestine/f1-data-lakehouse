import pytest

from jobs.ingest_recent.gcs_writer import _build_path, _build_quarantine_path


@pytest.mark.unit
class TestGcsWriter:
    def test_build_path_full(self):
        path = _build_path("fastf1", "laps", 2024, 8, "R", "20240427T120000Z")
        expected = (
            "raw/source=fastf1/dataset=laps/year=2024/round=08"
            "/session=R/ingest_run_id=20240427T120000Z/part-000.parquet"
        )
        assert path == expected

    def test_build_path_no_session(self):
        path = _build_path("jolpica", "results", 2024, 8, None, "20240427T120000Z")
        expected = (
            "raw/source=jolpica/dataset=results/year=2024/round=08/ingest_run_id=20240427T120000Z/part-000.parquet"
        )
        assert path == expected

    def test_build_path_no_round(self):
        path = _build_path("jolpica", "drivers", 2024, None, None, "20240427T120000Z")
        expected = "raw/source=jolpica/dataset=drivers/year=2024/ingest_run_id=20240427T120000Z/part-000.parquet"
        assert path == expected

    def test_build_quarantine_path(self):
        path = _build_quarantine_path("fastf1", "laps", 2024, 8, "20240427T120000Z")
        expected = (
            "raw/_quarantine/source=fastf1/dataset=laps/year=2024/round=08/ingest_run_id=20240427T120000Z/error.json"
        )
        assert path == expected
