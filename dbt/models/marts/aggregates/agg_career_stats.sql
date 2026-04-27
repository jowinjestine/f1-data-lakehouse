with results as (
    select * from {{ ref('fct_race_results') }}
)

select
    driver_key,
    driver_name,
    min(year) as first_year,
    max(year) as last_year,
    count(*) as total_starts,
    sum(points) as total_points,
    countif(position = 1) as total_wins,
    countif(position <= 3) as total_podiums,
    countif(grid_position = 1) as total_poles,
    countif(position = 1) / nullif(count(*), 0) as wins_per_start,
    countif(position <= 3) / nullif(count(*), 0) as podiums_per_start,
    count(distinct year) as seasons
from results
where position is not null
group by driver_key, driver_name
