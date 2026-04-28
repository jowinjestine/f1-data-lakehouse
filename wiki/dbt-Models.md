# dbt Models

## Overview

- **21 models** total across staging, marts, and aggregates
- **44 data tests** including custom assertions
- **4 seed files** for entity crosswalks and metadata
- **13 sources** from FastF1 and Jolpica GCS external tables

## Staging Models (f1_staging)

All staging models filter to `f1_ops.latest_successful_objects` for deduplication.

### FastF1 Staging

| Model | Source | Description |
|---|---|---|
| `stg_laps` | FastF1 laps | Timedeltas to FLOAT64, filter IsAccurate, surrogate key |
| `stg_results` | FastF1 results | DNF/DNS handling, points normalization |
| `stg_weather` | FastF1 weather | Temperature units, cardinal wind direction |
| `stg_schedule` | FastF1 schedule | Timestamp normalization |

### Jolpica Staging

| Model | Source | Description |
|---|---|---|
| `stg_jolpica_results` | Jolpica results | Race results with position and points |
| `stg_jolpica_qualifying` | Jolpica qualifying | Q1/Q2/Q3 times (2003+) |
| `stg_jolpica_pitstops` | Jolpica pitstops | Pit stop durations (2011+) |
| `stg_jolpica_standings` | Jolpica standings | Championship standings |
| `stg_jolpica_circuits` | Jolpica circuits | Circuit metadata |
| `stg_jolpica_drivers` | Jolpica drivers | Driver information |
| `stg_jolpica_constructors` | Jolpica constructors | Constructor/team info |

## Dimension Models (f1_analytics)

| Model | Strategy | Description |
|---|---|---|
| `dim_drivers` | UNION via crosswalk, SCD Type 1 | Combined driver data from both sources |
| `dim_circuits` | Jolpica + seeds + metadata | Circuit details with coordinates |
| `dim_constructors` | Via crosswalk | Constructor/team identity resolution |
| `dim_seasons` | Schedule + Jolpica | Season metadata and round counts |

## Fact Models (f1_analytics)

| Model | Coverage | Description |
|---|---|---|
| `fct_race_results` | 1950+ | UNION FastF1 (2018+) with Jolpica (1950-2017) via crosswalks |
| `fct_lap_analysis` | 2018+ | FastF1 laps + weather + dimensions (telemetry-era only) |
| `fct_qualifying` | 2003+ | Qualifying results with gap-to-pole |
| `fct_pitstops` | 2011+ | Pit stop durations and strategy |

## Aggregate Models (f1_analytics)

| Model | Description |
|---|---|
| `agg_season_standings` | Cumulative points progression across all years |
| `agg_constructor_standings` | Constructor championship aggregates |
| `agg_head_to_head` | Teammate comparison stats |
| `agg_era_comparison` | Normalized metrics across F1 eras (1950-70, 71-93, 94-2013, 14-21, 22+) |
| `agg_career_stats` | Career wins, poles, podiums, points_share |

## Seeds

| Seed | Purpose |
|---|---|
| `driver_crosswalk.csv` | FastF1-to-Jolpica driver identity mapping |
| `constructor_crosswalk.csv` | FastF1-to-Jolpica team identity mapping |
| `circuit_crosswalk.csv` | FastF1-to-Jolpica circuit identity mapping |
| `team_colors.csv` | Official F1 team hex colors for visualization |

## Testing Strategy

- **Schema tests**: unique, not_null, relationships, accepted_values on all models
- **Custom tests**:
  - `assert_lap_times_positive` — No negative lap times
  - `assert_no_orphan_laps` — All laps link to valid sessions
  - `assert_standings_monotonic` — Points don't decrease within a season
- **Crosswalk tests**: No unmapped drivers/constructors/circuits
