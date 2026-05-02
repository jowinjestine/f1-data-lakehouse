with results as (
    select * from {{ ref('fct_race_results') }}
)

select
    year,
    team_name,
    count(distinct driver_number) as num_drivers,
    count(*) as race_entries,
    sum(points) as total_points,
    countif(is_winner) as wins,
    countif(is_podium) as podiums,
    avg(finish_position) as avg_finish_position
from results
where team_name is not null
group by year, team_name
