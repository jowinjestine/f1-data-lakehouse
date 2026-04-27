# Era Normalization

## Why Normalize?

Direct comparison of raw statistics across F1 eras is misleading. Key differences include:

- **Number of races per season**: 7-8 races in the 1950s vs 20-24 races today
- **Points systems**: Multiple changes (1950, 1960, 1991, 2003, 2010, 2019 sprint points)
- **Field size**: Fewer entries in early decades, more competitive fields now
- **Reliability**: Cars finished far less often in early eras, inflating per-race metrics for survivors
- **Regulation changes**: Ground effect, turbo, refueling, hybrid — each era has different competitive dynamics

## Era Definitions

| Era | Years | Rationale |
|-----|-------|-----------|
| Post-war | 1950-1970 | Front-engine to rear-engine transition, early championship |
| Ground effect | 1971-1993 | Aerodynamic revolution through active suspension ban |
| Modern | 1994-2013 | Safety reforms, refueling era, Schumacher dominance |
| Hybrid | 2014-2021 | Turbo-hybrid power units, Mercedes dominance |
| Ground effect revival | 2022+ | New aero regulations, cost cap |

## Normalization Approach

This project uses **rate-based metrics** rather than absolute totals for cross-era comparison:

| Metric | Formula | Why |
|--------|---------|-----|
| Win rate | `wins / races_entered` | Controls for different season lengths |
| Podium rate | `podiums / races_entered` | Controls for different season lengths |
| Points per race | `season_points / races_entered` | Partially controls for points system changes |

### Limitations

- **Points per race** is still affected by points system changes (e.g., 10 points for a win pre-2010 vs 25 points post-2010). The `agg_era_comparison` model reports this metric within each era, not across eras.
- **Reliability normalization** is not applied. A driver who finished 80% of races in the 1960s was exceptional; today 95%+ finish rates are normal. This inflates win/podium rates for modern drivers.
- **Field competitiveness** is not modeled. Dominating a 20-car field is different from dominating a 30-car field.

## Dashboard Usage

When displaying era comparison data:

1. Always show the era label alongside metrics
2. Use rate-based metrics (win_rate, podium_rate) for cross-era charts
3. Use absolute metrics (total_wins, total_points) only within single-era views
4. Include a note explaining that cross-era comparisons are approximate
5. Do not rank drivers across eras by absolute totals without context

## What This Project Does NOT Do

- Retroactive points recalculation (applying modern points to historical races)
- Elo-style rating systems
- Adjusted-for-car-performance metrics
- Teammate-relative performance indexing across eras

These are valid analytical approaches but require subjective modeling decisions beyond the scope of a data lakehouse.
