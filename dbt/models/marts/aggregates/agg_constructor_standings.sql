with results as (
    select * from {{ ref('fct_race_results') }}
)

select
    year,
    constructor_key,
    constructor_name,
    count(distinct driver_key) as num_drivers,
    count(*) as race_entries,
    sum(points) as total_points,
    countif(position = 1) as wins,
    countif(position <= 3) as podiums,
    data_source
from results
where constructor_key is not null
group by year, constructor_key, constructor_name, data_source
