with results as (
    select * from {{ ref('fct_race_results') }}
    where finish_position is not null
)

select
    year,
    count(distinct driver_number) as unique_drivers,
    count(distinct team_name) as unique_teams,
    count(distinct circuit_short_name) as unique_circuits,
    count(*) as total_race_entries,
    avg(points) as avg_points_per_entry,
    countif(is_winner) * 1.0 / nullif(count(*), 0) as win_rate,
    avg(finish_position) as avg_finish_position,
    sum(points) as total_season_points
from results
group by year
order by year
