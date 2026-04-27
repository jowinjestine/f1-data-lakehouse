with raw as (
    select * from {{ source('f1_raw', 'fastf1_weather') }}
),

latest_objects as (
    select * from {{ source('f1_ops', 'latest_successful_objects') }}
    where source = 'fastf1' and dataset = 'weather'
),

filtered as (
    select r.*
    from raw r
    inner join latest_objects lo
        on r.year = lo.year
        and r.round = lo.round
        and r.session = lo.session_type
        and r.ingest_run_id = lo.latest_ingest_run_id
)

select
    cast(year as int64) as year,
    cast(round as int64) as round_number,
    session as session_type,
    cast(air_temp as float64) as air_temp_celsius,
    cast(track_temp as float64) as track_temp_celsius,
    cast(humidity as float64) as humidity_percent,
    cast(wind_speed as float64) as wind_speed_kph,
    cast(wind_direction as float64) as wind_direction_degrees,
    case
        when wind_direction >= 337.5 or wind_direction < 22.5 then 'N'
        when wind_direction >= 22.5 and wind_direction < 67.5 then 'NE'
        when wind_direction >= 67.5 and wind_direction < 112.5 then 'E'
        when wind_direction >= 112.5 and wind_direction < 157.5 then 'SE'
        when wind_direction >= 157.5 and wind_direction < 202.5 then 'S'
        when wind_direction >= 202.5 and wind_direction < 247.5 then 'SW'
        when wind_direction >= 247.5 and wind_direction < 292.5 then 'W'
        when wind_direction >= 292.5 and wind_direction < 337.5 then 'NW'
    end as wind_cardinal,
    cast(rainfall as bool) as is_raining,
    ingestion_timestamp,
    schema_version
from filtered
