from datetime import UTC, datetime, timedelta
from unittest.mock import patch

import pandas as pd
import pytest

from jobs.ingest_recent.calendar_check import get_recent_events


@pytest.mark.unit
class TestCalendarCheck:
    @patch("jobs.ingest_recent.calendar_check.fastf1.get_event_schedule")
    def test_finds_recent_event(self, mock_schedule):
        now = datetime.now(UTC)
        recent_date = now - timedelta(days=2)

        mock_schedule.return_value = pd.DataFrame(
            [
                {
                    "RoundNumber": 5,
                    "EventName": "Test GP",
                    "EventDate": recent_date,
                    "EventFormat": "conventional",
                }
            ]
        )

        events = get_recent_events(lookback_days=7)
        assert len(events) == 1
        assert events[0].event_name == "Test GP"
        assert events[0].round_number == 5
        assert "R" in events[0].session_types
        assert "Q" in events[0].session_types

    @patch("jobs.ingest_recent.calendar_check.fastf1.get_event_schedule")
    def test_no_recent_events(self, mock_schedule):
        old_date = datetime.now(UTC) - timedelta(days=30)

        mock_schedule.return_value = pd.DataFrame(
            [
                {
                    "RoundNumber": 1,
                    "EventName": "Old GP",
                    "EventDate": old_date,
                    "EventFormat": "conventional",
                }
            ]
        )

        events = get_recent_events(lookback_days=7)
        assert len(events) == 0
