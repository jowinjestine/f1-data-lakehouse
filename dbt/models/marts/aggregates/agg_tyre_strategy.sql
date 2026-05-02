with laps as (
    select * from {{ ref('fct_lap_analysis') }}
    where session_type = 'Race'
      and tyre_compound is not null
),

stint_summary as (
    select
        session_key,
        circuit_short_name,
        year,
        driver_number,
        driver_name,
        tyre_compound,
        stint_number,
        count(*) as stint_laps,
        min(lap_time_seconds) as best_lap_seconds,
        avg(lap_time_seconds) as avg_lap_seconds
    from laps
    where lap_time_seconds is not null
      and not is_pit_out_lap
    group by session_key, circuit_short_name, year, driver_number, driver_name,
             tyre_compound, stint_number
),

driver_strategy as (
    select
        session_key,
        circuit_short_name,
        year,
        driver_number,
        driver_name,
        count(distinct stint_number) as total_stints,
        string_agg(tyre_compound, ' → ' order by stint_number) as strategy_sequence,
        sum(stint_laps) as total_laps
    from stint_summary
    group by session_key, circuit_short_name, year, driver_number, driver_name
)

select
    ds.session_key,
    ds.year,
    ds.circuit_short_name,
    ds.driver_number,
    ds.driver_name,
    ds.total_stints,
    ds.strategy_sequence,
    ds.total_laps,
    ss.tyre_compound,
    ss.stint_number,
    ss.stint_laps,
    ss.best_lap_seconds,
    ss.avg_lap_seconds
from driver_strategy ds
inner join stint_summary ss
    on ds.session_key = ss.session_key
    and ds.driver_number = ss.driver_number
