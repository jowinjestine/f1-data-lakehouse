from unittest.mock import patch

import pytest

from jobs.ingest_recent.jolpica_client import _rate_limit


@pytest.mark.unit
class TestJolpicaClient:
    @patch("jobs.ingest_recent.jolpica_client.time.sleep")
    def test_rate_limit_sleeps(self, mock_sleep):
        _rate_limit()
        mock_sleep.assert_called_once()
        call_args = mock_sleep.call_args[0][0]
        assert call_args >= 8.0
