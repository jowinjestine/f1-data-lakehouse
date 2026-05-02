with results as (
    select * from {{ ref('fct_race_results') }}
)

select
    year,
    driver_number,
    driver_name,
    driver_code,
    team_name,
    count(*) as races,
    sum(points) as total_points,
    countif(is_winner) as wins,
    countif(is_podium) as podiums,
    countif(is_winner) / nullif(count(*), 0) as win_rate,
    countif(is_podium) / nullif(count(*), 0) as podium_rate,
    avg(finish_position) as avg_finish_position
from results
where finish_position is not null
group by year, driver_number, driver_name, driver_code, team_name
