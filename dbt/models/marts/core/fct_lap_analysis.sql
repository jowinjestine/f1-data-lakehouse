with laps as (
    select * from {{ ref('stg_laps') }}
),

weather as (
    select * from {{ ref('stg_weather') }}
),

drivers as (
    select * from {{ ref('dim_drivers') }}
)

select
    l.lap_id,
    l.year,
    l.round_number,
    l.session_type,
    l.driver_number,
    d.driver_key,
    d.full_name as driver_name,
    l.lap_number,
    l.lap_time_seconds,
    l.sector1_seconds,
    l.sector2_seconds,
    l.sector3_seconds,
    l.tyre_compound,
    l.tyre_life,
    w.air_temp_celsius,
    w.track_temp_celsius,
    w.humidity_percent,
    w.wind_speed_kph,
    w.wind_cardinal,
    w.is_raining,
    'fastf1' as data_source
from laps l
left join weather w
    on l.year = w.year
    and l.round_number = w.round_number
    and l.session_type = w.session_type
left join drivers d
    on l.driver_number = d.permanent_number
