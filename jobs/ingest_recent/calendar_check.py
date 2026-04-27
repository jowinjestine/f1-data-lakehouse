import logging
from dataclasses import dataclass
from datetime import datetime, timedelta, timezone

import fastf1

logger = logging.getLogger(__name__)


@dataclass
class RecentEvent:
    year: int
    round_number: int
    event_name: str
    session_types: list[str]


def get_recent_events(lookback_days: int = 7) -> list[RecentEvent]:
    now = datetime.now(timezone.utc)
    cutoff = now - timedelta(days=lookback_days)
    current_year = now.year

    schedule = fastf1.get_event_schedule(current_year)
    events = []

    for _, event in schedule.iterrows():
        event_date = event.get("EventDate")
        if event_date is None:
            continue

        if hasattr(event_date, "to_pydatetime"):
            event_date = event_date.to_pydatetime()
        if event_date.tzinfo is None:
            event_date = event_date.replace(tzinfo=timezone.utc)

        if cutoff <= event_date <= now:
            session_types = ["R", "Q"]
            if event.get("EventFormat", "") in ("sprint_qualifying", "sprint_shootout", "sprint"):
                session_types.extend(["S", "SQ"])

            events.append(
                RecentEvent(
                    year=current_year,
                    round_number=int(event["RoundNumber"]),
                    event_name=str(event["EventName"]),
                    session_types=session_types,
                )
            )

    logger.info("Found %d recent events in last %d days", len(events), lookback_days)
    return events
