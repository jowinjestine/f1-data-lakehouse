with results as (
    select * from {{ ref('fct_race_results') }}
),

with_era as (
    select
        *,
        case
            when year between 1950 and 1970 then '1950-70'
            when year between 1971 and 1993 then '1971-93'
            when year between 1994 and 2013 then '1994-2013'
            when year between 2014 and 2021 then '2014-21'
            when year >= 2022 then '2022+'
        end as era
    from results
)

select
    era,
    count(distinct driver_key) as unique_drivers,
    count(distinct year) as seasons,
    count(*) as total_race_entries,
    avg(points) as avg_points_per_entry,
    sum(countif(position = 1)) over (partition by era) / nullif(count(*), 0) as era_win_rate,
    data_source
from with_era
where position is not null
group by era, data_source
order by era
