# Metric Definitions

## Career Statistics (`agg_career_stats`)

| Metric | Formula | Notes |
|--------|---------|-------|
| `total_races` | COUNT of race entries | Includes DNFs, DSQs |
| `total_wins` | COUNT where `position = 1` | Championship rounds only |
| `total_podiums` | COUNT where `position <= 3` | |
| `total_poles` | COUNT where `grid_position = 1` | Qualifying-based, 2003+ only |
| `total_points` | SUM of `points` | Actual points per era's scoring system |
| `win_rate` | `total_wins / total_races` | |
| `podium_rate` | `total_podiums / total_races` | |

## Season Standings (`agg_season_standings`)

| Metric | Formula | Notes |
|--------|---------|-------|
| `total_points` | SUM of `points` for the season | Cumulative through season |
| `wins` | COUNT where `position = 1` in season | |
| `podiums` | COUNT where `position <= 3` in season | |
| `season_position` | RANK by `total_points` DESC | Tiebreaker: wins, then podiums |

## Lap Analysis (`fct_lap_analysis`)

| Metric | Formula | Notes |
|--------|---------|-------|
| `lap_time_seconds` | Lap time converted to FLOAT64 seconds | FastF1 timedelta → seconds |
| `sector_1_seconds` | Sector 1 time in seconds | |
| `sector_2_seconds` | Sector 2 time in seconds | |
| `sector_3_seconds` | Sector 3 time in seconds | |
| `is_accurate` | FastF1 accuracy flag | FALSE for in/out laps, SC laps |
| `is_personal_best` | `lap_time = MIN(lap_time) for driver in session` | |

## Era Comparison (`agg_era_comparison`)

| Metric | Formula | Notes |
|--------|---------|-------|
| `avg_wins_per_season` | AVG wins per driver per season in era | |
| `avg_podiums_per_season` | AVG podiums per driver per season in era | |
| `avg_points_per_race` | AVG points per race start in era | Affected by points system changes |
| `races_per_season` | AVG races per season in era | Growing over decades |
| `era` | Categorical: `1950-1970`, `1971-1993`, `1994-2013`, `2014-2021`, `2022+` | Based on major regulation changes |

See [Era Normalization](era_normalization.md) for cross-era comparison methodology.

## Head-to-Head (`agg_head_to_head`)

| Metric | Formula | Notes |
|--------|---------|-------|
| `qualifying_wins` | COUNT of races where driver out-qualified teammate | 2003+ only |
| `race_wins` | COUNT of races where driver finished ahead of teammate | Both must finish |
| `points_advantage` | `driver_points - teammate_points` in shared races | |

## Pit Stops (`fct_pitstops`)

| Metric | Formula | Notes |
|--------|---------|-------|
| `duration_seconds` | Pit stop duration in seconds | Stationary time, 2011+ only |
| `total_pit_time` | SUM of `duration_seconds` for driver in race | |
| `stop_number` | Sequential pit stop number in race | |
