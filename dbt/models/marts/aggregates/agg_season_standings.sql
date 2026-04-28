with results as (
    select * from {{ ref('fct_race_results') }}
)

select
    year,
    driver_key,
    driver_name,
    constructor_key,
    constructor_name,
    count(*) as races,
    sum(points) as total_points,
    countif(position = 1) as wins,
    countif(position <= 3) as podiums,
    countif(position = 1) / nullif(count(*), 0) as wins_per_start,
    countif(position <= 3) / nullif(count(*), 0) as podiums_per_start,
    data_source
from results
where position is not null
group by year, driver_key, driver_name, constructor_key, constructor_name, data_source
