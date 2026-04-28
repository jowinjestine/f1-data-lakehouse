# Data Sources

The F1 Data Lakehouse ingests from two complementary data sources, providing both modern telemetry data and comprehensive historical records.

## FastF1 SDK

- **Coverage**: 2018 to present
- **Data types**: Timing, laps, weather, session results, car telemetry
- **Access method**: Python SDK (`fastf1` package)
- **Rate limiting**: Built-in caching to `/tmp`

### Datasets Extracted

| Dataset | Description | Key Fields |
|---|---|---|
| `laps` | Lap-by-lap timing data | LapTime, Sector1/2/3Time, TyreLife, Compound, IsAccurate |
| `results` | Session results | Position, Points, GridPosition, Status, TeamName |
| `weather` | Track weather conditions | AirTemp, TrackTemp, Humidity, WindSpeed, WindDirection, Rainfall |

### Client: `jobs/ingest_recent/fastf1_client.py`
- `load_session_data(year, round, session_type)` returns dict of DataFrames
- Normalizes column names to snake_case
- Adds `ingestion_timestamp` and `schema_version` metadata columns

## Jolpica F1 API (Ergast Successor)

- **Coverage**: 1950 to present
- **Data types**: Results, standings, qualifying, pit stops, circuits, drivers, constructors
- **Access method**: REST API via `fastf1.ergast.Ergast` wrapper
- **Rate limiting**: 8-10 seconds between requests (stay under 500 req/h sustained)

### Datasets Extracted

| Dataset | Available From | Description |
|---|---|---|
| `results` | 1950 | Race results with positions, points, status |
| `qualifying` | 2003 | Qualifying times (Q1/Q2/Q3) |
| `pitstops` | 2011 | Pit stop durations and lap numbers |
| `standings` | 1950 | Driver championship standings |
| `constructor_standings` | 1958 | Constructor championship standings |
| `circuits` | 1950 | Circuit metadata (location, country, coordinates) |
| `drivers` | 1950 | Driver information (name, nationality, DOB) |
| `constructors` | 1950 | Constructor/team information |

### Client: `jobs/ingest_recent/jolpica_client.py`
- Pagination via `is_complete` / `get_next_result_page()`
- Rate-limited with configurable delay (default 8s)
- Returns pandas DataFrames

## Entity Resolution

Since FastF1 and Jolpica use different identifiers for the same entities, crosswalk seed files provide identity mapping:

| Crosswalk | Purpose |
|---|---|
| `driver_crosswalk.csv` | Map FastF1 driver IDs to Jolpica driver IDs |
| `constructor_crosswalk.csv` | Map FastF1 team names to Jolpica constructor IDs |
| `circuit_crosswalk.csv` | Map FastF1 circuit keys to Jolpica circuit IDs |

Fields: `source, source_id, normalized_id, source_name, normalized_name, abbreviation, valid_from, valid_to, notes`
