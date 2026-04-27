# Data Availability

## Coverage by Source

### Jolpica F1 API (Ergast Successor)

| Dataset | Years Available | Notes |
|---------|----------------|-------|
| Race Results | 1950-present | Complete for all championship rounds |
| Driver Standings | 1950-present | End-of-season standings |
| Constructor Standings | 1958-present | Constructors' championship started 1958 |
| Qualifying | 2003-present | Modern qualifying format; earlier data sparse |
| Pit Stops | 2011-present | Pit stop timing data introduced 2011 |
| Drivers | 1950-present | All drivers who entered a championship event |
| Constructors | 1950-present | All constructors who entered a championship event |
| Circuits | 1950-present | All circuits used in championship events |

### FastF1 (Python SDK)

| Dataset | Years Available | Notes |
|---------|----------------|-------|
| Lap Times | 2018-present | Per-lap timing with accuracy flags |
| Session Results | 2018-present | Detailed session results with status codes |
| Weather | 2018-present | Track temperature, air temperature, humidity, wind |
| Telemetry | 2018-present | Car telemetry (speed, throttle, brake, gear) — not ingested by default |

## Availability Matrix

| Feature | 1950-1957 | 1958-2002 | 2003-2010 | 2011-2017 | 2018+ |
|---------|-----------|-----------|-----------|-----------|-------|
| Race results | Jolpica | Jolpica | Jolpica | Jolpica | FastF1 + Jolpica |
| Driver standings | Jolpica | Jolpica | Jolpica | Jolpica | Jolpica |
| Constructor standings | — | Jolpica | Jolpica | Jolpica | Jolpica |
| Qualifying | — | — | Jolpica | Jolpica | Jolpica |
| Pit stops | — | — | — | Jolpica | Jolpica |
| Lap times | — | — | — | — | FastF1 |
| Weather | — | — | — | — | FastF1 |
| Telemetry | — | — | — | — | FastF1 (not ingested) |

## Known Gaps

- **Pre-2003 qualifying**: Qualifying format varied significantly before 2003. Data is incomplete or inconsistent.
- **Sprint races**: Available from 2021+. Session type `S` (Sprint) is handled separately from `R` (Race) and `Q` (Qualifying).
- **Wet/mixed conditions**: Weather data only available from FastF1 (2018+). Historical wet races must be identified from external sources.
- **DNF/DNS classification**: Status codes differ between FastF1 and Jolpica. Staging models normalize to `Finished`, `DNF`, `DNS`, `DSQ`, `Other`.
- **Points systems**: Points have changed multiple times (1950, 1960, 1991, 2003, 2010, 2019 sprint). Aggregations use actual points awarded, not retroactive recalculations.

## Entity Resolution

Drivers, constructors, and circuits appear in both sources with different identifiers. Crosswalk seed files in `dbt/seeds/` map between:

- `fastf1_driver_id` ↔ `jolpica_driver_id` → `normalized_id`
- `fastf1_constructor_id` ↔ `jolpica_constructor_id` → `normalized_id`
- `fastf1_circuit_id` ↔ `jolpica_circuit_id` → `normalized_id`

Constructor name changes (e.g., Renault → Alpine, Toro Rosso → AlphaTauri → VCARB) are tracked with `valid_from` and `valid_to` fields.
